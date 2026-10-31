-- AI_UI: minimalist chat interface. No module dependencies; AI_Core injects the handlers.
-- Window, sidebar (chats), welcome screen, formatted messages with Lua highlighting + Copy, multiline composer.
local UI = {}

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local ctx, Config, H
local gui, win, uiscale, side, main, topbar, scroll, welcome, composer, box, sendBtn, sideList, scrim, menuBtn, titleLbl, statusRow, launcherBtn
local pill = {}
local conns, rendered = {}, {}
local geo = { compact = false, sideOpen = false, compH = 46, sideW = 230, mainW = 600, scrollW = 560 }
local busy, indicator, order, opened = false, nil, 0, false

local T = {
	bg = Color3.fromRGB(27, 27, 31), side = Color3.fromRGB(22, 22, 26), panel = Color3.fromRGB(36, 36, 42), user = Color3.fromRGB(48, 48, 58),
	line = Color3.fromRGB(54, 54, 64), text = Color3.fromRGB(232, 232, 238), sub = Color3.fromRGB(150, 150, 164), accent = Color3.fromRGB(139, 148, 255),
	code = Color3.fromRGB(18, 18, 22), codeText = Color3.fromRGB(214, 214, 224), good = Color3.fromRGB(110, 200, 140), warn = Color3.fromRGB(232, 182, 92),
	bad = Color3.fromRGB(232, 112, 112), inline = Color3.fromRGB(240, 190, 140),
}
local txtSize = UIS.TouchEnabled and 14 or 15

function UI.init(c) ctx, Config = c, c.Config end
-- embed mode: the window fills a host frame (main UI overlay or Delta tab) and can be moved between hosts
local host, hostConn
function UI.setHost(f)
	host = f
	if hostConn then hostConn:Disconnect() hostConn = nil end
	if win and f then
		win.Parent = f
		hostConn = f:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() if UI.relayout then UI.relayout() end end)
		if UI.relayout then UI.relayout() end
	end
end

