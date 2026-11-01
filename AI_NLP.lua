-- AI_NLP: tokenizing, light stemming, intent / topic / slot extraction. No dependencies.
local NLP = {}

local function set(t) local s = {} for _, v in ipairs(t) do s[v] = true end return s end

local STOP = set({
	"a", "an", "the", "is", "are", "was", "were", "be", "been", "am", "i", "im", "ive", "you", "your", "me", "my", "we",
	"it", "its", "to", "of", "in", "on", "at", "for", "with", "and", "or", "but", "do", "does", "did", "can", "could",
	"would", "should", "will", "just", "so", "that", "this", "these", "those", "there", "here", "please", "pls", "hey",
	"hi", "hello", "some", "any", "have", "has", "had", "get", "got", "about", "into", "from", "as", "if", "then",
	"than", "what", "whats", "which", "who", "how", "why", "when", "where", "not", "no", "yes", "ok", "okay", "like",
	"want", "need", "make", "help", "tell", "know", "use", "thing", "things", "way", "also", "too", "very", "really",
	"much", "more", "one", "us", "them", "they", "he", "she", "his", "her", "our", "dont", "cant", "wont", "doesnt",
	"isnt", "thanks", "thank", "show", "give", "let", "lets", "can't", "u", "ur", "im", "ill", "id",
})

local SYN = { gui = "ui", interface = "ui", reanim = "reanimat" }
local EXC = { string = "string", strings = "string", class = "class", classes = "class", process = "process" }

local function stem(w)
	if EXC[w] then return EXC[w] end
	if #w <= 3 or w:find("[%d_]") then return SYN[w] or w end
	if w:sub(-3) == "ies" and #w > 4 then
		w = w:sub(1, -4) .. "y"
	elseif w:sub(-1) == "s" and w:sub(-2) ~= "ss" and w:sub(-2) ~= "us" then
		w = w:sub(1, -2)
	end
	if #w > 5 and w:sub(-3) == "ing" then
		w = w:sub(1, -4)
	elseif #w > 4 and w:sub(-2) == "ed" then
		w = w:sub(1, -3)
	end
	if #w > 6 and w:sub(-3) == "ion" then w = w:sub(1, -4) end
	if #w > 5 and w:sub(-2) == "ly" then w = w:sub(1, -3) end
	if #w > 3 and w:sub(-1) == "e" then w = w:sub(1, -2) end
	return SYN[w] or w
end
NLP.stem = stem

