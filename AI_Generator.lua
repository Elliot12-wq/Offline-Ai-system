-- AI_Generator: builds replies from retrieved knowledge, templates, and heuristics.
-- Template + retrieval generation; it does not pretend to be a neural LLM. Returns { text, meta = { ids, topic, src } }.
local Generator = {}

local ctx

function Generator.init(c) ctx = c end

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

-- ===== knowledge composition =====
local function composeKnowledge(a, r)
	local P = ctx.Personality
	local verb, level = P.verbosity(a), P.level(a)
	local intent = a.intent
	local meta = { ids = {}, topic = a.topic }
	local out = {}

	local op = P.opener(intent == "question" and a.hasCode and "explain" or intent, level, verb)
	if op then out[#out + 1] = op end

	local handled = false
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
		end
	end

	local top = r and r.top
	local confident = top and (r.cov >= 0.34 or top.score >= 2.5 or (a.more and a.follow))
	if confident then
		local v = top.e
		local body = v.text
		if v.src == "user" then
			body = (v.kind == "correction" and "Based on a correction you gave me earlier (unverified): " or (v.kind == "solution" and "A fix that worked for you before: " or "From what you taught me (unverified): ")) .. v.text
		end
		if verb == "short" then body = firstPara(body) end
		out[#out + 1] = body
		meta.ids[1] = top.id
		meta.topic = v.topic or meta.topic
		meta.src = v.src

		local wantCode = a.mode == "code" or a.wantsCode or intent == "code_request" or intent == "howto"
			or (verb ~= "short" and (level == "beginner" or intent == "debug"))
		if v.code and wantCode then
			local code = v.code
			local g = a.slots.gen
			if (v.id == "ui_tween") and (g.duration or g.easing or g.direction or g.prop or g.color) then
				code = tweenCode(g)
				out[#out + 1] = "Customized to what you asked:"
			end
			out[#out + 1] = fence(code)
		end

		if verb == "detailed" and r.hits[2] and r.hits[2].e.src == "verified" and r.hits[2].score >= top.score * 0.5 then
			out[#out + 1] = "**Also relevant: " .. r.hits[2].e.title .. "**\n" .. firstPara(r.hits[2].e.text)
			meta.ids[2] = r.hits[2].id
		end
		if verb ~= "short" and r.hits[2] and verb ~= "detailed" then
			local rel = {}
			for i = 2, #r.hits do
				if r.hits[i].e.src == "verified" then rel[#rel + 1] = r.hits[i].e.title end
			end
			if #rel > 0 then out[#out + 1] = "Related: " .. table.concat(rel, "; ") .. "." end
		end
		handled = true
	elseif r and r.facts and #r.facts > 0 and not handled then
		local f = r.facts[1]
		out[#out + 1] = "From what you told me (your info, unverified): " .. f.v
		handled = true
	end

	if not handled then
		if intent == "debug" then
			return mk("I need a bit more to go on. Paste the exact error message and the lines around it, and tell me what you expected to happen. If it's a reanimation issue, say whether you're on R6 or R15.", meta)
		end
		local related = {}
		if r then
			for i = 1, math.min(3, #r.hits) do
				if r.hits[i].e.src == "verified" then related[#related + 1] = r.hits[i].e.title end
			end
		end
		return mk(P.unknown(related), meta)
	end

	local cl = P.closer(a, verb)
	if cl then out[#out + 1] = cl end
	return mk(cap(table.concat(out, "\n\n"), ctx.Config.Limits.MaxReply), meta)
end

function Generator.reply(a, r, ev)
	local P = ctx.Personality
	if ev then return mk(P.ack(ev), { ids = {}, topic = a.topic }) end
	local i = a.intent
	if i == "greeting" then return mk(P.greet() .. (ctx.Mind and ctx.Mind.continuity() or "")) end
	if i == "thanks" then return mk(P.thanks()) end
	if i == "bye" then return mk(P.bye()) end
	if i == "identity" then return mk(P.identity(ctx.Neural.status()) .. (ctx.Mind and ctx.Mind.identityNote() or "")) end
	if i == "capabilities" then return mk(P.capabilities()) end
	if i == "smalltalk" then return mk(P.smalltalk(a.text)) end
	if i == "memory_query" then return mk(ctx.Mind and ctx.Mind.memoryReply() or memoryReply()) end
	if i == "teach" then return mk(P.ack({ kind = "teachhelp" })) end
	if i == "setting" or i == "forget" or i == "correction" then return mk("Okay.") end
	local M = ctx.Mind
	local alt = M and M.compose(a, r)
	local res = alt or composeKnowledge(a, r)
	return M and M.decorate(a, r, res) or res
end

return Generator