-- ===== helpers =====
local function hex(c)
	return string.format("#%02x%02x%02x", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function new(cls, props, parent)
	local o = Instance.new(cls)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function round(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = o
	return c
end

local function stroke(o, col)
	local s = Instance.new("UIStroke")
	s.Color = col or T.line
	s.Thickness = 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
	return s
end

local function pad(o, l, t, r, b)
	local p = Instance.new("UIPadding")
	p.PaddingLeft, p.PaddingTop, p.PaddingRight, p.PaddingBottom = UDim.new(0, l), UDim.new(0, t), UDim.new(0, r), UDim.new(0, b)
	p.Parent = o
	return p
end

local function tw(o, t, props, style, dir)
	local tween = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

local function conn(sig, f)
	local c = sig:Connect(f)
	conns[#conns + 1] = c
	return c
end

local function trim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end

-- ===== text formatting =====
local function esc(s)
	return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local KW = {}
for _, w in ipairs({ "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or", "repeat", "return", "then", "true", "until", "while", "continue" }) do KW[w] = true end
local BI = {}
for _, w in ipairs({ "game", "workspace", "script", "print", "warn", "error", "pcall", "xpcall", "pairs", "ipairs", "require", "task", "table", "string", "math", "Instance",
	"Vector3", "Vector2", "CFrame", "Color3", "UDim2", "UDim", "Enum", "TweenInfo", "setmetatable", "getmetatable", "tostring", "tonumber", "typeof", "type", "select", "next",
	"coroutine", "os", "tick", "wait", "spawn", "delay", "loadstring", "assert", "debug" }) do BI[w] = true end

local COL = { kw = hex(Color3.fromRGB(197, 134, 240)), str = hex(Color3.fromRGB(152, 208, 120)), num = hex(Color3.fromRGB(240, 170, 110)),
	cm = hex(Color3.fromRGB(110, 118, 135)), bi = hex(Color3.fromRGB(110, 190, 245)), fn = hex(Color3.fromRGB(240, 220, 140)) }

local function highlight(code)
	local out, i, n = {}, 1, #code
	local function put(col, s) out[#out + 1] = '<font color="' .. col .. '">' .. esc(s) .. "</font>" end
	while i <= n do
		local c = code:sub(i, i)
		if code:sub(i, i + 1) == "--" then
			local eq = code:match("^%-%-%[(=*)%[", i)
			if eq then
				local _, e = code:find("]" .. eq .. "]", i, true)
				e = e or n
				put(COL.cm, code:sub(i, e))
				i = e + 1
			else
				local e = (code:find("\n", i, true) or (n + 1))
				put(COL.cm, code:sub(i, e - 1))
				i = e
			end
		elseif c == '"' or c == "'" or c == "`" then
			local j = i + 1
			while j <= n do
				local ch = code:sub(j, j)
				if ch == "\\" then j = j + 2
				elseif ch == c or ch == "\n" then break
				else j = j + 1 end
			end
			local e = (code:sub(j, j) == c) and j or (j - 1)
			if e > n then e = n end
			put(COL.str, code:sub(i, e))
			i = e + 1
		elseif c == "[" and code:match("^%[=*%[", i) then
			local eq = code:match("^%[(=*)%[", i)
			local _, e = code:find("]" .. eq .. "]", i, true)
			e = e or n
			put(COL.str, code:sub(i, e))
			i = e + 1
		elseif c:match("%d") then
			local num = code:match("^0[xX]%x+", i) or code:match("^%d+%.?%d*", i)
			put(COL.num, num)
			i = i + #num
		elseif c:match("[%a_]") then
			local id = code:match("^[%a_][%w_]*", i)
			if KW[id] then put(COL.kw, id)
			elseif BI[id] then put(COL.bi, id)
			elseif code:find("^%s*%(", i + #id) then put(COL.fn, id)
			else out[#out + 1] = esc(id) end
			i = i + #id
		else
			local run = code:match('^[^%a_%d"\'`%-%[]+', i)
			if not run then run = c end
			out[#out + 1] = esc(run)
			i = i + #run
		end
	end
	return table.concat(out)
end

local function fmt(s)
	s = esc(s)
	s = s:gsub("`([^`\n]+)`", '<font color="' .. hex(T.inline) .. '">%1</font>')
	s = s:gsub("%*%*([^\n]-)%*%*", "<b>%1</b>")
	s = s:gsub("\n%- ", "\n\226\128\162 "):gsub("^%- ", "\226\128\162 ")
	s = s:gsub("\n#+%s*([^\n]+)", "\n<b>%1</b>"):gsub("^#+%s*([^\n]+)", "<b>%1</b>")
	return s
end

local function parse(text)
	local segs, pos = {}, 1
	local function addText(v)
		v = v:gsub("^\n+", ""):gsub("\n+$", "")
		if v ~= "" then segs[#segs + 1] = { t = "text", v = v } end
	end
	while true do
		local s, e, lang, body = text:find("```(%w*)\n(.-)```", pos)
		if not s then break end
		addText(text:sub(pos, s - 1))
		segs[#segs + 1] = { t = "code", lang = (lang ~= "" and lang or "lua"), v = (body:gsub("\n+$", "")) }
		pos = e + 1
	end
	addText(text:sub(pos))
	return segs
end

-- ===== gui parent =====
local function guiParent()
	local c = Config.Caps
	if c.gethui then
		local ok, h = pcall(c.gethui)
		if ok and h then return h end
	end
	local ok, cg = pcall(function() return game:GetService("CoreGui") end)
	if ok and cg then
		local probe = Instance.new("ScreenGui")
		local ok2 = pcall(function() probe.Parent = cg end)
		probe:Destroy()
		if ok2 then return cg end
	end
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function ensureGui()
	if gui and gui.Parent then return gui end
	gui = Instance.new("ScreenGui")
	gui.Name = "NoobyNeuralAI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 1000
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	gui.Parent = guiParent()
	return gui
end

-- ===== messages =====
local function maxBubble() return math.max(140, math.floor(geo.scrollW * 0.82)) end

local function scrollBottom(instant)
	task.defer(function()
		task.wait(0.03)
		if not scroll or not scroll.Parent then return end
		local y = math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y)
		if instant then scroll.CanvasPosition = Vector2.new(0, y)
		else tw(scroll, 0.25, { CanvasPosition = Vector2.new(0, y) }) end
	end)
end

local function fadeIn(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			local t = d.TextTransparency
			d.TextTransparency = 1
			tw(d, 0.3, { TextTransparency = t })
			if d.BackgroundTransparency < 1 then
				local b = d.BackgroundTransparency
				d.BackgroundTransparency = 1
				tw(d, 0.3, { BackgroundTransparency = b })
			end
		elseif d:IsA("Frame") and d.BackgroundTransparency < 1 then
			local b = d.BackgroundTransparency
			d.BackgroundTransparency = 1
			tw(d, 0.3, { BackgroundTransparency = b })
		end
	end
end

local function trackMessage(frame, limit)
	rendered[#rendered + 1] = { f = frame, c = limit }
	local cap = math.max(8, math.min(Config.Limits.History, 40))
	while #rendered > cap do
		local r = table.remove(rendered, 1)
		r.f:Destroy()
	end
end

local function userMsg(text, anim)
	order = order + 1
	local w = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order }, scroll)
	local b = new("TextLabel", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundColor3 = T.user, TextColor3 = T.text, Font = Enum.Font.Gotham, TextSize = txtSize, TextWrapped = true, RichText = false,
		Text = text, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
	}, w)
	round(b, 12)
	pad(b, 14, 10, 14, 10)
	local lim = new("UISizeConstraint", { MaxSize = Vector2.new(maxBubble(), math.huge) }, b)
	trackMessage(w, lim)
	if anim then fadeIn(w) end
end

local function codeBlock(parent, seg, lo)
	local f = new("Frame", { LayoutOrder = lo, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = T.code }, parent)
	round(f, 8)
	stroke(f)
	new("TextLabel", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.5, 0, 0, 26), BackgroundTransparency = 1, Text = seg.lang, Font = Enum.Font.Gotham,
		TextSize = 11, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left }, f)
	local btn = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0, 13), Size = UDim2.fromOffset(78, 20), BackgroundColor3 = T.panel,
		Text = "Copy", Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = T.text, AutoButtonColor = true }, f)
	round(btn, 6)
	local body = new("TextLabel", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		Font = Enum.Font.Code, TextSize = 13, TextColor3 = T.codeText, TextWrapped = true, RichText = true, TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top, Text = highlight(seg.v) }, f)
	pad(body, 12, 0, 12, 12)
	local sel
	btn.MouseButton1Click:Connect(function()
		local clip = Config.Caps.clip
		if clip then
			btn.Text = (pcall(clip, seg.v)) and "Copied" or "Copy failed"
		else
			btn.Text = "Select & copy"
			if not sel then
				sel = new("TextBox", { Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
					Font = Enum.Font.Code, TextSize = 13, TextColor3 = T.codeText, TextWrapped = true, MultiLine = true, TextEditable = false, ClearTextOnFocus = false,
					TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = seg.v }, f)
				pad(sel, 12, 0, 12, 12)
				body.Visible = false
			end
		end
		task.delay(1.4, function() if btn.Parent then btn.Text = "Copy" end end)
	end)
end

local function aiMsg(text, anim)
	order = order + 1
	local w = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order }, scroll)
	local av = new("TextLabel", { Size = UDim2.fromOffset(26, 26), BackgroundColor3 = T.accent, Text = "N", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1) }, w)
	round(av, 13)
	local col = new("Frame", { Position = UDim2.fromOffset(38, 2), Size = UDim2.new(1, -38, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1 }, w)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, col)
	for i, s in ipairs(parse(text)) do
		if s.t == "text" then
			new("TextLabel", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextColor3 = T.text,
				Font = Enum.Font.Gotham, TextSize = txtSize, TextWrapped = true, RichText = true, TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top, LineHeight = 1.15, Text = fmt(s.v) }, col)
		else
			codeBlock(col, s, i)
		end
	end
	trackMessage(w, nil)
	if anim then fadeIn(w) end
