-- AI_Subtitles: JARVIS speaks in cinematic subtitles. No module dependencies.
--
-- What it does
--   * Turns any reply into subtitle "cues" (max ~74 characters, split at sentence / clause boundaries like real subs).
--   * Reveals each cue word by word at a natural speaking pace: the live word glows, the trail cools to white,
--     upcoming words show as faint ghosts. Punctuation gets real pauses.
--   * A small reactor orb sits beside the text: its ring spins faster while JARVIS talks and the core pulses on every word.
--   * Soft cinematic band + bottom vignette, a thin progress rail that drains toward the centre as each cue plays out.
--   * Code blocks are never read out: they become a [ code displayed in chat ] caption. Very long replies are capped.
--   * Alerts switch the whole HUD to amber.  Tap a caption = skip it, double tap = dismiss.
--   * Chat command: /subs on | off | slow | normal | fast | test   (saved between sessions when the executor has a filesystem)
--
-- Public API (all safe to call from anywhere; failures never reach the caller)
--   Subs.say(text, {tone = "info"|"alert", interrupt = true, wait = false, cap = true}) -> started
--   Subs.skip() / Subs.dismiss() / Subs.clear()
--   Subs.setEnabled(bool) / Subs.isEnabled() / Subs.isSpeaking() / Subs.setSpeed(n)
--   Subs.greet() / Subs.markGreeted()      Subs.command(text) -> reply or nil      Subs.destroy()
local Subs = {}

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local CFG = {
	Name = "J.A.R.V.I.S.",
	CPS = 17,            -- reading / speaking speed in characters per second
	MaxCueChars = 74,    -- a cue never exceeds this (it wraps to two lines at most on a normal screen)
	MinBreak = 24,       -- do not split a long sentence earlier than this
	MaxCues = 9,         -- per reply; the rest becomes "[ the rest is in the chat ]"
	MaxSeconds = 42,
	Gap = 0.4,           -- pause between cues
	EndHold = 1.15,      -- how long the last cue lingers
	GreetOnOpen = true,
	Cyan = Color3.fromRGB(104, 224, 255),
	Amber = Color3.fromRGB(255, 186, 96),
	Ink = Color3.fromRGB(236, 244, 250),
	Dim = Color3.fromRGB(120, 140, 156),
	Dir = "NoobyAI",
	File = "subtitles.json",
}
Subs.Config = CFG

local st = { on = true, speed = 1, alive = true, greeted = false, accent = CFG.Cyan }
local gui, ui, conns = nil, {}, {}
local queue, running, curItem, active = {}, false, nil, nil
local shown, hideToken, animUntil, skipFlag = false, 0, 0, false
local frameConn
local spin, spinTarget, rot = 40, 40, 0

-- ===== helpers =====
local function clamp(v, lo, hi) return v < lo and lo or (v > hi and hi or v) end

local function genv()
	local ok, g = pcall(function() return getgenv and getgenv() end)
	return (ok and type(g) == "table") and g or _G
end
local function fnv(name)
	local v = rawget(genv(), name)
	if type(v) ~= "function" then v = rawget(_G, name) end
	return type(v) == "function" and v or nil
end

local function hex(c)
	return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function mix(a, b, f)
	return string.format("#%02x%02x%02x",
		math.floor((a.R + (b.R - a.R) * f) * 255 + 0.5),
		math.floor((a.G + (b.G - a.G) * f) * 255 + 0.5),
		math.floor((a.B + (b.B - a.B) * f) * 255 + 0.5))
end
local function esc(s)
	return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function new(cls, props, parent)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end
local function tw(o, t, props, style, dir)
	local tween = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

-- ===== saved preferences =====
local function prefPath() return CFG.Dir .. "/" .. CFG.File end
local function loadPrefs()
	local rf, isf = fnv("readfile"), fnv("isfile")
	if not (rf and isf) then return end
	local ok, data = pcall(function()
		if isf(prefPath()) then return HttpService:JSONDecode(rf(prefPath())) end
	end)
	if ok and type(data) == "table" then
		if type(data.on) == "boolean" then st.on = data.on end
		local sp = tonumber(data.speed)
		if sp then st.speed = clamp(sp, 0.5, 2) end
	end
