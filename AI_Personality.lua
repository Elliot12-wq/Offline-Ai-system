-- AI_Personality: voice, verbosity and adaptive tone. Friendly, patient, technically precise.
local Personality = {}

local ctx
local seq = 0

function Personality.init(c) ctx = c end

local function pick(t)
	seq = seq + 1
	return t[(seq + math.random(0, 2)) % #t + 1]
end

local function userName()
	local n = ctx.Memory.get("name")
	return n and (" " .. n) or ""
end

function Personality.level(a)
	return a.slots.level or ctx.Memory.pref("level")
end

function Personality.verbosity(a)
	if a.mode == "short" then return "short" end
	if a.mode == "detail" then return "detailed" end
	local pref = ctx.Memory.pref("verbosity")
	if pref == "short" or pref == "detailed" then return pref end
	if a.hasCode or a.intent == "debug" or #a.terms >= 9 then return "detailed" end
	if #a.terms <= 3 and a.intent ~= "howto" and a.intent ~= "code_request" then return "short" end
	return "normal"
end

function Personality.greet()
	return pick({
		"Hey" .. userName() .. "! I'm Nooby Neural AI. Ask me about UI, reanimation or Luau.",
		"Hi" .. userName() .. "! What are we building today: UI, reanimation, or some Luau?",
		"Hello" .. userName() .. "! Ready when you are. Paste code or just ask a question.",
	})
end

function Personality.thanks()
	return pick({ "Glad that helped! Send the next one whenever you're ready.", "Happy to help. If anything breaks, paste the error and I'll take a look.", "Anytime!" })
end

function Personality.bye()
	return pick({ "See you later! Your chats and what I've learned stay saved on this device.", "Bye for now. Good luck with the build!" })
end

function Personality.smalltalk(text)
	if text:find("joke", 1, true) then
		return pick({
			"Why did the script go to therapy? It had too many unresolved `nil` issues.",
			"A Luau dev walks into a bar and orders 1 beer. Then 0 beers. Then nil beers. The bartender errors out.",
		})
	end
	return "Doing well, thanks for asking! What are you working on?"
end

function Personality.identity(neural)
	local engine = "I combine local language processing, retrieval over a built-in Roblox knowledge base, and what you teach me."
	local state
	if neural and neural.state == "loaded" then
		state = "A compact neural classifier is loaded (" .. neural.params .. " parameters) and helps me classify your questions. It cannot generate text."
	else
		state = "No neural model is loaded. I'm not a large language model, so I won't pretend to be one."
	end
	return "I'm **Nooby Neural AI**, a fully offline Roblox development assistant for UI, reanimation and Luau. "
		.. engine .. " " .. state .. " Everything runs and is stored locally; nothing is sent anywhere."
end

function Personality.capabilities()
	return [[I can help with:
- **UI**: ScreenGui, Frames, buttons, themes, TweenService, layouts, optimization
- **Reanimation**: R6/R15, Motor6D, CFrame, physics, sync, troubleshooting
- **Luau**: variables, functions, tables, metatables, coroutines, debugging, modules
- **This script**: where any button, toggle or tab is, what Uh Admin commands do, what each reanimation option means, and why a reanimate fails
- Paste code and ask me to explain it or find problems.

I learn locally: say `remember: ...` to teach me something, correct me with "no, ..." and I'll keep the fix. Commands: `/memory`, `/forget <id or topic>`, `/edit <id> <text>`, `/confirm <id>`, `/why`, `/gaps`, `/sync`, `/mind`, `/status`, `/neural on|off`, `/new`, `/reset confirm`.]]
end

function Personality.unknown(related)
	local s = pick({
		"I don't have a good answer for that yet.",
		"That one is outside what I know right now.",
	})
	if related and #related > 0 then
		s = s .. " Closest things I know: " .. table.concat(related, ", ") .. "."
	end
	return s .. " Try rephrasing, paste the relevant code or error, or teach me with `remember: ...`."
end

function Personality.opener(intent, level, verbosity)
	if verbosity == "short" then return nil end
	local o = {
		howto = { "Here's how to do it:", "Good question. Here's the approach:" },
		code_request = { "Here's a starting point:", "Here's something you can build from:" },
		debug = { "Let's track this down.", "Okay, let's debug it." },
		explain = { "Quick explanation:", "Here's the idea:" },
		compare = { "Here's how they relate:" },
		question = { "Here's what I know:" },
	}
	local list = o[intent]
	if not list then return nil end
	local s = pick(list)
	if level == "beginner" then s = "No worries, we'll take it step by step. " .. s end
	return s
end

function Personality.closer(a, verbosity)
	if verbosity == "short" then return nil end
	seq = seq + 1
	if seq % 2 == 0 then return nil end
	local level = Personality.level(a)
	if level == "beginner" then return "If any part is confusing, tell me which one and I'll break it down." end
	if verbosity == "detailed" then return "Want a variation, or should I go deeper on a specific part?" end
	return nil
end

function Personality.ack(ev)
	local k = ev.kind
	if k == "taught" then
		local where = ev.personal and "your preferences" or "what you've taught me"
		local tmp = ev.temp and " (just for this session)" or ""
		if ev.status == "duplicate" then return "I already have that saved." end
		if ev.status == "updated" then return "Updated" .. tmp .. ". I'll use the new version." end
		if ev.status == "promoted" then return "Saved permanently." end
		if ev.status == "empty" then return "I need a bit more detail to remember that." end
		return "Got it" .. tmp .. ". Saved to " .. where .. ". I'll treat it as your information, not verified fact."
	elseif k == "teachhelp" then
		return "Tell me what to remember, for example: `remember: Motor6D joints live in the child part in R15`."
	elseif k == "forgot" then
		if not ev.key or ev.key == "" then return "Tell me what to forget, e.g. `forget my name`. To wipe everything use `/reset confirm`." end
		if ev.n > 0 then return "Forgot " .. ev.n .. " item" .. (ev.n > 1 and "s" or "") .. " matching that." end
		return "I couldn't find anything matching that."
	elseif k == "corrected" then
		if ev.status == "duplicate" then return "I already had that correction. Thanks for confirming." end
		return "Thanks for the correction. I saved it and will prefer it for similar questions."
	elseif k == "needfix" then
		return "Sorry about that. What should the right answer be? Send it and I'll remember it (or say `never mind`)."
	elseif k == "rejected" then
		return "I won't store that: " .. (ev.why or "it didn't pass my safety checks") .. ". I only learn useful facts, preferences and corrections."
	elseif k == "level" then
		return "Got it, I'll pitch explanations for a " .. ev.level .. " from now on."
	elseif k == "verbosity" then
		return ev.v == "short" and "Okay, I'll keep answers short." or "Okay, I'll give fuller explanations."
	elseif k == "nothing" then
		return "Nothing to correct yet. Ask me something first."
	end
	return "Done."
end

return Personality