end

local function showIndicator()
	if indicator then return end
	order = order + 1
	local w = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28), LayoutOrder = order }, scroll)
	local av = new("TextLabel", { Size = UDim2.fromOffset(26, 26), BackgroundColor3 = T.accent, Text = "N", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = Color3.new(1, 1, 1) }, w)
	round(av, 13)
	local l = new("TextLabel", { Position = UDim2.fromOffset(38, 4), Size = UDim2.fromOffset(160, 20), BackgroundTransparency = 1, Text = "Thinking\226\128\166", Font = Enum.Font.Gotham,
		TextSize = 14, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left }, w)
	local t = TweenService:Create(l, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { TextTransparency = 0.7 })
	t:Play()
	indicator = { f = w, t = t }
	scrollBottom()
end

local function hideIndicator()
	if indicator then
		indicator.t:Cancel()
		indicator.f:Destroy()
		indicator = nil
	end
end

-- ===== status pills =====
local function mkPill(parent, lo)
	local f = new("Frame", { LayoutOrder = lo, Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = T.panel }, parent)
	round(f, 12)
	stroke(f)
	new("UISizeConstraint", { MinSize = Vector2.new(24, 24) }, f)
	local dot = new("Frame", { Size = UDim2.fromOffset(7, 7), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 9, 0.5, 0), BackgroundColor3 = T.good }, f)
	round(dot, 4)
	local l = new("TextLabel", { Position = UDim2.fromOffset(22, 0), Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1,
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub, Text = "" }, f)
	pad(l, 0, 0, 10, 0)
	return { f = f, dot = dot, l = l }