end
local function savePrefs()
	local wf, mf, isf = fnv("writefile"), fnv("makefolder"), fnv("isfolder")
	if not wf then return end
	pcall(function()
		if mf and isf and not isf(CFG.Dir) then mf(CFG.Dir) end
		wf(prefPath(), HttpService:JSONEncode({ on = st.on, speed = st.speed }))
	end)
end

-- ===== text -> cues =====
local ABBR = { ["e.g"] = true, ["i.e"] = true, vs = true, etc = true, dr = true, mr = true, mrs = true, ms = true, no = true, approx = true, ["a.k.a"] = true }

-- markdown / rich text / code fences -> a list of units ({text = "..."} or {code = true})
local function parseUnits(raw)
	local s = tostring(raw or ""):gsub("\r", "")
	s = s:gsub("```.-```", "\n\2\n")
	s = s:gsub("```.*$", "\n\2\n")
	s = s:gsub("</?%a[^>]*>", "")
	s = s:gsub("%[([^%]\n]+)%]%(([^%)\n]*)%)", "%1")
	s = s:gsub("https?://%S+", "a link")
	s = s:gsub("%*%*", ""):gsub("__", ""):gsub("`", "")
	local units = {}
	for line in (s .. "\n"):gmatch("(.-)\n") do
		line = line:gsub("^%s*#+%s*", ""):gsub("^%s*[%-%*]%s+", ""):gsub("^%s*\226\128\162%s*", ""):gsub("^%s*%d+[%.%)]%s+", "")
		line = line:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
		if line == "\2" then
			if not (units[#units] and units[#units].code) then units[#units + 1] = { code = true } end
		elseif line:find("%w") then
			units[#units + 1] = { text = line }
		end
	end
	return units
end

local function splitSentences(line)
	local out, from, i, n = {}, 1, 1, #line
	while i <= n do
		local c = line:sub(i, i)
		if c == "." or c == "!" or c == "?" then
			local j = i
			while line:sub(j + 1, j + 1):match("^[%.!%?\"'%)]$") do j = j + 1 end
			if line:sub(j + 1, j + 1) == " " then
				local after = line:sub(j + 2, j + 2)
				local word = line:sub(from, i - 1):match("([%w%.]+)$") or ""
				local abbr = c == "." and (ABBR[word:lower()] or (#word == 1 and word:match("%u") ~= nil))
				if not abbr and after:match("[%u%d\"'%(%[]") then
					out[#out + 1] = line:sub(from, j)
					from = j + 2
				end
			end
			i = j
		end
		i = i + 1
	end
	if from <= n then out[#out + 1] = line:sub(from) end
	return out
end

-- {pattern, characters kept on the left side, offset where the right side starts}
local PUNCT = { { ", ", 1, 2 }, { "; ", 1, 2 }, { ": ", 1, 2 }, { " \226\128\148 ", 0, 1 }, { " - ", 0, 1 } }
local CONJ = { { " and ", 0, 1 }, { " but ", 0, 1 }, { " or ", 0, 1 }, { " so ", 0, 1 }, { " because ", 0, 1 }, { " which ", 0, 1 }, { " while ", 0, 1 }, { " then ", 0, 1 } }

local function lastBreak(s, max, list)
	local best, bestRight
	for _, b in ipairs(list) do
		local init = 1
		while true do
			local a = s:find(b[1], init, true)
			if not a then break end
			local leftEnd = a + b[2] - 1
			if leftEnd >= CFG.MinBreak and leftEnd <= max and (not best or leftEnd > best) then best, bestRight = leftEnd, a + b[3] end
			init = a + 1
		end
	end
	return best, bestRight
end

local function breakLong(s, max)
	local out = {}
	while #s > max do
		local cut, right = lastBreak(s, max, PUNCT)
		if not cut then cut, right = lastBreak(s, max, CONJ) end
		if not cut then
			local sp
			for k = max, CFG.MinBreak, -1 do
				if s:sub(k, k) == " " then sp = k break end
			end
			if sp then cut, right = sp - 1, sp + 1 else cut, right = max, max + 1 end
		end
		out[#out + 1] = s:sub(1, cut)
		s = s:sub(right):gsub("^%s+", "")
	end
	if #s > 0 then out[#out + 1] = s end
	return out
end

-- greedy packing: short sentences from the same line share a cue
local function packCues(sentences, max)
	local cues, cur = {}, nil
	for _, snt in ipairs(sentences) do
		for _, p in ipairs(breakLong(snt, max)) do
			if cur and #cur + 1 + #p <= max then
				cur = cur .. " " .. p
			else
				if cur then cues[#cues + 1] = cur end
				cur = p
			end
		end
	end
	if cur then cues[#cues + 1] = cur end
	return cues
end

-- per-word timing: length based, with real pauses on punctuation
local function timeline(text, speed)
	local words, t = {}, 0
	speed = speed or 1
	for w in text:gmatch("%S+") do
		local core = w:gsub("[^%w]", "")
		local dur = math.max(0.15, (#core + 1) / CFG.CPS) / speed
		local pause = 0
		if w:sub(-3) == "..." then pause = 0.42
		elseif w:match("[%.!%?][\"'%)]*$") then pause = 0.34
		elseif w:match(":$") then pause = 0.24
		elseif w:match("[,;]$") then pause = 0.17 end
		pause = pause / speed
		words[#words + 1] = { w = w, t0 = t, dur = dur, len = #core }
		t = t + dur + pause
	end
	return words, t
end

local function cueSeconds(text) local _, total = timeline(text, st.speed) return total end

local function buildCues(text, cap)
	local cues = {}
	for _, u in ipairs(parseUnits(text)) do
		if u.code then
			if not (cues[#cues] and cues[#cues].note) then cues[#cues + 1] = { note = "code displayed in chat" } end
		else
			for _, c in ipairs(packCues(splitSentences(u.text), CFG.MaxCueChars)) do cues[#cues + 1] = { text = c } end
		end
	end
	if cap then
		local out, t = {}, 0
		for _, c in ipairs(cues) do
			local d = c.note and 1.2 or cueSeconds(c.text)
			if #out >= CFG.MaxCues or (#out > 0 and t + d > CFG.MaxSeconds) then
				out[#out + 1] = { note = "the rest is in the chat" }
				break
			end
			out[#out + 1] = c
			t = t + d + CFG.Gap
		end
		cues = out
	end
	return cues
end

-- RichText for one cue at time e: ghosts ahead, glowing live word, trail that cools from accent to white
local GHOST = hex(CFG.Dim)
local function renderCue(words, e, accent)
	local parts = {}
	for i, wd in ipairs(words) do
		local txt = esc(wd.w)
		if e < wd.t0 then
			parts[i] = '<font color="' .. GHOST .. '" transparency="0.88">' .. txt .. "</font>"
		else
			local nxt = words[i + 1]
			local fadeStart = nxt and nxt.t0 or (wd.t0 + wd.dur)
			local f = clamp((e - fadeStart) / 0.32, 0, 1)
			local age = e - wd.t0
			local tr = age < 0.12 and (1 - age / 0.12) * 0.75 or 0
			parts[i] = '<font color="' .. mix(accent, CFG.Ink, f) .. '"' .. (tr > 0.02 and string.format(' transparency="%.2f"', tr) or "") .. ">" .. txt .. "</font>"
		end
	end
	return table.concat(parts, " ")
end

local function detectTone(text)
	local l = tostring(text):lower()
	if l:find("^performance warning") or l:find("^memory warning") or l:find("^staff alert") or l:find("^initialization report") or l:find("^warning") or l:find("^alert") then
		return "alert"
	end
	return "info"
end

-- ===== gui =====
local function guiParent()
	local ok, h = pcall(function() return gethui and gethui() end)
	if ok and h then return h end
	local ok2, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok2 and cg then
		local probe = Instance.new("ScreenGui")
		local ok3 = pcall(function() probe.Parent = cg end)
		probe:Destroy()
		if ok3 then return cg end
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function viewport()
	local cam = workspace.CurrentCamera
	return cam and cam.ViewportSize or Vector2.new(800, 600)
end
local function width() return clamp(math.floor(viewport().X * 0.74), 300, 860) end
local function tsize() return clamp(math.floor(viewport().Y / 36), 15, 24) end
local function basePos() return UDim2.new(0.5, 0, UIS.TouchEnabled and 0.86 or 0.92, 0) end

local function layout()
	if not (gui and ui.root) then return end
	ui.root.Size = UDim2.fromOffset(width(), 0)
	ui.text.TextSize = tsize()
	if os.clock() > animUntil then ui.root.Position = basePos() end
end

local function fade(keys)
	return NumberSequence.new(keys)
end

local function applyAccent(c)
	st.accent = c
	if not gui then return end
	ui.s1.Color, ui.s2.Color, ui.s0.Color = c, c, c
	ui.core.BackgroundColor3, ui.glow.BackgroundColor3 = c, c
	ui.rail.BackgroundColor3, ui.fill.BackgroundColor3 = c, c
end

local function setTag(tone)
	local c = tone == "alert" and CFG.Amber or CFG.Cyan
	local label = tone == "alert" and "PRIORITY ALERT" or "ONLINE"
	ui.tag.Text = '<font color="' .. hex(c) .. '">' .. CFG.Name .. '</font><font color="' .. hex(CFG.Dim) .. '">  //  ' .. label .. "</font>"
	applyAccent(c)
end

local function pulse(strength)
	if not (gui and ui.core) then return end
	local s = 12 + math.floor(4 + clamp(strength, 0.2, 1) * 6)
	ui.core.Size = UDim2.fromOffset(s, s)
	tw(ui.core, 0.24, { Size = UDim2.fromOffset(12, 12) })
	ui.glow.BackgroundTransparency = 0.4
	tw(ui.glow, 0.34, { BackgroundTransparency = 0.82 })
end

local lastTap = 0
local function build()
	gui = new("ScreenGui", { Name = "JarvisSubtitles", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1100, ZIndexBehavior = Enum.ZIndexBehavior.Sibling })
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	gui.Parent = guiParent()

	-- bottom vignette so captions stay readable on bright scenes
	ui.scrim = new("Frame", { Name = "Vignette", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.34),
		BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false }, gui)
	new("UIGradient", { Rotation = 90, Transparency = fade({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.5) }) }, ui.scrim)

	ui.root = new("CanvasGroup", { Name = "Subtitle", AnchorPoint = Vector2.new(0.5, 1), Position = basePos(), Size = UDim2.fromOffset(width(), 0),
		AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, BorderSizePixel = 0, GroupTransparency = 1, Visible = false }, gui)

	-- soft band, fading out at both ends
	ui.band = new("Frame", { Name = "Band", Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Color3.fromRGB(4, 8, 14),
		BackgroundTransparency = 0.2, BorderSizePixel = 0 }, ui.root)
	new("UIGradient", { Transparency = fade({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.16, 0), NumberSequenceKeypoint.new(0.84, 0), NumberSequenceKeypoint.new(1, 1) }) }, ui.band)

	ui.col = new("Frame", { Name = "Text", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y }, ui.band)
	new("UIPadding", { PaddingLeft = UDim.new(0, 66), PaddingRight = UDim.new(0, 66), PaddingTop = UDim.new(0, 11), PaddingBottom = UDim.new(0, 16) }, ui.col)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, ui.col)
	ui.tag = new("TextLabel", { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 13), BackgroundTransparency = 1, RichText = true, Font = Enum.Font.Code, TextSize = 11,
		TextColor3 = CFG.Cyan, Text = "", TextXAlignment = Enum.TextXAlignment.Center }, ui.col)
	ui.text = new("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, RichText = true,
		TextWrapped = true, Font = Enum.Font.GothamMedium, TextSize = tsize(), LineHeight = 1.12, TextColor3 = CFG.Ink, TextStrokeTransparency = 1, Text = "",
		TextXAlignment = Enum.TextXAlignment.Center, TextYAlignment = Enum.TextYAlignment.Top }, ui.col)

	-- hairline on top, progress rail at the bottom (drains toward the centre while a cue plays)
	ui.rail = new("Frame", { Name = "Rail", Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = CFG.Cyan, BackgroundTransparency = 0.35, BorderSizePixel = 0 }, ui.band)
	new("UIGradient", { Transparency = fade({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }, ui.rail)
	local track = new("Frame", { Name = "Track", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 2), BackgroundTransparency = 1, BorderSizePixel = 0 }, ui.band)
	ui.fill = new("Frame", { Name = "Fill", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), BackgroundColor3 = CFG.Cyan,
		BackgroundTransparency = 0.3, BorderSizePixel = 0 }, track)
	new("UIGradient", { Transparency = fade({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.18, 0), NumberSequenceKeypoint.new(0.82, 0), NumberSequenceKeypoint.new(1, 1) }) }, ui.fill)

	-- reactor orb: faint outer ring, two counter-rotating comet arcs, pulsing core
	ui.orb = new("Frame", { Name = "Orb", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 20, 0.5, 2), Size = UDim2.fromOffset(34, 34), BackgroundTransparency = 1 }, ui.band)
	local function ring(scale, thickness, transparency)
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(scale, scale), BackgroundTransparency = 1 }, ui.orb)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
		return new("UIStroke", { Thickness = thickness, Color = CFG.Cyan, Transparency = transparency, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
	end
	ui.s0 = ring(1, 1, 0.8)
	ui.s1 = ring(1, 2, 0)
	ui.s2 = ring(0.68, 1, 0.1)
	local comet = fade({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.45, 0.15), NumberSequenceKeypoint.new(0.55, 1), NumberSequenceKeypoint.new(1, 1) })
	ui.g1 = new("UIGradient", { Transparency = comet }, ui.s1)
	ui.g2 = new("UIGradient", { Transparency = comet }, ui.s2)
	ui.glow = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(26, 26), BackgroundColor3 = CFG.Cyan,
		BackgroundTransparency = 0.82, BorderSizePixel = 0 }, ui.orb)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ui.glow)
	ui.core = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 12), BackgroundColor3 = CFG.Cyan, BorderSizePixel = 0 }, ui.orb)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ui.core)

	-- tap = skip this caption, double tap = dismiss everything
	ui.hit = new("TextButton", { Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 20 }, ui.band)
	ui.hit.MouseButton1Click:Connect(function()
		local now = os.clock()
		if now - lastTap < 0.4 then Subs.dismiss() else Subs.skip() end
		lastTap = now
	end)

	local cam = workspace.CurrentCamera
	if cam then conns[#conns + 1] = cam:GetPropertyChangedSignal("ViewportSize"):Connect(layout) end
	setTag("info")
end

local function ensureFrame()
	if frameConn then return end
	local acc = 0
	frameConn = RunService.Heartbeat:Connect(function(dt)
		if not ui.g1 then return end
		spin = spin + (spinTarget - spin) * clamp(dt * 4, 0, 1)
		rot = (rot + spin * dt) % 360
		ui.g1.Rotation = rot
		ui.g2.Rotation = -(rot * 0.7)
		local a = active
		if not a then return end
		acc = acc + dt
		local e = os.clock() - a.t0
		if a.words then
			local words, idx, changed = a.words, a.idx, false
			while idx < #words and e >= words[idx + 1].t0 do idx, changed = idx + 1, true end
			if changed then
				a.idx = idx
				pulse(words[idx].len / 8)
			end
			local last = words[#words]
			local animating = idx > 0 and e < last.t0 + last.dur + 0.5
			if changed or (animating and acc >= 0.033) then
				acc = 0
				ui.text.Text = renderCue(words, e, st.accent)
			end
		end
		ui.fill.Size = UDim2.fromScale(clamp(1 - e / a.span, 0, 1), 1)
	end)
end

local function showBand(tone)
	if not gui then build() end
	setTag(tone)
	hideToken = hideToken + 1
	ui.root.Visible, ui.scrim.Visible = true, true
	ensureFrame()
	if not shown then
		shown = true
		animUntil = os.clock() + 0.5
		local midFade = ui.root.GroupTransparency < 0.9 -- still visible from a previous line: glide back instead of popping
		if not midFade then
			ui.root.Position = basePos() + UDim2.fromOffset(0, 14)
			ui.root.GroupTransparency = 1
		end
		tw(ui.root, 0.3, { GroupTransparency = 0, Position = basePos() }, Enum.EasingStyle.Quint)
		tw(ui.scrim, 0.45, { BackgroundTransparency = 0 })
	end
end

local function hideBand()
	if not shown or not gui then return end
	shown = false
	hideToken = hideToken + 1
	local token = hideToken
	animUntil = os.clock() + 0.5
	tw(ui.root, 0.38, { GroupTransparency = 1, Position = basePos() + UDim2.fromOffset(0, 8) })
	tw(ui.scrim, 0.55, { BackgroundTransparency = 1 })
	task.delay(0.6, function()
		if hideToken == token and not shown and gui then
			ui.root.Visible, ui.scrim.Visible = false, false
			if frameConn then pcall(function() frameConn:Disconnect() end) frameConn = nil end
		end
	end)
end

-- ===== playback =====
local function playCue(item, cue, isLast)
	active = nil
	ui.text.TextTransparency = 0
	local total
	if cue.note then
		total = 1.3
		ui.text.Text = '<i><font color="' .. hex(CFG.Dim) .. '">' .. esc("[ " .. cue.note .. " ]") .. "</font></i>"
		active = { t0 = os.clock(), span = total + CFG.Gap, idx = 0 }
	else
		local words
		words, total = timeline(cue.text, st.speed)
		ui.text.Text = renderCue(words, -1, st.accent)
		active = { words = words, t0 = os.clock(), span = total + (isLast and CFG.EndHold or CFG.Gap), idx = 0 }
	end
	local endAt = active.t0 + active.span
	skipFlag = false
	while os.clock() < endAt and not skipFlag and not item.abort and st.on and st.alive do
		task.wait(0.03)
	end
	if not isLast and not item.abort and st.on and st.alive then
		tw(ui.text, 0.14, { TextTransparency = 1 })
		task.wait(0.15)
	end
	active = nil
end

local function runItem(item)
	curItem = item
	showBand(item.tone)
	spinTarget = 240
	for i, cue in ipairs(item.cues) do
		if item.abort or not st.on or not st.alive then break end
		playCue(item, cue, i == #item.cues)
	end
	spinTarget = 40
	curItem = nil
end

local function startRunner()
	if running then return end
	running = true
	task.spawn(function()
		while st.alive and #queue > 0 do
			local item = table.remove(queue, 1)
			local ok, err = pcall(runItem, item)
			if not ok then
				curItem = nil
				active = nil
				warn("[JARVIS subtitles] " .. tostring(err))
			end
			item.finished = true
		end
		running = false
		pcall(hideBand)
	end)
end

local function abortAll()
	for _, it in ipairs(queue) do it.finished = true end
	queue = {}
	if curItem then curItem.abort = true end
	skipFlag = true
end

-- ===== public =====
function Subs.say(text, opts)
	opts = opts or {}
	text = tostring(text or "")
	if not st.on or not st.alive or text:find("^%s*$") then return false end
	local cues = buildCues(text, opts.cap ~= false)
	if #cues == 0 then return false end
	local item = { cues = cues, tone = opts.tone or detectTone(text), finished = false, abort = false }
	if opts.interrupt ~= false then abortAll() end
	queue[#queue + 1] = item
	startRunner()
	if opts.wait then
		while not item.finished and st.alive do task.wait(0.1) end
	end
	return true
end

function Subs.skip() skipFlag = true end
function Subs.dismiss() abortAll() end
Subs.clear = abortAll
function Subs.isEnabled() return st.on and st.alive end
function Subs.isSpeaking() return curItem ~= nil end
function Subs.setEnabled(on)
	st.on = on and true or false
	savePrefs()
	if not st.on then abortAll() end
end
function Subs.setSpeed(n)
	st.speed = clamp(tonumber(n) or 1, 0.5, 2)
	savePrefs()
end

local GREETS = {
	"Good {period}, {name}. All systems are online.",
	"Welcome back, {name}. I have kept everything ready for you.",
	"{name}, good to see you. Diagnostics are clean and I am at your disposal.",
	"Good {period}, {name}. Whatever you have in mind, I am ready.",
	"Systems online. Shall we begin, {name}?",
	"At your service, {name}.",
}
function Subs.markGreeted() st.greeted = true end
function Subs.greet()
	if st.greeted or not CFG.GreetOnOpen or not st.on or not st.alive then return false end
	st.greeted = true
	local lp = Players.LocalPlayer
	local name = lp and ((lp.DisplayName ~= "" and lp.DisplayName) or lp.Name) or "friend"
	local h = tonumber(os.date("%H")) or 12
	local period = (h >= 5 and h < 12) and "morning" or (h >= 12 and h < 17) and "afternoon" or "evening"
	local line = GREETS[Random.new():NextInteger(1, #GREETS)]
	line = line:gsub("{period}", period):gsub("{name}", function() return name end)
	return Subs.say(line, { interrupt = false, cap = false })
end

-- chat command: returns the reply text, or nil when the text is not a subtitles command
function Subs.command(raw)
	local cmd, arg = tostring(raw or ""):match("^/(%a+)%s*(.-)%s*$")
	if not cmd then return nil end
	cmd = cmd:lower()
	if cmd ~= "subs" and cmd ~= "subtitles" and cmd ~= "subtitle" then return nil end
	arg = arg:lower()
	if arg == "off" or arg == "mute" then
		Subs.setEnabled(false)
		return "Subtitles off. I will keep my replies in the chat. `/subs on` brings my voice back."
	elseif arg == "on" then
		Subs.setEnabled(true)
		return "Subtitles are back on. Tap a caption to skip it, double tap to dismiss it."
	elseif arg == "slow" then
		Subs.setSpeed(0.75)
		return "Understood. I will speak a little slower."
	elseif arg == "fast" then
		Subs.setSpeed(1.35)
		return "Understood. Picking up the pace."
	elseif arg == "normal" then
		Subs.setSpeed(1)
		return "Back to my normal pace."
	elseif arg == "test" then
		return "This is how I will sound from now on. Short lines, clean timing, and a pulse from the reactor on every word. If you would like a different pace, try `/subs slow` or `/subs fast`."
	end
	return "Subtitles are " .. (st.on and "on" or "off") .. " at " .. (st.speed == 1 and "normal" or (st.speed < 1 and "slow" or "fast")) .. " speed. Options: `/subs on`, `/subs off`, `/subs slow`, `/subs normal`, `/subs fast`, `/subs test`."
end

function Subs.destroy()
	st.alive = false
	abortAll()
	if frameConn then pcall(function() frameConn:Disconnect() end) frameConn = nil end
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	conns = {}
	if gui then pcall(function() gui:Destroy() end) gui = nil end
	ui, shown, active, curItem = {}, false, nil, nil
end

-- exposed for testing the pure text logic
Subs._ = { parseUnits = parseUnits, splitSentences = splitSentences, breakLong = breakLong, packCues = packCues, timeline = timeline, buildCues = buildCues, renderCue = renderCue, detectTone = detectTone }

-- one live instance: a re-executed script replaces the old one and its gui
do
	local g = genv()
	local prev = rawget(g, "__JarvisSubtitles")
	if type(prev) == "table" and type(prev.destroy) == "function" then pcall(prev.destroy) end
	pcall(loadPrefs)
	pcall(function() g.__JarvisSubtitles = Subs end)
end

return Subs
