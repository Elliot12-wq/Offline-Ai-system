-- AI_Script: knowledge about the host script (UI map, Uh Admin commands, reanimation options) + live UI sync.
-- Static map comes from AI_Data (generated from the script, loaded lazily). The live scan compares it with the real GUI.
-- Never invents controls or commands: everything it states comes from AI_Data, ENTRIES (copied from the script's own help text) or the live GUI.
local Script = {}

local ctx, NLP
local DM, uiList, cmdList, cmdIdx
local host
local live = { t = -1e9, sig = -1, set = nil, btn = nil, extra = {}, missing = {}, ok = false }

local function nl(s)
	s = tostring(s or ""):gsub("<[^>]*>", ""):gsub("&lt;", "<"):gsub("&gt;", ">"):lower()
	s = s:gsub("[^%w%s]", " "):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
	return s
end

local TYPE = { B = "button", S = "toggle", L = "slider", D = "dropdown", T = "text box" }
local TRIG = { "where", "find", "button", "toggle", "switch", "slider", "dropdown", "option", "setting", "tab", "page", "menu", "navigate", "open", "enable",
	"disable", "turn on", "turn off", "click", "press", "tap", "go to", "how do i", "how to", "what does", "what is", "explain" }
local CMDW = { command = true, cmd = true, cmds = true, commands = true, prefix = true }
local IGN = { command = true, cmd = true, admin = true, uh = true, na = true, nameless = true, script = true, button = true, option = true, setting = true }

-- ===== verified script entries (text copied from / grounded in the script's own help strings) =====
local ENTRIES = {
	{ id = "sc_methods", title = "Reanimator methods (Main page)", tags = "reanimator reanimate method limb hats hat tool dropdown config start refresh hitboxes",
		text = "On the Main page the **Reanimator** dropdown picks the method: **Limb Reanimator**, **Hats Reanimator** or **Tool Reanimation**. The block under it ('-=+ <method> Config +=-') shows that method's settings. The **\\* Reanimate \\*** button starts it; **Refresh Reanimate Character** and **Show Reanimate Hitboxes** are just below. 'Reanimate Character Settings' (Infinite Jump, Noclip, Smooth Camera, First Person Body, Allow Shiftlock, Can Sit on Seats, Can Pickup Tools, Apply Scale to Gravity, Void Float) apply to the reanimated character." },
	{ id = "sc_limb", title = "Limb Reanimator settings", tags = "limb reanimator rootpart mode velocity init mode compatibility checker animator r6 r15",
		text = "Limb Reanimator only works in SOME games: modern games create the Animator automatically, which breaks limb reanimation (the script's own README note). Settings: **RootPart Mode**, **RootPart Velocity** (No Velocity / Follow Character / Fling-like), **Init Mode** (Reset Character / CDSB + Reset / CDSB + SSE + Kill), **Show me how I look!**, **Target Fling Enabled**. Spawn a character, then press **Check Limb Compatibility**: it checks game animations, voice chat players, dynamic faces, the game environment and R6/R15. **Dump Fake Character State** copies a debug dump to console + clipboard." },
	{ id = "sc_hats", title = "Hats Reanimator settings", tags = "hats hat reanimator permadeath collide torso offset ensure fling spin rebuild hat map respawn stuck timeout r15 tool holding",
		text = "Hats Reanimator settings: **Permadeath (dolteddown's pd)** (needs replicatesignal support from your executor), **Auto Force Respawn when stuck** + **Stuck timeout (seconds)** (if the reanimate never finishes with the pd, your character is force respawned after that long), **respawntp**, **Hat Collide**, **Torso Offset**, **Ensure All Hats**, **Ensure Hat Collide**, **Hat Fling**, **Hat Spin Fling**, **Target Fling Method**, **Tool Holding**, **toolanim Method**. If your hats get voided when you use Hat Collide, try changing **Torso Offset**. **Rebuild Hat Map** is for when your rig was built wrong or you switched to a new rig; **Force Respawn Now** respawns immediately. Method 11 (R15 hat reanim) is exclusively for R15 characters. Don't combine Hat Fling / Hat Spin Fling with target fling unless you want walkfling or look glitchy." },
	{ id = "sc_tool", title = "Tool Reanimation (Original vs Corpse Claim)", tags = "tool reanimation corpse claim claiming original tools handle collide permadeath replicatesignal freed grip",
		text = "Every Tool you own (up to 6) becomes one R6 body part: Torso, Head, Right Arm, Left Arm, Right Leg, Left Leg, in that order. **Tool Method**: *Original* equips the tools, breaks the real character's joints server-side and uses the freed handles (optional dolteddown's permadeath; needs replicatesignal). *Corpse Claim* arms every tool at once, then kills the real character so the server breaks all grips together; a dead humanoid cannot pick anything up, so each tool is moved into Workspace right away. A tool is only driven once the server has really freed it and you own it; unconfirmed drops are resent; the respawned character is parked alive and touch-disabled (replicatesignal is only an optional helper). With Permadeath on, the real character stays alive so the tools stay yours; off = tools are lost when the game respawns you. **Tool Collide** and **Target Fling Enabled** are also here; the biggest tool handle you really own is thrown at fling targets." },
	{ id = "sc_fling", title = "Fling options", tags = "fling method click fling alt fling target fling default weak nooby nan state kill walkfling served user alt flinger",
		text = "Fling style is chosen with the **Fling Method** dropdown on the Main page (Default / Weak / Nooby's / NaN State / Fling 1 / Fling 2 / Fling 3). **Click Fling** flings whoever you click. Alt-fling: pick the method, then click a target; **Alt-fling: resend command**, **Request Served User** and **View users I'm Alt Flinger for** manage alts (it waits for an admin whitelist whisper). **Toggle Kill**, **Ya kids tool kill option** and **Kill All** are in the same area. Don't use tool fling together with physics glue." },
	{ id = "sc_internals", title = "Internals Settings (physics reanimation)", tags = "internals settings hook loadanimation physics glue netless patchma velocity rotvelocity",
		text = "**Internals Settings** on the Main page are 'internals for physics based reanimation (like hat reanimator)': **Hook LoadAnimation**, **Use Physics Glue**, **Patchma-like Netless**, **Netless Velocity**, **Apply RotVelocity**." },
	{ id = "sc_perf", title = "Performance options", tags = "performance lag low end ui mode anti lag textures hide players monitor weak device fps fast particle",
		text = "For weak devices: **Low End UI Mode** (simpler 3D triangle, basic UI without effects; turn it off to get everything back), **Anti Lag (remove all textures)**, **Hide All Players**, **Fast Particle Effects**. In the Customization page you can also switch off Ambient Particles, Accent Sheen, Cursor Trail and Liquid Glass. **Performance Monitor** (Main page) shows live graphs." },
	{ id = "sc_triangle", title = "Command triangle and command bar", tags = "triangle command bar hide show showtri hidetri tab prefix open bar uh admin button drag",
		text = "The Uh Admin triangle is the floating launcher: **tap = commands, hold = hide**. Drag it anywhere (mouse or finger). After hiding, a small tab stays at the top edge: tap it, type `showtri`, or flip the switch in the Customization page. The command bar also opens with the prefix key (default `.`). **Reset Triangle Position** (Customization page) puts it back if it is off-screen." },
	{ id = "sc_prefix", title = "Uh Admin prefix and commands", tags = "prefix command commands cmds list nameless admin uh admin catalogue blocked punch plugin",
		text = "Uh Admin is the Nameless Admin integrated into the script. Default prefix is `.` (saved in Nameless-Admin/prefix.txt; change it with `prefix <new>`; empty, `p`, `P` and `[` are rejected). `cmds` / `commands` opens the command list. Uh Admin's own handlers win on any name clash with Nameless Admin's catalogue, and `punch` is blocked. Plugins: `.na` files go to Nameless-Admin/Plugins, `.iy` files to PluginsIY (`addplugin`, `addallplugins`, `reloadplugin`, `pluginmaker`)." },
	{ id = "sc_roles", title = "Admin whitelist, roles and permissions", tags = "admin unadmin whitelist role roles owner permission permissions moderation broadcast announcement",
		text = "`admin <player>` whitelists someone so they can use your commands (they get a whisper with the prefix and a starter list); `unadmin <player>` removes them. The Main page shows your **Role** under REMOTE MODERATION / LIVE PLAYERS; the **OWNER BROADCAST** section (send announcement) is only for the owner role. Roles shown as tags (e.g. OWNER) come from the script's remote role list; I can't change them." },
	{ id = "sc_modules", title = "Modules, movesets, dances and marketplace", tags = "modules moveset dances keybinds marketplace market download delete reload local user module loading",
		text = "**Movesets >**, **Dances >** and **Dance Keybinds >** open item lists (Use Moveset / Play Dance; the Dance Keybinds Enabled switch turns keybinds on). **Module Loading**, **Reload Modules** and **Reload User Modules** are in MODULES MANAGEMENT. The marketplace pages ('See what we have >' / 'See what you have >') download or delete user modules: reload your modules afterwards to apply them." },
	{ id = "sc_security", title = "Security options", tags = "security malware scan delete danger zone clear downloaded content",
		text = "**SECURITY**: **Background Malware Scan**, **Auto-Delete Malware (EXPERIMENTAL)**, **Scan Now**. DANGER ZONE: **CLEAR ALL DOWNLOADED CONTENT**." },
	{ id = "sc_serverhop", title = "Server hop and auto execute", tags = "server hop rejoin auto execute skip servers visited hop mode",
		text = "**Server Hop** section: **Hop Mode**, **Skip servers I visited (1h)**, **Auto Execute after hop / rejoin**, **Server Hop**, **Rejoin This Server**. Auto Execute runs this script again in the new server; it looks for its own file in your executor's workspace folder, so normally you set nothing. If it can't find it, type the file name or a raw https:// link (optional override)." },
	{ id = "sc_custom", title = "Customization page", tags = "customization customize theme palette font scale glass haptic intro delta triangle particles sheen cursor trail reset",
		text = "Main page > **Customization >**: **Preview Intro**, **Test Notification**, **UI Scale (zoom)**, **UI Font**, **Ambient Particles**, **Accent Sheen**, **Cursor Trail / Touch Ripples**, **Liquid Glass (iOS 27)** + **Glass clarity**, **Haptic Feedback**, **Reset Proportions** (limb/hat spacing), **Reset Triangle Position**, Delta cache stats/clear (when Delta is detected), **Reset All Customization**. Everything is saved and applies instantly." },
	{ id = "sc_ai", title = "Nooby Neural AI", tags = "nooby neural ai assistant chat memory offline",
		text = "**Nooby Neural AI >** on the Main page opens this assistant. It is fully offline; my memory and learned notes are stored on this device (`/memory` to inspect them)." },
}
local entTerms

-- ===== data =====
local function data()
	if DM == nil then
		local ok, m = pcall(function() return ctx.Load and ctx.Load("AI_Data") end)
		DM = (ok and type(m) == "table" and type(m.ui) == "string") and m or false
	end
	return DM
end

function Script.init(c) ctx, NLP = c, c.NLP end
function Script.title(id)
	for _, e in ipairs(ENTRIES) do if e.id == id then return e.title end end
	return id
end
function Script.ready() return data() and true or false end
function Script.build() local d = data() return d and d.build or "?" end
function Script.setHost(f) host = f; live.t = -1e9 end

local function loadUI()
	if uiList then return uiList end
	uiList = {}
	local d = data()
	if not d then return uiList end
	for line in d.ui:gmatch("[^\n]+") do
		local sec, ty, lab = line:match("^(.-)\31(.-)\31(.*)$")
		if sec then
			local name, path = sec:match("^(.-)|(.*)$")
			local it = { sec = name or sec, path = path or "Main page", ty = ty, lab = lab, n = nl(lab) }
			it.lt = NLP.terms(lab)
			uiList[#uiList + 1] = it
		end
	end
	return uiList
end

local function loadCmds()
	if cmdList then return end
	cmdList, cmdIdx = {}, {}
	local d = data()
	if not d then return end
	for line in d.cmds:gmatch("[^\n]+") do
		local name, al, usage, desc = line:match("^(.-)\31(.-)\31(.-)\31(.*)$")
		if name then
			local c = { n = name, al = al, u = usage, d = desc }
			cmdList[#cmdList + 1] = c
			cmdIdx[name] = c
			for x in al:gmatch("[^,]+") do if not cmdIdx[x] then cmdIdx[x] = c end end
		end
	end
end

function Script.stats()
	loadUI(); loadCmds()
	return { controls = #uiList, commands = cmdList and #cmdList or 0, build = Script.build() }
end

-- ===== live UI sync =====
function Script.sync(force)
	if not host then return live end
	local now = os.clock()
	if not force and live.set and now - live.t < 30 then return live end
	pcall(function()
		local gui = host:FindFirstAncestorOfClass("ScreenGui") or host
		local ds = gui:GetDescendants()
		if not force and live.set and #ds == live.sig then live.t = now return end
		local set, btn = {}, {}
		for i, o in ipairs(ds) do
			if i % 600 == 0 then task.wait() end
			if (o:IsA("TextButton") or o:IsA("TextLabel") or o:IsA("TextBox")) and not host:IsAncestorOf(o) then
				local nm = nl(o.Text)
				if #nm >= 3 and #nm <= 70 then
					set[nm] = true
					if o:IsA("TextButton") then btn[nm] = true end
				end
			end
		end
		local known, found, total = {}, 0, 0
		local missing = {}
		for _, it in ipairs(loadUI()) do
			known[it.n] = true
			total = total + 1
			if set[it.n] then found = found + 1 elseif #missing < 12 then missing[#missing + 1] = it end
		end
		local extra = {}
		for nm in pairs(btn) do
			if not known[nm] and #extra < 12 and not nm:find("%d%d") then extra[#extra + 1] = nm end
		end
		table.sort(extra)
		live.set, live.btn, live.sig, live.t = set, btn, #ds, now
		live.ok = total > 0 and found / total >= 0.25
		live.found, live.total = found, total
		live.extra, live.missing = extra, missing
	end)
	return live
end

function Script.syncReport()
	local l = Script.sync(true)
	if not l.set then return "I can't see the script's UI from here (the AI window isn't mounted inside it), so I'm using my built-in map of build " .. Script.build() .. "." end
	if not l.ok then return "The window I'm mounted in doesn't contain the main script UI, so I'm using my built-in map of build " .. Script.build() .. "." end
	local out = { string.format("Synced with the live UI: %d of %d mapped controls are currently present (map build %s).", l.found, l.total, Script.build()) }
	if #l.missing > 0 then
		local t = {}
		for i, it in ipairs(l.missing) do if i <= 8 then t[#t + 1] = it.lab end end
		out[#out + 1] = "Not visible right now (renamed, removed, or on a page that isn't built yet): " .. table.concat(t, ", ") .. "."
	end
	if #l.extra > 0 then
		out[#out + 1] = "Buttons in the live UI that my map doesn't list (could be new, or dynamic items like player/module names): " .. table.concat(l.extra, ", ", 1, math.min(8, #l.extra)) .. "."
	end
	return table.concat(out, "\n")
end

-- ===== search =====
local function qset(a)
	local q = {}
	for _, t in ipairs(a.terms) do q[t] = true end
	return q
end

function Script.findUI(a)
	local list, q = loadUI(), qset(a)
	local nq = " " .. nl(a.raw) .. " "
	local out = {}
	for _, it in ipairs(list) do
		local m = 0
		for _, t in ipairs(it.lt) do if q[t] then m = m + 1 end end
		local exact = #it.n >= 4 and nq:find(" " .. it.n .. " ", 1, true) ~= nil
		if m > 0 or exact then
			local cov = #it.lt > 0 and m / #it.lt or 0
			out[#out + 1] = { it = it, cov = cov, m = m, exact = exact, sc = m * cov + (exact and 3 or 0) }
		end
	end
	table.sort(out, function(x, y) return x.sc > y.sc end)
	return out
end

function Script.findCmd(a)
	loadCmds()
	if not cmdList then return {}, {} end
	local exact, seen = {}, {}
	for w in a.text:gmatch("[%w_]+") do
		local c = #w >= 3 and cmdIdx[w]
		if c and not seen[c] then seen[c] = true; exact[#exact + 1] = c end
	end
	local fuzzy = {}
	local want = {}
	for _, t in ipairs(a.terms) do if not IGN[t] then want[#want + 1] = t end end
	if #want > 0 then
		local scored = {}
		for _, c in ipairs(cmdList) do
			if not c.l then c.l = (c.n .. " " .. c.al .. " " .. c.d):lower() end
			local m = 0
			for _, t in ipairs(want) do if c.l:find(t, 1, true) then m = m + 1 end end
			if m > 0 and m / #want >= 0.6 and not seen[c] then scored[#scored + 1] = { c = c, m = m } end
		end
		table.sort(scored, function(x, y) return x.m > y.m end)
		for i = 1, math.min(5, #scored) do fuzzy[i] = scored[i].c end
	end
	return exact, fuzzy
end

function Script.findDocs(a)
	if not entTerms then
		entTerms = {}
		for _, e in ipairs(ENTRIES) do entTerms[e.id] = { t = NLP.terms(e.title .. " " .. e.tags), x = NLP.terms(e.text) } end
	end
	local q = qset(a)
	local out = {}
	for _, e in ipairs(ENTRIES) do
		local et, sc, m = entTerms[e.id], 0, 0
		for _, t in ipairs(et.t) do if q[t] then sc = sc + 2; m = m + 1 end end
		for _, t in ipairs(et.x) do if q[t] then sc = sc + 0.4 end end
		if m > 0 then out[#out + 1] = { e = e, sc = sc, m = m } end
	end
	table.sort(out, function(x, y) return x.sc > y.sc end)
	return out
end

local function fmtCmd(c)
	local u = (c.u ~= "" and c.u or c.n)
	local s = "`" .. u .. "`"
	if c.al ~= "" then s = s .. " (aliases: " .. c.al:gsub(",", ", ") .. ")" end
	return "- " .. s .. (c.d ~= "" and (": " .. c.d) or "")
end

local function fmtUI(h, l)
	local it = h.it
	local s = string.format("- **%s** (%s) in *%s*, reached via %s.", it.lab:gsub("%s*>%s*$", ""), TYPE[it.ty] or "control", it.sec, it.path)
	if l and l.ok and l.set and not l.set[it.n] then s = s .. " *(I can't see it in the live UI right now, so the script may have changed.)*" end
	return s
end

-- Returns { text, ids, strong } or nil. `kcov` = coverage of the best general-knowledge hit (0..1).
function Script.answer(a, kcov)
	if not data() then return nil end
	local lo = a.text
	local trig = false
	for _, w in ipairs(TRIG) do if lo:find(w, 1, true) then trig = true break end end
	local cmdWord = false
	for w in lo:gmatch("[%w]+") do if CMDW[w] then cmdWord = true break end end
	if lo:find("uh admin", 1, true) or lo:find("nameless", 1, true) then cmdWord = true end

	local out, strong, ids = {}, false, {}
	local docs = Script.findDocs(a)
	local ui = Script.findUI(a)
	local ex, fz = Script.findCmd(a)

	-- explicit commands (only when the question looks like a command question or the token is prefixed)
	local prefixed = lo:find("[%.;:]%a%a%a") ~= nil
	if #ex > 0 and (cmdWord or prefixed or (trig and #a.terms <= 4)) then
		local t = {}
		for i = 1, math.min(3, #ex) do t[#t + 1] = fmtCmd(ex[i]) end
		out[#out + 1] = "**Uh Admin commands** (type them in the command bar after your prefix, default `.`):\n" .. table.concat(t, "\n")
		strong = true
	elseif cmdWord and #fz > 0 then
		local t = {}
		for i = 1, math.min(4, #fz) do t[#t + 1] = fmtCmd(fz[i]) end
		out[#out + 1] = "Commands that look related:\n" .. table.concat(t, "\n")
		strong = true
	end

	if docs[1] and (docs[1].m >= 2 or docs[1].sc >= 4 or (docs[1].m >= 1 and #a.terms <= 3)) and (docs[1].sc >= 3) then
		out[#out + 1] = docs[1].e.text
		ids[#ids + 1] = docs[1].e.id
		strong = true
		if docs[2] and docs[2].sc >= docs[1].sc * 0.75 and docs[2].m >= 2 then out[#out + 1] = docs[2].e.text; ids[#ids + 1] = docs[2].e.id end
	end

	local top = ui[1]
	if top and ((top.exact) or (top.cov >= 0.6 and top.m >= 1 and (trig or top.m >= 2)) or (top.cov >= 0.5 and trig and top.m >= 2)) then
		local l = Script.sync(false)
		local t = {}
		for i = 1, math.min(3, #ui) do
			if ui[i].sc >= top.sc * 0.6 and (ui[i].exact or ui[i].cov >= 0.5) then t[#t + 1] = fmtUI(ui[i], l) end
		end
		if #t > 0 then out[#out + 1] = "**Where to find it:**\n" .. table.concat(t, "\n"); strong = true end
	end

	if #out == 0 then
		-- weak fallback so Generator can still point at something real
		if ui[1] and ui[1].sc >= 1 and (kcov or 0) < 0.34 then
			return { text = "Closest control I know in the script: " .. fmtUI(ui[1], Script.sync(false)):gsub("^%- ", ""), ids = {}, strong = false }
		end
		return nil
	end
	return { text = table.concat(out, "\n\n"), ids = ids, strong = strong }
end

return Script
