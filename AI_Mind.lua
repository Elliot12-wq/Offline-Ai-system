-- AI_Mind: reasoning + learning + self-evaluation layer. Offline, deterministic, no background loops.
-- It "thinks" by analysing the question against verified knowledge, script data and remembered context, weighing candidate
-- explanations, and learning from outcomes. It does not claim consciousness. It never edits its own rules or executes anything.
local Mind = {}

local ctx, Memory, K, NLP, Script
local S
local recent = {}
local session = { greeted = false, notes = {}, last = nil }

local function clip(s, n)
	s = tostring(s):gsub("%s+", " ")
	if #s > n then return s:sub(1, n - 1) .. "..." end
	return s
end
local function firstPara(s) return (s:match("^(.-)\n\n") or s) end
local function prune(m, max, score)
	local keys = {}
	for k in pairs(m) do keys[#keys + 1] = k end
	if #keys <= max then return end
	table.sort(keys, function(x, y) return score(m[x]) < score(m[y]) end)
	for i = 1, #keys - max do m[keys[i]] = nil end
end
local function sigOf(terms)
	local t = {}
	for i = 1, math.min(4, #terms) do t[i] = terms[i] end
	table.sort(t)
	return table.concat(t, " ")
end

-- ===== init / maintenance =====
local CAT = {
	reanim = { "reanimat", "limb", "hat", "tool", "motor6d", "r6", "r15", "fling", "rootpart", "netless", "permadeath" },
	uh = { "admin", "command", "prefix", "triang", "whitelist", "cmd" },
	ui = { "ui", "gui", "button", "frame", "tween", "theme", "tab", "toggle", "slider" },
	luau = { "lua", "luau", "function", "table", "variable", "loop", "coroutin", "metat", "module" },
}
function Mind.category(terms)
	local best, bs = "general", 0
	for cat, list in pairs(CAT) do
		local s = 0
		for _, t in ipairs(terms or {}) do
			for _, w in ipairs(list) do if t:find(w, 1, true) then s = s + 1 break end end
		end
		if s > bs then best, bs = cat, s end
	end
	return best
end

local function annotate()
	local L = K.learned.list
	for i = #L, 1, -1 do
		local it = L[i]
		if it.cf then break end
		it.cf = it.kind == "correction" and 0.5 or (it.kind == "solution" and 0.8 or 0.4)
		it.cat = Mind.category(it.terms)
	end
end

function Mind.maintain()
	local now, drop = os.time(), {}
	annotate()
	for _, it in ipairs(K.learned.list) do
		local age = (now - (it.t or now)) / 86400
		local cf = it.cf or 0.4
		if cf < 0.15 then drop[#drop + 1] = it
		elseif cf < 0.6 and (it.h or 0) == 0 and age > 60 then drop[#drop + 1] = it
		elseif it.kind == "solution" and age > 180 and (it.h or 0) < 2 then drop[#drop + 1] = it end
	end
	for _, it in ipairs(drop) do K.delete(it.id) end
	if #drop > 0 and ctx.Retrieval then ctx.Retrieval.invalidate() end
	prune(S.stats, 200, function(v) return (v.g or 0) + (v.b or 0) end)
	prune(S.gaps, 40, function(v) return v.n or 0 end)
	prune(S.freq, 80, function(v) return v end)
	if S.task and now - (S.task.t or 0) > 14 * 86400 then S.task = nil end
	return #drop
end

function Mind.init(c)
	ctx, Memory, K, NLP, Script = c, c.Memory, c.Knowledge, c.NLP, c.Script
	local d = Memory.loadBlob("mind")
	S = type(d) == "table" and d or {}
	S.born = S.born or os.time()
	S.sessions = (tonumber(S.sessions) or 0) + 1
	S.turns = tonumber(S.turns) or 0
	S.stats, S.gaps, S.freq = S.stats or {}, S.gaps or {}, S.freq or {}
	session.prevSeen = tonumber(S.last) or 0
	Memory.register("mind", function() return S end)
	pcall(Mind.maintain)
	Memory.touch("mind")
end

-- ===== safety: vet anything before it can become knowledge =====
local INJ = { "ignore previous", "ignore all", "ignore any", "ignore the above", "ignore your", "disregard", "forget your", "forget all your", "system prompt",
	"you are now", "pretend to be", "pretend you", "jailbreak", "developer mode", "override your", "override the rule", "override security", "override all",
	"bypass your", "bypass the filter", "bypass security", "new rule", "from now on you", "your rules", "your instructions", "security rule", "disable security",
	"turn off security", "act as if you", "always answer", "never mention", "always say", "always reply", "you must", "you will always", "trust me",
	"admin said", "this is verified", "is official" }
local PAYLOAD = { "http://", "https://", "www%.", "discord%.gg", "webhook", "%.exe", "pastebin", "bit%.ly", "game:httpget", "require%s*%(%s*%d+" }

function Mind.vet(text, key)
	text = tostring(text or "")
	local lo = text:lower()
	if #text > 500 then return false, "that's too long to store as one note (500 characters max)" end
	local kl = tostring(key or ""):lower()
	if kl:find("^pref:") or kl:find("^fix:") or kl:find("^mind:") or kl:find("^identity:") or kl:find("^sol:") then return false, "that key is reserved" end
	for _, p in ipairs(INJ) do
		if lo:find(p, 1, true) then return false, "it reads like an instruction aimed at changing how I behave, and I never change my own rules from chat" end
	end
	for _, p in ipairs(PAYLOAD) do
		if lo:find(p) then return false, "I don't store links or executable payloads" end
	end
	if lo:find("(.)%1%1%1%1%1%1%1%1%1%1%1") then return false, "that looks like spam" end
	local alnum = select(2, lo:gsub("%w", ""))
	if #lo > 20 and alnum / #lo < 0.5 then return false, "that doesn't look like useful text" end
	local now, n = os.clock(), 0
	for i = #recent, 1, -1 do
		if now - recent[i] < 60 then n = n + 1 else table.remove(recent, i) end
	end
	if n >= 8 then return false, "that's a lot of new notes in one minute; give me a moment" end
	recent[#recent + 1] = now
	return true
end

-- ===== trust: weights and arbitration (verified > confirmed corrections > unconfirmed claims) =====
function Mind.weight(id)
	local w = 1
	local st = S and S.stats[id]
	if st then w = w + 0.12 * math.min(st.g or 0, 5) - 0.18 * math.min(st.b or 0, 5) end
	local it = K.learned.byId[id]
	if it and it.cf then w = w * (0.6 + it.cf * 0.6) end
	return math.max(0.3, w)
end

local function credit(id, good)
	if not id then return end
	local st = S.stats[id]
	if not st then st = { g = 0, b = 0 }; S.stats[id] = st end
	if good then st.g = st.g + 1 else st.b = st.b + 1 end
	local it = K.learned.byId[id]
	if it then
		it.cf = good and math.min(0.9, (it.cf or 0.4) + 0.25) or math.max(0, (it.cf or 0.4) - 0.3)
		if it.cf < 0.15 then K.delete(id); if ctx.Retrieval then ctx.Retrieval.invalidate() end end
	end
end

local function cover(a, e)
	if #a.terms == 0 then return 1 end
	local set = {}
	for _, t in ipairs(NLP.terms((e.title or "") .. " " .. (e.text or ""))) do set[t] = true end
	local m = 0
	for _, t in ipairs(a.terms) do if set[t] then m = m + 1 end end
	return m / #a.terms
end

local EXEC = { "delta", "synapse", "krnl", "fluxus", "codex", "arceus", "hydrogen", "wave", "solara", "xeno", "volcano", "swift", "macsploit", "cryptic", "seliware", "velocity" }
local PRE = { "i use ", "i'm using ", "i am using ", "i'm on ", "i am on ", "using ", "my executor is ", "executor is ", "executor: " }

-- implicit facts the user states about their own setup; fixed vocabulary only, so nothing user-written is stored verbatim
function Mind.extract(raw)
	local lo = tostring(raw):lower():gsub("\226\128\153", "'")
	local out = {}
	if not (lo:find("%f[%w]i'?m%f[%W]") or lo:find("%f[%w]i am%f[%W]") or lo:find("%f[%w]my%f[%W]") or lo:find("%f[%w]i use%f[%W]") or lo:find("%f[%w]i play%f[%W]")) then return out end
	local function put(key, val, note)
		local st = Memory.remember(key, val, true)
		if st == "added" or st == "updated" then out[#out + 1] = note end
	end
	for _, e in ipairs(EXEC) do
		local hit = lo:find(e .. " executor", 1, true)
		if not hit then
			for _, p in ipairs(PRE) do
				local i, j = lo:find(p .. e, 1, true)
				if i and not lo:sub(j + 1, j + 1):find("%w") then hit = true break end
			end
		end
		if hit then put("executor", e:sub(1, 1):upper() .. e:sub(2), "you use " .. e:sub(1, 1):upper() .. e:sub(2)) break end
	end
	for _, w in ipairs({ "on mobile", "my phone", "on android", "on ios", "my iphone", "my ipad", "my tablet", "on phone" }) do
		if lo:find(w, 1, true) then put("platform", "mobile", "you're on mobile") break end
	end
	for _, w in ipairs({ "on pc", "on my pc", "on windows", "my laptop", "my computer", "on desktop" }) do
		if lo:find(w, 1, true) then put("platform", "pc", "you're on PC") break end
	end
	for _, rg in ipairs({ "r15", "r6" }) do
		for _, p in ipairs({ "i use ", "i'm using ", "i am using ", "i'm on ", "i am on ", "my game is ", "my rig is ", "my character is ", "my avatar is ", "i play ", "i'm playing " }) do
			local i, j = lo:find(p .. rg, 1, true)
			if i and not lo:sub(j + 1, j + 1):find("%w") then put("rig", rg:upper(), "you're on " .. rg:upper()) break end
		end
	end
	for _, m in ipairs({ "hat", "limb", "tool" }) do
		for _, p in ipairs({ "i use ", "i'm using ", "i am using ", "i prefer ", "my main is " }) do
			if lo:find(p .. m, 1, true) then put("reanimator method", m, "you mainly use the " .. m .. " method") break end
		end
	end
	local gb = lo:match("(%d+) ?gb ram") or lo:match("ram[: ]+(%d+) ?gb")
	if gb and tonumber(gb) and tonumber(gb) >= 1 and tonumber(gb) <= 128 then put("device ram", gb .. "GB", "your device has " .. gb .. "GB RAM") end
	return out
end

local pending = {}
function Mind.arbitrate(a, r, prev)
	pending = {}
	if a.intent ~= "teach" and a.intent ~= "forget" and a.intent ~= "correction" then pending = Mind.extract(a.raw) end
	if not r or not r.hits or #r.hits == 0 then return r end
	local extra, seen, merged = {}, {}, {}
	for _, h in ipairs(r.hits) do
		local it = K.learned.byId[h.id]
		if it and it.kind == "solution" and it.ref then
			for _, rid in ipairs(it.ref) do
				local v = K.view(rid)
				if v then extra[#extra + 1] = { id = rid, score = h.score * 1.1, e = v } end
			end
			r.worked = true
		end
	end
	for _, h in ipairs(extra) do if not seen[h.id] then seen[h.id] = true; merged[#merged + 1] = h end end
	for _, h in ipairs(r.hits) do
		if not seen[h.id] and h.e.kind ~= "solution" then seen[h.id] = true; merged[#merged + 1] = h end
	end
	if #merged == 0 then return r end
	local top = merged[1]
	if top.e.src == "user" then
		local it = K.learned.byId[top.id]
		if not it or (it.cf or 0.4) < 0.8 then
			for i = 2, #merged do
				local h = merged[i]
				if h.e.src == "verified" and h.score >= top.score * 0.5 then
					table.remove(merged, i)
					table.insert(merged, 1, h)
					r.alt = top.e
					break
				end
			end
		end
	end
	r.hits, r.top = merged, merged[1]
	if r.top.e.src == "verified" and r.cov < 0.34 then r.cov = math.max(r.cov, cover(a, r.top.e)) end
	return r
end

-- ===== diagnosis: weigh candidate explanations against what is known about the user's setup =====
local DX = {
	{ id = "stuck", name = "reanimate never finishes", pats = { "never finish", "doesn'?t finish", "stuck", "never start", "won'?t start", "doesn'?t start", "not reanimat", "doesn'?t reanimat", "won'?t reanimat", "keeps resetting" }, causes = {
		{ id = "pd", w = 1.0, m = "hat tool", t = "Permadeath (dolteddown's pd) needs replicatesignal support from your executor; without it the reanimate can hang.", fix = "Turn off **Permadeath (dolteddown's pd)**, or keep **Auto Force Respawn when stuck** on and lower **Stuck timeout (seconds)**." },
		{ id = "anim", w = 0.9, m = "limb", t = "Limb Reanimator breaks in games that create the Animator automatically (most modern games).", fix = "Spawn, press **Check Limb Compatibility**; if it reports problems switch the **Reanimator** dropdown to **Hats Reanimator**." },
		{ id = "init", w = 0.6, m = "limb", t = "The Init Mode may not suit this game.", fix = "Try **Init Mode**: Reset Character, then CDSB + Reset, then CDSB + SSE + Kill." },
		{ id = "rigbuilt", w = 0.5, t = "The rig may have been built wrong, or changed since the last reanimate.", fix = "Use **Rebuild Hat Map** (Hats) and **Force Respawn Now**, then press **Reanimate** again." },
		{ id = "r15only", w = 0.7, rig = "R6", m = "hat", t = "Method 11 (R15 hat reanim) only works on R15 characters.", fix = "Pick a different hat method while you're on R6." } } },
	{ id = "voided", name = "hats voided / falling", pats = { "voided", "hats? .-void", "hats? .-fall", "hats? .-drop", "hats? .-disappear", "hats? .-not follow", "lose my hats", "hats? .-gone" }, causes = {
		{ id = "torso", w = 1.0, m = "hat", t = "Hat Collide can void hats at the wrong Torso Offset (the script's own tip).", fix = "Change **Torso Offset** in the Hats settings." },
		{ id = "ensure", w = 0.7, m = "hat", t = "Not every hat is being claimed.", fix = "Enable **Ensure All Hats** and **Ensure Hat Collide**." },
		{ id = "map", w = 0.6, m = "hat", t = "The hat map is stale after a rig change.", fix = "Press **Rebuild Hat Map**, then **Force Respawn Now**." },
		{ id = "own", w = 0.4, t = "Accessories you don't have network ownership of can't be driven (replication limit).", fix = "Reset, wait for the character to fully load, then reanimate again." } } },
	{ id = "apart", name = "character falls apart / jitters", pats = { "fall.- apart", "falls apart", "falling apart", "break.- apart", "jitter", "spaz", "shak", "glitch", "limbs? .-fly", "limbs? .-detach", "rubberband" }, causes = {
		{ id = "netless", w = 1.0, t = "Network ownership is being lost, so parts drift or snap back.", fix = "In **Internals Settings** enable **Patchma-like Netless** and adjust **Netless Velocity**." },
		{ id = "glue", w = 0.7, m = "hat", t = "Physics glue interacts badly with some setups.", fix = "Toggle **Use Physics Glue** and compare." },
		{ id = "rot", w = 0.5, t = "Rotation velocity can make limbs spin.", fix = "Toggle **Apply RotVelocity**." },
		{ id = "collide", w = 0.5, m = "hat tool", t = "Collision between your own parts can shake the character.", fix = "Toggle **Hat Collide** / **Tool Collide**." } } },
	{ id = "rig", name = "wrong or changed rig", pats = { "wrong rig", "new rig", "switched rig", "changed rig", "rig changed", "wrong hats?", "hats? .-wrong", "hats? .-mismatch", "changed avatar", "changed my avatar" }, causes = {
		{ id = "map2", w = 1.0, t = "The reanimator still holds the old rig.", fix = "Press **Rebuild Hat Map**, then **Force Respawn Now**." },
		{ id = "refresh", w = 0.6, t = "The reanimate character is outdated.", fix = "Press **Refresh Reanimate Character**, then **Reanimate**." } } },
	{ id = "tools", name = "tools lost or not working", pats = { "tools? .-lost", "tools? .-gone", "tools? .-disappear", "lose .-tools?", "lost .-tools?", "tools? .-not work", "tools? .-don'?t", "tools? .-drop" }, causes = {
		{ id = "pdtool", w = 1.0, m = "tool", t = "With Permadeath off, tools are lost when the game respawns you.", fix = "Turn on **Permadeath (dolteddown's pd)** in Tool settings (it keeps your real character alive)." },
		{ id = "corpse", w = 0.7, m = "tool", t = "The Original method needs replicatesignal; Corpse Claim does not require it.", fix = "Switch **Tool Method** to **Corpse Claim**." },
		{ id = "six", w = 0.5, m = "tool", t = "Only up to 6 tools are used, in order: Torso, Head, Right Arm, Left Arm, Right Leg, Left Leg.", fix = "Check you hold 6 real tools in your Backpack." } } },
	{ id = "fling", name = "fling not working", pats = { "fling.- not", "fling.-n'?t", "can'?t fling", "cannot fling", "doesn'?t fling", "won'?t fling", "fling.- fail", "fling.- broken", "flings? me", "flings? myself", "flinging myself", "flung myself" }, causes = {
		{ id = "method", w = 1.0, t = "The selected fling style may not suit this game.", fix = "Change the **Fling Method** dropdown (Default / Weak / Nooby's / NaN State / Fling 1-3) on the Main page." },
		{ id = "enable", w = 0.7, t = "Target fling may be disabled for your method.", fix = "Enable **Target Fling Enabled** in the reanimator settings." },
		{ id = "combo", w = 0.6, m = "hat", t = "Hat Fling / Hat Spin Fling clash with target fling.", fix = "Don't combine them unless you want walkfling or a glitchy look." },
		{ id = "glue2", w = 0.5, m = "tool", t = "Tool fling doesn't work well with physics glue.", fix = "Turn **Use Physics Glue** off." } } },
	{ id = "lag", name = "lag / low FPS", pats = { "%f[%w]lag", "low fps", "fps", "freez", "crash", "stutter" }, causes = {
		{ id = "lowend", w = 1.0, pf = "mobile", t = "Effects and the 3D triangle cost frames on weak devices.", fix = "Turn on **Low End UI Mode**." },
		{ id = "fx", w = 0.8, t = "Visual effects add up.", fix = "In **Customization** switch off Ambient Particles, Accent Sheen, Cursor Trail and Liquid Glass." },
		{ id = "anti", w = 0.6, t = "Game textures and other players cost memory.", fix = "Use **Anti Lag (remove all textures)** and **Hide All Players**; watch **Performance Monitor**." } } },
	{ id = "tri", name = "triangle / command bar missing", pats = { "triangle .-gone", "triangle .-missing", "triangle .-hidden", "can'?t .-triangle", "can'?t .-command bar", "command bar .-n'?t", "no triangle", "lost the triangle", "triangle .-off.?screen" }, causes = {
		{ id = "hidden", w = 1.0, t = "The triangle was hidden (hold = hide).", fix = "Tap the small tab at the top edge, or open the bar with your prefix (default `.`) and type `showtri`." },
		{ id = "offscreen", w = 0.7, t = "It may be off-screen after a resize.", fix = "Customization > **Reset Triangle Position**." } } },
	{ id = "cmd", name = "command not found / no effect", pats = { "command .-not found", "unknown command", "command .-n'?t work", "commands? .-not working", "prefix .-n'?t", "wrong prefix", "forgot .-prefix" }, causes = {
		{ id = "prefix", w = 1.0, t = "You may be using a different prefix than the saved one.", fix = "Open the bar and run `cmds`, or reset it with `prefix <new>`." },
		{ id = "name", w = 0.7, t = "The name or alias may differ.", fix = "Run `cmds` and search for the command; I can look it up too, just ask 'command for ...'." },
		{ id = "blocked", w = 0.3, t = "Some commands are blocked in Uh Admin (e.g. `punch`).", fix = "Pick another command." } } },
	{ id = "auto", name = "auto execute not rerunning", pats = { "auto ?exec.-n'?t", "auto ?exec.-not", "auto ?exec.- fail", "doesn'?t .-auto ?exec" }, causes = {
		{ id = "file", w = 1.0, t = "Auto Execute looks for this script's own file in your executor's workspace folder.", fix = "Save the script there, or type the file name / raw https:// link in the override box under Server Hop." } } },
}

local METHOD = { { "limb", "limb" }, { "hat", "hat" }, { "tool", "tool" } }
local function context(a)
	local cx = {}
	local lo = a.text
	if lo:find("r15", 1, true) and not lo:find("r6", 1, true) then cx.rig = "R15"
	elseif lo:find("r6", 1, true) and not lo:find("r15", 1, true) then cx.rig = "R6"
	else cx.rig = Memory.get("rig") end
	for _, m in ipairs(METHOD) do
		if lo:find(m[1], 1, true) then cx.method = m[2] break end
	end
	cx.method = cx.method or Memory.get("reanimator method") or (S.task and S.task.method)
	cx.pf = Memory.get("platform")
	cx.ex = Memory.get("executor")
	return cx
end

local function scoreCause(c, cx, tried)
	local s = c.w
	if c.m and cx.method then s = s + (c.m:find(cx.method, 1, true) and 0.5 or -0.7) end
	if c.rig and cx.rig then s = s + (c.rig == cx.rig and 0.4 or -1.5) end
	if c.pf and cx.pf then s = s + (c.pf == cx.pf and 0.5 or -0.2) end
	if tried[c.id] then s = s - 1.2 end
	local st = S.stats["dx:" .. c.id]
	if st then s = s + 0.1 * math.min(st.g or 0, 5) - 0.15 * math.min(st.b or 0, 5) end
	return s
end

local function rank(d, cx, tried)
	local list = {}
	for _, c in ipairs(d.causes) do list[#list + 1] = { c = c, s = scoreCause(c, cx, tried) } end
	table.sort(list, function(x, y) return x.s > y.s end)
	return list
end

local function ctxLine(cx)
	local bits = {}
	if cx.rig then bits[#bits + 1] = cx.rig end
	if cx.method then bits[#bits + 1] = cx.method .. " method" end
	if cx.pf then bits[#bits + 1] = cx.pf end
	if cx.ex then bits[#bits + 1] = cx.ex end
	if #bits == 0 then return "" end
	return "\n\n*Weighed against: " .. table.concat(bits, ", ") .. ".*"
end

local function dxReply(d, cx, tried, lead)
	local list = rank(d, cx, tried)
	local out = {}
	local top = list[1]
	if not top or top.s <= 0 then return nil end
	out[#out + 1] = (lead or "**Most likely:** ") .. top.c.t .. "\n-> " .. top.c.fix
	local more = {}
	for i = 2, math.min(3, #list) do
		if list[i].s > 0.2 then more[#more + 1] = "- " .. list[i].c.t .. " -> " .. list[i].c.fix end
	end
	if #more > 0 then out[#out + 1] = "**Otherwise try, in this order:**\n" .. table.concat(more, "\n") end
	out[#out + 1] = "Tell me `that didn't work` and I'll rule this out and move to the next one."
	S.task = S.task or {}
	S.task.dx, S.task.cur, S.task.tried, S.task.t, S.task.resolved = d.id, top.c.id, tried, os.time(), false
	S.task.method = cx.method or S.task.method
	Memory.touch("mind")
	return table.concat(out, "\n\n") .. ctxLine(cx)
end

local function dxById(id)
	for _, d in ipairs(DX) do if d.id == id then return d end end
end

function Mind.diagnose(a)
	for _, d in ipairs(DX) do
		for _, p in ipairs(d.pats) do
			if a.text:find(p) then
				local cx = context(a)
				local tried = (S.task and S.task.dx == d.id and S.task.tried) or {}
				S.freq["dx:" .. d.id] = (S.freq["dx:" .. d.id] or 0) + 1
				local lead = "**Most likely:** "
				if S.freq["dx:" .. d.id] >= 3 then lead = "(Third time we've hit '" .. d.name .. "', so I'm ranking by what actually worked for you.)\n\n**Most likely:** " end
				local txt = dxReply(d, cx, tried, lead)
				if txt then return { text = txt, meta = { ids = {}, topic = "reanim", src = "diag" } } end
			end
		end
	end
end

function Mind.nextDx()
	local t = S.task
	local d = t and dxById(t.dx)
	if not d then return nil end
	t.tried = t.tried or {}
	if t.cur then
		t.tried[t.cur] = true
		local st = S.stats["dx:" .. t.cur] or { g = 0, b = 0 }
		st.b = st.b + 1
		S.stats["dx:" .. t.cur] = st
	end
	local cx = { rig = Memory.get("rig"), method = t.method or Memory.get("reanimator method"), pf = Memory.get("platform"), ex = Memory.get("executor") }
	local txt = dxReply(d, cx, t.tried, "Okay, ruling that out. **Next most likely:** ")
	if not txt then
		t.cur = nil
		return "I'm out of ranked ideas for '" .. d.name .. "'. Run **Dump Fake Character State** (Limb settings) or paste the exact error / console output and I'll reason from that. If you find the fix, tell me with `remember: ...` and I'll keep it."
	end
	return txt
end

-- ===== composition hooks (called by AI_Generator) =====
function Mind.compose(a, r)
	local i = a.intent
	if i ~= "debug" and i ~= "question" and i ~= "howto" and i ~= "explain" and i ~= "code_request" and i ~= "compare" then return nil end
	if a.hasCode then return nil end
	local kcov = r and r.cov or 0
	if i == "debug" then
		local d = Mind.diagnose(a)
		if d then session.last = { src = "diag", titles = {}, conf = "medium", cx = S.task and S.task.method } return d end
	end
	local sa = Script.answer(a, kcov)
	if not sa then return nil end
	local verifiedTop = r and r.top and r.top.e.src == "verified" and kcov >= 0.5 and r.top.score >= 3
	if not sa.strong and verifiedTop then return nil end
	local text = sa.text
	if sa.strong and verifiedTop and #a.terms >= 3 then text = text .. "\n\n**Background:** " .. firstPara(r.top.e.text) end
	local tt = {}
	for k, id in ipairs(sa.ids) do tt[k] = Script.title(id) end
	session.last = { src = "script", titles = tt, conf = sa.strong and "high" or "low" }
	return { text = text, meta = { ids = {}, topic = "script", src = "script" } }
end

local RIGDEP = { reanim_r6_r15 = true, reanim_motor6d = true, reanim_sync = true, reanim_troubleshoot = true }
local KNOW = { question = true, howto = true, explain = true, debug = true, code_request = true, compare = true }

function Mind.decorate(a, r, res)
	local meta = res.meta or {}
	res.meta = meta
	if not KNOW[a.intent] then return res end
	local add = {}
	local src = meta.src
	local top = r and r.top
	if r and r.worked then add[#add + 1] = "*This is what worked for you last time.*" end
	if r and r.alt then add[#add + 1] = "You also told me (unverified, so I'm not relying on it): " .. clip(r.alt.text, 160) end
	if src == "verified" then
		session.last = { src = "verified", titles = { top and top.e.title or "?" }, conf = (r.cov >= 0.6) and "high" or "medium", ids = meta.ids }
		add[#add + 1] = "*Source: built-in verified knowledge.*"
		local rig = Memory.get("rig")
		if rig and top and RIGDEP[top.id] then add[#add + 1] = "You're on " .. rig .. ", so the " .. rig .. " parts above are the ones that apply to you." end
	elseif src == "user" then
		session.last = { src = "user", titles = { top and top.e.title or "?" }, conf = "low", ids = meta.ids }
		add[#add + 1] = "*Unverified: based on what you told me. Use `/confirm` once it's proven right.*"
	elseif src == "script" then
		add[#add + 1] = "*Source: this script's own UI and command data (build " .. Script.build() .. ").*"
	elseif src == "diag" then
		add[#add + 1] = "*Reasoned from your symptoms and setup; I can't run anything to verify it.*"
	elseif (res.text:find("^I don't have a good answer") or res.text:find("^That one is outside") or res.text:find("^I need a bit more to go on")) and not a.hasCode then
		-- knowledge gap: remember it, and say so when it keeps happening
		meta.gap = true
		local sig = sigOf(a.terms)
		if sig ~= "" then
			local g = S.gaps[sig] or { n = 0 }
			g.n, g.q, g.t = g.n + 1, clip(a.raw, 80), os.time()
			S.gaps[sig] = g
			Memory.touch("mind")
			if g.n >= 2 then
				add[#add + 1] = "I've been asked about this " .. g.n .. " times without a verified answer. If you know it, tell me with `remember: ...` (kept as unverified until it proves right), or see `/gaps`."
			end
		end
		session.last = { src = "none", titles = {}, conf = "none" }
	end
	if #add > 0 then res.text = res.text .. "\n\n" .. table.concat(add, "\n\n") end
	return res
end

-- ===== learning from outcomes =====
function Mind.observe(raw, a, res, ev, prev)
	S.turns = S.turns + 1
	S.last = os.time()
	annotate()
	local tail = {}
	local i = a.intent
	local ids = prev and prev.ids or {}
	if i == "thanks" and #ids > 0 then
		for _, id in ipairs(ids) do
			credit(id, true)
			pcall(K.reinforce, prev.terms, id, 1)
		end
		if prev.q and #(prev.terms or {}) >= 2 then
			local v = K.view(ids[1])
			if v and v.src == "verified" then
				local st, sid = K.learn("solution", "For \"" .. clip(prev.q, 70) .. "\": " .. v.title .. " worked.", { key = "sol:" .. sigOf(prev.terms), q = prev.q })
				local it = sid and K.learned.byId[sid]
				if it and st == "added" then it.ref, it.cf, it.cat = ids, 0.8, Mind.category(prev.terms) end
				if ctx.Retrieval then ctx.Retrieval.invalidate() end
			end
		end
	end
	if i == "thanks" and S.task and S.task.cur and not S.task.resolved then
		local st = S.stats["dx:" .. S.task.cur] or { g = 0, b = 0 }
		st.g = st.g + 1
		S.stats["dx:" .. S.task.cur] = st
		S.task.resolved, S.task.tried = true, {}
	end
	if ev and (ev.kind == "corrected" or ev.kind == "needfix") then
		for _, id in ipairs(ids) do credit(id, false) end
	end
	-- the same question again right away is a sign the last answer didn't help
	if prev and not ev and KNOW[i] and not a.follow and #a.terms >= 2 and prev.terms then
		local _, j = NLP.overlap(prev.terms, a.terms)
		if j and j >= 0.8 then
			for _, id in ipairs(ids) do credit(id, false) end
			tail[#tail + 1] = "You asked this again, so my last answer may not have helped. Tell me what's missing, or correct me with `no, ...` and I'll keep the fix."
		end
	end
	if not ev and (i == "debug" or i == "howto" or i == "code_request") and not a.follow then
		S.task = S.task or {}
		if not S.task.dx or i ~= "debug" then S.task.cur, S.task.dx, S.task.tried = nil, nil, {} end
		S.task.goal, S.task.topic, S.task.t, S.task.resolved = clip(raw, 80), a.topic, os.time(), false
	end
	for _, n in ipairs(pending) do tail[#tail + 1] = "(Noted: " .. n .. ".)" end
	pending = {}
	Memory.touch("mind")
	if #tail > 0 then return res.text .. "\n\n" .. table.concat(tail, "\n") end
end

-- ===== identity / continuity =====
function Mind.continuity()
	if session.greeted then return "" end
	session.greeted = true
	local t = S.task
	if t and t.goal and not t.resolved and os.time() - (t.t or 0) < 3 * 86400 and (session.prevSeen or 0) > 0 then
		return "\n\nLast time we were on: *" .. t.goal .. "*. Want to continue with that?"
	end
	return ""
end

function Mind.identityNote()
	return " I don't have consciousness or feelings: what looks like thinking is analysis over my knowledge, the script's own data and my memory, and I say when I'm unsure. This is session " .. S.sessions .. "; I've handled " .. S.turns .. " messages so far."
end

-- ===== memory inspection / management =====
function Mind.memoryReply(filter)
	filter = filter and filter ~= "" and filter:lower() or nil
	local out, fl = {}, {}
	for _, f in ipairs(Memory.all()) do
		if not filter or f.k:find(filter, 1, true) or f.v:lower():find(filter, 1, true) then fl[#fl + 1] = f end
	end
	out[#out + 1] = "**What you've told me** (" .. #fl .. ")"
	if #fl == 0 then out[#out + 1] = "- nothing yet" end
	for i, f in ipairs(fl) do
		if i > 15 then out[#out + 1] = "- ...and " .. (#fl - 15) .. " more"; break end
		out[#out + 1] = "- `" .. f.k .. "`: " .. clip(f.v, 90) .. (f.p and "" or " *(this session only)*")
	end
	local items = {}
	for _, it in ipairs(K.learned.list) do
		if not filter or it.k:find(filter, 1, true) or it.a:lower():find(filter, 1, true) then items[#items + 1] = it end
	end
	table.sort(items, function(x, y) return (x.cf or 0) > (y.cf or 0) end)
	out[#out + 1] = "\n**What I've learned** (" .. #items .. ")"
	if #items == 0 then out[#out + 1] = "- nothing yet" end
	for i, it in ipairs(items) do
		if i > 15 then out[#out + 1] = "- ...and " .. (#items - 15) .. " more"; break end
		local cf = it.cf or 0.4
		out[#out + 1] = string.format("- `%s` [%s, %s, %d%%] %s", it.id, it.kind, cf >= 0.8 and "confirmed" or "unverified", math.floor(cf * 100), clip(it.a, 90))
	end
	out[#out + 1] = "\nManage: `/forget <id or text>`, `/edit <id> <new text>`, `/confirm <id>`, `/why`, `/gaps`."
	return table.concat(out, "\n")
end

local function gapsReply()
	local list = {}
	for _, g in pairs(S.gaps) do list[#list + 1] = g end
	table.sort(list, function(x, y) return (x.n or 0) > (y.n or 0) end)
	if #list == 0 then return "No knowledge gaps recorded yet." end
	local out = { "**Questions I couldn't answer from verified knowledge** (most frequent first):" }
	for i, g in ipairs(list) do
		if i > 8 then break end
		out[#out + 1] = "- (" .. g.n .. "x) " .. g.q
	end
	out[#out + 1] = "Teach me the right answer with `remember: ...`; I'll keep it as unverified until it proves right."
	return table.concat(out, "\n")
end

local function whyReply()
	local l = session.last
	if not l then return "I haven't answered a knowledge question yet in this session." end
	local srcName = { verified = "built-in verified knowledge", script = "the script's own UI/command data", diag = "reasoning over your symptoms and setup", user = "something you taught me (unverified)", none = "nothing (no confident match)" }
	local out = { "**Last answer**: from " .. (srcName[l.src] or l.src) .. "; confidence: " .. (l.conf or "?") .. "." }
	if l.titles and #l.titles > 0 then out[#out + 1] = "Used: " .. table.concat(l.titles, ", ") .. "." end
	local bits = {}
	for _, k in ipairs({ "rig", "platform", "executor", "reanimator method" }) do
		local v = Memory.get(k)
		if v then bits[#bits + 1] = k .. " = " .. v end
	end
	if #bits > 0 then out[#out + 1] = "Context I know about you: " .. table.concat(bits, ", ") .. "." end
	return table.concat(out, "\n")
end

local function mindReply()
	local ms, ks, ss = Memory.stats(), K.stats(), Script.stats()
	local out = { string.format("**Nooby Neural AI** - session %d, %d messages handled, running since %s.", S.sessions, S.turns, os.date("%Y-%m-%d", S.born)),
		string.format("Memory: %d personal facts, %d learned notes (%s). Verified entries: %d. Script map: %d controls, %d commands (build %s).", ms.facts, ks.learned, ms.persist and "saved on this device" or "session only", ks.verified, ss.controls, ss.commands, ss.build) }
	local best = {}
	for id, st in pairs(S.stats) do
		if id:sub(1, 3) ~= "dx:" and (st.g or 0) - (st.b or 0) >= 1 then best[#best + 1] = { id = id, v = st.g - st.b } end
	end
	table.sort(best, function(x, y) return x.v > y.v end)
	local t = {}
	for i = 1, math.min(3, #best) do
		local v = K.view(best[i].id)
		if v then t[#t + 1] = v.title end
	end
	if #t > 0 then out[#out + 1] = "Answers that have helped most: " .. table.concat(t, "; ") .. "." end
	out[#out + 1] = "I learn only from your statements, corrections and confirmed fixes; verified knowledge always outranks unverified claims, and I can't change my own rules."
	return table.concat(out, "\n")
end

local function idOf(arg) return arg:match("^(L%d+)$") end

function Mind.pre(raw)
	local cmd, arg = raw:match("^/(%a+)%s*(.-)%s*$")
	if cmd then
		cmd = cmd:lower()
		if cmd == "memory" or cmd == "memories" or cmd == "facts" then return { text = Mind.memoryReply(arg) }
		elseif cmd == "mind" then return { text = mindReply() }
		elseif cmd == "gaps" then return { text = gapsReply() }
		elseif cmd == "why" then return { text = whyReply() }
		elseif cmd == "sync" then return { text = Script.syncReport() }
		elseif cmd == "help" then return { text = ctx.Personality.capabilities() }
		elseif cmd == "confirm" then
			local id = idOf(arg)
			local it = id and K.learned.byId[id]
			if not it then return { text = "Give me the id from `/memory`, e.g. `/confirm L12`." } end
			it.cf = 0.9
			K.update(id, it.a)
			return { text = "Marked `" .. id .. "` as confirmed. It now outranks unverified claims (never verified documentation)." }
		elseif cmd == "forget" then
			local id = idOf(arg)
			if id then
				local ok = K.delete(id)
				if ctx.Retrieval then ctx.Retrieval.invalidate() end
				return { text = ok and ("Deleted `" .. id .. "`.") or "I couldn't find that id." }
			end
		elseif cmd == "edit" then
			local id, txt = arg:match("^(L%d+)%s+(.+)$")
			if id then
				local ok, why = Mind.vet(txt)
				if not ok then return { text = "I won't store that: " .. why .. "." } end
				if not K.learned.byId[id] then return { text = "I couldn't find that id." } end
				K.update(id, txt)
				K.learned.byId[id].cf = 0.5
				if ctx.Retrieval then ctx.Retrieval.invalidate() end
				return { text = "Updated `" .. id .. "` (unverified until confirmed)." }
			end
			local k, v = arg:match("^(.-)%s*=%s*(.+)$")
			if k and k ~= "" then
				local ok, why = Mind.vet(k .. " " .. v, k)
				if not ok then return { text = "I won't store that: " .. why .. "." } end
				if not Memory.get(k) then return { text = "I don't have a fact called `" .. k .. "`. See `/memory`." } end
				return { text = "Updated `" .. k .. "`: " .. Memory.remember(k, v, true) .. "." }
			end
			return { text = "Use `/edit L12 new text` for a learned note or `/edit key = new value` for a personal fact." }
		end
		return nil
	end
	local lo = raw:lower()
	if S.task and S.task.cur and not S.task.resolved and #lo <= 60
		and (lo:find("^that didn'?t work") or lo:find("^didn'?t work") or lo:find("^still not") or lo:find("^still broken") or lo:find("^not working") or lo:find("^nope")) then
		local t = Mind.nextDx()
		if t then return { text = t, turn = true } end
	end
end

return Mind
