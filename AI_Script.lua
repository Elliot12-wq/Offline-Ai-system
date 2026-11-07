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

local TYPE = { B = "button", S = "toggle", L = "slider", D = "dropdown", T = "text box", P = "color picker" }
local TRIG = { "where", "find", "button", "toggle", "switch", "slider", "dropdown", "option", "setting", "tab", "page", "menu", "navigate", "open", "enable",
	"disable", "turn on", "turn off", "click", "press", "tap", "go to", "how do i", "how to", "what does", "what is", "explain", "what do", "do?", "used for", "purpose", "how does" }
local GENERIC = { script = true, enable = true, disable = true, run = true, open = true, find = true, help = true, start = true, stop = true, show = true, hide = true, set = true, get = true, use = true, list = true, send = true, make = true, change = true, clear = true, reset = true, play = true }
local CMDW = { command = true, cmd = true, cmds = true, commands = true, prefix = true }
local IGN = { command = true, cmd = true, admin = true, uh = true, na = true, nameless = true, script = true, button = true, option = true, setting = true }

-- ===== verified script entries (text copied from / grounded in the script's own help strings) =====
local ENTRIES = {
	{ id = "sc_methods", title = "Reanimator methods (Main page)", tags = "reanimator reanimate method methods limb hats hat tool ragdoll unanchored dropdown config start refresh hitboxes five 5 options choose which",
		text = [==[On the Main page the **Reanimator** dropdown picks the method. There are FIVE: **Limb Reanimator**, **Hats Reanimator**, **Tool Reanimation**, **Ragdoll Reanimator** and **Unanchored Reanimation**. The block under it ('-=+ <method> Config +=-') shows that method's settings. The **\* Reanimate \*** button starts it (pressing it again stops it; the status line shows 'Running: <method>'); **Refresh Reanimate Character** and **Show Reanimate Hitboxes** are just below. 'Reanimate Character Settings' (Infinite Jump, Noclip, Smooth Camera, First Person Body, Allow Shiftlock, Can Sit on Seats, Can Pickup Tools, Apply Scale to Gravity, Void Float) apply to the reanimated character.

Three separate systems are easy to mix up: (1) the five methods above, (2) **Extra Unanchored Reanimation**, an add-on at the bottom of the Limb and Ragdoll config, and (3) **Tool Reanimation Extras**, an add-on at the bottom of the Hats config. Ask 'what's the difference' and I'll compare them.]==] },
	{ id = "sc_limb", title = "Limb Reanimator settings", tags = "limb reanimator rootpart mode velocity init mode compatibility checker animator r6 r15",
		text = "Limb Reanimator only works in SOME games: modern games create the Animator automatically, which breaks limb reanimation (the script's own README note). Settings: **RootPart Mode**, **RootPart Velocity** (No Velocity / Follow Character / Fling-like), **Init Mode** (Reset Character / CDSB + Reset / CDSB + SSE + Kill), **Show me how I look!**, **Target Fling Enabled**. Spawn a character, then press **Check Limb Compatibility**: it checks game animations, voice chat players, dynamic faces, the game environment and R6/R15. **Dump Fake Character State** copies a debug dump to console + clipboard. At the bottom of this config sits **Extra Unanchored Reanimation** (off by default): when on, loose unanchored map parts become Wings, a Tail and a Halo Aura on your FAKE character while the Limb reanimation runs. It is an add-on, not the standalone Unanchored Reanimation method." },
	{ id = "sc_hats", title = "Hats Reanimator settings", tags = "hats hat reanimator finish finishes never permadeath collide torso offset ensure fling spin rebuild hat map respawn stuck timeout r15 tool holding",
		text = "Hats Reanimator settings: **Permadeath (dolteddown's pd)** (needs replicatesignal support from your executor), **Auto Force Respawn when stuck** + **Stuck timeout (seconds)** (if the reanimate never finishes with the pd, your character is force respawned after that long), **respawntp**, **Hat Collide**, **Torso Offset**, **Ensure All Hats**, **Ensure Hat Collide**, **Hat Fling**, **Hat Spin Fling**, **Target Fling Method**, **Tool Holding**, **toolanim Method**. If your hats get voided when you use Hat Collide, try changing **Torso Offset**. **Rebuild Hat Map** is for when your rig was built wrong or you switched to a new rig; **Force Respawn Now** respawns immediately. Method 11 (R15 hat reanim) is exclusively for R15 characters. Don't combine Hat Fling / Hat Spin Fling with target fling unless you want walkfling or look glitchy. At the bottom of the Hats config are the **Tool Reanimation Extras** (**Add Tool Reanimation as Extra** + Wings / Halo / Tail / Floating Aura built from spare Tool handles). They are cosmetic and separate from the Tool Reanimation method." },
	{ id = "sc_tool", title = "Tool Reanimation (Original vs Corpse Claim)", tags = "tool reanimation corpse claim claiming original tools handle collide permadeath replicatesignal freed grip",
		text = "Every Tool you own (up to 6) becomes one R6 body part: Torso, Head, Right Arm, Left Arm, Right Leg, Left Leg, in that order. **Tool Method**: *Original* equips the tools, breaks the real character's joints server-side and uses the freed handles (optional dolteddown's permadeath; needs replicatesignal). *Corpse Claim* arms every tool at once, then kills the real character so the server breaks all grips together; a dead humanoid cannot pick anything up, so each tool is moved into Workspace right away. A tool is only driven once the server has really freed it and you own it; unconfirmed drops are resent; the respawned character is parked alive and touch-disabled (replicatesignal is only an optional helper). With Permadeath on, the real character stays alive so the tools stay yours; off = tools are lost when the game respawns you. **Tool Collide** and **Target Fling Enabled** are also here; the biggest tool handle you really own is thrown at fling targets. Don't confuse this with **Tool Reanimation Extras**, a cosmetic add-on under the Hats Reanimator that turns SPARE Tool handles into Wings / Halo / Tail / Floating Aura: Tool Reanimation replaces your body parts with tools, the Extras don't." },
	{ id = "sc_fling", title = "Fling options", tags = "fling method click fling alt fling target fling default weak nooby nan state kill walkfling served user alt flinger",
		text = "Fling style is chosen with the **Fling Method** dropdown on the Main page (Default / Weak / Nooby's / NaN State / Fling 1 / Fling 2 / Fling 3). **Click Fling** flings whoever you click. Alt-fling: pick the method, then click a target; **Alt-fling: resend command**, **Request Served User** and **View users I'm Alt Flinger for** manage alts (it waits for an admin whitelist whisper). **Toggle Kill**, **Ya kids tool kill option** and **Kill All** are in the same area. Don't use tool fling together with physics glue." },
	{ id = "sc_internals", title = "Internals Settings (physics reanimation)", tags = "internals settings hook loadanimation physics glue netless patchma velocity rotvelocity",
		text = "**Internals Settings** on the Main page are 'internals for physics based reanimation (like hat reanimator)': **Hook LoadAnimation**, **Use Physics Glue**, **Patchma-like Netless**, **Netless Velocity**, **Apply RotVelocity**." },
	{ id = "sc_perf", title = "Performance options", tags = "performance lag low end ui mode anti lag textures hide players monitor weak device fps fast particle",
		text = "For weak devices: **Low End UI Mode** (simpler 3D triangle, basic UI without effects; turn it off to get everything back), **Anti Lag (remove all textures)**, **Hide All Players**, **Fast Particle Effects**. In the Customization page you can also switch off Ambient Particles, Accent Sheen, Cursor Trail and Liquid Glass. **Performance Profile** (Auto, Ultra, High, Balanced, Low, Potato) sets the overall quality: Auto adapts to your device and FPS, picking one yourself turns the automatic adjustments off. **Performance Monitor >** (Main page) shows live FPS and memory graphs." },
	{ id = "sc_triangle", title = "Command triangle and command bar", tags = "triangle command bar hide show showtri hidetri tab prefix open bar uh admin button drag",
		text = "The Uh Admin triangle is the floating launcher: **tap = commands, hold = hide**. Drag it anywhere (mouse or finger). After hiding, a small tab stays at the top edge: tap it, type `showtri`, or flip the switch in the Customization page. The command bar also opens with the prefix key (default `.`). **Reset Triangle Position** (Customization page) puts it back if it is off-screen." },
	{ id = "sc_prefix", title = "Uh Admin prefix and commands", tags = "prefix command commands cmds list nameless admin uh admin catalogue blocked punch plugin",
		text = "Uh Admin is the Nameless Admin integrated into the script. Default prefix is `.` (saved in Nameless-Admin/prefix.txt; change it with `prefix <new>`; empty, `p`, `P` and `[` are rejected). `cmds` / `commands` opens the command list. Uh Admin's own handlers win on any name clash with Nameless Admin's catalogue, and `punch` is blocked. Plugins: `.na` files go to Nameless-Admin/Plugins, `.iy` files to PluginsIY (`addplugin`, `addallplugins`, `reloadplugin`, `pluginmaker`)." },
	{ id = "sc_roles", title = "Admin whitelist, roles and permissions", tags = "admin unadmin whitelist role roles owner coowner co-owner permission permissions moderation broadcast announcement roles.json github decides decide who",
		text = "`admin <player>` whitelists someone so they can use your commands (they get a whisper with the prefix and a starter list); `unadmin <player>` removes them. The Main page shows your **Role** under REMOTE MODERATION / LIVE PLAYERS; the **OWNER BROADCAST** section (send announcement) is only for the owner role. Roles shown as tags (e.g. OWNER) come from roles.json in the Elliot12-wq/uh-mod-visual-system GitHub repo: only **owner** and **co-owner** entries are read (by username of 3-20 letters/digits/underscore and/or userId) and the list is re-fetched at most every 20 seconds. The announcement and banner backends look the sender up in roles.json themselves. I can't change roles." },
	{ id = "sc_modules", title = "Modules, movesets, dances and marketplace", tags = "modules moveset dances keybinds marketplace market download delete reload local user module loading",
		text = "**Movesets >**, **Dances >** and **Dance Keybinds >** open item lists (Use Moveset / Play Dance; the Dance Keybinds Enabled switch turns keybinds on). **Module Loading**, **Reload Modules** and **Reload User Modules** are in MODULES MANAGEMENT. The marketplace pages ('See what we have >' / 'See what you have >') download or delete user modules: reload your modules afterwards to apply them." },
	{ id = "sc_security", title = "Security options (overview)", tags = "security overview protections structure malware scan delete danger zone clear downloaded content background malware security external script protection sections explain",
		text = [==[The Main page **SECURITY** area has two parts plus a danger zone. **Background Malware Security** (SECURITY block): **Background Malware Scan**, **Auto-Delete Malware (EXPERIMENTAL)** and **Scan Now**; it checks the script's own files and modules. **External Script Protection** (its own block below): the switches **External Script Protection**, **Anti-Phishing**, **Script Checker**, **Execution Firewall** and **Runtime Monitoring**, a Statistics block, and the buttons **Security Findings**, **Security History**, **Executor Capabilities & Limits** and **Clear Findings & History**; it guards THIRD-PARTY scripts you run. **DANGER ZONE**: **CLEAR ALL DOWNLOADED CONTENT**. UH Admin's built-in scripts and the embedded Nameless Admin are trusted internal code and are excluded from the external protection; external copies are not. Nothing here guarantees safety: CLEAN only means no known pattern was found, and not every executor supports every interception. Ask about any part for details.]==] },
	{ id = "sc_serverhop", title = "Server hop and auto execute", tags = "server hop rejoin auto execute skip servers visited hop mode",
		text = "**Server Hop** section: **Hop Mode**, **Skip servers I visited (1h)**, **Auto Execute after hop / rejoin**, **Server Hop**, **Rejoin This Server**. Auto Execute runs this script again in the new server; it looks for its own file in your executor's workspace folder, so normally you set nothing. If it can't find it, type the file name or a raw https:// link (optional override)." },
	{ id = "sc_custom", title = "Customization page", tags = "customization customize theme palette font scale glass haptic intro delta triangle particles sheen cursor trail reset",
		text = "Main page > **Customization >**: **Preview Intro**, **Test Notification**, **UI Scale (zoom)**, **UI Font**, **Ambient Particles**, **Accent Sheen**, **Cursor Trail / Touch Ripples**, **Liquid Glass (iOS 27)** + **Glass clarity**, **Haptic Feedback**, **Reset Proportions** (limb/hat spacing), **Reset Triangle Position**, Delta cache stats/clear (when Delta is detected), **Reset All Customization**. Everything is saved and applies instantly." },
	{ id = "sc_ai", title = "JARVIS (this assistant)", tags = "jarvis nooby neural ai assistant chat memory offline",
		text = "**JARVIS >** on the Main page (and in the Feature Center) opens this assistant. It is fully offline; my memory and learned notes are stored on this device (`/memory` to inspect them). I can explain any button or toggle of the script, tell you where it is, and walk you through a goal." },
	{ id = "sc_featurecenter", title = "Feature Center (find any option)", tags = "feature center find option categories navigate lost where menu list everything search",
		text = "**Feature Center >** (Main page) lists every option of the Main page sorted into categories: Live Players / Moderation, Performance / Graphics, Reanimation / Character, Movesets / Dances, Fling / Interaction, Teleport / Servers, Customization / Settings, Customization, Music / Sound, Script Hub / Modules, Marketplace, Security / Danger Zone and Info / Logs. Open a category to see only its controls; **< Back** returns. It also has a **JARVIS >** shortcut." },
	{ id = "sc_ragdoll", title = "Ragdoll Reanimator", tags = "ragdoll reanimator stiffness ballsocket limbs detached physical pose",
		text = [==[**Ragdoll Reanimator** (4th of the five **Reanimator** dropdown options) detaches your real limbs into BallSocket ragdoll limbs and physically drives them to the reanimated pose. It uses the Limb Reanimator settings (including **Extra Unanchored Reanimation** at the bottom of that config), plus **Ragdoll Stiffness** (slider 10-200): how hard the limbs are pulled to the pose, applied on the next Reanimate.]==] },
	{ id = "sc_live", title = "Live Players and remote moderation", tags = "live players active players search join player remote moderation kill deanimate kick ban unban role owner staff alerts",
		text = "**Live Players >** (Main page) shows the ACTIVE PLAYERS list (search by name, game or server). Under REMOTE MODERATION you can pick a target (tap a player or type a username/ID) and use **Kill**, **Deanimate**, **Kick**, **Ban**, **Unban**; those buttons only appear when your role allows it, and your role is shown as 'Role: ...'. I can't change roles." },
	{ id = "sc_flywalk", title = "Fly, WalkSpeed, scale and sit", tags = "fly walkspeed speed scale size character sit gyro key toggle e q placeholders",
		text = "Main page > **Fly & WalkSpeed**: **Custom WalkSpeed** + **WalkSpeed** (1-250), **Fly (E = up, Q = down)** + **Fly Speed** + **Fly Toggle Key** (None/F/Y/O/I), **Force Sit (2x to remove gyro)**, **Character Scale** (0.5-5) and **Placeholders** (transparency of the placeholder parts)." },
	{ id = "sc_theme", title = "UI Theme and colors", tags = "theme ui theme colors color palette accent look style skin dark light preset customize",
		text = "**UI Theme** (Main page dropdown) swaps the whole look: RGB/Default, ALONE, Oxide, Patchma Hub, Genesis V4, Crimson, r/masterhacker, Homer Simpson, Immortality Lord, LIGHT RGB, LIGHT ALONE, Roserika, FastTracker II Blue, Cherry Blossom, Sakura, Tommorow Night 80s, User Defined, Modjo Disco Sunset. For fine control open **Customization >**: the COLOR SYSTEM section has Accent mode, Color harmony, Dynamic color speed, Saturation, Brightness and a color picker, and the whole UI follows that one live palette." },
	{ id = "sc_engine", title = "Roblox engine settings", tags = "engine settings roblox physics debug render network fast particle mesh cache frm replication lag overlay",
		text = "Main page > **ROBLOX ENGINE SETTINGS** (taken from Nameless Admin's settings page, saved and re-applied on the next start): toggles for network, physics-debug and render settings (e.g. Physics Owners Shown, Render Bounding Boxes, Frame Rate Manager), number boxes (Mesh Cache Size, Auto FRM Level, Incoming Replication Lag...), **Fast Particle Effects** (needs setfflag support), **Reload Render Assets**, and ASSET LOADING (**Preload Assets On Load**, **Load Game Assets**)." },
	{ id = "sc_hub", title = "Nooby's Script Hub", tags = "script hub nooby hub scripts run all scripthub",
		text = "**Nooby's Script Hub (NOT FROM SCRIPTHUB) >** (Main page) opens Nooby's own script list: tap a script to run it, or **Run all N scripts** to run every one. The `scripthub` command is a different thing (it uses the scriptblox API)." },
	{ id = "sc_arch", title = "Script architecture and loading", tags = "architecture structure how script works loads loading initialization startup init modules module folder uhhhhhhreanim plugins flingmethods assets util fx reanimate ui library default splitted instant slow loading mode reload",
		text = [==[The script is one big Lua file built from: a shared **Util** table (Roles, FX = UI effects + the Adaptive Performance Engine, Search, JARVIS, notifications, Fling...), the **Reanimate** engine, and the UI library (pages, buttons, switches, dropdowns, sliders, text boxes). Heavier features are separate modules kept in the **UhhhhhhReanim** folder (with **Plugins**, **FlingMethods** and **Assets/Cache UI** + **Assets/UI ANIMATION CACHE** subfolders). Main page > Script Hub / Modules has the **module loading mode**: **Default**, **Splitted**, **Instant** or **Slow** (one .lua at a time with a pause between each); the UI, Reanimate, Movesets and Dances are usable while modules load in the background. Load steps have safe error handling, so one failed module doesn't stop the rest. JARVIS itself downloads its modules from the GitHub repo Elliot12-wq/Offline-Ai-system (needs loadstring plus HttpGet or request) and caches them in the NoobyAI/cache folder; without file functions my memory is session-only.]==] },
	{ id = "sc_ape", title = "Adaptive Performance Engine (Performance Profile)", tags = "adaptive performance engine ape profile profiles performance profile auto manual ultra high balanced low potato fps governor vfx particles trails beams bloom shadows frame rate lag stutter boost dropdown",
		text = [==[Main page > Performance > **Performance Profile**: **Auto**, Ultra, High, Balanced, Low, Potato. In **Auto** the engine picks a starting profile from your device (tier, mobile or not), then a light FPS governor watches the frame rate (target = your FPS cap if it is under 90, otherwise 60). If FPS stays below about 72% of the target for a few seconds it drops one profile (two if below about 35%); after FPS stays above about 92% for roughly 8 seconds (and 15 s since the last change) it climbs back up, and it avoids bouncing back into a level that just failed. Choosing a fixed profile is **Manual**: automatic changes stay off until you pick Auto again. The profiles scale VFX: particle emitter Rate (Ultra 100%, High 75%, Balanced 50%, Low 25%, Potato 8%), trails, beams, lights and post effects (bloom, sun rays, depth of field), global shadows, terrain decoration, mesh detail and simulation-radius refresh, plus an FPS cap on mobile for Low and Potato. High turns depth of field off, Balanced also turns shadows and sun rays off, Low also turns trails, beams and terrain decoration off, Potato also turns lights and bloom off. The engine never switches **Low End UI Mode** on by itself. A status line under the dropdown shows what is running.]==] },
	{ id = "sc_uicache", title = "UI Cache and UI animation cache", tags = "ui cache cache ui animation cache customization json snapshot textures meshes memo lag stutter folder rebuild delete assets v293 v299 v300 sparkles cursor trail",
		text = [==[Main page > Performance > **UI Cache** switch (on by default). ON: UI assets (3D triangle face meshes, ring and spark textures, UI graphics) are copied once into UhhhhhhReanim/Assets/Cache UI and reused, text sizes are remembered for layout, and per-frame colour / transparency writes are skipped when nothing changed (v293-v294). v299 adds UhhhhhhReanim/Assets/UI ANIMATION CACHE (cache.json + animations.json): title-decode frames are built once and replayed from disk and ripple dots are pooled. v300 draws ambient sparkles and the cursor trail from one cached VFX dot texture and snapshots your UI customization into Assets/UI ANIMATION CACHE/UI/customization.json (restored only when the save has no customization at all). The 3D triangle and effects pick up a change on the next launch; delete the Cache UI folder to rebuild it. Reanimation, movesets and other features are not affected. It is separate from **Low End UI Mode**.]==] },
	{ id = "sc_backend", title = "Backend communication (HTTP, Cloudflare Workers, GitHub)", tags = "backend http request cloudflare worker workers.dev server network github raw announcement poll banner logger kv ann override getgenv httpget online offline blocked executor",
		text = [==[The script talks to three Cloudflare Workers through the executor's request function (request / http_request / syn.request) and reads GitHub raw files with HttpGet. (1) **Announcements** (backend-announcement.elliptmal.workers.dev, override with getgenv().UH_BROADCAST_URL): clients poll GET /poll and show announcements; only owners listed in roles.json may send, and the worker needs a KV binding named ANN. (2) **Banner system** (banner-system.elliptmal.workers.dev, override with getgenv().UhBannerConfig = {Backend = url, Base = repo url}): GET /banners?room=, POST /banner, POST /mod, GET/POST /blacklist; with no backend configured it runs LOCAL-ONLY (only you see your banner). (3) **Server logger / live players** (nooby-server-logger.elliptmal.workers.dev) feeds the Live Players list (who runs the script, in which game and server) and the Owner / Co-owner alerts. GitHub files: roles.json and blacklist.json in Elliot12-wq/uh-mod-visual-system, and my modules in Elliot12-wq/Offline-Ai-system. These calls are wrapped in pcall: if requests are blocked or the executor has no request function, the feature stays quiet and the rest of the script keeps working.]==] },
	{ id = "sc_banners", title = "Player banners and moderation modules", tags = "banner banners billboard receiver sender modtools blacklist altfling room moderator kill deanimate kick live sync",
		text = [==[Banners are animated character banners (a BillboardGui themed from the UI colours, with a 3D triangle beside the profile picture). The banner system is embedded as modules: **BannerUI**, **BannerReceiver** (polls the backend, sanitises banner data, one banner per player, follows respawns), **BannerSender** (publishes your banner + keep-alive), **ModTools** (kill / deanimate / kick relayed to OTHER script users who misuse the script), **Blacklist** (backend GET /blacklist, falling back to blacklist.json in the repo; only OWNER / CO-OWNER can add or remove entries, with a Yes/No warning each time) and **AltFling** (Served User requests with consent, Alt-Flinger console, relationship viewer). Players are grouped per room = PlaceId-JobId, so only people in the same server see each other's banners. OWNER / CO-OWNER are not hardcoded: they come from roles.json.]==] },
	{ id = "sc_motion", title = "UI motion, transitions and effects", tags = "motion animation animations transition transitions orbit doors bubble pop card flip wave register lock fold minimize intro buttons 3d triangle accent colour harmony sheen ripple glow vfx effects blur ambient",
		text = [==[The UI is built around motion: 15 page transitions (including ORBIT, DOORS, BUBBLE POP, CARD FLIP and WAVE), 3D buttons with squish / lift / elastic release and a staggered pop-in, bubbly toggles and slider knobs, the REGISTER LOCK hand-over from the intro (three outline plates snap onto the window frame), and WINDOW FOLD when you minimize and reopen. The colour system has 7 accent modes and 5 harmonies with a visual colour picker. Intro, transition blur, fancy transitions, extra UI sounds and ambient FX are toggles under Intro settings / Customization. **Low End UI Mode** removes most of this (no intro, blur, transitions, glow, particles, sheen, cursor trail, hover / press animations) and renders the 3D triangle with 8 parts instead of 18 at 30 fps; turning it off restores everything. The Cards dashboard (Welcome back greeting, friends in your server) has its own **Backdrop blur** switch.]==] },
	{ id = "sc_trouble", title = "Troubleshooting map", tags = "troubleshoot troubleshooting troubleshooter fixes common problems quick fix map",
		text = [==[Fixes that match the script's own options: **Laggy UI / low FPS** > Main page > Performance: Low End UI Mode, Performance Profile (Auto or a lower fixed one), UI Cache, Anti Lag, Hide All Players. **Hat reanimate never finishes** > Hats Reanimator: Auto Force Respawn when stuck + Stuck timeout, or Force Respawn Now; hats voided with Hat Collide > change Torso Offset; Rebuild Hat Map after changing rigs. **Limb Reanimator does nothing** > the game probably creates an Animator automatically; run the Compatibility Checker or use Hats / Tool / Ragdoll instead. **Only you see your banner** > no banner backend reachable (LOCAL-ONLY mode) or the executor has no request function. **JARVIS won't load** > needs loadstring and HttpGet or request; a cached copy in NoobyAI/cache is used when the download fails. **Modules download slowly or fail** > try another module loading mode (Slow loads one .lua at a time) or reload modules from Script Hub / Modules.]==] },
	{ id = "sc_unanchored", title = "Unanchored Reanimation (5th method, standalone)", tags = "unanchored reanimation unanchor method fifth 5th standalone loose parts map wings tail halo aura part finder automatic part search radius teleport confirmation how does work independent no tools no hats no reset respawn config options",
		text = [==[**Unanchored Reanimation** is the 5th choice of the **Reanimator** dropdown and works on its own: no tools, no hats, no reset or respawn. It finds loose, unanchored parts lying around the map near you, only moves a part once the engine confirms you are simulating it (you own it), and turns the parts into **Wings**, a **Tail** and a **Halo Aura**. In this standalone method the effects are built on your real character. It rejects characters / NPCs, anchored or grounded assemblies, seats, terrain, destroyed or oversized parts, and rates each part's size and shape for the job (a minimum fit is required), so it needs suitable unanchored parts that you can get ownership of.

Options: **Use unanchored parts as tools** (on: the Wings / Tail / Halo effects), **Use unanchored parts as limbs** (off; see 'unanchored limbs'), **Torso Offset**, **Wings** + **Wing Animation** (Flap / Idle), **Tail** + **Tail Animation** (Wag / Slash Tail), **Halo Aura**, and a **Part Finder** block with a live 'Detector:' status line, **Automatic Part Search** (on), **Search Radius (studs)** (20-500, default 150) and **Teleport Confirmation** (a Yes / No prompt before any teleport). With Automatic Part Search off, no new parts are searched or claimed and parts already held keep animating.]==] },
	{ id = "sc_ua_limbs", title = "Unanchored limbs (Use unanchored parts as limbs)", tags = "unanchored limbs limb use unanchored parts as limbs lifecycle independent torso offset teleport prompt slots six parts fake character real limbs hidden how does differ standard limb reanimation",
		text = [==[Switching **Use unanchored parts as limbs** on (inside Unanchored Reanimation) changes what Reanimate does: it runs its **own unanchored-limb lifecycle** and the Limb Reanimator is never started. With Automatic Part Search on it scouts for a suitable part and asks (Teleport Confirmation) whether to teleport to it; then it resets your character like the Limb Reanimator and uses up to **6** unanchored parts (5, 4... if fewer exist) as the limbs of the fake character, filled in the order Left Arm, Right Arm, Left Leg, Right Leg, Head, Torso (Torso last). A part is never used twice. A real limb is only hidden while its replacement part is owned, attached and settled in its slot, and is shown again if ownership is lost; an equipped real Tool keeps the real right arm in place. **Torso Offset** decides where your real root / torso sits during the run: Nooby's Method, RootPart Streamed, or RootPart in Sky/Void. Wings / Tail / Halo still work alongside it while 'Use unanchored parts as tools' is on.

Difference from standard Limb Reanimation: there the limbs come from your own character and the Limb settings (RootPart Mode, Init Mode...) apply; here the limbs are loose MAP parts and the Unanchored settings apply.]==] },
	{ id = "sc_ua_extra", title = "Extra Unanchored Reanimation (works with Limb / Ragdoll)", tags = "extra unanchored reanimation limb ragdoll integrate integration integrated fake character wings tail halo aura add on addon works with combine combined how does unanchored work with limb reanimation fake real",
		text = [==[**Extra Unanchored Reanimation** is a switch at the bottom of the **Limb Reanimator** and **Ragdoll Reanimator** config (block '-=+ Extra Unanchored Reanimation +=-'), off by default. It integrates unanchored parts INTO the Limb/Ragdoll reanimation: while that reanimation runs, loose unanchored map parts become **Wings, a Tail and a Halo Aura on your FAKE (reanimated) character**, not on the real one. It starts with the Limb/Ragdoll run (or immediately if you flip it while one is running) and stops with it. Parts are only moved once the engine confirms you simulate them; because the fake rig only exists on your client, the script points physics replication at a part of your real character.

When it is on you get the same options as Unanchored Reanimation (Wings, Wing Animation, Tail, Tail Animation, Halo Aura, Part Finder, Automatic Part Search, Search Radius, Teleport Confirmation), but NOT 'Use unanchored parts as tools / limbs' or Torso Offset. It adds effects only: it does not replace your limbs or the Limb/Ragdoll method. The standalone Unanchored Reanimation is a separate dropdown choice.]==] },
	{ id = "sc_toolextras", title = "Tool Reanimation Extras (Hats)", tags = "tool reanimation extras extra tools hats reanimator spare tool handles wings halo tail floating aura cosmetic add tool reanimation as extra requirements how many tools replicatesignal how do tool extras work with hats effects options",
		text = [==[**Tool Reanimation Extras** sit at the bottom of the **Hats Reanimator** config (block '-=+ Tool Reanimation Extras +=-'; Hats only). The master switch **Add Tool Reanimation as Extra** (off by default) reveals four effect switches: **Wings** (needs 6 spare tools), **Halo** (3), **Tail** (4) and **Floating Aura** (takes ALL the tools left over). They are cosmetic effects built from your SPARE Tool handles (Backpack tools that are not in use), assigned in the order Wings, Halo, Tail, Floating Aura. If there are not enough spare tools an effect is skipped with a notification ('needs N tools but only M are available'). They only run while the Hats Reanimator is the running method and at least one effect is on. Each handle goes through arm -> server grip break -> free -> confirmed ownership -> live and is only moved once the engine confirms you simulate it; replicatesignal is needed to break the grips on the server (without it other players will not see the tools correctly).

This is NOT Tool Reanimation: the primary **Tool Reanimation** method (its own dropdown choice) turns up to 6 tools into body parts (Torso, Head, Right Arm, Left Arm, Right Leg, Left Leg) and replaces the character; Tool Extras only decorate while your hats are being driven.]==] },
	{ id = "sc_ua_compare", title = "Unanchored vs Limb vs Extra Unanchored vs Tool Extras (differences)", tags = "difference differences differ different compare comparison versus vs unanchored limb reanimator standalone extra unanchored tool extras tool reanimation hats distinguish confuse which one separate systems three similar same",
		text = [==[**Unanchored Reanimation vs Limb Reanimator**: Limb Reanimator is the classic method (settings: RootPart Mode / Velocity / Init Mode; it only works in games that don't auto-create the Animator). Unanchored Reanimation is a separate 5th method that uses loose unanchored MAP parts, needs no tools, hats, reset or respawn in its default mode, and builds Wings / Tail / Halo Aura on your real character. If you also turn on 'Use unanchored parts as limbs', map parts become the limbs of the fake character through an independent lifecycle; it still never runs the Limb Reanimator.

**Three different systems, don't mix them up:**
1. **Unanchored Reanimation** (Reanimator dropdown, 5th choice): standalone; map parts; effects on the real character.
2. **Extra Unanchored Reanimation** (bottom of the Limb and Ragdoll config): an add-on that integrates map parts into a running Limb/Ragdoll reanimation; the effects are on the FAKE character.
3. **Tool Reanimation Extras** (bottom of the Hats config): cosmetic Wings / Halo / Tail / Floating Aura from spare Tool handles. Not the primary **Tool Reanimation** method, which replaces your body parts with up to 6 tools.]==] },
	{ id = "sc_new_reanim", title = "What's new in reanimation (current build)", tags = "whats new reanimation latest changes added methods update recent current unanchored extra tool extras what changed reanimator",
		text = [==[The current build (source revision v324) has five reanimator methods: Limb, Hats, Tool, Ragdoll and **Unanchored Reanimation**. It also has two add-ons: **Extra Unanchored Reanimation** (Limb / Ragdoll config) and **Tool Reanimation Extras** (Hats config). Tool Reanimation has two methods, *Original* and *Corpse Claim*. The script's header changelog doesn't list each of these, so I can't date them individually; ask me about any of them for the details.]==] },
	{ id = "sc_sec_bg", title = "Background Malware Security (scan, auto-delete, Scan Now)", tags = "background malware scan auto delete experimental scan now quarantine files modules pass folder limits skipped suspicious malicious confidence scanner own files",
		text = [==[**Background Malware Scan** (on by default) walks the script's files in the background (.lua, .luau and .txt in UhhhhhhReanim/Modules and the executor workspace; the Content, Muzik, Assets and Quarantine folders are skipped; the built-in modules folder is report-only) in repeating passes about 5 minutes apart, and also checks a module right before it loads. **MALICIOUS** modules are blocked from loading and reported; **SUSPICIOUS** ones only warn ('needs review'); details go to Init Logs.

**Auto-Delete Malware (EXPERIMENTAL)** (off by default) only acts on MALICIOUS files with confidence of at least 0.75 outside report-only folders: it copies the file to UhhhhhhReanim/Quarantine, reads the copy back to verify it, then deletes the original. If the executor lacks the file functions (writefile, readfile, isfile, delfile), the copy can't be verified, or the file changed since the scan, the original is kept. It can delete a safe file by mistake.

**Scan Now** needs Background Malware Scan on: it clears the scan cache and starts a fresh pass when the scanner is idle, or tells you a scan is already running. Limits: files over 6 MB are skipped, modules over 16 MB are blocked as unscannable, and a clean result is not a guarantee of safety. This block covers the script's own files; scripts you run from elsewhere are handled by External Script Protection.]==] },
	{ id = "sc_sec_ext", title = "External Script Protection (overview and how the pieces fit)", tags = "external script protection third party scripts guard editor clipboard hubs scriptblox github pastebin five protections switches master anti phishing script checker execution firewall runtime monitoring explain system structure confirmation dialog turn off how does work pipeline",
		text = [==[**External Script Protection** guards THIRD-PARTY scripts (the editor, clipboard, script hubs, ScriptBlox, GitHub, Pastebin and anything that calls loadstring / loadfile). It is a block on the Main page under SECURITY with five switches, all on by default: **External Script Protection** (master), **Anti-Phishing**, **Script Checker**, **Execution Firewall** and **Runtime Monitoring**.

How the pieces fit: when a third-party script is about to be compiled, the **Script Checker** inspects its source (its web addresses go through **Anti-Phishing**) and gives a verdict (CLEAN / SUSPICIOUS / MALICIOUS / UNVERIFIED); the **Execution Firewall** decides what happens to a flagged one (pause and ask, or block); then the script is compiled under its own tracked identity so **Runtime Monitoring** can watch what it does afterwards (network, clipboard, files, teleport queue, hooks). Statistics, **Security Findings**, **Security History** and **Executor Capabilities & Limits** show what happened.

Turning any of the five switches OFF first opens a confirmation dialog (KEEP PROTECTION ON / TURN OFF PROTECTION); the setting only changes after you confirm, and if the dialog can't be shown protection stays ON. UH Admin's own scripts are not treated as external; external copies are.]==] },
	{ id = "sc_sec_phish", title = "Anti-Phishing", tags = "anti phishing phishing links urls addresses web address ip logger shortener impersonation roblox look alike typosquat webhook redirect lure credential domain",
		text = [==[**Anti-Phishing** (on by default) pulls the web addresses out of a third-party script (decoding escapes, string joins and base64) and rates each one; at runtime it also rates the addresses a script tries to request or open. Red flags: IP-logger domains, URL shorteners, domains that impersonate or look like Roblox (typosquats, 'roblox' inside another site's name), user@host tricks, raw IP or obfuscated / IPv6 addresses, punycode or non-ASCII hostnames, high-abuse top-level domains, login / verify wording on a non-Roblox site, free-Robux lures and Discord webhooks. Roblox's own domains are official; github.com, githubusercontent.com, gitlab.com and jsdelivr.net count as trusted hosts. At runtime a MALICIOUS destination is blocked and a SUSPICIOUS one pauses for the Execution Firewall. Limit: it judges the address text only and makes no requests, so redirect chains are not followed.]==] },
	{ id = "sc_sec_checker", title = "Script Checker and verdicts (CLEAN / SUSPICIOUS / MALICIOUS / UNVERIFIED)", tags = "script checker static analysis verdict verdicts clean suspicious malicious unverified difference meaning cache sha256 inspect source patterns what does clean mean",
		text = [==[**Script Checker** (on by default) inspects a third-party script's source before it runs, with the same static-analysis engine as the background scan plus the Anti-Phishing address check. Verdicts:
- **CLEAN**: no known bad pattern was found. This is NOT a guarantee of safety.
- **SUSPICIOUS**: risky patterns were found (for example obfuscation, remote code loading or suspicious network use); worth a human look, and the firewall pauses it.
- **MALICIOUS**: strong evidence such as login-cookie theft, webhook exfiltration or IP loggers.
- **UNVERIFIED**: the source could not be inspected: it was not visible, is over 4 MB, analysis failed or was interrupted, the chunk wasn't a string, or the executor compiled it before UH could see it (editor / clipboard / script-hub scripts). A script over 256 KB on a thread that can't yield is scanned in the background and counts as UNVERIFIED until then.
Identical sources are checked once (verified SHA-256 identity). With the checker on, an unreadable file is UNVERIFIED and blocked (fail-closed). The one exception is the verified embedded Nameless Admin source: trusted, not inspected.]==] },
	{ id = "sc_sec_firewall", title = "Execution Firewall (pause, two confirmations, block)", tags = "execution firewall pause paused confirmation confirmations type phrase run anyway understand risks block override critical loadfile dofile approval cache sha256 flagged script prompt",
		text = [==[**Execution Firewall** (on by default) stops a flagged third-party script (SUSPICIOUS, MALICIOUS or UNVERIFIED) before it runs. A red/amber 'UH SECURITY - EXECUTION PAUSED' panel lists the script, ID, verdict, severity, origin and the findings. To run it anyway you must type **I UNDERSTAND THE SECURITY RISKS** and press CONFIRM, then type **RUN ANYWAY** and press CONFIRM (two confirmations); **BLOCK** stops it, and no answer within 120 seconds counts as blocked. **Critical threats can never be overridden.** File execution (loadfile / dofile) with an UNVERIFIED verdict is blocked outright (strict fail-closed). An approval is remembered for the session only when the executor has a verified SHA-256 API (otherwise both phrases are needed every time). If the firewall is OFF, MALICIOUS scripts are still blocked (no override prompt) and the others run without a prompt. If it can't pause or can't show the panel, it blocks.]==] },
	{ id = "sc_sec_runtime", title = "Runtime Monitoring", tags = "runtime monitoring monitor guarded functions http request clipboard file write delete queue_on_teleport hookfunction hook guard exfiltration webhook cookie credential blocked runtime ops what does it watch",
		text = [==[**Runtime Monitoring** (on by default) follows what third-party scripts do AFTER they start, but only through the functions UH guards: loadstring / load (nested compiles go through the firewall), loadfile / dofile, HTTP requests (request / http_request, game:HttpGet / HttpPost, HttpService, OpenBrowserWindow), clipboard read and write, file writes and deletes (writefile, appendfile, delfile, delfolder), queue_on_teleport, and hookfunction / restorefunction. It records the scripts and their activity in Security History, blocks Roblox login data from leaving the device and device identifiers going to webhooks (critical), and every 2 seconds restores a guarded function that another script replaced (counted under 'runtime ops blocked').
Limits: a script that cached an original function before UH loaded, or reaches executor internals directly, can bypass a guard; require(assetId) and native Roblox services not reached through a guarded call are not intercepted; if UH can't identify the caller of a hooked function on your executor, ALL interception is switched off to keep UH working (Statistics then shows INACTIVE).]==] },
	{ id = "sc_sec_findings", title = "Security Findings, History, Statistics and Executor Capabilities & Limits", tags = "security findings history statistics stats executor capabilities limits clear findings history scripts intercepted scanned blocked monitored active inactive severity decision evidence panel buttons",
		text = [==[Under the External Script Protection switches: **Statistics** [ACTIVE / INACTIVE - see capabilities]: scripts intercepted, scripts scanned, malicious blocked, suspicious detected, phishing links blocked, runtime ops blocked and currently monitored scripts. **Security Findings** (button, latest 6): severity, EXT-id and name, verdict, origin, the decision (ALLOWED / BLOCKED and why) and up to 3 pieces of evidence with line numbers. **Security History** (latest 12): timestamped scan, block, decision, confirmation, network, runtime and setting-change events. **Executor Capabilities & Limits**: which interceptions work on YOUR executor ([OK], [PARTIAL], [NOT INTERCEPTABLE] or [N/A] for loadstring / load, loadfile / dofile, game:HttpGet-style colon-calls via the __namecall hook, dot-calls, clipboard, file functions and hookfunction), whether the approval cache is possible (needs a verified SHA-256 API), and the limits list. **Clear Findings & History** empties the findings and history lists (the statistics stay).]==] },
	{ id = "sc_sec_trust", title = "Trusted internal scripts vs third-party scripts", tags = "trusted internal uh admin embedded nameless admin excluded exclusion exclusions third party external copy sha256 chunk identity not treated external runners built in modules",
		text = [==[External Script Protection is for **third-party** scripts. UH Admin's own runners (P.execute, runUrl, the built-in modules) and the **embedded Nameless Admin** are intentionally excluded so the script's own features keep working; they are not supposed to be treated as external scripts. The embedded Nameless Admin is recognised by a byte-identical, verified SHA-256 match of its embedded source and is then trusted without inspection. A modified copy, or an external Nameless Admin you run yourself, never matches and is inspected like any other script, and an external script can never run under a trusted chunk identity even if it asks for the same name. The background scan lets the embedded sources through its module gate, and the built-in modules folder is report-only.]==] },
	{ id = "sc_sec_limits", title = "Security limitations (what it cannot do)", tags = "security limits limitations cannot bypass guarantee safe clean not guaranteed executor support interception editor clipboard script hub unverified require assetid redirect quarantine honest weakness",
		text = [==[What the protections can NOT do:
- **CLEAN is not 'safe'**; it only means no known pattern was found.
- Not every executor supports every interception; see **Executor Capabilities & Limits** for what yours covers. If the caller of a hooked function can't be identified, all interception is turned off.
- Scripts run from the executor's editor, clipboard or script hub are compiled by the executor before UH sees them: UNVERIFIED, runtime monitoring only.
- A script that cached an original function before UH loaded, or reaches executor internals, can bypass a guard.
- Redirect chains are judged from the address text only (no requests are made).
- require(assetId) and native Roblox services not reached through a guarded call are not intercepted.
- The background scan skips files over 6 MB, can't verify a quarantine copy without the executor's file functions, and Auto-Delete is experimental.
- UH Admin's own runners and the embedded Nameless Admin are intentionally excluded.]==] },
	{ id = "sc_sec_new", title = "What's new in security (current build)", tags = "whats new security latest changes added update recent now current what changed protection layers",
		text = [==[The security area now has two layers. **Background Malware Security** (Background Malware Scan, Auto-Delete Malware (EXPERIMENTAL) with a verified copy in UhhhhhhReanim/Quarantine, Scan Now) covers the script's own files and modules. **External Script Protection** is a separate layer for third-party scripts: five switches (**External Script Protection**, **Anti-Phishing**, **Script Checker**, **Execution Firewall**, **Runtime Monitoring**), each asking for confirmation before it can be turned off; CLEAN / SUSPICIOUS / MALICIOUS / UNVERIFIED verdicts; flagged scripts pause behind a two-phrase confirmation; plus Statistics, **Security Findings**, **Security History**, **Executor Capabilities & Limits** and **Clear Findings & History**. UH Admin's built-in scripts and the embedded Nameless Admin are excluded; external copies are not. The script's header changelog doesn't date these additions, so I describe the current build (v324) rather than a version history.]==] },
	{ id = "sc_changelog", title = "Recent changes (v293 to v300)", tags = "changelog changed change changes new version update updates latest release v293 v294 v298 v299 v300 whats new",
		text = [==[**v293** Cache UI: UI assets cached in UhhhhhhReanim/Assets/Cache UI, plus the Main page > Performance > **UI Cache** switch. **v294** per-frame write cache (colours / transparencies only pushed when changed), memoised palette and accent, cursor trail idles until the mouse moves. **v298** immersive UI motion fix: the Delta immersive UI no longer drops itself into low-end mode (slow frames / touch + low quality); default animation intensity 100%. **v299** UI animation cache (Assets/UI ANIMATION CACHE: cache.json + animations.json), pooled ripple dots, stable page cascade order. **v300** UI-only cache: cached VFX dot texture for sparkles and cursor trail, and a customization.json snapshot of your UI settings. Reanimation, movesets and other features were not touched by these versions. For the current reanimation and security systems (five methods, Extra Unanchored Reanimation, Tool Reanimation Extras, External Script Protection) ask 'what's new in reanimation' or 'what's new in security'.]==] },
}
local entTerms
-- feature families: lets follow-ups ("and with limb?", "what about wings?") stay in the same group of related features
local FAM = { sc_unanchored = "unanchored", sc_ua_limbs = "unanchored", sc_ua_extra = "unanchored", sc_ua_compare = "unanchored", sc_toolextras = "toolextras", sc_new_reanim = "reanim",
	sc_security = "security", sc_sec_bg = "security", sc_sec_ext = "security", sc_sec_phish = "security", sc_sec_checker = "security", sc_sec_firewall = "security",
	sc_sec_runtime = "security", sc_sec_findings = "security", sc_sec_trust = "security", sc_sec_limits = "security", sc_sec_new = "security" }
function Script.family(id) return FAM[id] end

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

local cats
local function loadUI()
	if uiList then return uiList end
	uiList = {}
	cats = {}
	local d = data()
	if not d then return uiList end
	if type(d.cats) == "string" then
		for line in d.cats:gmatch("[^\n]+") do
			local s, c = line:match("^(.-)\31(.*)$")
			if s then cats[s] = c end
		end
	end
	for line in d.ui:gmatch("[^\n]+") do
		local sec, ty, lab, desc = line:match("^(.-)\31(.-)\31(.-)\31(.*)$")
		if not sec then sec, ty, lab = line:match("^(.-)\31(.-)\31(.*)$") end
		if sec then
			local name, path = sec:match("^(.-)|(.*)$")
			local it = { sec = name or sec, path = path or "Main page", ty = ty, lab = lab, d = desc or "", n = nl(lab) }
			local core = (lab:gsub("%s*%b()", ""))
			if #core < 3 then core = lab end
			it.n2 = nl(core)
			it.lt = NLP.terms(core)
			it.dt = it.d ~= "" and NLP.terms(it.d) or {}
			it.st = NLP.terms(it.sec .. " " .. (cats[it.sec] or ""))
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

-- typo tolerance: same first letter, edit distance 1 (words of 5-7 letters) or 2 (8+). Returns true when t1 ~ t2.
local function near(t1, t2)
	local n1, n2 = #t1, #t2
	if n1 < 5 or n2 < 5 or math.abs(n1 - n2) > 2 or t1:sub(1, 1) ~= t2:sub(1, 1) then return false end
	local lim = math.min(n1, n2) >= 8 and 2 or 1
	local prev = {}
	for j = 0, n2 do prev[j] = j end
	for i = 1, n1 do
		local cur, best = { [0] = i }, i
		for j = 1, n2 do
			local c = t1:byte(i) == t2:byte(j) and 0 or 1
			local v = math.min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + c)
			cur[j] = v
			if v < best then best = v end
		end
		if best > lim then return false end
		prev = cur
	end
	return prev[n2] <= lim
end

function Script.findUI(a)
	local list, q = loadUI(), qset(a)
	local nq = " " .. nl(a.raw) .. " "
	local nt = #a.terms
	local out = {}
	for _, it in ipairs(list) do
		local m = 0
		for _, t in ipairs(it.lt) do if q[t] then m = m + 1 end end
		local exact = (#it.n >= 4 and nq:find(" " .. it.n .. " ", 1, true) ~= nil) or (#it.n2 >= 4 and nq:find(" " .. it.n2 .. " ", 1, true) ~= nil)
		local fz = 0
		if m == 0 and not exact and nt >= 1 and nt <= 4 then
			for _, qt in ipairs(a.terms) do
				for _, lt in ipairs(it.lt) do if qt ~= lt and near(qt, lt) then fz = fz + 1 break end end
			end
			if fz > 0 then m = fz * 0.8 end
		end
		-- purpose search: the question's words appear in the control's description ("walk through walls" -> Noclip)
		local dm = 0
		if m == 0 and nt >= 2 then
			for _, t in ipairs(it.dt) do if q[t] then dm = dm + 1 end end
		end
		if m > 0 or exact then
			if m > 0 and m < 1 then m = 1 end -- fuzzy hit counts as one matched word
			local cov = #it.lt > 0 and m / #it.lt or 0
			out[#out + 1] = { it = it, cov = cov, m = m, exact = exact, sc = m * cov + (exact and 3 or 0) }
		elseif dm >= 2 and dm / nt >= 0.5 then
			out[#out + 1] = { it = it, cov = dm / nt, m = dm, exact = false, purpose = true, sc = dm * 0.6 * (dm / nt) }
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

local function labClean(it) return (it.lab:gsub("%s*>%s*$", "")) end

local function where(it)
	local c = cats and cats[it.sec]
	local s = "*" .. it.sec .. "*, " .. (it.path == "Main page" and "on the Main page" or ("under " .. it.path))
	if c and it.path == "Main page" then s = s .. " (also listed in Feature Center > " .. c .. ")" end
	return s
end

local function firstSentence(s)
	local f = s:match("^(.-[%.!%?])%s") or s
	return f
end

-- mode "explain": description first. mode "where": location first, short description after.
local function fmtUI(h, l, mode)
	local it = h.it
	local ty = TYPE[it.ty] or "control"
	local s
	if mode == "explain" and it.d ~= "" then
		s = string.format("**%s** (%s): %s Find it in %s.", labClean(it), ty, it.d, where(it))
	else
		s = string.format("**%s** is a %s in %s.", labClean(it), ty, where(it))
		if it.d ~= "" then s = s .. " " .. (mode == "where" and firstSentence(it.d) or it.d) end
	end
	if l and l.ok and l.set and not l.set[it.n] then s = s .. " *(I can't see it in the live UI right now, so the script may have changed.)*" end
	return s
end

local EXPLAIN = { "what does", "what do", "what is", "what's", "whats", "explain", "mean", "purpose", "used for", "use for", "do?", "does it", "for?", "tell me about", "how does" }
local function wantsExplain(lo)
	for _, w in ipairs(EXPLAIN) do if lo:find(w, 1, true) then return true end end
	return false
end

-- last controls I described, so "what does that do?" / "where is it?" can use them
Script.lastItems = nil
function Script.last() return Script.lastItems end

function Script.describeLast(lo)
	local li = Script.lastItems
	if not li or #li == 0 then return nil end
	local it = li[1]
	local l = Script.sync(false)
	local h = { it = it }
	if lo:find("where", 1, true) or lo:find("find", 1, true) or lo:find("open", 1, true) then return fmtUI(h, l, "where") end
	return fmtUI(h, l, "explain")
end

-- ===== browse: overview of the script + listing a section / category =====
local OVERVIEW = {
	{ "Live Players / Moderation", "who is in the game, join a player, remote moderation (staff roles), owner alerts" },
	{ "Performance / Graphics", "Low End UI Mode, Performance Profile, Anti Lag, Hide All Players, transitions and effects" },
	{ "Reanimation / Character", "the Reanimator (Limb, Hats, Tool, Ragdoll), hitboxes, character settings, Fly, WalkSpeed, scale, internals" },
	{ "Movesets / Dances", "movesets, dances and dance keybinds" },
	{ "Fling / Interaction", "Fling Method, Click Fling, Toggle Kill, Kill All, Key+Click Teleport" },
	{ "Teleport / Servers", "teleports, LastSafe, Server Hop, Rejoin, Auto Execute" },
	{ "Customization / Settings", "UI Theme, Roblox engine settings, particles, asset loading, the Customization page" },
	{ "Music / Sound", "intro choice, UI music, Skip Intro" },
	{ "Script Hub / Modules", "Nooby's Script Hub, module loading mode, reload modules" },
	{ "Marketplace", "download and delete user-made modules, movesets and dances" },
	{ "Security / Danger Zone", "malware scan, Scan Now, clear downloaded content" },
	{ "Info / Logs", "credits, changelogs, init logs" },
}

function Script.tour()
	loadUI()
	local t = { "Here is the map of the script (build " .. Script.build() .. "). Everything lives on the **Main page**, and **Feature Center >** sorts every option into these categories:" }
	for _, o in ipairs(OVERVIEW) do t[#t + 1] = "- **" .. o[1] .. "**: " .. o[2] end
	t[#t + 1] = "Two more spots: **Customization >** (colors, triangle, intro, notifications, chat) and the floating Uh Admin triangle for commands. Ask me \"what does Noclip do\", \"where is Server Hop\" or \"what's in the Fling options\" and I'll go into detail."
	return table.concat(t, "\n")
end

local function overlapScore(q, terms)
	if #terms == 0 then return 0, 0 end
	local m = 0
	for _, t in ipairs(terms) do if q[t] then m = m + 1 end end
	return m, m / #terms
end

function Script.browse(raw)
	if not data() then return nil end
	local lo = raw:lower()
	local asks = lo:find("what.*%f[%a]options") or lo:find("what.*%f[%a]settings") or lo:find("what.*%f[%a]buttons") or lo:find("what.*%f[%a]toggles") or lo:find("what.*%f[%a]controls")
		or lo:find("list.*%f[%a]options") or lo:find("list.*%f[%a]settings") or lo:find("list.*%f[%a]buttons") or lo:find("list.*%f[%a]features") or lo:find("what.*%f[%a]features")
		or lo:find("what.*is in") or lo:find("what.*are in") or lo:find("what.*inside") or lo:find("show me.*%f[%a]options") or lo:find("each button") or lo:find("every button")
	local tour = lo:find("tour") or lo:find("what can i do") or lo:find("getting started") or lo:find("where do i start") or lo:find("where should i start")
		or lo:find("what features") or lo:find("all features") or lo:find("every feature") or lo:find("what does this script") or lo:find("what is this script") or lo:find("script overview")
		or lo:find("show me around") or lo:find("help me navigate") or lo:find("how do i navigate")
	if not (asks or tour) then return nil end
	local list = loadUI()
	local q = {}
	for _, t in ipairs(NLP.terms(raw)) do q[t] = true end
	local best, bs, bkind
	local seen = {}
	for _, it in ipairs(list) do
		if not seen[it.sec] then
			seen[it.sec] = true
			local nm = NLP.terms(it.sec)
			local m, cov = overlapScore(q, nm)
			local sc = m > 0 and (cov * 2 + m * 0.5) or 0
			local ct = cats[it.sec] and NLP.terms(cats[it.sec]) or {}
			local m2, cov2 = overlapScore(q, ct)
			if m2 > 0 and cov2 * 1.5 + m2 * 0.3 > sc then sc = cov2 * 1.5 + m2 * 0.3 end
			if sc > (bs or 0) then best, bs = it.sec, sc end
		end
	end
	if best and bs >= 1.0 then
		local out, n = {}, 0
		local path
		for _, it in ipairs(list) do
			if it.sec == best then
				n = n + 1
				path = path or it.path
				if n <= 24 then out[#out + 1] = "- **" .. labClean(it) .. "** (" .. (TYPE[it.ty] or "control") .. ")" .. (it.d ~= "" and (": " .. firstSentence(it.d)) or "") end
			end
		end
		if n > 0 then
			local head = string.format("**%s** has %d controls (%s):", best, n, path == "Main page" and "Main page" or path)
			return head .. "\n" .. table.concat(out, "\n") .. (n > 24 and ("\n...and " .. (n - 24) .. " more.") or "") .. "\nAsk about any of them for the full explanation.", { best }
		end
	end
	if tour then return Script.tour() end
	return nil
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
	local top0 = ui[1]
	local precise = top0 and (top0.exact or (top0.m >= 2 and top0.cov >= 0.5)) and not top0.purpose
	local locQ = lo:find("where", 1, true) or lo:find("find", 1, true) or lo:find("open", 1, true)
	local hasUI = top0 and top0.sc >= 1 and not top0.purpose

	-- explicit commands (only when the question looks like a command question or the token is prefixed)
	local prefixed = lo:find("[%.;:]%a%a%a") ~= nil
	if #ex > 0 and not (cmdWord or prefixed) then
		-- plain words only count when they are a command's real name, not one of its aliases ("walk" -> follow)
		local words, keep = {}, {}
		for w in lo:gmatch("[%w_]+") do words[w] = true end
		for _, c in ipairs(ex) do
			-- when a control matches precisely, a command only joins if it carries the same name as that control
			if words[c.n] and not GENERIC[c.n] and not ((precise or (locQ and hasUI)) and nl(top0.it.lab) ~= c.n) then keep[#keep + 1] = c end
		end
		ex = keep
	end
	if #ex > 0 and (cmdWord or prefixed or (trig and #a.terms <= 4 and not (docs[1] and docs[1].sc >= 4))) then
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

	local top = ui[1]
	local uiOk = top and ((top.exact) or (top.cov >= 0.6 and top.m >= 1 and (trig or top.m >= 2)) or (top.cov >= 0.5 and trig and top.m >= 2) or (top.cov >= 0.5 and trig and top.m >= 1 and #a.terms <= 3) or (top.purpose and top.sc >= 1.2))
	local explain = wantsExplain(lo)
	-- whole-system questions ("how does X work", "explain the X system", differences, what's new) want the topic note even when a single control matches precisely
	local broad = lo:find("%f[%a]system%f[%A]") or lo:find("overview", 1, true) or lo:find("structure", 1, true) or lo:find("%f[%a]works?%f[%A]") or lo:find("differ", 1, true) or lo:find("versus", 1, true)
		or lo:find("%f[%a]vs%f[%A]") or lo:find("compare", 1, true) or lo:find("%f[%a]new%f[%A]") or lo:find("%f[%a]limits?%f[%A]") or lo:find("limitation", 1, true)
	local asksWhere = lo:find("where", 1, true) or lo:find("find", 1, true) or lo:find("open", 1, true) or lo:find("how do i get", 1, true)

	-- a precise control match beats the broad topic notes; broad notes still follow for general "how does X work" questions
	if docs[1] and (docs[1].m >= 2 or docs[1].sc >= 4 or (docs[1].m >= 1 and #a.terms <= 3)) and (docs[1].sc >= 3 or (docs[1].m >= 1 and #a.terms <= 3 and docs[1].sc >= 2.4)) and not (uiOk and precise and (explain or asksWhere) and not (broad and docs[1].sc >= 6)) then
		out[#out + 1] = docs[1].e.text
		ids[#ids + 1] = docs[1].e.id
		strong = true
		if docs[2] and docs[2].sc >= docs[1].sc * 0.75 and docs[2].m >= 2 then out[#out + 1] = docs[2].e.text; ids[#ids + 1] = docs[2].e.id end
	end

	if uiOk then
		local l = Script.sync(false)
		local t, picked = {}, {}
		local mode = explain and "explain" or (asksWhere and "where" or "explain")
		for i = 1, math.min(3, #ui) do
			if ui[i].sc >= top.sc * 0.6 and (ui[i].exact or ui[i].cov >= 0.5 or ui[i].purpose) then
				t[#t + 1] = fmtUI(ui[i], l, mode)
				picked[#picked + 1] = ui[i].it
			end
		end
		if #t > 0 then
			if #t > 1 then
				out[#out + 1] = (top.purpose and "These look like what you're after:\n- " or "Closest matches in the script:\n- ") .. table.concat(t, "\n- ")
			else
				out[#out + 1] = (top.purpose and "That sounds like this one: " or "") .. t[1]
			end
			Script.lastItems = picked
			if #picked == 1 then
				local all, idx = loadUI(), nil
				for k, it in ipairs(all) do if it == picked[1] then idx = k break end end
				local sib = {}
				if idx then
					for k = idx + 1, #all do
						if all[k].sec == picked[1].sec then sib[#sib + 1] = "**" .. labClean(all[k]) .. "**" end
						if #sib >= 3 then break end
					end
					if #sib == 0 then
						for k = idx - 1, 1, -1 do
							if all[k].sec == picked[1].sec then sib[#sib + 1] = "**" .. labClean(all[k]) .. "**" end
							if #sib >= 3 then break end
						end
					end
				end
				if #sib > 0 then out[#out] = out[#out] .. "\n\nNearby in the same section: " .. table.concat(sib, ", ") .. "." end
			end
			strong = true
		end
	end

	if #out == 0 then
		-- weak fallback so Generator can still point at something real
		if ui[1] and ui[1].sc >= 1 and (kcov or 0) < 0.34 then
			Script.lastItems = { ui[1].it }
			return { text = "Closest control I know in the script: " .. fmtUI(ui[1], Script.sync(false), "where"), ids = {}, strong = false }
		end
		-- an explicit question about what this script has/supports with no match anywhere: say so instead of guessing
		if (lo:find("the script", 1, true) or lo:find("this script", 1, true)) and (lo:find("have", 1, true) or lo:find("support", 1, true) or lo:find("feature", 1, true) or lo:find("include", 1, true) or lo:find("does it", 1, true) or lo:find("can it", 1, true)) then
			return { text = "I don't have a control, command or note matching that in this script's map (build " .. Script.build() .. "), so I won't guess. Ask me for a tour of the script, or `/sync` to compare my map with the live UI.", ids = {}, strong = true }
		end
		return nil
	end
	return { text = table.concat(out, "\n\n"), ids = ids, strong = strong, fam = ids[1] and FAM[ids[1]] or nil }
end

return Script