function NLP.tokens(text)
	local out = {}
	for w in text:gmatch("[%w_]+") do
		out[#out + 1] = w
		if #out >= 200 then break end
	end
	return out
end

-- stemmed, stop-word-free, unique terms (order kept, capped)
function NLP.terms(text)
	local out, seen = {}, {}
	for _, w in ipairs(NLP.tokens(text:lower())) do
		if not STOP[w] and #w > 1 then
			local s = stem(w)
			if not seen[s] then
				seen[s] = true
				out[#out + 1] = s
				if #out >= 32 then break end
			end
		end
	end
	return out
end

function NLP.overlap(a, b)
	if #a == 0 or #b == 0 then return 0, 0 end
	local m = {}
	for _, t in ipairs(a) do m[t] = true end
	local common = 0
	for _, t in ipairs(b) do if m[t] then common = common + 1 end end
	return common, common / (#a + #b - common)
end

-- ===== topics =====
local TOPICS = { ui = {}, reanim = {}, luau = {}, sec = {}, help = {} }
local function addTopic(t, words, w)
	for _, x in ipairs(words) do TOPICS[t][stem(x)] = w end
end
addTopic("ui", { "ui", "gui", "screengui", "frame", "button", "textbutton", "textlabel", "textbox", "label", "tween", "tweenservice",
	"tweeninfo", "animation", "transition", "layout", "uicorner", "uilistlayout", "uigridlayout", "uipadding", "uiscale", "scrollingframe",
	"draggable", "drag", "hover", "theme", "menu", "window", "slider", "toggle", "notification", "popup", "anchorpoint", "udim2", "easing",
	"fade", "interface", "corner", "gradient", "responsive", "click", "scroll" }, 1)
addTopic("ui", { "screengui", "tweenservice", "tweeninfo", "uicorner", "uilistlayout", "udim2", "textbutton", "scrollingframe" }, 2)
addTopic("reanim", { "reanimate", "reanimation", "reanim", "humanoid", "joint", "limb", "rig", "character", "network", "ownership",
	"replicate", "replication", "physics", "weld", "fling", "velocity", "simulation", "heartbeat", "fake", "clone", "torso", "humanoidrootpart",
	"neck", "shoulder", "hip", "accessory", "respawn", "anchored", "massless", "collision" }, 1)
addTopic("reanim", { "r6", "r15", "motor6d", "cframe", "reanimate", "reanimation", "reanim", "humanoidrootpart", "ownership", "replication" }, 2)
addTopic("luau", { "luau", "lua", "variable", "function", "table", "loop", "metatable", "metamethod", "coroutine", "task", "pcall",
	"xpcall", "debug", "error", "module", "modulescript", "require", "string", "array", "dictionary", "closure", "oop", "class", "local",
	"nil", "ipairs", "pairs", "script", "scope", "return", "parameter", "argument", "vararg", "insert", "sort", "print", "warn", "typeof",
	"tostring", "tonumber", "service", "event", "signal", "connect", "instance", "pattern", "gsub", "format", "executor", "loadstring" }, 1)
addTopic("luau", { "luau", "metatable", "coroutine", "pcall", "closure", "modulescript", "dictionary" }, 2)
addTopic("luau", { "remote", "remoteevent", "remotefunction", "heartbeat", "runservice", "raycast", "datastore", "collectionservice", "attribute", "userinputservice", "localscript", "strict", "client", "server" }, 1)
addTopic("sec", { "vulnerability", "vulnerable", "exploit", "exploiter", "exploiting", "security", "secure", "anticheat", "validate", "validation", "sanity", "cheat", "cheater", "ownership", "networkowner", "disclosure", "protect", "weakness" }, 1)
addTopic("sec", { "vulnerability", "exploiter", "anticheat", "validation", "sanity" }, 2)
addTopic("help", { "help", "assist", "support", "troubleshoot", "beginner", "teach", "tutorial", "learn", "stuck", "newbie", "noob", "guide", "report", "bug", "checklist" }, 1)

local function detectTopic(terms)
	local best, bestScore, second = nil, 0, 0
	for t, kw in pairs(TOPICS) do
		local s = 0
		for _, term in ipairs(terms) do s = s + (kw[term] or 0) end
		if s > bestScore then second = bestScore; best, bestScore = t, s
		elseif s > second then second = s end
	end
	return best, bestScore
end

-- ===== code detection =====
function NLP.code(text)
	local fenced = text:match("```%w*\n?(.-)```")
	if fenced and #fenced > 0 then return true, fenced end
	local score = 0
	for _, p in ipairs({ "%f[%w]local%f[%W]", "%f[%w]function%f[%W]", "%f[%w]end%f[%W]", "%f[%w]then%f[%W]", ":Connect", "GetService", "%f[%w]for%f[%W].-%f[%w]do%f[%W]" }) do
		if text:find(p) then score = score + 1 end
	end
	if score >= 3 and text:find("\n") then return true, text end
	return false, nil
end

-- ===== slots for code generation =====
local EASING = { quad = "Quad", sine = "Sine", bounce = "Bounce", elastic = "Elastic", back = "Back", quart = "Quart", quint = "Quint",
	cubic = "Cubic", linear = "Linear", exponential = "Exponential", circular = "Circular" }
local COLORS = { red = "255, 80, 80", green = "80, 200, 120", blue = "80, 140, 255", yellow = "250, 210, 80", orange = "255, 150, 60",
	purple = "160, 100, 255", pink = "255, 120, 190", white = "255, 255, 255", black = "20, 20, 20", cyan = "70, 220, 230" }

function NLP.slots(lower)
	local s = {}
	local d = lower:match("(%d*%.?%d+)%s*sec") or lower:match("(%d*%.?%d+)%s*s%f[%A]") or lower:match("for (%d*%.?%d+)")
	if d then s.duration = math.clamp(tonumber(d) or 0.3, 0.05, 10) end
	for k, v in pairs(EASING) do if lower:find(k, 1, true) then s.easing = v break end end
	if lower:find("inout", 1, true) or lower:find("in out", 1, true) or lower:find("in-out", 1, true) then s.direction = "InOut"
	elseif lower:find("ease in", 1, true) or lower:find("easein", 1, true) then s.direction = "In"
	elseif lower:find("ease out", 1, true) or lower:find("easeout", 1, true) then s.direction = "Out" end
	if lower:find("transparen") or lower:find("fade") then s.prop = "Transparency"
	elseif lower:find("rotat") or lower:find("spin") then s.prop = "Rotation"
	elseif lower:find("position") or lower:find("slide") or lower:find("move") then s.prop = "Position"
	elseif lower:find("size") or lower:find("grow") or lower:find("shrink") or lower:find("expand") then s.prop = "Size"
	elseif lower:find("colou?r") then s.prop = "Color" end
	for w, rgb in pairs(COLORS) do
		if lower:find("%f[%w]" .. w .. "%f[%W]") then s.color = rgb break end
	end
	return s
end

-- ===== statement parsing =====
local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

local function parseFix(raw, lower)
	for _, p in ipairs({ "^no[%s,%.!:]+", "^no$", "^actually[%s,:]+", "^that'?s wrong[%s,%.!:]*", "^that is wrong[%s,%.!:]*", "^wrong[%s,%.!:]*",
		"^incorrect[%s,%.!:]*", "^you'?re wrong[%s,%.!:]*", "^you are wrong[%s,%.!:]*", "^not right[%s,%.!:]*", "^that'?s not right[%s,%.!:]*",
		"^that'?s incorrect[%s,%.!:]*", "^that didn'?t work[%s,%.!:]*", "^wrong answer[%s,%.!:]*" }) do
		local s, e = lower:find(p)
		if s then
			local fix = trim(raw:sub(e + 1))
			if #fix < 6 then fix = nil end
			return fix, true
		end
	end
	return nil, false
end

local function parseTeach(raw, lower)
	local temp = (lower:find("for now", 1, true) or lower:find("this session", 1, true) or lower:find("this chat", 1, true)
		or lower:find("temporarily", 1, true) or lower:find("just for today", 1, true)) and true or false
	local personal, key, value
	local v = raw:match("^[Mm]y [Nn]ame [Ii]s (.+)") or raw:match("^[Cc]all [Mm]e (.+)")
	if v then return { key = "name", value = trim(v:gsub("[%.!]+$", "")), personal = true, temp = temp } end
	local k, v2 = raw:match("^[Mm]y ([%w ]-) [Ii]s (.+)")
	if k and #k <= 24 then return { key = k:lower(), value = trim(v2), personal = true, temp = temp } end
	local verb, rest = raw:match("^[Ii] (prefer) (.+)")
	if not verb then verb, rest = raw:match("^[Ii] (use) (.+)") end
	if not verb then verb, rest = raw:match("^[Ii] (like) (.+)") end
	if not verb then verb, rest = raw:match("^[Ii] (love) (.+)") end
	if not verb then verb, rest = raw:match("^[Ii] (work with) (.+)") end
	if verb then
		return { key = "i " .. verb .. " " .. trim(rest:lower():gsub("[%.!]+$", "")), value = "I " .. verb .. " " .. trim(rest), personal = true, temp = temp }
	end
	local rest2
	for _, p in ipairs({ "^[Rr]emember%s*[:,]?%s*(.+)", "^[Nn]ote that%s+(.+)", "^[Nn]ote%s*:%s*(.+)", "^[Ll]earn that%s+(.+)", "^[Ff][Yy][Ii]%s*[:,]?%s*(.+)", "^[Ss]ave this%s*[:,]?%s*(.+)" }) do
		rest2 = raw:match(p)
		if rest2 then break end
	end
	if rest2 then
		rest2 = trim(rest2:gsub("^[Tt]hat%s+", ""))
		personal = rest2:find("^[Ii]%s") ~= nil or rest2:find("^[Mm]y%s") ~= nil or rest2:find("^[Ii]'") ~= nil
		local t = NLP.terms(rest2:lower())
		key = #t > 0 and table.concat(t, " ", 1, math.min(6, #t)) or rest2:lower():sub(1, 30)
		return { key = key, value = rest2, personal = personal, temp = temp }
	end
	return nil
end

-- ===== intents =====
local function any(head, pats)
	for _, p in ipairs(pats) do if head:find(p) then return true end end
	return false
end

local GREET = set({ "hi", "hello", "hey", "yo", "sup", "hiya", "howdy", "greetings", "gm" })
local DEBUG_WORDS = { "error", "not working", "doesn't work", "doesnt work", "does not work", "isn't working", "isnt working", "broken", "bug",
	"attempt to", "nil value", "why is", "why does", "why isn", "why won", "fails", "failed", "crash", "freez", "lagg", "stuck",
	"nothing happens", "invalid member", "infinite yield", "falls apart", "falling apart", "flinging", "glitch", "jitter", "not showing" }

local IMPLIED = { "can't", "cant ", "won't", "wont ", "keeps ", "stopped ", "no longer", "isn't", "isnt ", "doesn't", "doesnt ", "didn't", "not loading", "not appearing" }

local function hasDebug(head)
	for _, w in ipairs(DEBUG_WORDS) do if head:find(w, 1, true) then return true end end
	if head:find("%f[%w]fix%f[%W]") then return true end
	if not (head:find("^how ") or head:find("^what ") or head:find("^why ") or head:find("^can you")) then
		for _, w in ipairs(IMPLIED) do if head:find(w, 1, true) then return true end end
	end
	return false
end

local function intentOf(head, tokens, terms)
	if any(head, { "^forget[%s:,]", "^delete .*memory", "^remove .* from memory", "^erase " }) then return "forget" end
	if any(head, { "^remember[%s:,]", "^note that", "^note:", "^learn that", "^fyi[%s:,]", "^save this", "^my name is", "^call me ",
		"^my favou?rite", "^my executor is", "^my main ", "^my device is", "^my username is" }) then return "teach" end
	if any(head, { "what do you remember", "what do you know about me", "do you remember", "what.*my name", "what have you learned",
		"what did i tell you", "what do you know about me" }) then return "memory_query" end
	if #tokens <= 4 and tokens[1] and (GREET[tokens[1]] or (tokens[1] == "good" and (tokens[2] == "morning" or tokens[2] == "afternoon" or tokens[2] == "evening"))) then
		return "greeting"
	end
	if #terms <= 3 and any(head, { "^thank", "^thx", "^ty[%s%p]*", "^tysm", "^nice[%s%p]", "^great[%s%p]", "^perfect", "^awesome", "^cool[%s%p]*$",
		"^that worked", "^it works", "^works now", "^it worked", "^got it", "^makes sense" }) then return "thanks" end
	if any(head, { "^bye", "^goodbye", "^see ya", "^cya", "^good night", "^gtg" }) then return "bye" end
	if any(head, { "who are you", "what are you", "your name", "are you an? ai", "are you an? llm", "are you real", "are you gpt", "are you chatgpt",
		"are you claude", "are you neural", "how do you work", "what model", "are you offline", "do you use .*internet", "are you online", "are you smart" }) then
		return "identity"
	end
	if any(head, { "what can you do", "^help[%s%p]*$", "^commands", "what can i ask", "^menu[%s%p]*$", "how do i use you", "your features" }) then return "capabilities" end
	if any(head, { "how are you", "what'?s up", "tell me a joke", "^joke", "you good" }) then return "smalltalk" end
	if not head:find("?", 1, true) and not hasDebug(head) and not head:find("%f[%w]but%f[%W]") then
		if any(head, { "^i prefer ", "^i use ", "^i like ", "^i love ", "^i work with " }) then return "teach" end
	end
	if hasDebug(head) then return "debug" end
	if any(head, { "^write ", "^make ", "^create ", "^build ", "^generate ", "^give me", "^show me", "^code ", "^script ", "example", "snippet",
		"sample", "template", "how do i make", "can you make", "can you write", "can you create", "i need a script", "i want a script" }) then
		return "code_request"
	end
	if any(head, { "difference between", "%f[%w]vs%f[%W]", "versus", "compare", "better than", "or should i" }) then return "compare" end
	if any(head, { "^how do", "^how can", "^how to", "^how would", "how do i", "how to", "ways to", "^can i ", "^is it possible" }) then return "howto" end
	if any(head, { "^what is", "^what are", "^what'?s", "^whats", "explain", "meaning of", "tell me about", "teach me", "^why ", "what does",
		"how does", "describe", "^define" }) then return "explain" end
	return "question"
end

-- short replies: yes/no to an offer, plain acknowledgements
local YES = set({ "yes", "yeah", "yep", "yup", "sure", "ok", "okay", "k", "please", "yes please", "go ahead", "do it", "sure thing", "ok sure", "okay sure",
	"show me", "please do", "y", "yea", "alright", "go on", "continue", "why not", "sounds good", "ok please", "okay please" })
local NO = set({ "no", "nope", "nah", "no thanks", "no thank you", "not now", "n", "nah im good", "im good", "nothing" })
local ACK = set({ "ok", "okay", "k", "kk", "alright", "aight", "yes", "yeah", "yep", "yup", "sure", "lol", "lmao", "haha", "hmm", "hmmm", "i see", "oh", "ah", "ohh",
	"wow", "interesting", "true", "fair", "fair enough", "right", "mhm", "noted", "ic", "oh ok", "oh okay", "ah ok", "ah okay", "i get it", "understood" })

local COMPLAIN = { "not what i asked", "not what i meant", "didn'?t answer", "did not answer", "doesn'?t help", "does not help", "not helpful", "unhelpful",
	"useless", "that'?s not it", "you misunderstood", "misunderstood", "you didn'?t understand", "off topic", "irrelevant", "that doesn'?t answer", "missed the point",
	"not even close", "that is not what" }

-- follow-up kinds: what the user wants done with the previous answer
local function followKindOf(head, bare, terms)
	if bare:find("^why$") or bare:find("^but why") or bare:find("^why so") or bare:find("^why tho") or bare:find("^how come") or bare:find("^why is (that|it|this)$")
		or bare:find("^why does (that|it|this)") or bare:find("^why do i need") or bare:find("^what for$") or bare:find("^why not$") then return "why" end
	if bare:find("^how$") or bare:find("^how so") or bare:find("^how exactly") or bare:find("^how do i do (that|it|this)") or bare:find("^how to do (that|it|this)")
		or bare:find("^and how") or bare:find("^how would i") and #terms == 0 then return "how" end
	if bare:find("what do you mean") or bare:find("don'?t understand") or bare:find("do not understand") or bare:find("confus") or bare:find("^huh") or bare:find("i'?m lost")
		or bare:find("^simpl") or bare:find("explain (it |that )?simpl") or bare:find("easier") or bare:find("eli5") then return "simplify" end
	if (head:find("better") or head:find("improv") or head:find("optimi[sz]") or head:find("cleaner") or head:find("polish") or head:find("upgrade") or head:find("fancier")
		or head:find("more advanced")) and #terms <= 4 then return "improve" end
	if bare:find("^example") or bare:find("^for example") or bare:find("^show me an? example") or bare:find("^can you show") or bare:find("^show it") or bare:find("^code$") then return "example" end
	if head:find("^what about") or head:find("^how about") or head:find("^and what") or head:find("^and how") or head:find("^and the") or head:find("^and for") then return "about" end
	if bare:find("^continue") or bare:find("^go on") or bare:find("^more$") or bare:find("^keep going") or bare:find("^tell me more") then return "more" end
	if bare:find("^again$") or bare:find("^try again") or bare:find("^retry") or bare:find("^redo") or bare:find("^another way") or bare:find("^something else") then return "retry" end
	return nil
end

-- message kind: question / instruction / opinion / correction / casual / statement
local function kindOf(a, head)
	local i = a.intent
	if i == "correction" then return "correction" end
	if i == "greeting" or i == "thanks" or i == "bye" or i == "smalltalk" or i == "ack" or i == "identity" or i == "capabilities" then return "casual" end
	if i == "teach" or i == "setting" or i == "forget" then return "instruction" end
	if head:find("?", 1, true) or head:find("^(what|why|how|when|where|which|who|is|are|does|do|did|should|would|could|can)%f[%W]") then return "question" end
	if head:find("^(write|make|create|build|give|show|fix|add|remove|change|convert|explain|tell|help|list|generate|update|rewrite|implement|please)%f[%W]") then return "instruction" end
	for _, p in ipairs({ "i think", "i feel", "imo", "i believe", "i don'?t like", "i hate", "i love", "i prefer", "sucks", "is better", "is worse", "is trash", "is mid", "is so ", "is really ", "pretty cool", "kinda " }) do
		if head:find(p) then return "opinion" end
	end
	if #a.terms <= 1 then return "casual" end
	return "statement"
end

local FOLLOW_INTENT = { question = true, howto = true, explain = true, debug = true, code_request = true, compare = true }

local ENT = set({ "r6", "r15", "motor6d", "humanoid", "cframe", "tweenservice", "metatable", "coroutine", "screengui", "uicorner", "humanoidrootpart" })

function NLP.analyze(text, ctx)
	text = tostring(text or "")
	if #text > 4000 then text = text:sub(1, 4000) end
	local raw = text
	local lower = raw:lower()
	local prev = ctx and ctx.prev
	local cv = NLP.conv and NLP.conv() or nil
	local sub = cv and cv.last
	-- the caller's "prev" is overwritten by every turn (even "ok"/"why?"); keep pointing at the last substantive answer
	if prev and sub and (#(prev.terms or {}) == 0 or #(prev.ids or {}) == 0) then
		prev = { topic = sub.topic or prev.topic, terms = (#(prev.terms or {}) > 0) and prev.terms or sub.terms, ids = (#(prev.ids or {}) > 0) and prev.ids or sub.ids, q = sub.q or prev.q }
	end
	local a = { raw = raw, text = lower, slots = {}, entities = {} }
	local bare = lower:gsub("[%s%p]+$", ""):gsub("^[%s%p]+", ""):gsub("%s+", " ")
	if #bare <= 24 and #bare > 0 then
		if cv and cv.offer and YES[bare] then a.tokens, a.terms, a.intent, a.slots.reply, a.kind = {}, {}, "ack", "yes", "casual"; a.topic, a.topicScore, a.slots.gen = prev and prev.topic, 0, {}; return a end
		if cv and cv.offer and NO[bare] then a.tokens, a.terms, a.intent, a.slots.reply, a.kind = {}, {}, "ack", "no", "casual"; a.topic, a.topicScore, a.slots.gen = prev and prev.topic, 0, {}; return a end
		if ACK[bare] then a.tokens, a.terms, a.intent, a.slots.reply, a.kind = {}, {}, "ack", "ok", "casual"; a.topic, a.topicScore, a.slots.gen = prev and prev.topic, 0, {}; return a end
	end
	a.tokens = NLP.tokens(lower)
	a.terms = NLP.terms(lower)
	a.hasCode, a.code = NLP.code(raw)

	-- corrections ("no, ...", "that's wrong ...")
	local fix, isFix = parseFix(raw, lower)
	if isFix then
		local fl = fix and fix:lower() or ""
		if fix and (fix:find("%?%s*$") or fl:find("^how ") or fl:find("^what ") or fl:find("^why ") or fl:find("^can ")) then
			return NLP.analyze(fix, ctx)
		end
		a.intent, a.slots.fix = "correction", fix
		a.topic = prev and prev.topic or nil
		return a
	end

	local head = lower:sub(1, 200)
	a.intent = intentOf(head, a.tokens, a.terms)

	-- explicit slots
	if a.intent == "teach" then a.slots.teach = parseTeach(raw, lower) end
	if a.intent == "forget" then a.slots.forget = trim(raw:gsub("^[Ff]orget[%s:,]*", ""):gsub("^[Dd]elete[^:]*:%s*", "")) end

	-- experience level / standing verbosity preference
	local lv
	if head:find("i'?m a beginner") or head:find("i am a beginner") or head:find("i'?m new to") or head:find("i am new to") or head:find("i'?m a noob")
		or head:find("i'?m just starting") or head:find("i'?m a newbie") then lv = "beginner"
	elseif head:find("i'?m advanced") or head:find("i am advanced") or head:find("i'?m experienced") or head:find("i am experienced") or head:find("i'?m a pro%f[%W]")
		or head:find("i know a lot") or head:find("i'?m an expert") then lv = "advanced" end
	if lv then a.slots.level = lv; a.level = lv end
	local standing = head:find("always") or head:find("from now on") or head:find("going forward") or head:find("i prefer")
	if standing then
		if head:find("concise") or head:find("short") or head:find("brief") then a.slots.verbosity = "short"
		elseif head:find("detail") or head:find("thorough") or head:find("in depth") or head:find("verbose") then a.slots.verbosity = "detailed" end
	end
	if (a.slots.level or a.slots.verbosity) and #a.terms <= 4 then a.intent = "setting" end

	-- one-shot modes
	if head:find("shorter") or head:find("simpler") or head:find("tldr") or head:find("tl;dr") or head:find("in short") or head:find("briefly") then a.mode = "short"
	elseif head:find("more detail") or head:find("elaborate") or head:find("explain more") or head:find("go deeper") or head:find("in depth") or head:find("in detail") then a.mode = "detail"
	elseif head:find("example") or head:find("show me code") or head:find("code for") or head:find("snippet") then a.mode = "code" end
	a.more = (head:find("^more") or head:find("again") or head:find("another") or head:find("elaborate") or head:find("simpler") or head:find("shorter")
		or head:find("explain that") or head:find("explain it") or head:find("what do you mean") or head:find("^example") or head:find("^show me") and #a.terms == 0) and true or false

	for _, t in ipairs(a.tokens) do if ENT[t] then a.entities[#a.entities + 1] = t end end
	a.wantsCode = a.intent == "code_request" or a.mode == "code" or head:find("example") ~= nil or head:find("snippet") ~= nil or head:find("script") ~= nil
	a.slots.gen = NLP.slots(lower)

	-- topic
	local topic, score = detectTopic(a.terms)
	a.topic, a.topicScore = topic, score

	for _, p in ipairs(COMPLAIN) do
		if head:find(p) then a.complaint = true break end
	end
	a.kind = kindOf(a, head)

	-- follow-up detection
	if prev and FOLLOW_INTENT[a.intent] then
		local pad = " " .. (lower:gsub("%p", " ")) .. " "
		local pron = pad:find(" it ", 1, true) or pad:find(" that ", 1, true) or pad:find(" this ", 1, true) or pad:find(" those ", 1, true) or pad:find(" them ", 1, true)
		local opener = head:find("^and ") or head:find("^what about") or head:find("^how about") or head:find("^also") or head:find("^then ") or head:find("^so ")
		if #a.terms <= 2 or ((pron or opener) and #a.terms <= 4) or a.more then
			a.follow = true
			a.ctxTerms = prev.terms
			if not a.topic or a.topicScore < 2 then a.topic = prev.topic or a.topic end
		end
	end
	local fk = followKindOf(head, bare, a.terms)
	if prev and (fk or a.complaint) and (FOLLOW_INTENT[a.intent] or a.complaint) then
		a.followKind = fk or "retry"
		a.follow, a.ctxTerms = true, prev.terms
		if a.followKind ~= "about" and a.followKind ~= "retry" then a.more = true end
		if a.intent == "debug" and (fk == "why" or fk == "how") then a.intent = "explain" end
		if a.complaint and not FOLLOW_INTENT[a.intent] then a.intent = "question" end
		if not a.topic or (a.topicScore or 0) < 2 then a.topic = prev.topic or a.topic end
	end
	return a
end

return NLP