end

function UI.refreshStatus()
	if not win or not H then return end
	local s = H.status()
	pill.net.l.Text = busy and "Thinking" or "Offline \194\183 local"
	pill.net.dot.BackgroundColor3 = busy and T.accent or T.good
	pill.mem.l.Text = s.persist and (s.convos .. " chats \194\183 " .. (s.facts + s.learned) .. " memories") or "session memory only"
	pill.mem.dot.BackgroundColor3 = s.pressure >= 2 and T.bad or ((s.pressure == 1 or not s.persist) and T.warn or T.good)
	pill.neu.l.Text = s.neural == "loaded" and "Neural classifier" or "Local NLP"
	pill.neu.dot.BackgroundColor3 = s.neural == "loaded" and T.accent or T.sub
end

-- ===== sidebar =====
local function setSide(open)
	geo.sideOpen = open
	if geo.compact then
		tw(side, 0.2, { Position = UDim2.fromOffset(open and 0 or -(geo.sideW + 2), 0) })
		scrim.Visible = open
	end
end

local refreshSidebar

local function renderMessages(msgs)
	hideIndicator()
	for _, r in ipairs(rendered) do r.f:Destroy() end
	rendered = {}
	if not msgs or #msgs == 0 then
		welcome.Visible = true
		return
	end
	welcome.Visible = false
	local cap = math.max(8, math.min(Config.Limits.History, 40))
	for i = math.max(1, #msgs - cap + 1), #msgs do
		local m = msgs[i]
		if m.r == "u" then userMsg(m.x, false) else aiMsg(m.x, false) end
	end
	scrollBottom(true)
end

local function openConvo(id)
	local msgs = H.open(id)
	renderMessages(msgs)
	refreshSidebar()
	setSide(false)
end

local function deleteConvo(id)
	local wasCurrent = H.delete(id)
	if wasCurrent then renderMessages({}) end
	refreshSidebar()
	UI.refreshStatus()
end

function refreshSidebar()
	if not sideList then return end
	for _, c in ipairs(sideList:GetChildren()) do
		if c:IsA("Frame") then c:Destroy() end
	end
	local list, cur = H.list()
	for i, c in ipairs(list) do
		local active = c.id == cur
		local row = new("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.user, BackgroundTransparency = active and 0 or 1 }, sideList)
		round(row, 8)
		local tb = new("TextButton", { Size = UDim2.new(1, -34, 1, 0), BackgroundTransparency = 1, Text = c.title, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = T.text,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, AutoButtonColor = false }, row)
		pad(tb, 10, 0, 4, 0)
		local del = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -4, 0.5, 0), Size = UDim2.fromOffset(26, 26), BackgroundTransparency = 1,
			Text = "\195\151", TextSize = 18, Font = Enum.Font.GothamMedium, TextColor3 = T.sub }, row)
		tb.MouseButton1Click:Connect(function() openConvo(c.id) end)
		local armed = false
		del.MouseButton1Click:Connect(function()
			if not armed then
				armed = true
				del.Text, del.TextColor3 = "?", T.bad
				task.delay(2, function()
					if del.Parent and armed then armed = false; del.Text, del.TextColor3 = "\195\151", T.sub end
				end)
			else
				deleteConvo(c.id)
			end
		end)
	end
end

