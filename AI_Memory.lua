-- AI_Memory: short-term (session), long-term (persistent) memory, conversations, user facts.
-- Also owns the persistence primitive used by AI_Knowledge. Never sends anything off-device.
local Memory = {}

local ctx, Config, Http
local S = { convos = {}, order = {}, cur = nil, loaded = false, providers = {}, dirty = {}, timer = false, saved = 0 }
local facts = { map = {}, n = 0 }
local seq = 0

Memory.temp = {} -- session-only scratch (never persisted)

local function norm(s)
	return (tostring(s):lower():gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function trim(s)
	return (tostring(s):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function path(name) return Config.Dir .. "/" .. name .. ".json" end

function Memory.canPersist()
	return Config.Flags.Persist and Config.Caps.fs and Config.Caps.json and true or false
end

function Memory.loadBlob(name)
	if not Memory.canPersist() then return nil end
	local C = Config.Caps
	local ok, data = pcall(function()
		if not C.isfile(path(name)) then return nil end
		return Http:JSONDecode(C.read(path(name)))
	end)
	if ok then return data end
	return nil
end

function Memory.saveBlob(name, tbl)
	if not Memory.canPersist() then return false end
	local C = Config.Caps
	return (pcall(function()
		if C.makefolder and C.isfolder and not C.isfolder(Config.Dir) then C.makefolder(Config.Dir) end
		C.write(path(name), Http:JSONEncode(tbl))
	end))
end

function Memory.register(name, provider) S.providers[name] = provider end

function Memory.flush()
	for name in pairs(S.dirty) do
		S.dirty[name] = nil
		local p = S.providers[name]
		if p then Memory.saveBlob(name, p()) end
	end
	S.saved = os.time()
end

-- debounced: one pending timer at most, no background loop
function Memory.touch(name)
	S.dirty[name] = true
	if S.timer or not Memory.canPersist() then return end
	S.timer = true
	task.delay(1.5, function()
		S.timer = false
		Memory.flush()
	end)
end

local function ensure()
	if S.loaded then return end
	S.loaded = true
	Memory.register("convos", function() return { convos = S.convos, order = S.order } end)
	Memory.register("profile", function()
		local l = {}
		for _, f in pairs(facts.map) do
			if f.p then l[#l + 1] = { k = f.k, v = f.v, t = f.t } end
		end
		return { facts = l }
	end)
	local d = Memory.loadBlob("convos")
	if type(d) == "table" and type(d.convos) == "table" and type(d.order) == "table" then
		S.convos = d.convos
		local clean = {}
		for _, id in ipairs(d.order) do
			local c = S.convos[id]
			if type(c) == "table" and type(c.m) == "table" then
				c.id = id
				clean[#clean + 1] = id
			end
		end
		S.order = clean
	end
	local p = Memory.loadBlob("profile")
	if type(p) == "table" and type(p.facts) == "table" then
		for _, f in ipairs(p.facts) do
			if type(f) == "table" and f.k and f.v then
				facts.map[f.k] = { k = f.k, v = f.v, t = f.t or 0, p = true }
				facts.n = facts.n + 1
			end
		end
	end
end

local function uid()
	local id
	repeat
		seq = seq + 1
		id = tostring(os.time()) .. "-" .. seq .. math.random(10, 99)
	until not S.convos[id]
	return id
end

function Memory.init(c)
	ctx = c
	Config = c.Config
	Http = game:GetService("HttpService")
	ensure()
end

-- ===== conversations =====
function Memory.newConvo()
	ensure()
	local cur = S.convos[S.cur or ""]
	if cur and #cur.m == 0 then return cur.id end
	local id = uid()
	S.convos[id] = { id = id, title = "New chat", t = os.time(), m = {} }
	table.insert(S.order, 1, id)
	S.cur = id
	Memory.trim()
	return id
end

function Memory.addTurn(role, text, topic)
	ensure()
	local c = S.convos[S.cur or ""]
	if not c then c = S.convos[Memory.newConvo()] end
	c.m[#c.m + 1] = { r = role, x = text, k = topic }
	if role == "u" and c.title == "New chat" then
		c.title = (text:gsub("%s+", " "):sub(1, 42))
	end
	c.t = os.time()
	while #c.m > Config.Limits.History do table.remove(c.m, 1) end
	for i, id in ipairs(S.order) do
		if id == c.id then table.remove(S.order, i) break end
	end
	table.insert(S.order, 1, c.id)
	Memory.touch("convos")
end

function Memory.recent(n)
	ensure()
	local c = S.convos[S.cur or ""]
	local out = {}
	if not c then return out end
	for i = math.max(1, #c.m - n + 1), #c.m do out[#out + 1] = c.m[i] end
	return out
end

function Memory.open(id)
	ensure()
	local c = S.convos[id]
	if not c then return nil end
	S.cur = id
	Memory.temp.prev, Memory.temp.awaitFix = nil, nil
	return c.m
end

function Memory.current()
	ensure()
	local c = S.convos[S.cur or ""]
	return c and c.m or {}, S.cur
end

function Memory.delete(id)
	ensure()
	if not S.convos[id] then return false end
	S.convos[id] = nil
	for i, v in ipairs(S.order) do
		if v == id then table.remove(S.order, i) break end
	end
	local was = S.cur == id
	if was then S.cur = nil; Memory.temp.prev, Memory.temp.awaitFix = nil, nil end
	Memory.touch("convos")
	return was
end

function Memory.list()
	ensure()
	local out = {}
	for _, id in ipairs(S.order) do
		local c = S.convos[id]
		if c and #c.m > 0 then out[#out + 1] = { id = id, title = c.title, t = c.t, n = #c.m } end
	end
	return out, S.cur
end

-- ===== facts / preferences (user-provided, never "verified") =====
function Memory.remember(key, value, permanent)
	ensure()
	key, value = norm(key), trim(value)
	if key == "" or value == "" then return "empty" end
	if #value > 400 then value = value:sub(1, 400) end
	local f = facts.map[key]
	if f then
		if norm(f.v) == norm(value) then
			if permanent and not f.p then
				f.p = true
				Memory.touch("profile")
				return "promoted"
			end
			return "duplicate"
		end
		f.v, f.t = value, os.time()
		f.p = f.p or (permanent and true or false)
		if f.p then Memory.touch("profile") end
		return "updated"
	end
	facts.map[key] = { k = key, v = value, t = os.time(), p = permanent and true or false }
	facts.n = facts.n + 1
	Memory.trim()
	if permanent then Memory.touch("profile") end
	return "added"
end

function Memory.get(key)
	ensure()
	local f = facts.map[norm(key)]
	return f and f.v or nil
end

function Memory.setPref(k, v) return Memory.remember("pref:" .. k, v, true) end
function Memory.pref(k) return Memory.get("pref:" .. k) end

-- removes by exact key first, otherwise by key/value substring; returns count
function Memory.forget(q)
	ensure()
	q = norm(q)
	if q == "" then return 0 end
	local n = 0
	if facts.map[q] then
		facts.map[q] = nil; facts.n = facts.n - 1; n = 1
	else
		for k, f in pairs(facts.map) do
			if k:sub(1, 5) ~= "pref:" and (k:find(q, 1, true) or norm(f.v):find(q, 1, true)) then
				facts.map[k] = nil; facts.n = facts.n - 1; n = n + 1
			end
		end
	end
	if n > 0 then Memory.touch("profile") end
	return n
end

function Memory.all()
	ensure()
	local out = {}
	for _, f in pairs(facts.map) do out[#out + 1] = f end
	table.sort(out, function(a, b) return a.t > b.t end)
	return out
end

-- keep everything inside adaptive limits (temporary facts are evicted first)
function Memory.trim()
	ensure()
	local L = Config.Limits
	while #S.order > L.Convos do
		local id = table.remove(S.order)
		S.convos[id] = nil
		if S.cur == id then S.cur = nil end
	end
	for _, c in pairs(S.convos) do
		while #c.m > L.History do table.remove(c.m, 1) end
	end
	while facts.n > L.Facts do
		local victim
		for k, f in pairs(facts.map) do
			if k:sub(1, 5) ~= "pref:" then
				if not victim or (not f.p and victim.p) or (f.p == victim.p and f.t < victim.t) then victim = f end
			end
		end
		if not victim then break end
		facts.map[victim.k] = nil
		facts.n = facts.n - 1
	end
	Memory.touch("convos")
	Memory.touch("profile")
end

function Memory.stats()
	ensure()
	return { convos = #S.order, facts = facts.n, persist = Memory.canPersist(), saved = S.saved }
end

function Memory.clearAll()
	ensure()
	S.convos, S.order, S.cur = {}, {}, nil
	facts.map, facts.n = {}, 0
	Memory.temp = {}
	Memory.saveBlob("convos", { convos = {}, order = {} })
	Memory.saveBlob("profile", { facts = {} })
end

return Memory
