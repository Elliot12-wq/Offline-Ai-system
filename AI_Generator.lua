-- AI_Generator: builds replies from retrieved knowledge, templates, and heuristics.
-- Template + retrieval generation; it does not pretend to be a neural LLM. Returns { text, meta = { ids, topic, src } }.
local Generator = {}

local ctx

function Generator.init(c)
	ctx = c
	-- lets NLP see the conversation state (pending offers, last answer) without depending on Memory
	c.NLP.conv = function() return c.Memory.conv() end
end

local function mk(text, meta) return { text = text, meta = meta or { ids = {} } } end

local function firstPara(s) return (s:match("^(.-)\n\n") or s) end

local function fence(code) return "```lua\n" .. code .. "\n```" end

-- ===== static hints on pasted code (heuristic, not a compiler) =====
local function strip(code)
	code = code:gsub("%-%-%[=*%[.-%]=*%]", ""):gsub("%-%-[^\n]*", "")
	code = code:gsub('"[^"\n]*"', '""'):gsub("'[^'\n]*'", "''")
	return code
end

local function count(code, word)
	local n = 0
	for _ in code:gmatch("%f[%w_]" .. word .. "%f[^%w_]") do n = n + 1 end
	return n
end

local function lint(src)
	local code = strip(src)
	local h = {}
	local opens = count(code, "function") + count(code, "if") + count(code, "for") + count(code, "while")
	local ends = count(code, "end")
	if opens > ends then
		h[#h + 1] = "Looks like " .. (opens - ends) .. " `end` may be missing (blocks opened: " .. opens .. ", `end`s: " .. ends .. ")."
	elseif ends > opens then
		h[#h + 1] = "Looks like " .. (ends - opens) .. " extra `end` (blocks opened: " .. opens .. ", `end`s: " .. ends .. ")."
	end
	if code:find("%f[%w_]wait%s*%(") then h[#h + 1] = "`wait()` is deprecated; use `task.wait()`." end
	if code:find("%f[%w_]spawn%s*%(") or code:find("%f[%w_]delay%s*%(") then h[#h + 1] = "`spawn`/`delay` are deprecated; use `task.spawn` / `task.delay`." end
	if code:find(":connect%s*%(") then h[#h + 1] = "`:connect` is deprecated; use `:Connect`." end
	if code:find("while%s+true%s+do") and not code:find("task%.wait") and not code:find("%f[%w_]wait%s*%(") and not code:find("Wait%s*%(") then
		h[#h + 1] = "`while true do` with no `task.wait()` will freeze the game; add a yield."
	end
	if code:find("Instance%.new%s*%([^%)]-,[^%)]-%)") then
		h[#h + 1] = "`Instance.new(class, parent)` sets Parent before properties; set properties first, then Parent."
	end
	if code:find(":FindFirstChild%b()%.") or code:find(":FindFirstChild%b():") then
		h[#h + 1] = "You index the result of `FindFirstChild` directly; it can be nil. Check it first or use `WaitForChild`."
	end
	local localsSeen = {}
	for names in code:gmatch("local%s+([%w_,%s]+)") do
		for n in names:gmatch("[%a_][%w_]*") do localsSeen[n] = true end
	end
	local globals = {}
	for line in code:gmatch("[^\n]+") do
		local n = line:match("^([%a_][%w_]*)%s*=[^=]")
		if n and not localsSeen[n] and not globals[n] and n ~= "_G" then globals[n] = true; globals[#globals + 1] = n end
	end
	if #globals > 0 then
		h[#h + 1] = "Possible accidental global(s): `" .. table.concat(globals, "`, `", 1, math.min(3, #globals)) .. "` (missing `local`?)."
	end
	return h
end

local function explainCode(src)
	local bits = {}
	local services, seen = {}, {}
	for s in src:gmatch('GetService%(%s*["\'](%w+)["\']%s*%)') do
		if not seen[s] then seen[s] = true; services[#services + 1] = s end
	end
	if #services > 0 then bits[#bits + 1] = "Gets services: " .. table.concat(services, ", ") .. "." end
	local fns, fseen = {}, {}
	for n in src:gmatch("function%s+([%w_%.:]+)%s*%(") do
		if not fseen[n] then fseen[n] = true; fns[#fns + 1] = n end
	end
	if #fns > 0 then bits[#bits + 1] = "Defines function(s): " .. table.concat(fns, ", ", 1, math.min(6, #fns)) .. "." end
	local inst, iseen = {}, {}
	for c in src:gmatch('Instance%.new%(%s*["\'](%w+)["\']') do
		if not iseen[c] then iseen[c] = true; inst[#inst + 1] = c end
	end
	if #inst > 0 then bits[#bits + 1] = "Creates instances: " .. table.concat(inst, ", ") .. "." end
	local events = select(2, src:gsub(":Connect%s*%(", ""))
	if events > 0 then bits[#bits + 1] = "Connects " .. events .. " event handler(s)." end
	if src:find("TweenService") or src:find(":Create%(") then bits[#bits + 1] = "Uses tweens for animation." end
	if src:find("Heartbeat") or src:find("RenderStepped") or src:find("Stepped") then bits[#bits + 1] = "Runs code every frame through a RunService event." end
	if src:find("while%s+") then bits[#bits + 1] = "Contains a `while` loop." end
	if src:find("setmetatable") then bits[#bits + 1] = "Uses metatables (likely OOP/classes)." end
	if src:find("pcall") then bits[#bits + 1] = "Uses pcall for error handling." end
	if src:find("Motor6D") or src:find("CFrame") then bits[#bits + 1] = "Works with CFrames/joints (reanimation-style maths)." end
	return bits
end

-- ===== error message explanations =====
local ERR = {
	{ "attempt to index nil with '([%w_]+)'", function(n) return "The value before `." .. n .. "` is **nil**. Usual causes: a typo, the object doesn't exist yet (FindFirstChild returned nil), or the wrong parent. Print the parent first and use `WaitForChild` or a nil check." end },
	{ "attempt to call a nil value", function() return "You're calling something that doesn't exist: check the name, `.` vs `:`, and that the function is defined above where it's called." end },
	{ "([%w_%.]+) is not a valid member of ([%w_]+)", function(m, p) return "`" .. m .. "` isn't a child/property of `" .. p .. "`. Check spelling and the Explorer path, and use `WaitForChild` if it loads late." end },
	{ "attempt to perform arithmetic", function() return "You're doing maths on a nil or string value. Check it with `print(typeof(x), x)` and use `tonumber`." end },
	{ "infinite yield possible on '([^']+)'", function(n) return "`WaitForChild` never found `" .. n .. "`. The name or parent is wrong, or it doesn't exist on the client." end },
	{ "attempt to compare", function() return "You're comparing incompatible types (often nil vs number). Print both sides first." end },
	{ "attempt to concatenate", function() return "You're joining a nil/table with a string using `..`. Use `tostring(x)` or string interpolation." end },
	{ "expected 'end'", function() return "A block isn't closed: an `if`/`for`/`function` is missing its `end`." end },
	{ "unexpected symbol", function() return "Syntax error: check for a stray character, missing operator or unclosed bracket on that line." end },
	{ "stack overflow", function() return "A function calls itself without stopping (infinite recursion). Add a base case." end },
}

local function errorHelp(text)
	local lower = text:lower()
	for _, e in ipairs(ERR) do
		local c1, c2 = lower:match(e[1])
		if c1 ~= nil or lower:find(e[1]) then return e[2](c1, c2) end
	end
	return nil
end

-- ===== parametric code =====
local function tweenCode(s)
	local dur = s.duration or 0.3
	local style = s.easing or "Quad"
	local dir = s.direction or "Out"
	local prop = s.prop or "Size"
	local goal = ({
		Size = "Size = UDim2.fromOffset(340, 220)",
		Position = "Position = UDim2.fromScale(0.5, 0.5)",
		Transparency = "BackgroundTransparency = 0.5",
		Rotation = "Rotation = 45",
		Color = "BackgroundColor3 = Color3.fromRGB(" .. (s.color or "130, 140, 255") .. ")",
	})[prop]
	return "local TweenService = game:GetService(\"TweenService\")\n\n"
		.. "local info = TweenInfo.new(" .. dur .. ", Enum.EasingStyle." .. style .. ", Enum.EasingDirection." .. dir .. ")\n"
		.. "TweenService:Create(frame, info, {" .. goal .. "}):Play()"
end

local function cap(s, n)
	if #s <= n then return s end
	local cut = s:sub(1, n)
	local c = select(2, cut:gsub("```", ""))
	if c % 2 == 1 then
		local last = 0
		for i in cut:gmatch("()```") do last = i end
		cut = cut:sub(1, last - 1)
	end
	cut = cut:match("^(.*)\n\n") or cut
	return cut .. "\n\n(Trimmed for length; ask me to continue on any part.)"
end

-- ===== conversation helpers =====
local function conv() return ctx.Memory.conv() end

local function splitParas(text)
	local out = {}
	for p in (text .. "\n\n"):gmatch("(.-)\n\n") do
		if p:find("%S") then out[#out + 1] = p end
	end
	return out
end

local function sentences(p)
	local out, n, s, i = {}, #p, 1, 1
	while i <= n do
		local ch = p:sub(i, i)
		local tail = p:sub(math.max(1, i - 3), i)
		if (ch == "." or ch == "!" or ch == "?") and (i == n or p:sub(i + 1, i + 1):find("%s")) and tail ~= "e.g." and tail ~= "i.e." then
			out[#out + 1] = p:sub(s, i)
			s = i + 1
			while s <= n and p:sub(s, s):find("%s") do s = s + 1 end
			i = s
		else
			i = i + 1
		end
	end
	if s <= n then out[#out + 1] = p:sub(s) end
	return out
end

local function qset(a)
	local q = {}
	for _, t in ipairs(a.terms or {}) do q[t] = true end
	if a.follow and a.ctxTerms and #(a.terms or {}) <= 2 then
		for _, t in ipairs(a.ctxTerms) do q[t] = true end
	end
	return q
end

local function overlapCount(txt, q)
	local m = 0
	for _, t in ipairs(ctx.NLP.terms(txt)) do if q[t] then m = m + 1 end end
	return m
end

-- the sentences of `text` that best match the question (original order kept)
local function bestSentences(a, text, n)
	local q = qset(a)
	local all = {}
	for _, p in ipairs(splitParas(text)) do
		for _, s in ipairs(sentences(p)) do
			all[#all + 1] = { s = s, sc = overlapCount(s, q) - #all * 0.01, i = #all + 1 }
		end
	end
	if #all == 0 then return "" end
	local pool = {}
	for k, x in ipairs(all) do pool[k] = x end
	table.sort(pool, function(x, y) return x.sc > y.sc end)
	local sel = {}
	for k = 1, math.min(n, #pool) do sel[k] = pool[k] end
	table.sort(sel, function(x, y) return x.i < y.i end)
	local out = {}
	for k, x in ipairs(sel) do out[k] = x.s end
	return table.concat(out, " ")
end

local REASON = { "because", "so that", "since ", "otherwise", "reason", "causes", "that's why", "which is why", "without ", "prevents", "avoid" }
local function reasonScore(p)
	local lo, c = p:lower(), 0
	for _, w in ipairs(REASON) do if lo:find(w, 1, true) then c = c + 1.5 end end
	return math.min(c, 3)
end
local function stepScore(p)
	local c = 0
	if p:find("\n%s*%d+[%.%)]") or p:find("^%s*%d+[%.%)]") then c = c + 1.5 end
	if p:find("\n%s*[%-%*] ") then c = c + 1 end
	local lo = p:lower()
	if lo:find("first", 1, true) or lo:find("then ", 1, true) then c = c + 0.5 end
	return c
end

-- Picks the paragraphs of an entry that answer the question, best first, skipping what the user already received.
-- Returns text (nil when everything was already delivered) and whether a "reason" paragraph was found.
local function renderEntry(a, e, o)
	local given = ctx.Memory.given(e.id)
	local q = qset(a)
	local pool = {}
	for i, p in ipairs(splitParas(e.text)) do
		if o.repeatOK or not given[i] then
			local rs = o.fk == "why" and reasonScore(p) or 0
			pool[#pool + 1] = { i = i, p = p, rs = rs, s = overlapCount(p, q) + rs + (o.fk == "how" and stepScore(p) or 0) - i * 0.01 }
		end
	end
	if #pool == 0 then return nil end
	table.sort(pool, function(x, y) return x.s > y.s end)
	local take = o.verb == "short" and 1 or (o.verb == "detailed" and #pool or math.min(2, #pool))
	local sel = {}
	for k = 1, take do sel[k] = pool[k] end
	local lead = table.remove(sel, 1)
	table.sort(sel, function(x, y) return x.i < y.i end)
	table.insert(sel, 1, lead)
	local out = {}
	for _, x in ipairs(sel) do
		if o.verb == "short" then
			out[#out + 1] = bestSentences(a, x.p, 2) -- short answers are not marked delivered, so "more" gives the full paragraph
		else
			out[#out + 1] = x.p
			given[x.i] = true
		end
	end
	return table.concat(out, "\n\n"), lead.rs > 0
end

local function hasUnseen(v)
	local given = ctx.Memory.given(v.id)
	for i = 1, #splitParas(v.text) do if not given[i] then return true end end
	return false
end

local function isRepeat(a, cv)
	local lq = cv.lastq
	if not lq or a.follow or #a.terms < 2 or cv.n - lq.turn > 3 then return false end
	local _, j = ctx.NLP.overlap(lq.terms, a.terms)
	return j >= 0.8
end

-- an answer that was probably not what the user wanted: first entry that is new, or an unseen part of the same one
local function alternative(hits, cv)
	local skip = {}
	local lastIds = cv.last and cv.last.ids or {}
	for _, id in ipairs(lastIds) do skip[id] = true end
	for _, h in ipairs(hits) do
		if not skip[h.id] and h.e.src == "verified" then return h end
	end
	for _, id in ipairs(lastIds) do
		local v = ctx.Knowledge.view(id)
		if v and hasUnseen(v) then return { id = id, score = 5, e = v } end
	end
end

-- a related, not yet delivered entry to suggest next
local function nextHit(hits, top, minScore)
	for i = 1, #hits do
		local h = hits[i]
		if h.id ~= top.id and h.e.src == "verified" and h.score >= minScore and not next(ctx.Memory.given(h.id)) then return h end
	end
end

local function setOffer(cv, kind, id, title)
	if cv.n - (cv.lastOfferTurn or -9) < 3 then return nil end
	cv.offer = { kind = kind, id = id, turn = cv.n }
	cv.lastOfferTurn = cv.n
	return ctx.Personality.offer(kind, title)
end

local IMPROVE = {
	ui = {
		{ "UICorner", "Round the corners with a `UICorner` (plus a thin `UIStroke`) so it looks finished." },
		{ "TweenService", "Animate state changes (hover, open/close) with TweenService instead of snapping values." },
		{ "UIListLayout", "Let `UIListLayout` / `UIPadding` handle spacing instead of hand-placed offsets." },
		{ "AnchorPoint", "Use Scale sizes plus `AnchorPoint` so it fits any screen, which matters on mobile." },
		{ "Disconnect", "Store your connections in a table and `:Disconnect()` them when the UI closes so nothing leaks." },
	},
	luau = {
		{ "task.wait", "Use `task.wait`/`task.spawn`/`task.delay`, never the deprecated `wait`/`spawn`/`delay`." },
		{ "pcall", "Wrap risky calls (file access, remote calls, HTTP) in `pcall` and handle the failure case." },
		{ "local", "Cache `game:GetService(...)` results and hot functions in locals." },
		{ "typeof", "Validate inputs with `typeof` / `assert` at function boundaries." },
	},
	reanim = {
		{ "Netless", "Keep network ownership with the Netless options (Internals Settings) so parts don't drift or snap back." },
		{ "Heartbeat", "Write CFrames on Heartbeat, after physics, to avoid desync." },
		{ "CharacterAdded", "Rebuild the rig when the character changes (respawn, new avatar); a stale hat map is a common cause of broken limbs." },
	},
}

-- extra improvements on the code/topic we were just on, minus what was already said
local function improveReply(a, cv, last, top)
	local topic = (last and last.topic) or a.topic or (top and top.e.topic) or "luau"
	local code = (last and last.code) or (top and top.e and top.e.code) or ""
	local parts = {}
	if code ~= "" then
		local hints = lint(code)
		if #hints > 0 then
			local lines = {}
			for _, h in ipairs(hints) do lines[#lines + 1] = "- " .. h end
			parts[#parts + 1] = "**Fix first:**\n" .. table.concat(lines, "\n")
		end
	end
	local tips = {}
	for _, t in ipairs(IMPROVE[topic] or IMPROVE.luau) do
		if not cv.tips[t[2]] and (code == "" or not code:find(t[1], 1, true)) then tips[#tips + 1] = t end
		if #tips >= 3 then break end
	end
	if #tips > 0 then
		local lines = {}
		for _, t in ipairs(tips) do lines[#lines + 1] = "- " .. t[2]; cv.tips[t[2]] = true end
		parts[#parts + 1] = table.concat(lines, "\n")
	end
	if #parts == 0 then return nil end
	return table.concat(parts, "\n\n")
end

local function codeFor(v, a)
	local g = a.slots and a.slots.gen or {}
	if v.id == "ui_tween" and (g.duration or g.easing or g.direction or g.prop or g.color) then return tweenCode(g), true end
	return v.code, false
end

local function clarify(cv)
	local last = cv.last
	return mk("I may have misread you. I took it as **" .. (last.title or "the same topic") .. "**, and I've already given you what I have on it. Which part is off: the topic, the level (more basic or more advanced), or do you need code or a fix for something specific? Pasting the exact code or error is the fastest way for me to get it right.",
		{ ids = last.ids or {}, topic = last.topic, src = last.src, title = last.title, retried = true })
end

local function needMore(a, cv)
	local M = ctx.Memory
	local need = { "the exact error message and the lines around it" }
	local reanim = a.topic == "reanim" or (cv.last and cv.last.topic == "reanim")
	if reanim then
		if not M.get("rig") then need[#need + 1] = "whether you're on R6 or R15" end
		if not M.get("reanimator method") then need[#need + 1] = "which method you use (hat, limb or tool)" end
		if not M.get("executor") then need[#need + 1] = "your executor" end
	end
	local s = need[1]
	if #need > 1 then s = table.concat(need, ", ", 1, #need - 1) .. " and " .. need[#need] end
	return "I need a bit more to go on: " .. s .. ", plus what you expected vs what actually happens."
end

local function converse(a, cv)
	local t = cv.last and cv.last.title
	local s
	if a.kind == "opinion" then
		s = t and ("Fair. If that's about **" .. t .. "**, tell me what you'd change and I'll work from that.") or "Fair enough. Tell me what you want to do with that and I'll help."
	else
		s = t and ("Got it. Should I apply that to **" .. t .. "**, or is it a new problem? A line of code or the exact error helps.") or "Got it. Do you want me to explain something, fix an error, or write code for it?"
	end
	if not cv.hinted and (a.text:find("^i ") or a.text:find("^my ")) then
		cv.hinted = true
		s = s .. " If you want me to keep it in mind, say `remember: ...`."
	end
	return s
end

-- the closest thing I know, with the key missing piece named; used when nothing matches well enough to answer outright
local function partialAnswer(a, r, cv)
	local top = r and r.top
	if not (top and top.e.src == "verified" and (r.cov >= 0.15 or top.score >= 1.2)) then return nil end
	local um = r.unmatched or {}
	local s = "I can't answer that exactly. Closest thing I know is **" .. top.e.title .. "**: " .. bestSentences(a, top.e.text, 2)
	if #um > 0 then
		s = s .. "\n\nI don't know anything about `" .. table.concat(um, "`, `", 1, math.min(2, #um)) .. "`. If that's the key part, tell me what it is (`remember: ...` teaches me)."
	else
		s = s .. "\n\nIf that's not it, tell me what you're trying to do and what you've tried."
	end
	return s, top
end

-- ===== knowledge composition =====
local function composeKnowledge(a, r)
	local P, K, M = ctx.Personality, ctx.Knowledge, ctx.Memory
	local cv = conv()
	local verb, level = P.verbosity(a), P.level(a)
	local intent, fk, last = a.intent, a.followKind, cv.last
	local meta = { ids = {}, topic = a.topic }
	local out = {}
	local retry = a.retry

	local top = r and r.top
	local cov = r and r.cov or 0
	local hitsL = r and r.hits or {}
	local anchored = false

	-- follow-ups stay on the previous entry unless the new message clearly matches something else
	if a.follow and last and last.ids and last.ids[1] and not retry then
		local weak = not top or not (cov >= 0.34 or top.score >= 2.5)
		if (weak and (fk ~= "about" or #a.terms == 0)) or (#a.terms <= 1 and fk and fk ~= "about") then
			local v = K.view(last.ids[1])
			if v then top, cov, anchored = { id = last.ids[1], score = 5, e = v }, 1, true end
		end
	end

	-- "make it better": concrete upgrades for what we were just on
	if fk == "improve" and last then
		local txt = improveReply(a, cv, last, top)
		if txt then
			local ld = P.lead(a, cv, {})
			return mk(cap((ld and (ld .. "\n\n") or "") .. txt, ctx.Config.Limits.MaxReply),
				{ ids = last.ids or {}, topic = last.topic, src = last.src or "verified", title = last.title, code = last.code })
		end
	end

	-- the last answer did not help: something new, an unseen part of it, or an honest question
	if retry then
		local alt = alternative(hitsL, cv)
		if alt then
			top, cov, anchored = alt, 1, true
		elseif last and last.ids and last.ids[1] then
			return clarify(cv)
		end
	end

	local handled, allGiven = false, false
	if intent == "debug" or a.hasCode then
		local err = errorHelp(a.raw)
		if err then out[#out + 1] = err; handled = true end
		if a.hasCode and a.code then
			local hints = lint(a.code)
			if #hints > 0 then
				local lines = {}
				for _, h in ipairs(hints) do lines[#lines + 1] = "- " .. h end
				out[#out + 1] = "**Quick static hints** (a heuristic scan, not a compiler):\n" .. table.concat(lines, "\n")
				handled = true
			elseif intent ~= "explain" and intent ~= "question" then
				out[#out + 1] = "I don't see obvious problems from a quick scan, but I can't run the code. Tell me what you expect vs what happens."
				handled = true
			end
			if intent == "explain" or intent == "question" or verb == "detailed" then
				local bits = explainCode(a.code)
				if #bits > 0 then
					out[#out + 1] = "**What this code does**\n- " .. table.concat(bits, "\n- ")
					handled = true
				end
			end
			meta.code = a.code
		end
	end

	local confident = top and (anchored or cov >= 0.34 or top.score >= 2.5 or (a.more and a.follow))
	local hedge = confident and not anchored and cov < 0.5 and top.score < 4 and not handled
	if confident then
		local v = top.e
		local body, reasonFound
		if v.src == "user" then
			body = (v.kind == "correction" and "Based on a correction you gave me earlier (unverified): " or (v.kind == "solution" and "A fix that worked for you before: " or "From what you taught me (unverified): ")) .. v.text
			if verb == "short" then body = firstPara(body) end
		else
			body, reasonFound = renderEntry(a, v, { verb = verb, fk = fk })
			if not body then
				local rest = bestSentences(a, v.text, verb == "short" and 1 or 2)
				if fk or retry or a.more then
					body = "That's everything I have on **" .. v.title .. "**. The part closest to your question: " .. rest .. "\n\nIf a specific step or line is still unclear, name it and I'll go through it."
				else
					body = "Covered above; the part that matters here: " .. rest
				end
				allGiven = true
			elseif fk == "why" and not reasonFound then
				body = "I don't have a specific reason written down for that. The closest explanation I have:\n\n" .. body
			end
		end
		out[#out + 1] = body
		meta.ids[1] = top.id
		meta.topic = v.topic or meta.topic
		meta.src = v.src
		meta.title = v.title

		local g = M.given(v.id)
		local wantCode = a.mode == "code" or a.wantsCode or intent == "code_request" or intent == "howto" or fk == "how" or fk == "example"
			or (verb ~= "short" and (level == "beginner" or intent == "debug"))
		local offerText
		if v.code and v.src ~= "user" then
			if wantCode and (not g.code or a.mode == "code" or fk == "example" or retry) then
				local code, custom = codeFor(v, a)
				if custom then out[#out + 1] = "Customized to what you asked:" end
				out[#out + 1] = fence(code)
				g.code, meta.code = true, code
			elseif not g.code and verb ~= "short" then
				offerText = setOffer(cv, "code", v.id, v.title)
			end
		end

		if verb == "detailed" and hitsL[2] and hitsL[2].id ~= v.id and hitsL[2].e.src == "verified" and hitsL[2].score >= top.score * 0.5 and not next(M.given(hitsL[2].id)) then
			local h2 = hitsL[2]
			out[#out + 1] = "**Also relevant: " .. h2.e.title .. "**\n" .. firstPara(h2.e.text)
			M.given(h2.id)[1] = true
			meta.ids[2] = h2.id
		elseif not offerText and verb ~= "short" and not allGiven then
			local rel = nextHit(hitsL, top, top.score * 0.3)
			if rel then offerText = setOffer(cv, "next", rel.id, rel.e.title) end
		end
		if offerText then out[#out + 1] = offerText end
		handled = true
	elseif r and r.facts and #r.facts > 0 and not handled then
		out[#out + 1] = "From what you told me (your info, unverified): " .. r.facts[1].v
		handled = true
	end

	if not handled then
		if intent == "debug" then return mk(needMore(a, cv), meta) end
		if a.kind == "opinion" or a.kind == "statement" then
			local rel = partialAnswer(a, r, cv)
			if not rel then return mk(converse(a, cv), meta) end
		end
		local txt, ptop = partialAnswer(a, r, cv)
		if txt then
			if ptop then meta.ids[1], meta.topic, meta.src, meta.title = ptop.id, ptop.e.topic or meta.topic, ptop.e.src, ptop.e.title end
			return mk(cap(txt, ctx.Config.Limits.MaxReply), meta)
		end
		local related = {}
		if r then
			for i = 1, math.min(3, #r.hits) do
				if r.hits[i].e.src == "verified" then related[#related + 1] = r.hits[i].e.title end
			end
		end
		return mk(P.unknown(related, r and r.unmatched, cv), meta)
	end

	local ld = P.lead(a, cv, { retry = retry, hedge = hedge })
	if ld then table.insert(out, 1, ld) end
	return mk(cap(table.concat(out, "\n\n"), ctx.Config.Limits.MaxReply), meta)
end

-- ===== memory questions: answer from what is actually stored, never from assumption =====
local MEMF = { remember = true, told = true, learn = true, memory = true, sav = true, stor = true }

local function memoryReply()
	local M = ctx.Memory
	local lines = {}
	for i, f in ipairs(M.all()) do
		if i > 12 then lines[#lines + 1] = "- ...and more"; break end
		local label = f.k:sub(1, 5) == "pref:" and ("preference " .. f.k:sub(6)) or f.k
		lines[#lines + 1] = "- " .. label .. ": " .. f.v .. (f.p and "" or " *(this session only)*")
	end
	local ks = ctx.Knowledge.stats()
	local head = #lines > 0 and "Here's what you've told me:\n" .. table.concat(lines, "\n") or "You haven't told me anything personal yet."
	return head .. "\n\nI've also learned " .. ks.learned .. " note(s)/correction(s) from you. These are your statements, not verified facts. Use `/forget <topic>` to remove something."
end

local function memoryAnswer(a)
	local M, K, NLP = ctx.Memory, ctx.Knowledge, ctx.NLP
	local q = {}
	for _, t in ipairs(a.terms) do if not MEMF[t] then q[#q + 1] = t end end
	if #q == 0 then return ctx.Mind and ctx.Mind.memoryReply() or memoryReply() end
	local want = {}
	for _, t in ipairs(q) do want[t] = true end
	local found = {}
	for _, f in ipairs(M.all()) do
		if f.k:sub(1, 5) ~= "pref:" then
			local m = 0
			for _, t in ipairs(NLP.terms(f.k .. " " .. f.v)) do if want[t] then m = m + 1 end end
			if m > 0 then found[#found + 1] = { m = m, t = f.k == "name" and ("your name is " .. f.v) or ("**" .. f.k .. "**: " .. f.v) } end
		end
	end
	for _, it in ipairs(K.learned.list) do
		local m = 0
		for _, t in ipairs(it.terms or {}) do if want[t] then m = m + 1 end end
		if m > 0 then found[#found + 1] = { m = m, t = it.a } end
	end
	if #found == 0 then
		return "I don't have anything saved about `" .. table.concat(q, " ") .. "`. If you tell me, I'll keep it (`remember: ...`)."
	end
	table.sort(found, function(x, y) return x.m > y.m end)
	local lines = {}
	for i = 1, math.min(3, #found) do lines[i] = "- " .. found[i].t end
	return "You told me:\n" .. table.concat(lines, "\n") .. "\n\nThat's your information, not something I verified."
end

-- ===== offers (yes / no / ok) =====
local function deliverOffer(off, a, cv)
	local K, M = ctx.Knowledge, ctx.Memory
	local v = K.view(off.id)
	if not v then return mk("I lost track of that one. Ask me again and I'll pick it up.") end
	local meta = { ids = { off.id }, topic = v.topic or a.topic, src = v.src, title = v.title }
	local out = {}
	local g = M.given(v.id)
	if off.kind == "next" then
		local fa = { terms = cv.last and cv.last.terms or {}, slots = { gen = {} }, follow = false, intent = "howto" }
		local body = renderEntry(fa, v, { verb = "normal" })
		out[#out + 1] = "**" .. v.title .. "**" .. (body and ("\n\n" .. body) or "")
	elseif off.kind == "detail" then
		local fa = { terms = cv.last and cv.last.terms or {}, slots = { gen = {} }, follow = false, intent = "howto" }
		out[#out + 1] = renderEntry(fa, v, { verb = "detailed" }) or "That's all I have on it."
	else
		out[#out + 1] = "Here you go:"
	end
	if v.code and not g.code then
		out[#out + 1] = fence(v.code)
		g.code, meta.code = true, v.code
	elseif off.kind == "code" and g.code then
		out[#out + 1] = fence(v.code)
	end
	cv.last = { q = cv.last and cv.last.q or v.title, terms = cv.last and cv.last.terms or {}, topic = meta.topic, ids = meta.ids, src = v.src, title = v.title, code = meta.code or (cv.last and cv.last.code), turn = cv.n }
	return mk(cap(table.concat(out, "\n\n"), ctx.Config.Limits.MaxReply), meta)
end

local function ackReply(a, cv, off)
	local P = ctx.Personality
	local rep = a.slots and a.slots.reply
	local keep = { ids = cv.last and cv.last.ids or {}, topic = cv.last and cv.last.topic or a.topic }
	if rep == "yes" and off then return deliverOffer(off, a, cv) end
	if rep == "no" and off then return mk(P.declined(cv), keep) end
	return mk(P.okay(cv), keep)
end

-- remember what we just answered so follow-ups ("why?", "make it better", "what about X") have something to attach to
local function record(a, res)
	local cv = conv()
	local meta = res.meta or {}
	local ids, src = meta.ids or {}, meta.src
	if #ids == 0 and not src then
		cv.lastq = { terms = a.terms, turn = cv.n }
		return
	end
	local keep = a.follow and cv.last
	local terms, seen = {}, {}
	if keep then
		for _, t in ipairs(keep.terms or {}) do if not seen[t] then seen[t] = true; terms[#terms + 1] = t end end
	end
	for _, t in ipairs(a.terms) do if not seen[t] and #terms < 12 then seen[t] = true; terms[#terms + 1] = t end end
	cv.last = {
		q = keep and keep.q or a.raw, terms = terms, topic = meta.topic or a.topic, ids = ids, src = src,
		title = meta.title or (keep and keep.title), code = meta.code or (keep and keep.code), turn = cv.n, intent = a.intent,
	}
	if not a.follow then cv.lastq = { terms = a.terms, turn = cv.n } end
end

-- without the Mind module there is no outcome learning, so do the simple version here
local function outcome(good, cv)
	if ctx.Mind or not cv.last or not cv.last.ids then return end
	for _, id in ipairs(cv.last.ids) do pcall(ctx.Knowledge.reinforce, cv.last.terms, id, good and 1 or -1) end
end

function Generator.reply(a, r, ev)
	local P, cv = ctx.Personality, conv()
	local off = cv.offer
	cv.offer = nil
	cv.n = cv.n + 1
	if ev then return mk(P.ack(ev), { ids = {}, topic = a.topic }) end
	local i = a.intent
	if i == "greeting" then return mk(P.greet(cv) .. (ctx.Mind and ctx.Mind.continuity() or "")) end
	if i == "thanks" then outcome(true, cv); return mk(P.thanks(cv)) end
	if i == "bye" then return mk(P.bye(cv)) end
	if i == "identity" then return mk(P.identity(ctx.Neural.status()) .. (ctx.Mind and ctx.Mind.identityNote() or "")) end
	if i == "capabilities" then return mk(P.capabilities()) end
	if i == "smalltalk" then return mk(P.smalltalk(a.text, cv)) end
	if i == "memory_query" then return mk(memoryAnswer(a)) end
	if i == "ack" then return ackReply(a, cv, off) end
	if i == "teach" then return mk(P.ack({ kind = "teachhelp" })) end
	if i == "setting" or i == "forget" or i == "correction" then return mk("Okay.") end
	a.retry = (a.complaint or a.followKind == "retry" or isRepeat(a, cv)) and cv.last ~= nil
	if a.retry then outcome(false, cv) end
	local M = ctx.Mind
	local alt = M and M.compose(a, r)
	local res = alt or composeKnowledge(a, r)
	if a.retry then res.meta = res.meta or {}; res.meta.retried = true end
	res = M and M.decorate(a, r, res) or res
	record(a, res)
	return res
end

return Generator