local function newChat()
	renderMessages(H.new())
	refreshSidebar()
	UI.refreshStatus()
	setSide(false)
end

-- ===== sending =====
local function setSendEnabled(on)
	if not sendBtn then return end
	sendBtn.BackgroundColor3 = on and T.accent or T.user
	sendBtn.Active = on
end

local function submit(text)
	text = trim(text or "")
	if text == "" or busy or not H then return end
	busy = true
	setSendEnabled(false)
	welcome.Visible = false
	userMsg(text, true)
	showIndicator()
	UI.refreshStatus()
	H.ask(text, function(res)
		busy = false
		hideIndicator()
		if res.render then renderMessages(res.render) end
		if res.text and res.text ~= "" then aiMsg(res.text, true) end
		setSendEnabled(true)
		if win then
			refreshSidebar()
			UI.refreshStatus()
			scrollBottom()
		end
	end)
end

-- ===== layout =====
local function setCompH(h)
	geo.compH = h
	composer.Size = UDim2.new(1, -28, 0, h)
	local sz = UDim2.new(1, 0, 1, -(46 + h + 24))
	scroll.Size = sz
	welcome.Size = sz
end

local function layout()
	if not win then return end
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(800, 600)
	local W = math.clamp(vp.X - 20, 300, 900)
	local Hh = math.clamp(vp.Y - 20, 320, 620)
	if host then local hs = host.AbsoluteSize; W, Hh = math.max(280, hs.X), math.max(260, hs.Y) end
	if UI._close then local cl = host == nil or host:GetAttribute("AIClose") == true; UI._close.Visible = cl; if statusRow then statusRow.Position = UDim2.new(1, cl and -44 or -12, 0.5, 0) end end
	geo.compact = W < 640
	geo.sideW = geo.compact and math.min(250, math.floor(W * 0.78)) or 230
	local mainX = geo.compact and 0 or geo.sideW
	geo.mainW = W - mainX
	geo.scrollW = geo.mainW - 28
	if not host then win.Size = UDim2.fromOffset(W, Hh) end
	side.Size = UDim2.new(0, geo.sideW, 1, 0)
	side.Position = UDim2.fromOffset(geo.compact and (geo.sideOpen and 0 or -(geo.sideW + 2)) or 0, 0)
	side.ZIndex = geo.compact and 20 or 1
	main.Position = UDim2.fromOffset(mainX, 0)
	main.Size = UDim2.new(1, -mainX, 1, 0)
	scrim.Visible = geo.compact and geo.sideOpen
	menuBtn.Visible = geo.compact
	titleLbl.Position = UDim2.fromOffset(geo.compact and 50 or 18, 0)
	pill.mem.f.Visible = not geo.compact
	pill.neu.f.Visible = not geo.compact
	pill.net.l.Visible = W >= 420
	for _, r in ipairs(rendered) do
		if r.c then r.c.MaxSize = Vector2.new(maxBubble(), math.huge) end
	end
end

UI.relayout = layout

