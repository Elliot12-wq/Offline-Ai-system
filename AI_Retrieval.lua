-- AI_Retrieval: context-aware retrieval over verified + learned knowledge and user facts.
-- Inverted index is built lazily, in small batches, and rebuilt only when Knowledge.version changes.
local Retrieval = {}

local ctx
local idx

function Retrieval.init(c) ctx = c end

local function build()
	local K, NLP, B = ctx.Knowledge, ctx.NLP, ctx.Config.Limits.Batch
	local ix = { ver = K.version, post = {}, df = {}, docs = {}, N = 0 }
	local post = ix.post

	local function add(id, list, w, bucket)
		for _, t in ipairs(list) do
			local m = post[t]
			if not m then m = {}; post[t] = m end
			m[id] = (m[id] or 0) + w
			bucket.len = bucket.len + 1
		end
	end

	local n = 0
	local function tick()
		n = n + 1
		if n % B == 0 and coroutine.isyieldable and coroutine.isyieldable() then task.wait() end
	end

	for _, e in ipairs(K.verified) do
		local d = { topic = e.topic, kind = "entry", len = 0 }
		add(e.id, NLP.terms(e.title), 3, d)
		add(e.id, NLP.terms(e.tags), 2.5, d)
		add(e.id, NLP.terms(e.text), 1, d)
		if e.code then
			local ct = NLP.terms(e.code)
			local cut = {}
			for i = 1, math.min(#ct, 20) do cut[i] = ct[i] end
			add(e.id, cut, 0.4, d)
		end
		ix.docs[e.id] = d
		ix.N = ix.N + 1
		tick()
	end
	for _, it in ipairs(K.learned.list) do
		local d = { kind = it.kind, len = 0 }
		if it.kind == "correction" then
			add(it.id, it.qt or {}, 3, d)
			add(it.id, it.terms, 0.5, d)
		else
			add(it.id, it.terms, 1.2, d)
		end
		ix.docs[it.id] = d
		ix.N = ix.N + 1
		tick()
	end
	for _, d in pairs(ix.docs) do d.norm = 1 / (1 + 0.1 * math.log(1 + d.len)) end
	for t, m in pairs(post) do
		local c = 0
		for _ in pairs(m) do c = c + 1 end
		ix.df[t] = c
	end
	idx = ix
end

function Retrieval.invalidate() idx = nil end

-- user facts relevant to the query (top 3)
function Retrieval.facts(a)
	local qs = {}
	for _, t in ipairs(a.terms) do qs[t] = true end
	local out = {}
	for _, f in ipairs(ctx.Memory.all()) do
		if f.k:sub(1, 5) ~= "pref:" then
			local c = 0
			for _, t in ipairs(ctx.NLP.terms(f.k .. " " .. f.v)) do
				if qs[t] then c = c + 1 end
			end
			if c > 0 then out[#out + 1] = { f = f, c = c } end
		end
	end
	table.sort(out, function(x, y) return x.c > y.c end)
	local res = {}
	for i = 1, math.min(3, #out) do res[i] = out[i].f end
	return res
end

function Retrieval.search(a, prev)
	local K = ctx.Knowledge
	if not idx or idx.ver ~= K.version then build() end
	local L = ctx.Config.Limits
	local scores = {}
	local qt = a.terms
	local N = math.max(idx.N, 1)

	local function acc(list, mult)
		for _, t in ipairs(list) do
			local m = idx.post[t]
			if m then
				local df = idx.df[t] or 1
				local idf = math.log(1 + N / df)
				for id, w in pairs(m) do scores[id] = (scores[id] or 0) + idf * w * mult end
			end
		end
	end
	acc(qt, 1)
	if a.follow and a.ctxTerms then acc(a.ctxTerms, 0.4) end

	-- learned associations (query term -> entry), positive or negative
	for _, t in ipairs(qt) do
		local m = K.learned.assoc[t]
		if m then
			for id, w in pairs(m) do
				if idx.docs[id] then scores[id] = (scores[id] or 0) + w * 1.5 end
			end
		end
	end

	-- corrections that closely match the query win
	for _, it in ipairs(K.learned.list) do
		if it.kind == "correction" and it.qt and #it.qt > 0 then
			local common = ctx.NLP.overlap(it.qt, qt)
			if common / #it.qt >= 0.6 then scores[it.id] = (scores[it.id] or 0) * 2.5 + 6 end
		end
	end

	-- normalisation, topic and usage boosts
	local list = {}
	for id, s in pairs(scores) do
		local d = idx.docs[id]
		if d then
			s = s * d.norm
			if d.topic and a.topic and d.topic == a.topic then s = s * 1.25 end
			local it = K.learned.byId[id]
			if it then s = s * (1.1 + 0.05 * math.min(it.h, 10)) end
			if ctx.Mind then s = s * ctx.Mind.weight(id) end
			if s > 0.05 then list[#list + 1] = { id = id, score = s } end
		end
	end
	table.sort(list, function(x, y) return x.score > y.score end)

	local hits = {}
	for i = 1, math.min(L.TopK, #list) do
		local v = K.view(list[i].id)
		if v then hits[#hits + 1] = { id = list[i].id, score = list[i].score, e = v } end
	end

	-- "more / explain that" with nothing new to match: reuse the previous answer's entries
	if (a.more or #qt == 0) and prev and prev.ids and #prev.ids > 0 and (#hits == 0 or a.more) then
		local reuse, seen = {}, {}
		for _, id in ipairs(prev.ids) do
			local v = K.view(id)
			if v then reuse[#reuse + 1] = { id = id, score = 5, e = v }; seen[id] = true end
		end
		for _, h in ipairs(hits) do if not seen[h.id] then reuse[#reuse + 1] = h end end
		hits = reuse
	end

	local top = hits[1]
	local cov = 0
	if top and #qt > 0 then
		local matched = 0
		for _, t in ipairs(qt) do
			local m = idx.post[t]
			if m and m[top.id] then matched = matched + 1 end
		end
		cov = matched / #qt
	elseif top then
		cov = 1
	end
	return { hits = hits, top = top, cov = cov, facts = Retrieval.facts(a) }
end

return Retrieval
