-- AI_Neural: optional local neural inference.
-- Honest scope: this runs a COMPACT feed-forward classifier (hashed bag-of-words -> MLP -> softmax) from a weights file
-- you provide at NoobyAI/model.json. It is NOT a generative LLM and cannot write replies. Nothing is loaded
-- automatically; enable with "/neural on". If no compatible model/runtime exists, the local NLP + retrieval engine is used.
--
-- Model file (JSON), format "nooby-mlp-v1":
--   { "format":"nooby-mlp-v1", "buckets":1024, "bigrams":true,
--     "labels":["intent:howto","topic:reanim", ...],
--     "layers":[ {"w":[[...H floats] x buckets], "b":[H], "act":"relu"},
--                {"w":[[...L floats] x H],       "b":[L], "act":"none"} ] }
-- Features: FNV-1a 32-bit hash of each lowercase token (and "tok1 tok2" bigrams if enabled), bucket = hash % buckets, value 1.
-- Labels starting with "intent:" or "topic:" refine NLP results when confidence >= 0.7.
local Neural = {}

local ctx
local model

Neural.state = "off" -- off | unavailable | loaded | error
Neural.reason = nil
Neural.canGenerate = false
Neural.params = 0

function Neural.init(c) ctx = c end

local function mul32(a, b)
	local ah, al = math.floor(a / 65536), a % 65536
	return ((ah * b % 65536) * 65536 + al * b) % 4294967296
end

local function fnv(s)
	local h = 2166136261
	for i = 1, #s do
		h = bit32.bxor(h, s:byte(i))
		h = mul32(h, 16777619)
	end
	return h
end

local function validate(m, maxParams)
	if type(m) ~= "table" or m.format ~= "nooby-mlp-v1" then return nil, "unsupported model format" end
	local B = tonumber(m.buckets)
	if not B or B < 16 or B > 8192 then return nil, "bad bucket count" end
	if type(m.labels) ~= "table" or #m.labels < 2 then return nil, "missing labels" end
	if type(m.layers) ~= "table" or #m.layers < 1 or #m.layers > 4 then return nil, "bad layer count" end
	local inDim, params = B, 0
	for i, l in ipairs(m.layers) do
		if type(l) ~= "table" or type(l.w) ~= "table" or type(l.b) ~= "table" or #l.w ~= inDim then
			return nil, "layer " .. i .. " shape mismatch"
		end
		local out = #l.b
		for r = 1, #l.w do
			if type(l.w[r]) ~= "table" or #l.w[r] ~= out then return nil, "layer " .. i .. " row mismatch" end
		end
		params = params + inDim * out + out
		if params > maxParams then return nil, "model too large for the current limits" end
		inDim = out
	end
	if inDim ~= #m.labels then return nil, "label count mismatch" end
	m.B = B
	return m, params
end

function Neural.load()
	local C = ctx.Config
	if not C.Flags.Neural then
		Neural.state, Neural.reason = "off", "disabled"
		return false, "Neural inference is off. Use /neural on."
	end
	if model then return true end
	if not (C.Caps.fs and C.Caps.json) then
		Neural.state, Neural.reason = "unavailable", "no file or JSON support"
		return false, "This executor has no file/JSON support, so no model can be loaded. I'm using the local NLP + retrieval engine."
	end
	if C.adapt() >= 2 then
		Neural.state, Neural.reason = "unavailable", "memory pressure"
		return false, "Memory pressure is high, so I'm not loading a model right now."
	end
	local path = C.Dir .. "/" .. C.ModelFile
	local ok, exists = pcall(C.Caps.isfile, path)
	if not ok or not exists then
		Neural.state, Neural.reason = "unavailable", "no model file"
		return false, "No model file found at `" .. path .. "`. I'm using the local NLP + retrieval engine."
	end
	local ok2, src = pcall(C.Caps.read, path)
	if not ok2 or type(src) ~= "string" then
		Neural.state, Neural.reason = "error", "read failed"
		return false, "Couldn't read the model file."
	end
	if #src > C.Limits.ModelMaxKB * 1024 then
		Neural.state, Neural.reason = "unavailable", "model too large"
		return false, "The model file is larger than the " .. C.Limits.ModelMaxKB .. " KB limit, so it was not loaded."
	end
	local ok3, data = pcall(function() return game:GetService("HttpService"):JSONDecode(src) end)
	src = nil
	if not ok3 then
		Neural.state, Neural.reason = "error", "bad json"
		return false, "The model file isn't valid JSON."
	end
	local m, info = validate(data, C.Limits.ModelMaxParams)
	if not m then
		Neural.state, Neural.reason = "error", info
		return false, "Model rejected: " .. tostring(info) .. "."
	end
	model = m
	Neural.params = info
	Neural.state, Neural.reason = "loaded", nil
	return true
