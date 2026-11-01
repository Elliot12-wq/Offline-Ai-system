-- AI_Butler: JARVIS-style butler layer. Greeting (ai_greetings.json), AI-only alerts, session briefing.
-- Self-contained: it reaches the host script only through the `api` table given to start(). Never invents data:
-- every alert comes from a real measurement (Heartbeat FPS, Stats memory, init log text, the host's own compat checker,
-- verifiable staff sources). Informational only - it never leaves servers, moderates, or touches other players.
local Butler = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local CFG = {
	GreetingsFile = "ai_greetings.json", CacheTTL = 86400, MinPool = 20,
	LowFps = 10, FpsSustain = 3, FpsCooldown = 180, FpsRearm = 20, FpsRearmSecs = 5, FpsGrace = 20,
	MemMB = 3072, MemRearmMB = 2800, MemCooldown = 300, MemPoll = 10,
	StaffCooldown = 60, MaxQueue = 8, MaxEvents = 40, TextMax = 230,
}

local FALLBACK = {
	"Good {period}, {title}. All systems are standing by, {name}.",
	"Welcome back, {name}. I took the liberty of getting everything ready.",
	"{title}, good {period}. The workshop is yours.",
	"Systems online, {name}. Shall we begin?",
	"Good to see you, {title}. Everything is running smoothly at my end.",
	"Good {period}, {name}. I trust you are well rested.",
	"At your service, {title}. Just say the word.",
	"Welcome, {name}. Diagnostics are clean and I am at your disposal.",
	"{title}, you are back. I kept the lights on.",
	"Good {period}, {title}. Whatever you have in mind, I am ready.",
	"Hello again, {name}. All modules have been accounted for.",
	"Ready when you are, {title}.",
}

local S -- per-start state

-- ===== helpers =====
local function genv()
	local ok, g = pcall(function() return getgenv and getgenv() end)
	return (ok and type(g) == "table") and g or _G
end
local function fnv(name)
	local v = rawget(genv(), name)
	if type(v) ~= "function" then v = rawget(_G, name) end
	return type(v) == "function" and v or nil