-- ===== build =====
local function build()
	if not host then ensureGui() end
	win = new("Frame", { Name = "Window", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(820, 560),
		BackgroundColor3 = T.bg, ClipsDescendants = true }, host or gui)
	if host then win.AnchorPoint, win.Position, win.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(1, 1) end
	round(win, 14)
	stroke(win)
	uiscale = new("UIScale", { Scale = 0.94 }, win)

	-- sidebar
	side = new("Frame", { Name = "Sidebar", BackgroundColor3 = T.side, Size = UDim2.new(0, 230, 1, 0), BorderSizePixel = 0 }, win)
	new("TextLabel", { Position = UDim2.fromOffset(16, 14), Size = UDim2.new(1, -32, 0, 22), BackgroundTransparency = 1, Text = "Nooby Neural AI", Font = Enum.Font.GothamBold,
		TextSize = 15, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left }, side)
	local nb = new("TextButton", { Position = UDim2.fromOffset(12, 46), Size = UDim2.new(1, -24, 0, 36), BackgroundColor3 = T.panel, Text = "+  New chat", Font = Enum.Font.GothamMedium,
		TextSize = 13, TextColor3 = T.text }, side)
	round(nb, 8)
	stroke(nb)
	nb.MouseButton1Click:Connect(newChat)
	sideList = new("ScrollingFrame", { Position = UDim2.fromOffset(8, 92), Size = UDim2.new(1, -16, 1, -128), BackgroundTransparency = 1, ScrollBarThickness = 3,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), BorderSizePixel = 0 }, side)
	new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sideList)
	new("TextLabel", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 16, 1, -10), Size = UDim2.new(1, -32, 0, 16), BackgroundTransparency = 1,
		Text = "Offline \194\183 stored on this device", Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = T.sub, TextXAlignment = Enum.TextXAlignment.Left }, side)

	-- main
	main = new("Frame", { Name = "Main", BackgroundTransparency = 1, ClipsDescendants = true, Size = UDim2.new(1, -230, 1, 0), Position = UDim2.fromOffset(230, 0) }, win)
	topbar = new("Frame", { Size = UDim2.new(1, 0, 0, 46), BackgroundTransparency = 1, Active = true }, main)
	new("Frame", { Position = UDim2.new(0, 0, 1, -1), Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.line, BorderSizePixel = 0 }, topbar)
	menuBtn = new("TextButton", { Position = UDim2.fromOffset(8, 5), Size = UDim2.fromOffset(36, 36), BackgroundTransparency = 1, Text = "", Visible = false }, topbar)
	for i = 0, 2 do
		new("Frame", { Position = UDim2.fromOffset(10, 11 + i * 6), Size = UDim2.fromOffset(16, 2), BackgroundColor3 = T.text, BorderSizePixel = 0 }, menuBtn)
	end
	menuBtn.MouseButton1Click:Connect(function() setSide(not geo.sideOpen) end)
	titleLbl = new("TextLabel", { Position = UDim2.fromOffset(18, 0), Size = UDim2.fromOffset(150, 46), BackgroundTransparency = 1, Text = "Nooby Neural AI", Font = Enum.Font.GothamMedium,
		TextSize = 15, TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left }, topbar)
	local closeBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(30, 30), BackgroundTransparency = 1,
		Text = "\195\151", TextSize = 22, Font = Enum.Font.GothamMedium, TextColor3 = T.sub }, topbar)
	UI._close = closeBtn
	closeBtn.MouseButton1Click:Connect(function() if H then H.close() end end)
	statusRow = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -44, 0.5, 0), Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1 }, topbar)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, statusRow)
	pill.neu = mkPill(statusRow, 1)
	pill.mem = mkPill(statusRow, 2)
	pill.net = mkPill(statusRow, 3)

	-- messages
	scroll = new("ScrollingFrame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -116), BackgroundTransparency = 1, ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), BorderSizePixel = 0, ScrollBarImageColor3 = T.line }, main)
	new("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
	pad(scroll, 14, 14, 14, 14)

	-- welcome
	welcome = new("Frame", { Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 1, -116), BackgroundTransparency = 1 }, main)
	local wc = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, -40, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1 }, welcome)
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, wc)
	local logo = new("TextLabel", { LayoutOrder = 1, Size = UDim2.fromOffset(48, 48), BackgroundColor3 = T.accent, Text = "N", Font = Enum.Font.GothamBold, TextSize = 24,
		TextColor3 = Color3.new(1, 1, 1) }, wc)
	round(logo, 24)
	new("TextLabel", { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "Nooby Neural AI", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = T.text }, wc)
	new("TextLabel", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, TextWrapped = true,
		Text = "Offline Roblox dev assistant for UI, reanimation and Luau.\nEverything stays on this device.", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = T.sub }, wc)
	local chips = { "How do I tween a frame's size?", "R6 vs R15 joints", "Explain metatables with an example" }
	for i, p in ipairs(chips) do
		local ch = new("TextButton", { LayoutOrder = 3 + i, Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.panel, Text = p, Font = Enum.Font.Gotham, TextSize = 13,
			TextColor3 = T.text }, wc)
		round(ch, 10)
		stroke(ch)
		new("UISizeConstraint", { MaxSize = Vector2.new(360, 34) }, ch)
		ch.MouseButton1Click:Connect(function() submit(p) end)
	end

	-- composer
	composer = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 14, 1, -12), Size = UDim2.new(1, -28, 0, 46), BackgroundColor3 = T.panel }, main)
	round(composer, 14)
	stroke(composer)
	box = new("TextBox", { Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -86, 1, 0), BackgroundTransparency = 1, MultiLine = true, TextWrapped = true,
		ClearTextOnFocus = false, PlaceholderText = "Message Nooby Neural AI\226\128\166", PlaceholderColor3 = T.sub, TextColor3 = T.text, Font = Enum.Font.Gotham,
		TextSize = txtSize, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Text = "" }, composer)
	pad(box, 0, 13, 0, 8)
	sendBtn = new("TextButton", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -7), Size = UDim2.fromOffset(58, 32), BackgroundColor3 = T.accent, Text = "Send",
		Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = Color3.new(1, 1, 1) }, composer)
	round(sendBtn, 10)

	local last = ""
	box:GetPropertyChangedSignal("Text"):Connect(function()
		local t = box.Text
		local shift = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
		local touchOnly = UIS.TouchEnabled and not UIS.KeyboardEnabled
		if not shift and not touchOnly and #t == #last + 1 and t:sub(-1) == "\n" and t:sub(1, -2) == last then
			box.Text = last
			submit(last)
			return
		end
		last = t
		setCompH(math.clamp(box.TextBounds.Y + 22, 46, 150))
	end)
	box:GetPropertyChangedSignal("TextBounds"):Connect(function()
		setCompH(math.clamp(box.TextBounds.Y + 22, 46, 150))
	end)
	sendBtn.MouseButton1Click:Connect(function()
		local t = box.Text
		box.Text = ""
		last = ""
		submit(t)
	end)

	-- scrim for compact sidebar
	scrim = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.55, Text = "", AutoButtonColor = false,
		Visible = false, ZIndex = 10 }, main)
	scrim.MouseButton1Click:Connect(function() setSide(false) end)

	-- drag by top bar
	local dragging, dragStart, startPos
	conn(topbar.InputBegan, function(i)
		if host then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, dragStart, startPos = true, i.Position, win.Position
			local c
			c = i.Changed:Connect(function()
				if i.UserInputState == Enum.UserInputState.End then dragging = false; c:Disconnect() end
			end)
		end
	end)
	conn(UIS.InputChanged, function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragStart
			win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	local cam = workspace.CurrentCamera
	if cam then conn(cam:GetPropertyChangedSignal("ViewportSize"), layout) end
	if host then hostConn = host:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout) end

	layout()
	setCompH(46)
	setSendEnabled(true)
