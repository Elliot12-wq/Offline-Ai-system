-- AI_Personality: voice, verbosity and adaptive tone. Friendly, patient, technically precise.
local Personality = {}

local ctx
local seq = 0

function Personality.init(c) ctx = c end

-- avoids lines used in the last few picks
local recentPick = {}
local function pick(t)
	seq = seq + 1
	local n = #t
	local start = (seq + math.random(0, 2)) % n
	local chosen
	for k = 0, n - 1 do
		local c = t[(start + k) % n + 1]
		local used = false
		for _, r in ipairs(recentPick) do if r == c then used = true break end end
		if not used then chosen = c break end
	end
	chosen = chosen or t[start + 1]
	recentPick[#recentPick + 1] = chosen
	if #recentPick > 5 then table.remove(recentPick, 1) end
	return chosen
end

local function cvs() return ctx.Memory.conv() end

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
	if a.followKind and a.followKind ~= "about" or a.retry then return "normal" end
	if a.hasCode or a.intent == "debug" or #a.terms >= 9 then return "detailed" end
	if #a.terms <= 3 and a.intent ~= "howto" and a.intent ~= "code_request" then return "short" end
	return "normal"
end

function Personality.greet(cv)
	cv = cv or cvs()
	if cv.n > 1 then
		local t = cv.last and cv.last.title
		return pick({ "Hey again" .. userName() .. ". " .. (t and ("Still on **" .. t .. "**, or something new?") or "What's next?"), "I'm here" .. userName() .. ". What do you need?" })
	end
	return pick({
		"Hey" .. userName() .. "! Ask me what any button in the script does, where to find it, or anything about reanimation, UI or Luau. Say `tour` for a map of the script.",
		"Hi" .. userName() .. "! Looking for a feature, stuck on a reanimate, or working on some Luau? I can also walk you through the script if you say `tour`.",
		"Hello" .. userName() .. "! Ask what a button does, paste an error or code, or just tell me what you want to do.",
	})
end

function Personality.thanks(cv)
	cv = cv or cvs()
	local t = cv.last and cv.last.title
	if t and cv.last.src ~= "none" then
		return pick({ "Glad that sorted out **" .. t .. "**. Send the next one whenever.", "Good. If **" .. t .. "** acts up again, paste the error.", "Anytime." })
	end
	return pick({ "Anytime.", "Happy to help. Send the next one whenever.", "Glad it helped." })
end

function Personality.bye(cv)
	return pick({ "See you. Your chats and what I've learned stay on this device.", "Bye for now. Good luck with the build.", "Later" .. userName() .. "." })
end

local JOKES = {
	"Why did the script go to therapy? It had too many unresolved `nil` issues.",
	"A Luau dev walks into a bar and orders 1 beer. Then 0 beers. Then nil beers. The bartender errors out.",
	"There are 10 kinds of devs: those who use `task.wait()` and those still using `wait()`.",
}

function Personality.smalltalk(text, cv)
	cv = cv or cvs()
	if text:find("joke", 1, true) then return pick(JOKES) end
	local t = cv.last and cv.last.title
	if t then return pick({ "Doing fine. Still on **" .. t .. "**, or something new?", "All good here. Want to keep going with **" .. t .. "**?" }) end
	return pick({ "Doing well. What are you working on?", "All good. What's the project today?" })
end

-- reply to "ok / hmm / lol" when there is nothing pending
function Personality.okay(cv)
	local l = cv.last
	if l and l.src == "diag" then return "Okay. Try it and tell me what happens; if it doesn't work, say `that didn't work` and I'll rule it out and move to the next cause." end
	return pick({ "Okay.", "Alright. Ask whenever you're ready.", "Sure." })
end

function Personality.declined(cv)
	return pick({ "Alright. What next?", "No problem. Anything else?" })
end

-- one natural follow-up, phrased by what it offers
function Personality.offer(kind, title)
	if kind == "code" then return pick({ "I can show the code for this if you want it.", "Want the code for this?" }) end
	if kind == "next" then return "Related, if you want it next: **" .. title .. "**. Say yes and I'll cover it." end
	if kind == "detail" then return "There's more detail on this; say yes for the rest." end
	return nil
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
- **This script**: what every button, toggle, dropdown and tab does and where it is (try `tour`, "what does Noclip do", "where is Server Hop", "what's in the Fling options", or just describe what you want like "walk through walls"), what Uh Admin commands do, what each reanimation option means, and why a reanimate fails
- Paste code and ask me to explain it or find problems.
- Follow-ups work: "why?", "how?", "make it better", "what about X", "simpler", "example". Say `that didn't work` during a diagnosis and I move to the next cause.

I learn locally: say `remember: ...` to teach me something, correct me with "no, ..." and I'll keep the fix. Commands: `/memory`, `/forget <id or topic>`, `/edit <id> <text>`, `/confirm <id>`, `/why`, `/gaps`, `/sync`, `/mind`, `/status`, `/neural on|off`, `/new`, `/reset confirm`.]]
end

function Personality.unknown(related, unmatched, cv)
	local s
	if unmatched and #unmatched > 0 then
		s = "I don't know anything about `" .. table.concat(unmatched, "`, `", 1, math.min(2, #unmatched)) .. "` yet."
	else
		s = pick({ "I don't have a good answer for that yet.", "That one is outside what I know right now." })
	end
	if related and #related > 0 then
		s = s .. " Closest things I know: " .. table.concat(related, ", ") .. "."
	end
	if cv and cv.last and cv.last.title then
		return s .. " If this is about **" .. cv.last.title .. "**, say what part and I'll narrow it down. Otherwise paste the code or error, or teach me with `remember: ...`."
	end
	return s .. " Paste the relevant code or error, rephrase, ask for a `tour` of the script, or teach me with `remember: ...`."
end

-- short connective at the start of an answer. Mostly nil: the answer itself comes first.
function Personality.lead(a, cv, o)
	o = o or {}
	local fk = a.followKind
	local l
	if o.retry then
		l = pick({ "That missed. Different angle:", "Let me come at it another way:" })
	elseif fk == "why" then l = pick({ "The reason:", "Why it works that way:" })
	elseif fk == "how" then l = "Here's how:"
	elseif fk == "simplify" then l = pick({ "In plainer terms:", "Simpler version:" })
	elseif fk == "improve" then l = "To take it further:"
	elseif fk == "example" then l = "Example:"
	elseif o.hedge then l = "Best match I have, though I'm not fully sure:"
	elseif a.intent == "debug" and not cv.debugged then cv.debugged = true; l = "Let's track it down."
	end
	if Personality.level(a) == "beginner" and not cv.beginner and a.intent ~= "ack" then
		cv.beginner = true
		l = "We'll take it step by step." .. (l and (" " .. l) or "")
	end
	return l
end

-- kept for compatibility: canned openers/closers are gone, replaced by lead()/offer()
function Personality.opener() return nil end
function Personality.closer() return nil end

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