end

function Neural.unload()
	model = nil
	Neural.params = 0
	if Neural.state == "loaded" then Neural.state = "off" end
	pcall(collectgarbage, "collect")
end

function Neural.setEnabled(on)
	ctx.Config.Flags.Neural = on and true or false
	if not on then
		Neural.unload()
		Neural.state, Neural.reason = "off", "disabled"
		return true, "Neural inference is off."
	end
	local ok, msg = Neural.load()
	if ok then return true, "Neural classifier loaded (" .. Neural.params .. " parameters)." end
	return false, msg
end

function Neural.status()
	return { state = Neural.state, reason = Neural.reason, params = Neural.params, labels = model and #model.labels or 0 }
end

local function act(v, a)
	if a == "relu" then
		for i = 1, #v do if v[i] < 0 then v[i] = 0 end end
	elseif a == "tanh" then
		for i = 1, #v do v[i] = math.tanh(v[i]) end
	end
end

function Neural.classify(text)
	if not model then return nil end
	local toks = ctx.NLP.tokens(text:lower())
	local seen, active = {}, {}
	local function feat(s)
		local b = fnv(s) % model.B
		if not seen[b] then seen[b] = true; active[#active + 1] = b end
	end
	for i = 1, math.min(#toks, 64) do
		feat(toks[i])
		if model.bigrams and i > 1 then feat(toks[i - 1] .. " " .. toks[i]) end
	end
	if #active == 0 then return nil end

	local l1 = model.layers[1]
	local h = {}
	for j = 1, #l1.b do h[j] = l1.b[j] end
	for _, b in ipairs(active) do
		local row = l1.w[b + 1]
		for j = 1, #h do h[j] = h[j] + row[j] end
	end
	act(h, l1.act)
	for li = 2, #model.layers do
		local l = model.layers[li]
		local o = {}
		for k = 1, #l.b do o[k] = l.b[k] end
		for j = 1, #h do
			local hj = h[j]
			if hj ~= 0 then
				local row = l.w[j]
				for k = 1, #o do o[k] = o[k] + hj * row[k] end
			end
		end
		act(o, l.act)
		h = o
	end
	-- softmax
	local mx = -math.huge
	for i = 1, #h do if h[i] > mx then mx = h[i] end end
	local sum = 0
	for i = 1, #h do h[i] = math.exp(h[i] - mx); sum = sum + h[i] end
	local best, bp = 1, 0
	for i = 1, #h do
		h[i] = h[i] / sum
		if h[i] > bp then best, bp = i, h[i] end
	end
	return { label = model.labels[best], p = bp }
end

-- refine an NLP analysis when the model is confident
function Neural.apply(a)
	if not model then
		if ctx.Config.Flags.Neural and Neural.state == "off" then Neural.load() end
		if not model then return a end
	end
	local r = Neural.classify(a.raw)
	if not r or r.p < 0.7 then return a end
	a.neural = r
	local kind, name = r.label:match("^(%w+):(.+)$")
	if kind == "intent" and a.intent == "question" then
		a.intent = name
	elseif kind == "topic" and (not a.topic or a.topicScore < 2) then
		a.topic = name
	end
	return a
end

return Neural