end

-- ===== public API =====
function UI.show(handlers)
	H = handlers
	if not win then build() end
	win.Visible = true
	layout()
	uiscale.Scale = 0.94
	tw(uiscale, 0.18, { Scale = 1 }, Enum.EasingStyle.Back)
	refreshSidebar()
	UI.refreshStatus()
	opened = true
	if not UIS.TouchEnabled then task.defer(function() if box and box.Parent then box:CaptureFocus() end end) end
end

function UI.hide()
	if not win then return end
	opened = false
	local t = tw(uiscale, 0.14, { Scale = 0.94 })
	t.Completed:Once(function() if win and not opened then win.Visible = false end end)
end

function UI.isOpen() return win ~= nil and opened end

function UI.render(msgs)
	if not win then return end
	renderMessages(msgs)
	refreshSidebar()
end

function UI.destroyWindow()
	opened = false
	hideIndicator()
	for _, c in ipairs(conns) do c:Disconnect() end
	conns = {}
	if win then win:Destroy() end
	win, side, main, topbar, scroll, welcome, composer, box, sendBtn, sideList, scrim, menuBtn, titleLbl, statusRow, uiscale = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
	pill, rendered = {}, {}
	busy = false
end

function UI.launcher(handlers)
	H = handlers
	ensureGui()
	if launcherBtn and launcherBtn.Parent then return end
	launcherBtn = new("TextButton", { Name = "NoobyLauncher", AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.6, 0), Size = UDim2.fromOffset(44, 44),
		BackgroundColor3 = T.accent, Text = "N", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = Color3.new(1, 1, 1) }, gui)
	round(launcherBtn, 22)
	stroke(launcherBtn, T.bg)
	launcherBtn.MouseButton1Click:Connect(function() if H and H.toggle then H.toggle() end end)
end

function UI.destroy()
	UI.destroyWindow()
	if launcherBtn then launcherBtn:Destroy() launcherBtn = nil end
	if gui then gui:Destroy() gui = nil end
end

return UI
