-- AI_Config: settings, capability detection, adaptive limits. No dependencies.
local Config = {}

Config.Name = "Nooby Neural AI"
Config.Version = "2.0.0"
Config.Dir = "NoobyAI"
Config.ModelFile = "model.json"

local BASE = {
	History = 40, Convos = 20, Facts = 120, Learned = 250, Assoc = 400,
	ContextTurns = 6, MaxReply = 3200, TopK = 4, Batch = 20,
	ModelMaxKB = 1536, ModelMaxParams = 300000,
}
local MIN = { History = 10, Convos = 5, Facts = 20, Learned = 40, Assoc = 80, ContextTurns = 2, MaxReply = 1200 }

Config.Base = BASE
Config.Limits = {}
for k, v in pairs(BASE) do Config.Limits[k] = v end

-- Roblox total client memory (MB) thresholds tuned for 4 GB machines
Config.Thresholds = { MB1 = 1800, MB2 = 2500, LuaKB1 = 48000, LuaKB2 = 96000 }
Config.Flags = { Neural = false, Persist = true, Launcher = true, DestroyOnClose = false }
Config.Caps = {}
Config.pressure = 0
Config.mb = nil

local function fn(name)
	local ok, g = pcall(function() return getgenv and getgenv() end)
	local v = ok and g and g[name]
	if type(v) ~= "function" then v = _G[name] end
	if type(v) == "function" then return v end
	return nil
end

function Config.detect()
	local c = Config.Caps
	c.write, c.read, c.isfile = fn("writefile"), fn("readfile"), fn("isfile")
	c.isfolder, c.makefolder, c.delfile = fn("isfolder"), fn("makefolder"), fn("delfile")
	c.clip = fn("setclipboard") or fn("toclipboard")
	c.gethui = fn("gethui")
	c.fs = (c.write and c.read and c.isfile) and true or false
	c.json = (pcall(function() return game:GetService("HttpService"):JSONEncode({ 1 }) end))
	c.stats = (pcall(function() return game:GetService("Stats"):GetTotalMemoryUsageMb() end))
	return c
end

-- 0 = fine, 1 = elevated, 2 = high
function Config.level()
	local T = Config.Thresholds
	local ok, mb = pcall(function() return game:GetService("Stats"):GetTotalMemoryUsageMb() end)
	if ok and type(mb) == "number" then
		Config.mb = mb
		return mb > T.MB2 and 2 or (mb > T.MB1 and 1 or 0)
	end
	local kb = collectgarbage("count")
	return kb > T.LuaKB2 and 2 or (kb > T.LuaKB1 and 1 or 0)
end

function Config.adapt()
	local lvl = Config.level()
	local s = lvl == 2 and 0.35 or (lvl == 1 and 0.6 or 1)
	for k, m in pairs(MIN) do
		Config.Limits[k] = math.max(m, math.floor(BASE[k] * s))
	end
	Config.pressure = lvl
	return lvl
end

function Config.init()
	Config.detect()
	Config.adapt()
end

return Config
