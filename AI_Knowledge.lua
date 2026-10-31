-- AI_Knowledge: built-in verified Roblox knowledge + learned (user-provided) facts, corrections, associations.
-- Verified entries are authored here; anything learned from the user is tagged src="user" and never presented as verified.
local Knowledge = {}

local ctx, Memory, Config

local function E(id, topic, title, tags, text, code)
	return { id = id, topic = topic, title = title, tags = tags, text = text, code = code, src = "verified" }
end

local DATA = {
	-- ===================== UI =====================
	E("ui_screengui", "ui", "Creating a ScreenGui and Frame",
		"screengui gui frame create parent playergui gethui coregui container window start basic",
		[=[A ScreenGui is the root container for on-screen UI. Set ResetOnSpawn = false so it survives respawns, and parent it to gethui() (if your executor has it) or PlayerGui.

Prefer Scale for layout that adapts to screen size and Offset for fixed pixel sizes. AnchorPoint decides which point of the frame Position refers to.]=],
		[=[local Players = game:GetService("Players")

local gui = Instance.new("ScreenGui")
gui.Name = "MyUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = (gethui and gethui()) or Players.LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.fromScale(0.5, 0.5)
frame.Size = UDim2.fromOffset(320, 200)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame]=]),

	E("ui_tween", "ui", "TweenService basics",
		"tween tweenservice tweeninfo animate animation easing style direction play size position transparency completed cancel smooth",
		[=[TweenService animates numeric-like properties (Size, Position, Transparency, Color3, Rotation, CFrame...) from their current value to a goal. Build a TweenInfo (time, EasingStyle, EasingDirection), create the tween on an object with a goal table, then Play() it.

If a property can be tweened by two tweens at once they fight each other, so keep a reference and :Cancel() the old tween first. Use tween.Completed:Wait() or :Connect() to chain animations.]=],
		[=[local TweenService = game:GetService("TweenService")

local info = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tween = TweenService:Create(frame, info, {
	Size = UDim2.fromOffset(340, 220),
	BackgroundTransparency = 0.2,
})
tween:Play()
tween.Completed:Connect(function(state)
	print("done", state)
end)]=]),

	E("ui_hover", "ui", "Button hover and click effects",
		"button hover click press mouseenter mouseleave effect animation textbutton touch mobile",
		[=[MouseEnter/MouseLeave drive hover effects on desktop. Touch screens have no hover, so animate on press instead (MouseButton1Down / MouseButton1Up). Keep the original colour in a variable and tween back to it.]=],
		[=[local TweenService = game:GetService("TweenService")
local info = TweenInfo.new(0.15, Enum.EasingStyle.Quad)
local base = button.BackgroundColor3
local hover = base:Lerp(Color3.new(1, 1, 1), 0.12)

button.MouseEnter:Connect(function()
	TweenService:Create(button, info, {BackgroundColor3 = hover}):Play()
end)
button.MouseLeave:Connect(function()
	TweenService:Create(button, info, {BackgroundColor3 = base}):Play()
end)
button.MouseButton1Down:Connect(function()
	TweenService:Create(button, info, {BackgroundColor3 = base:Lerp(Color3.new(0, 0, 0), 0.15)}):Play()
end)
button.MouseButton1Up:Connect(function()
	TweenService:Create(button, info, {BackgroundColor3 = hover}):Play()
end)]=]),

	E("ui_layout", "ui", "Layouts: UIListLayout, UIPadding, AutomaticSize, ScrollingFrame",
		"layout uilistlayout uigridlayout uipadding uiscale automaticsize scrollingframe scroll list grid padding responsive size scale offset canvas",
		[=[Let layout objects position things for you instead of hand-computing Positions. UIListLayout stacks children (set SortOrder to LayoutOrder and Padding), UIGridLayout makes grids, UIPadding adds inner margins, UIAspectRatioConstraint keeps proportions, UIScale scales a whole tree.

For scrolling lists set ScrollingFrame.AutomaticCanvasSize = Y and put a UIListLayout inside; the canvas grows as you add children. AutomaticSize makes a frame fit its content.]=],
		[=[local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, 0, 1, 0)
list.BackgroundTransparency = 1
list.ScrollBarThickness = 4
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = list

local pad = Instance.new("UIPadding")
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = list]=]),

	E("ui_draggable", "ui", "Draggable frame (mouse and touch)",
		"draggable drag move frame window inputbegan inputchanged touch mouse userinputservice handle",
		[=[Listen for InputBegan on the drag handle, remember the start position, then update Position from UserInputService.InputChanged while dragging. Handling Touch as well as MouseButton1 makes it work on mobile. Disconnect the InputChanged connection when you destroy the UI.]=],
		[=[local UIS = game:GetService("UserInputService")

local function makeDraggable(handle, target)
	local dragging, startInput, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, startInput, startPos = true, input.Position, target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	return UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startInput
			target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end]=]),

	E("ui_theme", "ui", "Themes (dark/light) with one switch",
		"theme themes dark light color colors palette style switch bind registry",
		[=[Keep colours in one table and register every object that uses them, so switching theme is a loop instead of hunting through the UI. Optionally tween the colour change for a smooth transition.]=],
		[=[local Themes = {
	Dark = {bg = Color3.fromRGB(26, 26, 30), text = Color3.fromRGB(235, 235, 240), accent = Color3.fromRGB(130, 140, 255)},
	Light = {bg = Color3.fromRGB(245, 245, 248), text = Color3.fromRGB(30, 30, 36), accent = Color3.fromRGB(80, 90, 230)},
}
local current = "Dark"
local registry = {}

local function bind(obj, prop, key)
	registry[#registry + 1] = {obj, prop, key}
	obj[prop] = Themes[current][key]
end

local function setTheme(name)
	current = name
	for _, r in ipairs(registry) do
		game:GetService("TweenService"):Create(r[1], TweenInfo.new(0.25), {[r[2]] = Themes[name][r[3]]}):Play()
	end
end

bind(frame, "BackgroundColor3", "bg")
bind(label, "TextColor3", "text")]=]),

	E("ui_transition", "ui", "Open/close transitions",
		"transition open close show hide fade scale uiscale popup menu animation appear disappear",
		[=[Tween a UIScale and transparency for a clean open/close. Hide the window (Visible = false) after the close tween finishes so it stops rendering.]=],
		[=[local TweenService = game:GetService("TweenService")
local scale = Instance.new("UIScale")
scale.Scale = 0.92
scale.Parent = frame

local function open()
	frame.Visible = true
	TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
end
local function close()
	local t = TweenService:Create(scale, TweenInfo.new(0.15), {Scale = 0.92})
	t:Play()
	t.Completed:Once(function() frame.Visible = false end)
end]=]),

	E("ui_optimize", "ui", "UI optimization",
		"ui optimize optimization performance lag memory fps destroy connections renderstepped cleanup instances pool",
		[=[Cheap UI habits that matter on low-memory devices:
- Don't update UI every frame (RenderStepped/Heartbeat) unless it animates; react to events instead.
- Track every Connection and Disconnect() it when the UI closes; call :Destroy() on instances you no longer need.
- Reuse frames for long lists (pooling) instead of creating hundreds of instances.
- Let UIListLayout/AutomaticSize position things, and avoid stacking many transparent, overlapping frames.
- Tween only what changes, cancel old tweens, and keep images small.]=],
		[=[local conns = {}
local function track(c) conns[#conns + 1] = c return c end

track(button.MouseButton1Click:Connect(function() print("hi") end))

local function destroyUI()
	for _, c in ipairs(conns) do c:Disconnect() end
	table.clear(conns)
	gui:Destroy()
end]=]),

	-- ===================== REANIMATION =====================
	E("reanim_overview", "reanim", "What reanimation is and how it works",
		"reanimation reanimate reanim overview basics what how work fake rig clone character network ownership concept",
		[=[Reanimation scripts drive your character's parts (or a copy of the rig) with custom animation maths. On the client you control the physics of parts you have network ownership of, and the server replicates those parts' positions to other players. So the usual shape is: pick a source rig (an animated fake rig or pure math), compute a target CFrame for each part every physics step, and apply it to the parts you own.

Limits: ownership can be lost, Roblox updates can change what works, and anything the server owns (Humanoid state, animation tracks you don't own) does not replicate from your client. Executor helper functions differ between executors, so check a function exists before calling it.]=],
		nil),

	E("reanim_r6_r15", "reanim", "R6 vs R15 rigs and their joints",
		"r6 r15 rig humanoid parts joints difference torso uppertorso lowertorso arm leg hand foot rigtype names motor6d",
		[=[R6 has 6 body parts (Head, Torso, Left Arm, Right Arm, Left Leg, Right Leg) plus HumanoidRootPart. Its Motor6Ds (Neck, Left/Right Shoulder, Left/Right Hip) live in the Torso; RootJoint lives in HumanoidRootPart.

R15 has 15 parts (UpperTorso, LowerTorso, UpperArm/LowerArm/Hand, UpperLeg/LowerLeg/Foot per side) and more joints (Waist, Elbow, Wrist, Knee, Ankle...). In R15 each Motor6D lives in its Part1, the child part. Detect the rig with Humanoid.RigType and never hard-code part names for both.]=],
		[=[local function rigType(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	return (hum and hum.RigType == Enum.HumanoidRigType.R15) and "R15" or "R6"
end

local R6 = {"Head", "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"}
local R15 = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot"}

local function collect(char)
	local map = {}
	for _, name in ipairs(rigType(char) == "R15" and R15 or R6) do
		map[name] = char:FindFirstChild(name)
	end
	return map
end]=]),

	E("reanim_motor6d", "reanim", "Motor6D joints (C0, C1, Transform)",
		"motor6d joint c0 c1 transform part0 part1 animation weld neck shoulder hip rootjoint offset rotate",
		[=[A Motor6D connects Part0 to Part1. Each frame Part1 is placed at Part0.CFrame * C0 * Transform * C1:Inverse(). Animations write to Transform; scripts usually change C0 (or C1) for permanent offsets. If Part0 or Part1 is nil, or the Motor6D is removed, the limb stops following the body.]=],
		[=[local char = game.Players.LocalPlayer.Character
for _, d in ipairs(char:GetDescendants()) do
	if d:IsA("Motor6D") then
		print(d.Name, d.Part0 and d.Part0.Name, d.Part1 and d.Part1.Name)
	end
end

-- tilt the head 15 degrees
local neck = char:FindFirstChild("Neck", true)
if neck then
	neck.C0 = neck.C0 * CFrame.Angles(math.rad(15), 0, 0)
end]=]),

	E("reanim_cframe", "reanim", "CFrame maths for reanimation",
		"cframe math multiply order angles lookat lerp tobjectspace offset relative rotate position rotation inverse",
		[=[CFrames multiply in order: A * B means "B relative to A". Compute a part's offset from a target once with target.CFrame:ToObjectSpace(part.CFrame), then each step set part.CFrame = target.CFrame * offset. CFrame.Angles takes radians (use math.rad). Lerp gives smooth following. Remember rotation order matters: position/orientation first, then local rotation on the right.]=],
		[=[local offset = target.CFrame:ToObjectSpace(part.CFrame)   -- once

-- every step: keep the same relative pose
part.CFrame = target.CFrame * offset

-- rotate in place
part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(90), 0)

-- smooth follow
part.CFrame = part.CFrame:Lerp(target.CFrame * offset, 0.35)]=]),

	E("reanim_sync", "reanim", "Synchronizing parts each frame",
		"sync synchronize synchronization heartbeat renderstepped prerender step loop update frame connection follow clone fake mapping timing",
		[=[Use a single connection that updates every tracked part, instead of one connection per part. Heartbeat runs after physics each frame and is the usual place to apply CFrames; use RenderStepped only for camera/visual-only work. Cache part references and precomputed offsets, skip parts that no longer exist, and Disconnect on respawn or when you stop.]=],
		[=[local RunService = game:GetService("RunService")
local links = {}  -- { {part = realPart, source = fakePart, offset = CFrame}, ... }
local conn

local function start()
	conn = RunService.Heartbeat:Connect(function()
		for i = 1, #links do
			local l = links[i]
			if l.part.Parent and l.source.Parent then
				l.part.CFrame = l.source.CFrame * l.offset
			end
		end
	end)
end

local function stop()
	if conn then conn:Disconnect() conn = nil end
	table.clear(links)
end]=]),

	E("reanim_replication", "reanim", "Replication and ownership limits",
		"replication replicate network ownership server client filteringenabled see others visible owner limits simulation radius physics",
		[=[Other players only see what the server accepts. In practice that means movement of parts your client has network ownership of. Animations or Transform changes you play locally on a clone are not seen by others, and server-owned things (Humanoid state, other players' parts, anchored parts) won't replicate from you. Ownership can transfer away (distance, physics, game scripts) and some games add checks that reset suspicious movement.

Whether a helper such as isnetworkowner exists depends on your executor, so guard calls with `if fn then`. Treat what you see locally and what others see as two different things and test with a second client if you can.]=],
		[=[local function isOwner(part)
	if isnetworkowner then return isnetworkowner(part) end
	return nil -- unknown on this executor
end]=]),

	E("reanim_troubleshoot", "reanim", "Troubleshooting reanimation problems",
		"troubleshoot troubleshooting debug problem fix limbs falling apart flinging spinning jitter flicker glitch not working broken stuck respawn nil joints",
		[=[Common problems and likely causes:
- Limbs fall off or the character collapses: joints removed, Part0/Part1 nil, Humanoid state changed, or ownership lost.
- Flinging/spinning: velocity builds up. Zero AssemblyLinearVelocity/AssemblyAngularVelocity, check the offset maths, and disable collisions (CanCollide = false) on parts that don't need them.
- Flicker/jitter: two things write the same CFrame (an Animator track plus your loop) or you update on a different step than physics. Pick one writer and use Heartbeat consistently, or lerp.
- Works for R6 but not R15 (or vice versa): part names differ; map by RigType.
- Breaks on respawn: you kept old references. Rebuild on CharacterAdded and disconnect the old loop.
Print the part list and joint list first; a nil there explains most bugs.]=],
		nil),

	E("reanim_optimize", "reanim", "Optimizing reanimation scripts",
		"optimize optimization performance lag fps cpu reanimation loop cache throttle memory efficient",
		[=[One Heartbeat connection for everything, references and offsets cached up front, no FindFirstChild or table creation inside the loop, early-out when the character or parts are missing, and a clean stop() on respawn. Turn off CanCollide/CanTouch/CanQuery on parts that don't need them and avoid per-frame prints. Heavy math (IK, smoothing) can run every second frame if it still looks fine.]=],
		nil),

	E("reanim_physics", "reanim", "Physics: velocity, collisions, Humanoid states",
		"physics velocity assemblylinearvelocity massless cancollide humanoid state platformstand changestate anchored collision network fling gravity",
		[=[Set AssemblyLinearVelocity/AssemblyAngularVelocity to Vector3.zero when you reposition parts so leftover motion doesn't accumulate. Massless parts stop accessories from dragging the assembly around. Humanoid states (PlatformStand, Physics, Dead) change how the character reacts; BreakJointsOnDeath and RequiresNeck decide what happens when joints break. Anchored parts don't replicate their CFrame changes from the client.]=],
		[=[local hrp = char:FindFirstChild("HumanoidRootPart")
if hrp then
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
end]=]),

	-- ===================== LUAU =====================
	E("luau_variables", "luau", "Variables, scope and types",
		"variable variables local scope global type typeof nil number string boolean constant interpolation declare assign",
		[=[Use `local` for variables so they stay inside their block and are faster than globals. Luau values: number, string, boolean, nil, table, function, plus Roblox types (Vector3, CFrame, Instance...). `type(x)` returns Lua types and `typeof(x)` also knows Roblox types. Only nil and false are falsy; 0 and "" are truthy. Luau supports string interpolation with backticks and compound assignment like +=.]=],
		[=[local speed = 16
local name = "Nooby"
local alive = true
speed += 4
print(`{name} runs at {speed}`)   -- Nooby runs at 20
print(typeof(Vector3.new()), type(speed))]=]),

	E("luau_functions", "luau", "Functions, arguments and closures",
		"function functions argument parameter return vararg closure callback local function call define method",
		[=[Functions are values. Declare with `local function name(args) ... end`; return multiple values with `return a, b`; accept any number of arguments with `...`. A closure is a function that remembers variables from where it was created, which is how counters, callbacks and event handlers keep state.]=],
		[=[local function add(a, b)
	return a + b
end

local function sum(...)
	local total = 0
	for _, v in ipairs({...}) do total += v end
	return total
end

local function counter()
	local n = 0
	return function() n += 1 return n end
end
local c = counter()
print(add(2, 3), sum(1, 2, 3), c(), c())  --> 5 6 1 2]=]),

	E("luau_tables", "luau", "Tables: arrays and dictionaries",
		"table tables array dictionary list insert remove find sort concat clear unpack ipairs pairs length clone freeze key value index",
		[=[Tables are Luau's only data structure. Arrays are 1-indexed (`t[1]` is the first item) and `#t` is the length. Dictionaries map keys to values. Use table.insert/remove/find/sort/concat/clear/unpack/clone, iterate arrays with ipairs and dictionaries with pairs (or simply `for k, v in t do`). Assigning a table copies the reference, not the contents; use table.clone for a shallow copy.]=],
		[=[local list = {"a", "b", "c"}
table.insert(list, "d")
table.remove(list, 1)
print(#list, table.concat(list, ", "))  --> 3 b, c, d

local stats = {hp = 100, speed = 16}
for key, value in stats do
	print(key, value)
end
table.sort(list, function(x, y) return x > y end)]=]),

	E("luau_loops", "luau", "Loops and control flow",
		"loop loops for while repeat until break continue ipairs pairs numeric if else elseif condition iterate",
		[=[Numeric for: `for i = 1, 10 do`. Iterate arrays with ipairs, dictionaries with pairs (Luau also lets you write `for k, v in t do`). `while cond do` loops while true; `repeat ... until cond` runs at least once. `break` leaves a loop and Luau's `continue` skips to the next iteration. A loop that never yields (no task.wait()) will freeze the game, so always yield in `while true do`.]=],
		[=[for i = 1, 5 do
	if i % 2 == 0 then continue end
	print(i)           --> 1 3 5
end

while true do
	-- work
	task.wait(1)        -- always yield in infinite loops
end]=]),

	E("luau_metatables", "luau", "Metatables and OOP",
		"metatable metatables setmetatable index newindex call tostring oop class object inheritance method self new metamethod",
		[=[A metatable customises how a table behaves. `__index` runs when a missing key is read (the basis of classes and inheritance), `__newindex` on writes, `__call` makes tables callable, `__tostring` controls tostring/print. The usual OOP pattern: put methods in a class table, set `Class.__index = Class`, and create objects with setmetatable({}, Class). Methods called with `:` receive the object as `self`.]=],
		[=[local Account = {}
Account.__index = Account

function Account.new(owner, balance)
	return setmetatable({Owner = owner, Balance = balance or 0}, Account)
end
function Account:Deposit(n)
	self.Balance += n
end

local acc = Account.new("Nooby", 10)
acc:Deposit(5)
print(acc.Balance)  --> 15

-- inheritance
local Savings = setmetatable({}, {__index = Account})
Savings.__index = Savings
function Savings.new(owner)
	return setmetatable(Account.new(owner, 0), Savings)
end]=]),

	E("luau_coroutines", "luau", "Coroutines and the task library",
		"coroutine coroutines task spawn defer delay wait yield resume wrap thread async parallel wait spawn delay deprecated",
		[=[Use the task library in Roblox: task.spawn(fn) runs now in a new thread, task.defer(fn) runs at the end of the frame, task.delay(t, fn) runs later, task.wait(t) yields. Prefer these over the old wait()/spawn()/delay(). Raw coroutines (create/resume/yield/wrap) are useful for generators and custom schedulers.]=],
		[=[task.spawn(function() print("runs now") end)
task.delay(2, function() print("2 seconds later") end)

local gen = coroutine.wrap(function()
	for i = 1, 3 do coroutine.yield(i) end
end)
print(gen(), gen(), gen())  --> 1 2 3]=]),

	E("luau_errors", "luau", "Common error messages and what they mean",
		"error errors message nil index attempt call valid member arithmetic infinite yield debug traceback fix output why nil value",
		[=[- "attempt to index nil with 'X'": the thing before `.X` is nil: a typo, an object that doesn't exist yet, or FindFirstChild returned nil.
- "attempt to call a nil value": the function/method doesn't exist (wrong name, `.` vs `:`, defined later in the file).
- "X is not a valid member of Y": wrong name or it hasn't loaded; check the Explorer path and use WaitForChild.
- "attempt to perform arithmetic on nil/string": convert with tonumber and check for nil first.
- "Infinite yield possible on ...": WaitForChild never found the object.
Print the suspicious value, then add checks or pcall around risky calls.]=],
		[=[local part = workspace:FindFirstChild("Door")
if part then
	part.Size = Vector3.new(4, 8, 1)
else
	warn("Door not found")
end

local ok, err = pcall(function()
	error("boom")
end)
if not ok then warn(err) print(debug.traceback()) end]=]),

	E("luau_debug", "luau", "Debugging techniques",
		"debug debugging print warn pcall xpcall assert traceback breakpoint output console find bug test troubleshoot",
		[=[Print the values you think you have (print(typeof(x), x)), use warn for visible warnings, wrap risky code in pcall/xpcall(fn, debug.traceback), and use assert(cond, message) to fail early with a clear message. Narrow the problem by commenting out halves of the code. Always read the first error in the output; later ones are often fallout.]=],
		[=[local ok, err = xpcall(function()
	local x = nil
	return x.Position
end, debug.traceback)
print(ok, err)]=]),

	E("luau_modules", "luau", "Modular programming and require",
		"module modulescript require modular return table share reuse organize circular dependency loadstring",
		[=[A ModuleScript returns a value (usually a table) and require() runs it once and caches the result. Split code by responsibility, keep dependencies one-directional, and avoid circular requires. In executors without ModuleScripts, the same idea works with loadstring(source)() returning a table; inject dependencies through an init(ctx) call to avoid cycles.]=],
		[=[-- MathUtil (ModuleScript)
local M = {}
function M.clamp01(x) return math.clamp(x, 0, 1) end
return M

-- elsewhere
local MathUtil = require(path.to.MathUtil)
print(MathUtil.clamp01(1.7))  --> 1]=]),

	E("luau_roblox_api", "luau", "Roblox API basics: services, events, instances",
		"roblox api service getservice players localplayer character runservice userinputservice event signal connect disconnect once instance new destroy clone findfirstchild waitforchild",
		[=[Get services with game:GetService("Name"). Players.LocalPlayer is you; its Character may not exist yet, so use CharacterAdded or WaitForChild. Events use :Connect(fn) and return a Connection you can :Disconnect(); :Once() fires one time and :Wait() yields. Create with Instance.new(), copy with :Clone(), remove with :Destroy(). FindFirstChild returns nil if missing; WaitForChild yields until it exists.]=],
		[=[local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hum = character:WaitForChild("Humanoid")

local conn
conn = hum.Died:Connect(function()
	print("died")
	conn:Disconnect()
end)]=]),

	E("luau_strings", "luau", "Strings and patterns",
		"string strings format gsub find match gmatch sub split pattern lower upper rep len concat",
		[=[Luau strings are immutable. Handy functions: string.format("%d %s %.2f"), s:sub(i, j), s:find(pattern, init, plain), s:gsub(pattern, repl), s:match, s:gmatch, s:split(",") (Roblox), s:lower(), s:upper(). Lua patterns are not regex: `%d` digit, `%a` letter, `%s` space, `.` any char, `-` lazy repeat.]=],
		[=[local s = "hello world"
print(s:upper(), #s, s:sub(1, 5))
print(string.format("%s has %d items (%.1f%%)", "bag", 3, 42.5))
for word in s:gmatch("%a+") do print(word) end]=]),

	E("exec_env", "luau", "Executor environment and capability checks",
		"executor environment exploit getgenv loadstring writefile readfile isfile setclipboard gethui httpget capability check client script",
		[=[Executor scripts run on the client. Functions such as loadstring, writefile, readfile, isfile, setclipboard, gethui, getgenv and game:HttpGet exist only on some executors, with slightly different behaviour. Always check before using (`if writefile then ... end`) and wrap file/network calls in pcall. There is no server access (no ServerScriptService), and `script` may be nil, so don't rely on script.Parent.]=],
		[=[local function safeRead(path)
	if readfile and isfile and isfile(path) then
		local ok, data = pcall(readfile, path)
		if ok then return data end
	end
	return nil
end]=]),
}

Knowledge.verified = DATA
Knowledge.byId = {}
Knowledge.version = 1

local L = { list = {}, byKey = {}, byId = {}, assoc = {}, c = 0, edges = 0 }
Knowledge.learned = L

local function trim(s) return (tostring(s):gsub("^%s+", ""):gsub("%s+$", "")) end

local function recount()
	local n = 0
	for _, m in pairs(L.assoc) do for _ in pairs(m) do n = n + 1 end end
	L.edges = n
end

function Knowledge.init(c)
	ctx, Memory, Config = c, c.Memory, c.Config
	for _, e in ipairs(DATA) do Knowledge.byId[e.id] = e end
	Memory.register("knowledge", function()
		local items = {}
		for _, it in ipairs(L.list) do
			if it.p ~= false then items[#items + 1] = it end
		end
		return { items = items, assoc = L.assoc, c = L.c }
	end)
	local d = Memory.loadBlob("knowledge")
	if type(d) == "table" and type(d.items) == "table" then
		for _, it in ipairs(d.items) do
			if type(it) == "table" and it.id and it.a and it.k and type(it.terms) == "table" then
				it.h = tonumber(it.h) or 0
				L.list[#L.list + 1] = it
				L.byKey[it.k], L.byId[it.id] = it, it
			end
		end
		L.c = tonumber(d.c) or #L.list
		if type(d.assoc) == "table" then L.assoc = d.assoc end
		recount()
		Knowledge.version = Knowledge.version + 1
	end
end

local function dropAssocFor(id)
	for term, m in pairs(L.assoc) do
		if m[id] ~= nil then
			m[id] = nil
			L.edges = L.edges - 1
			if next(m) == nil then L.assoc[term] = nil end
		end
	end
end

local function remove(it)
	for i, v in ipairs(L.list) do
		if v == it then table.remove(L.list, i) break end
	end
	L.byKey[it.k], L.byId[it.id] = nil, nil
	dropAssocFor(it.id)
end

local function evict()
	local victim
	for _, it in ipairs(L.list) do
		if not victim or it.h < victim.h or (it.h == victim.h and it.t < victim.t) then victim = it end
	end
	if victim then remove(victim) end
end

local function changed(it)
	Knowledge.version = Knowledge.version + 1
	if not it or it.p ~= false then Memory.touch("knowledge") end
end

-- kind: "fact" | "correction"; opts: {key=, q=, temp=}
-- returns status ("added"|"updated"|"duplicate"|"empty"), id
function Knowledge.learn(kind, text, opts)
	opts = opts or {}
	text = trim(text)
	if #text < 3 then return "empty" end
	if #text > 500 then text = text:sub(1, 500) end
	local NLP = ctx.NLP
	local tt = NLP.terms(text)
	local qt = opts.q and NLP.terms(opts.q) or nil
	local key
	if kind == "correction" then
		key = "fix:" .. table.concat(qt or {}, " ")
	else
		key = opts.key or table.concat(tt, " ", 1, math.min(6, #tt))
	end
	key = trim(key):lower()
	if key == "" or key == "fix:" then return "empty" end

	local existing = L.byKey[key]
	if existing then
		if existing.a == text then return "duplicate", existing.id end
		existing.a, existing.terms, existing.t = text, tt, os.time()
		existing.p = (not opts.temp) and true or existing.p
		changed(existing)
		return "updated", existing.id
	end
	if kind ~= "correction" then
		for _, it in ipairs(L.list) do
			if it.kind == kind then
				local _, j = NLP.overlap(it.terms, tt)
				if j >= 0.85 then return "duplicate", it.id end
			end
		end
	end
	while #L.list >= Config.Limits.Learned do evict() end
	L.c = L.c + 1
	local it = { id = "L" .. L.c, k = key, kind = kind, a = text, q = opts.q, qt = qt, terms = tt, h = 0, t = os.time(), p = not opts.temp }
	L.list[#L.list + 1] = it
	L.byKey[key], L.byId[it.id] = it, it
	changed(it)
	return "added", it.id
end

function Knowledge.update(id, text)
	local it = L.byId[id]
	if not it then return false end
	text = trim(text)
	if #text < 3 then return false end
	it.a, it.terms, it.t = text:sub(1, 500), ctx.NLP.terms(text), os.time()
	changed(it)
	return true
end

function Knowledge.delete(id)
	local it = L.byId[id]
	if not it then return false end
	remove(it)
	changed(it)
	return true
end

-- forget by key or text fragment; returns how many were removed
function Knowledge.forget(q)
	q = trim(q):lower()
	if q == "" then return 0 end
	local hit = {}
	for _, it in ipairs(L.list) do
		if it.k:find(q, 1, true) or it.a:lower():find(q, 1, true) then hit[#hit + 1] = it end
	end
	for _, it in ipairs(hit) do remove(it) end
	if #hit > 0 then changed() end
	return #hit
end

local function prune()
	local excess = L.edges - Config.Limits.Assoc
	if excess <= 0 then return end
	local all = {}
	for term, m in pairs(L.assoc) do
		for id, w in pairs(m) do all[#all + 1] = { term, id, math.abs(w) } end
	end
	table.sort(all, function(x, y) return x[3] < y[3] end)
	local n = math.min(#all, excess + Config.Limits.Batch)
	for i = 1, n do
		local e = all[i]
		local m = L.assoc[e[1]]
		if m and m[e[2]] ~= nil then
			m[e[2]] = nil
			L.edges = L.edges - 1
			if next(m) == nil then L.assoc[e[1]] = nil end
		end
	end
end

-- strengthen/weaken the link between query terms and an entry (learned association)
function Knowledge.reinforce(qt, id, delta)
	if not qt or not id or not delta then return end
	for i = 1, math.min(#qt, 8) do
		local t = qt[i]
		local m = L.assoc[t]
		if not m then m = {}; L.assoc[t] = m end
		local old = m[id]
		local nv = math.max(-3, math.min(6, (old or 0) + delta))
		if math.abs(nv) < 0.05 then
			if old ~= nil then m[id] = nil; L.edges = L.edges - 1 end
			if next(m) == nil then L.assoc[t] = nil end
		else
			if old == nil then L.edges = L.edges + 1 end
			m[id] = nv
		end
	end
	local it = L.byId[id]
	if it and delta > 0 then it.h = it.h + 1 end
	prune()
	Memory.touch("knowledge")
end

function Knowledge.view(id)
	local e = Knowledge.byId[id]
	if e then return { id = e.id, src = "verified", topic = e.topic, title = e.title, text = e.text, code = e.code, kind = "entry" } end
	local it = L.byId[id]
	if it then
		return { id = it.id, src = "user", kind = it.kind, title = it.kind == "correction" and "Your correction" or (it.kind == "solution" and "A fix that worked before" or "Something you taught me"), text = it.a, q = it.q }
	end
	return nil
end

function Knowledge.clearLearned()
	L.list, L.byKey, L.byId, L.assoc, L.edges = {}, {}, {}, {}, 0
	changed()
	Memory.saveBlob("knowledge", { items = {}, assoc = {}, c = L.c })
end

function Knowledge.stats()
	return { verified = #DATA, learned = #L.list, edges = L.edges }
end

return Knowledge