end
local function clean(s, n)
	s = tostring(s or "")
	s = s:gsub("<[^>]*>", ""):gsub("https?://%S+", "")
	s = s:gsub("[%w%+/=_%-]+", function(w) if #w > 28 then return "..." end end)
	s = s:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
	if #s > n then s = s:sub(1, n - 3) .. "..." end
	return s
end
local function plural(n, w) return n .. " " .. w .. (n == 1 and "" or "s") end

local function dirPath() return (S and S.api and S.api.dir) or "NoobyAI" end
local function ensureDir()
	local mf, isf = fnv("makefolder"), fnv("isfolder")
	if not (mf and isf) then return end
	pcall(function()
		if not isf(dirPath()) then mf(dirPath()) end
		if not isf(dirPath() .. "/cache") then mf(dirPath() .. "/cache") end
	end)
end
local function readJson(path)
	local rf, isf = fnv("readfile"), fnv("isfile")
	if not (rf and isf) then return nil end
	local ok, txt = pcall(function() if isf(path) then return rf(path) end end)
	if not ok or type(txt) ~= "string" or #txt < 2 then return nil end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, txt)
	return ok2 and data or nil
end
local function writeJson(path, tbl)
	local wf = fnv("writefile")
	if not wf then return end
	ensureDir()
	local ok, txt = pcall(HttpService.JSONEncode, HttpService, tbl)
	if ok then pcall(wf, path, txt) end
end
local function httpGet(url)
	local ok, r = pcall(function() return game:HttpGet(url) end)
	if ok and type(r) == "string" and #r > 2 and not r:find("^404: Not Found") then return r end
	local rq = fnv("request") or fnv("http_request") or (syn and syn.request)
	if rq then
		local ok2, res = pcall(rq, { Url = url, Method = "GET" })
		if ok2 and type(res) == "table" and (res.StatusCode or res.Status) == 200 and type(res.Body) == "string" then return res.Body end
	end
	local ok3, r3 = pcall(function() return HttpService:GetAsync(url) end)
	if ok3 and type(r3) == "string" and #r3 > 2 then return r3 end
end

-- ===== session memory =====
local function note(kind, text, shown)
	local e = S.events
	e[#e + 1] = { t = os.clock(), kind = kind, text = clean(text, 160), shown = shown ~= false }
	if #e > CFG.MaxEvents then table.remove(e, 1) end
end

-- ===== AI-only notification queue (priority ordered, serialized, greeting always first) =====
local Q, busy = {}, false
local function pump()
	if busy or not S.running then return end
	local it = Q[1]
	if not it then return end
	if it.kind ~= "greeting" and not S.greetDone then return end
	table.remove(Q, 1)
	busy = true
	task.spawn(function()
		local ok, delivered, hold = pcall(S.api.notify, "JARVIS", it.text)
		local shown = ok and delivered == true
		note(it.kind, it.text, shown)
		if it.kind == "greeting" then S.greetDone = true end
		if shown then task.wait(math.max(tonumber(hold) or 5, 3) + 1) end
		busy = false
		pump()
	end)
end
local function push(kind, text, prio)
	if not S.running then return end
	text = clean(text, CFG.TextMax)
	for _, q in ipairs(Q) do if q.text == text then return end end
	local item, pos = { kind = kind, text = text, prio = prio or 5 }, #Q + 1
	for i, q in ipairs(Q) do if item.prio < q.prio then pos = i break end end
	table.insert(Q, pos, item)
	while #Q > CFG.MaxQueue do table.remove(Q) end
	pump()
end
local function waitFor(cond, timeout)
	local t = os.clock()
	while S.running and os.clock() - t < timeout do
		local ok, v = pcall(cond)
		if ok and v then return true end
		task.wait(0.25)
	end
	return false
end

-- ===== greeting: GitHub file + cache + shuffle-bag =====
local function validPool(t)
	if type(t) ~= "table" then return nil end
	local list = type(t.greetings) == "table" and t.greetings or t
	local out, seen = {}, {}
	for _, g in ipairs(list) do
		if type(g) == "string" and #g >= 8 and #g <= 280 and not seen[g] then seen[g] = true out[#out + 1] = g end
	end
	return #out >= CFG.MinPool and out or nil
end
local function cachePath() return dirPath() .. "/cache/ai_greetings_cache.json" end
local function bagPath() return dirPath() .. "/cache/ai_greet_bag.json" end
local function fetchPool()
	local url = (S.api.repo or "") .. CFG.GreetingsFile
	local body = S.api.repo and httpGet(url)
	if not body then return nil end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, body)
	local pool = ok and validPool(data)
	if pool then writeJson(cachePath(), { fetched = os.time(), greetings = pool }) end
	return pool
end
local function prefetch()
	local cached = readJson(cachePath())
	local pool = type(cached) == "table" and validPool(cached) or nil
	if pool then
		S.pool = pool
		S.poolDone = true
		if os.time() - (tonumber(cached.fetched) or 0) >= CFG.CacheTTL then
			local fresh = fetchPool() -- background refresh; the cached pool is already in use
			if fresh then S.pool = fresh end
		end
		return
	end
	S.pool = fetchPool()
	S.poolDone = true
end
local function nextIndex(n)
	local st = readJson(bagPath())
	local last = type(st) == "table" and tonumber(st.last) or nil
	if type(st) ~= "table" or st.n ~= n or type(st.bag) ~= "table" or #st.bag == 0 then
		local bag, rnd = {}, Random.new()
		for i = 1, n do bag[i] = i end
		for i = n, 2, -1 do local j = rnd:NextInteger(1, i) bag[i], bag[j] = bag[j], bag[i] end
		if n > 1 and last and bag[n] == last then bag[n], bag[1] = bag[1], bag[n] end -- no back-to-back repeat across refills
		st = { n = n, bag = bag }
	end
	local idx = table.remove(st.bag)
	if type(idx) ~= "number" or idx < 1 or idx > n then idx = Random.new():NextInteger(1, n) end
	st.last = idx
	writeJson(bagPath(), st)
	if not fnv("readfile") then -- no filesystem: in-session fallback only avoids an immediate repeat
		if n > 1 and S.lastIdx == idx then idx = idx % n + 1 end
		S.lastIdx = idx
	end
	return idx
end
local function period()
	local h = tonumber(os.date("%H")) or 12
	return (h >= 5 and h < 12) and "morning" or (h >= 12 and h < 17) and "afternoon" or "evening"
end
local function render(tpl, name, title)
	local s = tpl:gsub("{period}", period()):gsub("{name}", function() return name end)
	if title then
		s = s:gsub("{title}", function() return title end)
	else
		s = s:gsub(",%s*{title}", ""):gsub("{title},%s*", ""):gsub("%s*{title}", "")
	end
	s = s:gsub("%s+([%.,!%?;:])", "%1"):gsub("%s%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	s = s:gsub("([%.!%?]%s+)(%l)", function(a, b) return a .. b:upper() end):gsub("^%l", string.upper)
	return s
end
local function buildGreeting()
	local lp = Players.LocalPlayer
	local name = lp and ((lp.DisplayName ~= "" and lp.DisplayName) or lp.Name) or "friend"
	local ok, title = pcall(S.api.getTitle)
	title = ok and title or nil
	local pool = S.pool or FALLBACK
	local tpl = pool[nextIndex(#pool)] or FALLBACK[1]
	return render(tpl, name, title)
end

-- ===== reanimation compatibility (the host's own checker) =====
local function compatClass(status)
	local s = tostring(status or ""):lower()
	if s:find("^not") then return "NOT COMPATIBLE" end
	if s:find("^partial") then return "PARTIAL" end
	if s:find("^compatible") then return "COMPATIBLE" end
end
local function runCompat()
	if not S.running or S.compatDone then return end
	S.compatDone = true
	local lp = Players.LocalPlayer
	local ready = waitFor(function() local c = lp and lp.Character return c and c:FindFirstChildOfClass("Humanoid") and c:FindFirstChild("HumanoidRootPart") end, 45)
	if not ready then
		S.compat = "unavailable"
		push("compat", "I could not run the reanimation compatibility check because your character has not loaded.", 3)
		return
	end
	task.wait(2)
	local ok, rep, err = pcall(S.api.runCompat)
	if not ok or type(rep) ~= "table" then
		S.compat = "failed"
		push("compat", "The reanimation compatibility check failed to run: " .. clean(ok and err or rep, 90) .. ". I will not guess at the result.", 3)
		return
	end
	local class = compatClass(rep.Status)
	if not class then
		S.compat = "unknown"
		push("compat", "The compatibility checker returned an unrecognized result, so I cannot classify it.", 3)
		return
	end
	S.compat = class
	local fails, reviews = {}, {}
	for _, f in ipairs(rep.Flags or {}) do
		if f.Severity == "FAIL" then fails[#fails + 1] = f elseif f.Severity == "REVIEW" then reviews[#reviews + 1] = f end
	end
	table.sort(fails, function(a, b) if a.Critical ~= b.Critical then return a.Critical end return a.Index < b.Index end)
	local why
	if class == "COMPATIBLE" then
		why = "All checks passed."
	elseif class == "PARTIAL" then
		why = plural(#fails + #reviews, "item") .. " need review, so some methods may behave unevenly."
	else
		why = plural(tonumber(rep.CriticalFailures) or #fails, "critical failure") .. " detected. The checker notes this result may be inaccurate."
	end
	local lim = {}
	for _, f in ipairs(fails) do if #lim < 2 then lim[#lim + 1] = clean(f.Message, 70) end end
	for _, f in ipairs(reviews) do if #lim < 2 then lim[#lim + 1] = clean(f.Message, 70) end end
	local text = "Reanimation compatibility: " .. class .. ". " .. why
	if #lim > 0 then text = text .. " Limitations: " .. table.concat(lim, "; ") .. "." end
	push("compat", text, 3)
end

-- ===== initialization report =====
local function analyzeInit(text)
	local r, seen = { err = {}, warn = {}, sec = {}, git = 0 }, {}
	for line in tostring(text or ""):gmatch("[^\r\n]+") do
		local tag, msg = line:match("^%s*%[(%u+)%]%s*(.*)$")
		if tag == "ERROR" or tag == "WARN" or tag == "SECURITY" then
			if tag == "WARN" and msg:lower():find("chill", 1, true) then -- routine module-reload notice
			elseif tag == "WARN" and msg:find("GitGET", 1, true) then r.git = r.git + 1
			else
				local m = clean((msg:gsub("%S+/(%S+)", "%1")), 80) -- keep file names, drop paths
				if m ~= "" and not seen[tag .. m] then
					seen[tag .. m] = true
					local t = tag == "ERROR" and r.err or (tag == "WARN" and r.warn or r.sec)
					t[#t + 1] = m
				end
			end
		end
	end
	return r
end
local function onInit(text)
	if not S or not S.running or type(text) ~= "string" then return end
	local r = analyzeInit(text)
	local ne, nw, ns = #r.err, #r.warn, #r.sec
	if ne == 0 and nw == 0 and ns == 0 and r.git < 3 then
		S.init = "clean"
		note("init", "Initialization finished without errors or warnings.", true)
		return
	end
	local sig = ne .. "/" .. nw .. "/" .. ns .. "/" .. (r.git >= 3 and 1 or 0) .. (r.err[1] or r.sec[1] or r.warn[1] or "")
	if S.initSigs[sig] then return end
	S.initSigs[sig] = true
	local head = {}
	if ne > 0 then head[#head + 1] = plural(ne, "error") end
	if nw > 0 then head[#head + 1] = plural(nw, "warning") end
	if ns > 0 then head[#head + 1] = plural(ns, "security notice") end
	if r.git >= 3 then head[#head + 1] = plural(r.git, "failed GitHub request") end
	local first = r.err[1] or r.sec[1] or r.warn[1]
	local blob = (table.concat(r.err, " ") .. " " .. table.concat(r.warn, " ")):lower()
	local tip
	if ne > 0 and (blob:find("load step") or blob:find("module") or blob:find("skipping")) then
		tip = "Re-execute to retry; if it persists, try a gentler Module Load Mode and check Init Logs for the failing module."
	elseif ns > 0 then
		tip = "Review Init Logs before trusting the flagged content."
	elseif r.git >= 3 or blob:find("sha1") or blob:find("download") then
		tip = "Check your connection or executor HTTP access; cached modules will be used where available."
	else
		tip = "Open Init Logs for details."
	end
	S.init = table.concat(head, ", ")
	push("init", "Initialization report: " .. S.init .. "." .. (first and (" Most important: " .. first .. ".") or "") .. " " .. tip, 2)
end

-- ===== staff detection (verified sources only; informational) =====
local function staffCfg()
	local c, g = { Groups = {}, UserIds = {} }, rawget(genv(), "NoobyAIStaff")
	local function merge(t)
		if type(t) ~= "table" then return end
		for gid, rank in pairs(type(t.Groups) == "table" and t.Groups or {}) do
			if tonumber(gid) and tonumber(rank) then c.Groups[tonumber(gid)] = tonumber(rank) end
		end
		for _, id in ipairs(type(t.UserIds) == "table" and t.UserIds or {}) do
			if tonumber(id) then c.UserIds[tonumber(id)] = true end
		end
	end
	merge(g)
	if S.api.staffConfig then merge(select(2, pcall(S.api.staffConfig))) end
	return c
end
local function checkStaff(p, already)
	local lp = Players.LocalPlayer
	if p == lp or S.staffSeen[p.UserId] then return end
	S.staffSeen[p.UserId] = true
	task.spawn(function()
		local c, proofs, unverified = staffCfg(), {}, false
		if c.UserIds[p.UserId] then proofs[#proofs + 1] = "the trusted staff roster" end
		local okc, ctype, cid = pcall(function() return game.CreatorType, game.CreatorId end)
		if okc then
			if ctype == Enum.CreatorType.User and cid == p.UserId then
				proofs[#proofs + 1] = "being the creator of this experience"
			elseif ctype == Enum.CreatorType.Group and cid and cid > 0 then
				local okr, rank = pcall(p.GetRankInGroup, p, cid)
				if okr and rank == 255 then proofs[#proofs + 1] = "owning this experience's group" elseif not okr then unverified = true end
			end
		end
		for gid, minRank in pairs(c.Groups) do
			local okr, rank = pcall(p.GetRankInGroup, p, gid)
			if okr and type(rank) == "number" then
				if rank >= minRank then
					local okn, role = pcall(p.GetRoleInGroup, p, gid)
					proofs[#proofs + 1] = ("rank %d%s in group %d"):format(rank, okn and (" (" .. clean(role, 24) .. ")") or "", gid)
				end
			else
				unverified = true
			end
		end
		if #proofs == 0 then
			if unverified then note("staff", p.Name .. ": staff status could not be verified, so I am not reporting it.", false) end
			return
		end
		if not S.running or not p.Parent then return end
		local who = (p.DisplayName ~= p.Name) and (p.DisplayName .. " (@" .. p.Name .. ")") or p.Name
		push("staff", "Staff alert: " .. who .. (already and " is in your server" or " has joined your server") .. ". Verified by " .. proofs[1] .. ". For your awareness only.", 4)
	end)
end

-- ===== performance monitors =====
local function startFps()
	local acc, frames, low, recover, armed, lastAlert = 0, 0, 0, 0, true, -1e9
	local focused = true
	pcall(function()
		local uis = game:GetService("UserInputService")
		S.conns[#S.conns + 1] = uis.WindowFocused:Connect(function() focused = true end)
		S.conns[#S.conns + 1] = uis.WindowFocusReleased:Connect(function() focused = false acc, frames, low = 0, 0, 0 end)
	end)
	S.conns[#S.conns + 1] = RunService.Heartbeat:Connect(function(dt)
		acc, frames = acc + dt, frames + 1
		if acc < 1 then return end
		local fps = frames / acc
		local stalled = acc > 3
		acc, frames = 0, 0
		if stalled or not focused or os.clock() - S.t0 < CFG.FpsGrace then low = 0 return end
		S.minFps = math.min(S.minFps or fps, fps)
		if not armed then
			recover = fps >= CFG.FpsRearm and recover + 1 or 0
			if recover >= CFG.FpsRearmSecs then armed, recover = true, 0 end
			return
		end
		low = fps <= CFG.LowFps and low + 1 or 0
		if low >= CFG.FpsSustain and os.clock() - lastAlert >= CFG.FpsCooldown then
			lastAlert, armed, low, recover = os.clock(), false, 0, 0
			push("fps", ("Performance warning: FPS has held at about %d. Try lowering Roblox graphics quality, enabling Low End UI Mode, turning off Ambient Particles, Liquid Glass or Cursor Trail in Customization, and closing background apps."):format(math.floor(fps + 0.5)), 5)
		end
	end)
end
local function startMem()
	task.spawn(function()
		local stats = game:GetService("Stats")
		local armed, lastAlert, fails = true, -1e9, 0
		while S.running do
			task.wait(CFG.MemPoll)
			local ok, mb = pcall(function() return stats:GetTotalMemoryUsageMb() end)
			if ok and type(mb) == "number" then
				fails = 0
				S.peakMB = math.max(S.peakMB or 0, mb)
				if not armed then
					if mb < CFG.MemRearmMB then armed = true end
				elseif mb >= CFG.MemMB and os.clock() - lastAlert >= CFG.MemCooldown then
					lastAlert, armed = os.clock(), false
					push("mem", ("Memory warning: Roblox is using %.1f GB (%d MB) of client memory, as measured by Roblox's Stats service. This is Roblox's own usage, not total device RAM. Consider rejoining, lowering graphics quality, or closing other apps."):format(mb / 1024, math.floor(mb)), 5)
				end
			else
				fails = fails + 1
				if fails >= 3 then
					note("mem", "Memory monitoring is unavailable on this executor.", false)
					return
				end
			end
		end
	end)
end

-- ===== public =====
local inst = {}
function inst.onInit(text) pcall(onInit, text) end
function inst.stop()
	if not S then return end
	S.running = false
	for _, c in ipairs(S.conns) do pcall(c.Disconnect, c) end
	table.clear(Q)
end
function inst.briefing()
	local ok, title = pcall(S.api.getTitle)
	local lines = { "**Session briefing" .. ((ok and title) and (", " .. title) or "") .. "**" }
	lines[#lines + 1] = "- Initialization: " .. (S.init or "no report yet")
	lines[#lines + 1] = "- Reanimation compatibility: " .. (S.compat or "not checked yet")
	if S.peakMB then lines[#lines + 1] = ("- Peak Roblox memory: %d MB"):format(math.floor(S.peakMB)) end
	if S.minFps then lines[#lines + 1] = ("- Lowest FPS seen: %d"):format(math.floor(S.minFps + 0.5)) end
	local c = staffCfg()
	if next(c.Groups) == nil and next(c.UserIds) == nil then
		lines[#lines + 1] = "- Staff alerts: only experience creators/group owners can be verified (no roster configured)."
	end
	local n0 = math.max(1, #S.events - 7)
	for i = n0, #S.events do
		local e = S.events[i]
		lines[#lines + 1] = ("- %dm ago, %s%s: %s"):format(math.floor((os.clock() - e.t) / 60), e.kind, e.shown and "" or " (not shown)", e.text)
	end
	return table.concat(lines, "\n")
end

function Butler.start(api)
	local g = genv()
	local prev = rawget(g, "__NoobyButlerStop")
	if type(prev) == "function" then pcall(prev) end
	S = { api = api, running = true, t0 = os.clock(), events = {}, conns = {}, staffSeen = {}, initSigs = {}, greeted = false, greetDone = false }
	pcall(function() g.__NoobyButlerStop = inst.stop end)

	task.spawn(prefetch)
	task.spawn(function()
		waitFor(function() return game:IsLoaded() and Players.LocalPlayer ~= nil end, 60)
		waitFor(function() return not api.introRunning() end, 150)
		waitFor(function() return not api.uiReady or api.uiReady() end, 60)
		if not S.running or S.greeted then return end
		S.greeted = true -- exactly one greeting per initialization
		waitFor(function() return S.poolDone end, 3)
		local ok, text = pcall(buildGreeting)
		push("greeting", ok and text or FALLBACK[1], 1)
		waitFor(function() return S.greetDone end, 30)
		S.greetDone = true
		pump()
		runCompat()
		for _, p in ipairs(Players:GetPlayers()) do checkStaff(p, true) end
	end)

	startFps()
	startMem()
	S.conns[#S.conns + 1] = Players.PlayerAdded:Connect(function(p) checkStaff(p, false) end)
	S.conns[#S.conns + 1] = Players.PlayerRemoving:Connect(function(p)
		task.delay(CFG.StaffCooldown, function() if S then S.staffSeen[p.UserId] = nil end end)
	end)
	local pending = api.getInitLog and api.getInitLog()
	if type(pending) == "table" then onInit(pending.text) end
	return inst
end

return Butler
