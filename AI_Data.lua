-- AI_Data: rebuilt from Nooby's UH Modded Reanimation (UhhhhhhVersion V10, UHMergeBuild a_very_cool_script_v42, newest header revision v324): five reanimation methods, Extra Unanchored, Tool Reanimation Extras, full Security + External Script Protection map (UI map with per-control descriptions + Uh Admin / Nameless Admin command registry). Loaded lazily by AI_Script.
local D = {}
D.build = "v324"
D.source = "Nooby's UH Modded Reanimation (UhhhhhhVersion V10, UHMergeBuild a_very_cool_script_v42, header revision v324)"
-- ui line: Section|Path <US> Type(B button, S toggle/slider, D dropdown, T text box, L color picker) <US> Label <US> Description
D.ui = [=====[
Owner broadcast (owner only)|Main pageBSend announcementOwner only: sends the text you typed (max 200 characters) as an announcement to every user of the script.
Owner broadcast (owner only)|Main pageBCopy backend (announcement_server.js)Owner only: copies the Node.js backend that serves announcements to your clipboard so you can host it.
Intro settings|Main pageDIntroPicks which startup intro plays: Original, Moonlight, Jealousy, lil peep, Liquid Smooth, Thriller, Perfect Face, The Aura Farmer, In The End, Impostor Syndrome, Paparazzi, Baby One More Time or Survivor. Picking one starts downloading its song.
Intro settings|Main pageSSkip IntroSkips the intro animation on start.
Intro settings|Main pageSTransition BlurAdds a soft blur while pages slide in and out.
Intro settings|Main pageSFancy TransitionsTurns the animated page transitions on or off.
Intro settings|Main pageSExtra UI SoundsPlays extra click and transition sounds in the UI.
Intro settings|Main pageSAmbient FXTurns the ambient background effects of the UI on or off.
Navigation|Main pageBCustomization >Opens the Customization page: colors, triangle, intro text, notifications, chat styling, proportions and more.
Navigation|Main pageDUI ThemeSwitches the whole look of the script. Presets include RGB/Default, ALONE, Oxide, Patchma Hub, Genesis V4, Crimson, r/masterhacker, Homer Simpson, Immortality Lord, LIGHT RGB, LIGHT ALONE, Roserika, FastTracker II Blue, Cherry Blossom, Sakura, Tommorow Night 80s, User Defined and Modjo Disco Sunset.
Navigation|Main pageBFeature Center >Opens a menu that lists every option of the main page sorted into categories (Live Players, Performance, Reanimation, Movesets, Fling, Teleport, Customization, Music, Script Hub, Marketplace, Security, Info). Good place to start if you cannot find something.
Navigation|Main pageBLive Players >Opens the live players page: active players list with search, Join Player, remote moderation and owner alerts.
Navigation|Main pageBPerformance Monitor >Opens live performance graphs (FPS and memory); the Pause button freezes the graphs.
Navigation|Main pageBMusic >Opens the music page where the script UI music is controlled.
Navigation|Main pageBJARVIS >Opens me, the built-in offline assistant. I answer questions about the script, Roblox and reanimation, and remember what you teach me.
Navigation|Main pageBNooby's Script Hub (NOT FROM SCRIPTHUB) >Opens Nooby's own list of scripts. Tap a script to run it, or use 'Run all' to run the whole list.
Navigation|Main pageBCreditsOpens the credits page with the people and projects the script builds on.
Navigation|Main pageBChangelogsOpens the list of changes between script versions.
Navigation|Main pageBInit LogsOpens the initialization log shown when the script starts: errors, warnings and security notices from module loading.
Visual Effects (Roblox engine)|Main pageSFast Particle EffectsSets a Roblox fast-flag so particles render cheaper. Needs an executor with setfflag support.
Visual Effects (Roblox engine)|Main pageBReload Render AssetsTells Roblox to reload its render assets, which can fix missing or stuck textures.
Asset loading|Main pageSPreload Assets On LoadPreloads the game assets automatically when the game loads, so they stream in before you need them.
Asset loading|Main pageBLoad Game AssetsPreloads the game assets right now.
Reanimator|Main pageDReanimatorChooses the reanimation method. Five methods: Limb Reanimator, Hats Reanimator, Tool Reanimation, Ragdoll Reanimator and Unanchored Reanimation. The block right under it ("-=+ <method> Config +=-") shows the settings of the chosen method.
Reanimator|Main pageB* Reanimate *Starts the selected reanimation. While it runs the button becomes a stop button and the status line shows "Running: <method>"; pressing it again deanimates.
Reanimator|Main pageBShow Reanimate HitboxesShows the hitboxes of your reanimated character (what the server sees). Only works while reanimated.
Reanimator|Main pageBRefresh Reanimate CharacterRebuilds the reanimate character if it looks wrong.
Limb Reanimator config|Main page > Reanimator dropdown > Limb ReanimatorDRootPart ModeHow the reanimated root part is handled. Pick a different mode if your character behaves oddly.
Limb Reanimator config|Main page > Reanimator dropdown > Limb ReanimatorDRootPart VelocityVelocity applied to the root part: No Velocity, Follow Character or Fling-like.
Limb Reanimator config|Main page > Reanimator dropdown > Limb ReanimatorDInit ModeHow the reanimation starts: Reset Character, CDSB + Reset, or CDSB + SSE + Kill. Try the next one if a game rejects the first.
Limb Reanimator config|Main page > Reanimator dropdown > Limb ReanimatorSShow me how I look!Replicates your reanimated look to yourself at 10 FPS so you can see what other players see.
Limb Reanimator config|Main page > Reanimator dropdown > Limb ReanimatorSTarget Fling EnabledLets the reanimated character fling targets (Click Fling / Toggle Kill need this). Everyone you touch loses network ownership.
Limb Reanimator config|Main page > Reanimator dropdown > Limb ReanimatorBCheck Limb CompatibilitySpawn a character first, then press it. It checks game animations, voice chat players, dynamic faces, the game environment and R6/R15 and tells you whether Limb Reanimator will work here.
Limb Reanimator config|Main page > Reanimator dropdown > Limb ReanimatorBDump Fake Character State (console + clipboard)Copies a debug dump of the fake character to the console and clipboard, for bug reports.
Extra Unanchored Reanimation (Limb / Ragdoll)|Main page > Reanimator dropdown > Limb Reanimator or Ragdoll ReanimatorSExtra Unanchored ReanimationOff by default. Block "-=+ Extra Unanchored Reanimation +=-" at the bottom of the Limb and Ragdoll config. ON: while that Limb/Ragdoll reanimation runs, loose unanchored parts from the map become Wings, a Tail and a Halo Aura on your FAKE (reanimated) character, not on the real one. Parts are only moved once the engine confirms you simulate them. When ON it shows the same options as Unanchored Reanimation (Wings, Wing Animation, Tail, Tail Animation, Halo Aura, Part Finder, Automatic Part Search, Search Radius (studs), Teleport Confirmation) but not the tools/limbs switches or Torso Offset. It adds to Limb/Ragdoll reanimation; it is not the standalone Unanchored Reanimation method.
Ragdoll Reanimator config|Main page > Reanimator dropdown > Ragdoll ReanimatorLRagdoll StiffnessHow hard the ragdoll limbs are pulled toward the pose. Higher is stiffer. Applies on the next Reanimate. Ragdoll Reanimation detaches your real limbs into BallSocket ragdoll limbs and drives them to the reanimated pose; it also uses the Limb Reanimator settings. (Range 10-200.) Ragdoll uses the Limb Reanimator settings below it, including Extra Unanchored Reanimation.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorSPermadeath (dolteddown's pd)Uses dolteddown's permadeath so your real character stays dead while the hats are driven. Needs replicatesignal support from your executor.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorSAuto Force Respawn when stuckIf the reanimate never finishes, respawns you automatically after the stuck timeout.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorLStuck timeout (seconds)How long to wait before Auto Force Respawn kicks in. (Range 5-60.)
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorDrespawntpWhere your character goes after a force respawn: The Void, Behind ReanimCharacter, Randomtp near, At spawn, or Under ReanimCharacter (Keep Streamed).
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorSHat CollideMakes the hats collide so they act like solid limbs. If your hats get voided, try changing Torso Offset.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorDTorso OffsetChanges the torso offset used by Hat Collide. Change it if hats are voided when Hat Collide is on.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorSEnsure All HatsOnly reanimates when every hat is accounted for.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorDEnsure Hat CollideMakes sure hats collide: Off, Atleast one, or Atleast #hats - 2.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorSHat FlingFlings people with your hats. Do not combine with Target Fling unless you want a walkfling.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorSHat Spin FlingSpins your hats to fling. Combining it with target fling makes the character look glitchy.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorDTarget Fling MethodWhich method the hats use to fling a clicked target.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorSTool HoldingLets the reanimated character hold tools.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorDtoolanim MethodTool animation style: Disabled or Sword.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorBRebuild Hat MapUse it when your rig was built wrong or you switched to a new rig; it rebuilds which hat becomes which limb.
Hats Reanimator config|Main page > Reanimator dropdown > Hats ReanimatorBForce Respawn NowRespawns you immediately without waiting for the stuck timeout.
Tool Reanimation Extras (Hats)|Main page > Reanimator dropdown > Hats ReanimatorSAdd Tool Reanimation as ExtraOff by default. Block "-=+ Tool Reanimation Extras +=-" at the bottom of the Hats Reanimator config (Hats only). Master switch for cosmetic effects built from your SPARE Tool handles (never the tools in use). It is not Tool Reanimation itself: it does not replace your body parts. When ON the four effect switches appear below it.
Tool Reanimation Extras (Hats)|Main page > Reanimator dropdown > Hats ReanimatorSWingsTool Extras effect (shown when Add Tool Reanimation as Extra is ON). Needs 6 spare tools. Not the same switch as Wings in Unanchored Reanimation, which uses loose map parts.
Tool Reanimation Extras (Hats)|Main page > Reanimator dropdown > Hats ReanimatorSHaloTool Extras effect. Needs 3 spare tools.
Tool Reanimation Extras (Hats)|Main page > Reanimator dropdown > Hats ReanimatorSTailTool Extras effect. Needs 4 spare tools. Not the same switch as Tail in Unanchored Reanimation.
Tool Reanimation Extras (Hats)|Main page > Reanimator dropdown > Hats ReanimatorSFloating AuraTool Extras effect. Takes ALL the tools left after the other enabled effects. Effects are filled in order Wings, Halo, Tail, Floating Aura; if there are not enough spare tools the effect is skipped with a notification.
Tool Reanimation config|Main page > Reanimator dropdown > Tool ReanimationDTool MethodOriginal equips your tools, breaks the character's joints and drives the freed handles. Corpse Claim arms every tool, kills the real character so the server frees all grips together, then drives the tools.
Tool Reanimation config|Main page > Reanimator dropdown > Tool ReanimationSPermadeath (dolteddown's pd)Keeps your real character alive so the tools stay yours. Off means the tools are lost when the game respawns you.
Tool Reanimation config|Main page > Reanimator dropdown > Tool ReanimationSAuto Force Respawn when stuckRespawns you automatically if the reanimate never finishes.
Tool Reanimation config|Main page > Reanimator dropdown > Tool ReanimationLStuck timeout (seconds)Slider (5-60) for Auto Force Respawn.
Tool Reanimation config|Main page > Reanimator dropdown > Tool ReanimationSTool CollideMakes the tool limbs collide with the world.
Tool Reanimation config|Main page > Reanimator dropdown > Tool ReanimationSTarget Fling EnabledEnables fling for tool reanimation; the biggest tool handle you own is thrown at fling targets.
Tool Reanimation config|Main page > Reanimator dropdown > Tool ReanimationBForce Respawn NowRespawns you immediately.
Unanchored Reanimation config|Main page > Reanimator dropdown > Unanchored ReanimationSUse unanchored parts as toolsOn by default. Loose unanchored map parts become Wings / Tail / Halo Aura (the tool-style handling). Off: those effects are not built from parts in the standalone or unanchored-limb run.
Unanchored Reanimation config|Main page > Reanimator dropdown > Unanchored ReanimationSUse unanchored parts as limbsOff by default. On: pressing Reanimate (with Automatic Part Search on) asks whether to teleport to a suitable part, resets your character like the Limb Reanimator, and uses up to 6 parts (5, 4... if fewer exist) as the limbs of your reanimated character; one part is never used twice. This runs its own unanchored-limb lifecycle, not the Limb Reanimator.
Unanchored Reanimation config|Main page > Reanimator dropdown > Unanchored ReanimationDTorso OffsetWhere your real root / torso is placed during an unanchored-limb run: Nooby's Method, RootPart Streamed, or RootPart in Sky/Void. (Unanchored Reanimation has its own Torso Offset; Hats Reanimator has a different one.)
Unanchored Reanimation config|Main page > Reanimator dropdown > Unanchored ReanimationSWingsOn by default. Loose parts become Wings (targets up to 20 parts). Shows the Wing Animation dropdown when on.
Unanchored Reanimation config|Main page > Reanimator dropdown > Unanchored ReanimationDWing AnimationFlap or Idle.
Unanchored Reanimation config|Main page > Reanimator dropdown > Unanchored ReanimationSTailOn by default. Loose parts become a Tail (targets 6 parts). Shows the Tail Animation dropdown when on.
Unanchored Reanimation config|Main page > Reanimator dropdown > Unanchored ReanimationDTail AnimationWag or Slash Tail.
Unanchored Reanimation config|Main page > Reanimator dropdown > Unanchored ReanimationSHalo AuraOn by default. Loose parts orbit as a Halo Aura (targets 8 parts).
Unanchored Reanimation config|Main page > Reanimator dropdown > Unanchored ReanimationSAutomatic Part SearchOn by default; the Part Finder block above it shows a "Detector:" status line (discovered / suitable / pending / acquired / attached / ownership lost). ON: the script looks for suitable unanchored parts within the Search Radius. OFF: no new parts are searched or claimed; parts already held keep animating.
Unanchored Reanimation config|Main page > Reanimator dropdown > Unanchored ReanimationLSearch Radius (studs)Slider 20-500 studs (default 150), shown while Automatic Part Search is on.
Unanchored Reanimation config|Main page > Reanimator dropdown > Unanchored ReanimationSTeleport ConfirmationOn by default, shown while Automatic Part Search is on. ON: a Yes / No prompt appears when a suitable part is out of reach and you are only teleported after pressing YES. OFF: no prompt and no teleport; only parts already in range are used.
Reanimate Character Settings|Main pageSInfinite JumpLets the reanimated character jump again in mid-air.
Reanimate Character Settings|Main pageSNoclipLets the reanimated character pass through walls and objects.
Reanimate Character Settings|Main pageSSmooth CameraSmooths the camera while reanimated.
Reanimate Character Settings|Main pageSFirst Person BodyShows your body in first person.
Reanimate Character Settings|Main pageSAllow ShiftlockAllows Shift Lock while reanimated.
Reanimate Character Settings|Main pageSCan Sit on SeatsLets the reanimated character sit on seats.
Reanimate Character Settings|Main pageSCan Pickup ToolsLets the reanimated character pick up tools from the ground.
Reanimate Character Settings|Main pageSApply Scale to GravityScales gravity with the character scale so big or small characters fall naturally.
Reanimate Character Settings|Main pageSVoid FloatKeeps the character floating instead of falling when it goes into the void.
Fly & WalkSpeed|Main pageSCustom WalkSpeedTurns on your own WalkSpeed value.
Fly & WalkSpeed|Main pageLWalkSpeedThe WalkSpeed used when Custom WalkSpeed is on. (Range 1-250.)
Fly & WalkSpeed|Main pageSFly  (E = up, Q = down)Turns flying on or off. E goes up, Q goes down.
Fly & WalkSpeed|Main pageLFly SpeedHow fast you fly. (Range 5-300.)
Fly & WalkSpeed|Main pageDFly Toggle KeyPick a key (None, F, Y, O, I) that toggles flying.
Fly & WalkSpeed|Main pageBForce Sit (2x to remove gyro)Forces your character to sit. Press it twice to remove the gyro it adds.
Fly & WalkSpeed|Main pageLCharacter ScaleResizes the reanimated character. (Range 0.5-5.)
Fly & WalkSpeed|Main pageLPlaceholdersTransparency of the placeholder parts shown for your real limbs. (Range 0-1.)
Performance|Main pageSLow End UI ModeFixes lag spikes on weak devices: simpler 3D triangle and a basic UI without effects. Turn it off to get everything back.
Performance|Main pageSUI CacheStores the UI meshes, textures and graphics in UhhhhhhReanim/Assets/Cache UI and reuses them; remembers text sizes and skips unchanged per-frame colour writes. Delete that folder to rebuild it. Applies to the 3D triangle and effects on next launch.
Performance|Main pageDPerformance ProfileAuto, Ultra, High, Balanced, Low or Potato. Auto adapts to your device and FPS; picking one manually turns automatic adjustments off.
Performance|Main pageSAnti Lag (remove all textures)Removes textures in the game to raise FPS.
Performance|Main pageSHide All PlayersHides every other player on your screen.
Fling|Main pageDFling MethodChooses how flings work: Default (spins into the target at high velocity), Weak (just trips them), Nooby's Method (clips inside their root part and flings them to the nullzone), NaN State, Fling 1 (Nameless/Source), Fling 2 (Carpet), Fling 3 (Hidden/Flight) or Alt-fling (your Nameless Admin alt does the flinging).
Fling|Main pageBAlt-fling: resend commandSends the alt-fling command to your alt again. Only works with the Alt-fling method.
Fling|Main pageBRequest Served UserType a username in the box above it and press this to ask that player to be your Served User for alt-fling (it waits for their admin whitelist whisper).
Fling|Main pageBView users I'm Alt Flinger forShows the users you currently serve as their alt flinger.
Fling|Main pageSClick FlingFlings whoever you click, using the selected Fling Method.
Fling|Main pageSToggle KillAutomatically kills targets with an equipped damage tool (sword). Needs Target Fling enabled and an executor with firetouchinterest.
Fling|Main pageSYa kids tool kill optionChanges how Toggle Kill uses tools (kids-tool variant).
Fling|Main pageBKill AllRuns through every player and tries to kill them. Needs Toggle Kill requirements.
Teleport|Main pageSKey+Click TeleportHold the TP key and click to teleport the reanimated character to the click position.
Teleport|Main pageDTP KeyChooses the key for Key+Click Teleport (Left Ctrl default, inno's pick, Tab, Z, X, F, T).
Teleport|Main pageSTP Key HeldMakes the TP key behave as hold-to-teleport.
Teleport|Main pageBTeleport to 0, highest, 0Teleports to the top of the map at X=0, Z=0.
Teleport|Main pageBTeleport to 'LastSafe'Teleports to the last safe spot under the void height.
Teleport|Main pageTTeleport To PlayerType a player name (partial works) and the character teleports to them.
Server Hop|Main pageDHop ModeRandom server, Fewest players or Most players (not full).
Server Hop|Main pageSSkip servers I visited (1h)Avoids servers you were in during the last hour.
Server Hop|Main pageSAuto Execute after hop / rejoinRuns this script again in the new server. It finds its own file in your executor workspace folder, so normally you set nothing.
Server Hop|Main pageToverride: file name or link (optional)Optional file name or raw https:// link for Auto Execute if the script cannot find its own file.
Server Hop|Main pageBServer HopTeleports you to another server using the Hop Mode.
Server Hop|Main pageBRejoin This ServerRejoins the same server.
Internals Settings|Main pageSHook LoadAnimationHooks LoadAnimation for the reanimated character (may not work for you on some executors).
Internals Settings|Main pageSUse Physics GlueInternals for physics-based reanimation like hat reanimator. Do not use tool fling with physics glue.
Internals Settings|Main pageSPatchma-like NetlessKeeps network ownership of your parts so they do not drift or snap back.
Internals Settings|Main pageLNetless VelocityThe velocity used by Patchma-like Netless. (Range 25.01-30.)
Internals Settings|Main pageSApply RotVelocityApplies rotational velocity to parts; toggle it if limbs spin.
Movesets / Dances|Main pageBMovesets >Opens the moveset list. Open one, press Use Moveset and its Configuration section appears.
Movesets / Dances|Main pageBDances >Opens the dance list. Open one and press Play Dance (it becomes Stop Dance).
Movesets / Dances|Main pageBDance Keybinds >Opens the dance keybind list (a key per dance, M switches page).
Movesets / Dances|Main pageSDance Keybinds EnabledTurns the dance keybinds on so pressing the key plays that dance.
Marketplace|Main pageBStore >The Marketplace page (the button says Store or Marketplace). Download and delete user-made modules, movesets and dances.
Marketplace|Main pageBSee what we have >Browse the online user modules (Buy Module for... downloads one).
Marketplace|Main pageBSee what you have >Shows the modules you already downloaded; open one to Redownload/Update or Delete Module.
Marketplace|Main pageBBuy Module forDownloads the module from the marketplace. Reload your modules afterwards to apply it.
Marketplace|Main pageBRedownload/UpdateDeletes the local copy of that module and downloads it again.
Marketplace|Main pageBDelete ModuleDeletes the module. It asks for several clicks to confirm.
Modules management|Main pageDModule LoadingHow modules load: Default, Splitted (2 at a time) or Instant (all at once). Use a gentler mode on weak devices.
Modules management|Main pageBReload ModulesReloads every module with a short loading screen.
Modules management|Main pageBReload User ModulesReloads only your downloaded user modules.
Live players|Main pageTSearch name / game / serverSearches the ACTIVE PLAYERS list by name, game or server.
Live players|Main pageTTarget (tap a player or type username / ID)The target for the remote moderation buttons below.
Live players|Main pageBKillRemote moderation (staff roles only): kills the target.
Live players|Main pageBDeanimateRemote moderation: stops the target's reanimation.
Live players|Main pageBKickRemote moderation: kicks the target.
Live players|Main pageBBanRemote moderation: bans the target.
Live players|Main pageBUnbanRemote moderation: removes the ban from the target.
Security|Main pageSBackground Malware ScanOn by default. Quietly scans .lua / .luau / .txt files in UhhhhhhReanim/Modules and the executor workspace for malicious patterns (a new pass about every 5 minutes) and checks modules before they load. Skips Content / Muzik / Assets / Quarantine; the built-in modules are report-only. MALICIOUS modules are blocked at load, SUSPICIOUS ones only warn. Files over 6 MB are skipped; modules over 16 MB are blocked as unscannable. A clean result is not a guarantee of safety.
Security|Main pageSAuto-Delete Malware (EXPERIMENTAL)Off by default. Only for MALICIOUS verdicts with confidence of at least 0.75 and not in report-only folders: the file is first copied to UhhhhhhReanim/Quarantine (the copy is read back and verified), then deleted. If the executor lacks writefile / readfile / isfile / delfile, the copy fails, or the file changed since the scan, it is kept in place. Experimental: it can delete a safe file by mistake.
Security|Main pageBScan NowStarts a new background scan immediately (clears the scan cache). Needs Background Malware Scan on (otherwise it tells you to turn it on); if a scan is already running it says so.
External Script Protection|Main pageSExternal Script ProtectionOn by default. Master switch for guarding third-party scripts (editor, clipboard, script hubs, ScriptBlox, GitHub, Pastebin, loadstring / loadfile). UH Admin's own scripts and the embedded Nameless Admin are not touched; an external copy of them is still checked. Turning any of the five protection switches OFF first shows a confirmation dialog (KEEP PROTECTION ON / TURN OFF PROTECTION); if the dialog cannot be shown, protection stays ON.
External Script Protection|Main pageSAnti-PhishingOn by default. Analyses the web addresses found in third-party scripts (also decoded from escapes, string joins and base64): IP-logger domains, URL shorteners, look-alikes of Roblox domains, raw / obfuscated IP hosts, punycode, login or free-Robux lures. Judges the address text only; it follows no redirects.
External Script Protection|Main pageSScript CheckerOn by default. Inspects third-party script source before it runs and gives CLEAN, SUSPICIOUS, MALICIOUS or UNVERIFIED. UNVERIFIED means the source could not be inspected (unreadable, over 4 MB, analysis failed, or compiled by the executor first). CLEAN only means no known pattern was found.
External Script Protection|Main pageSExecution FirewallOn by default. Pauses a flagged script (SUSPICIOUS / MALICIOUS / UNVERIFIED) with an EXECUTION PAUSED panel; running it needs two typed confirmations (I UNDERSTAND THE SECURITY RISKS, then RUN ANYWAY) or you press BLOCK; no answer in 120 s means blocked. Critical threats can never be overridden. File execution (loadfile / dofile) that is UNVERIFIED is blocked. With the firewall OFF, MALICIOUS scripts are still blocked and others run without a prompt.
External Script Protection|Main pageSRuntime MonitoringOn by default. Watches what third-party scripts do while running through guarded functions: HTTP requests, clipboard read/write, file writes and deletes, queue_on_teleport, and attempts to replace or restore the guarded hooks. Only calls that go through those guarded functions are seen.
External Script Protection|Main pageBSecurity FindingsToggles the findings panel (latest 6): severity, script id and name, verdict, origin, decision and evidence with line numbers.
External Script Protection|Main pageBSecurity HistoryToggles the history log (latest 12): scans, blocks, decisions, confirmations, setting changes and runtime events.
External Script Protection|Main pageBExecutor Capabilities & LimitsShows what this executor can intercept (loadstring, HTTP, __namecall colon-calls, file and clipboard functions, hookfunction) marked OK / PARTIAL / NOT INTERCEPTABLE / N/A, plus the known limits of the protection. Not every executor supports every interception.
External Script Protection|Main pageBClear Findings & HistoryEmpties the findings and history lists (the statistics block stays).
Security|Main pageBCLEAR ALL DOWNLOADED CONTENTDANGER ZONE. Deletes everything the script downloaded (needs repeated clicks to confirm) and reloads modules.
Color system|Main page > CustomizationDAccent modeHow the UI accent color is chosen (picked color, harmony, aurora, music-driven and more).
Color system|Main page > CustomizationDColor harmony (secondary + tertiary colors)How the secondary and tertiary colors are derived from the accent.
Color system|Main page > CustomizationLDynamic color speedHow fast animated color modes cycle.
Color system|Main page > CustomizationLSaturationColor saturation of the palette.
Color system|Main page > CustomizationLBrightnessBrightness of the palette.
Color system|Main page > CustomizationPBase / picked color (used by Picked, Harmony, Aurora, Music modes)Color picker for the base accent color.
Triangle|Main page > CustomizationDTriangle Color ModeTheme (follows UI color), Custom color, Rainbow or Dynamic palette.
Triangle|Main page > CustomizationPTriangle custom color (used by Custom color)Color of the 3D triangle when Custom color is selected.
Triangle|Main page > CustomizationLTriangle SizeSize of the 3D loader triangle.
Triangle|Main page > CustomizationLTriangle Spin SpeedHow fast the triangle spins.
Triangle|Main page > CustomizationLFace TransparencyTransparency of the triangle faces.
Triangle|Main page > CustomizationLEdge ThicknessThickness of the triangle edges.
Triangle|Main page > CustomizationSShow Vertex OrbsShows glowing orbs at the triangle corners.
Triangle|Main page > CustomizationSShow Faces (off = wireframe)Turns the filled faces on or off (off leaves a wireframe).
Triangle|Main page > CustomizationSReact To MusicMakes the triangle react to the music beat.
Triangle|Main page > CustomizationSMusic Dance (triangles + logos follow the beat)Triangles and logos move to the beat.
Triangle|Main page > CustomizationSMusic Colors (UI accent follows the beat)The UI accent color follows the beat.
Triangle|Main page > CustomizationSHold 5s To ExplodeHold the triangle for 5 seconds to make it explode (visual effect).
Intro (customization)|Main page > CustomizationTIntro title text (max 20 characters)Custom title shown in the intro.
Intro (customization)|Main page > CustomizationTIntro subtitle (empty = default)Custom subtitle for the intro.
Intro (customization)|Main page > CustomizationTIntro scrolling text (empty = random)Custom scrolling text in the intro.
Intro (customization)|Main page > CustomizationDIntro ColorDisco palette, Custom color, White or Dynamic palette.
Intro (customization)|Main page > CustomizationPIntro custom color (used by Custom color)Color used when Intro Color is Custom.
Intro (customization)|Main page > CustomizationSWarp StarfieldStarfield effect in the intro.
Intro (customization)|Main page > CustomizationSGod RaysGod ray effect in the intro.
Intro (customization)|Main page > CustomizationSScanline + Letterbox BarsScanlines and cinema bars in the intro.
Intro (customization)|Main page > CustomizationSHUD Brackets + CounterHUD brackets and counter in the intro.
Intro (customization)|Main page > CustomizationLEffects Intensity (shake / flash)Strength of shake and flash in the intro.
Intro (customization)|Main page > CustomizationBPreview IntroPlays the intro now so you can see your changes.
Notifications|Main page > CustomizationDNotification ModeHow notifications are shown (Roblox popup, UI bar or both).
Notifications|Main page > CustomizationLDuration (seconds)How long a notification stays.
Notifications|Main page > CustomizationTRoblox popup titleTitle of Roblox popup notifications.
Notifications|Main page > CustomizationDUI bar positionBelow window, Above window, Top of screen or Bottom of screen.
Notifications|Main page > CustomizationLUI bar widthWidth of the notification bar.
Notifications|Main page > CustomizationLUI bar text sizeText size of the notification bar.
Notifications|Main page > CustomizationSShow progress barShows a progress bar on notifications.
Notifications|Main page > CustomizationPNotification bar colorColor of the notification bar.
Notifications|Main page > CustomizationSPlay sound on notificationPlays a sound when a notification appears.
Notifications|Main page > CustomizationLSlide animation speedSpeed of the notification slide animation.
Notifications|Main page > CustomizationBTest NotificationSends a test notification.
Extra UI|Main page > CustomizationLBackground TransparencyTransparency of the UI background.
Extra UI|Main page > CustomizationLBorder ThicknessBorder thickness.
Extra UI|Main page > CustomizationLCorner RoundnessHow round the corners are.
Extra UI|Main page > CustomizationSGlow EffectAdds a glow to the UI.
Extra UI|Main page > CustomizationLAnimation speed (effects, transitions)Speed of UI animations.
Extra UI|Main page > CustomizationDPage transitionStyle of page transitions: Liquid (default), Push, Sheet Rise, Zoom Through, Depth Dive, Fan Card, Island Morph, Pull Down, Stack Shuffle, Elastic Pop, Swipe Away and more.
Extra UI|Main page > CustomizationDButton animationButton press animation: Original, Jelly, Wiggle, Pop Burst, Haptic Nudge, Shockwave, Whirl, Tilt Follow, Glow Pulse, Drop & Settle or Sheen Sweep.
Extra UI|Main page > CustomizationLUI Scale (zoom)Zooms the whole UI. (Range 1-1.5.)
Extra UI|Main page > CustomizationDUI FontChanges the UI font.
Extra UI|Main page > CustomizationSAmbient Particles (palette colored)Floating particles in the UI colored by your palette.
Extra UI|Main page > CustomizationSAccent Sheen (animated gradient)Animated gradient sheen on accents.
Extra UI|Main page > CustomizationSCursor Trail / Touch RipplesTrail behind the cursor or ripples where you touch.
Extra UI|Main page > CustomizationSLiquid Glass (iOS 27): buttons, sliders, toggles, fieldsGlass look for controls.
Extra UI|Main page > CustomizationLGlass clarity (left = clear, right = frosted / tinted)Clear to frosted glass.
Extra UI|Main page > CustomizationSHaptic Feedback (vibrate on phones)Vibrates on phones when you press things.
Roblox icon / top bar|Main page > CustomizationSTheme-colored top bar icons (Roblox, menu, chat)Colors the Roblox top bar icons with your theme.
Roblox icon / top bar|Main page > CustomizationSTheme-colored top bar background (Roblox button + menu/chat pill)Colors the top bar backgrounds with your theme.
Chat|Main page > CustomizationSChat styling (follows the UI theme)Styles the Roblox chat with your UI theme.
Chat|Main page > CustomizationLChat text sizeChat text size.
Chat|Main page > CustomizationLChat background transparencyChat background transparency.
Chat|Main page > CustomizationLChat window widthChat window width.
Chat|Main page > CustomizationLChat window heightChat window height.
Chat|Main page > CustomizationLBubble duration (seconds)How long chat bubbles stay.
Chat|Main page > CustomizationLBubble max distanceDistance up to which bubbles show.
Chat|Main page > CustomizationSBubble tail visibleShows or hides the tail of chat bubbles.
Character proportions|Main page > CustomizationLWidth (sides)Spreads limbs and hats sideways on the reanimate character (1 = normal). (Range 0.5-3.)
Character proportions|Main page > CustomizationLHeightSpreads limbs and hats vertically. (Range 0.5-3.)
Character proportions|Main page > CustomizationLDepthSpreads limbs and hats front to back. (Range 0.5-3.)
Character proportions|Main page > CustomizationBReset ProportionsSets width, height and depth back to 1. It does not resize hat meshes themselves.
Command triangle|Main page > CustomizationSHide Command TriangleHides the Uh Admin triangle launcher (hold it to hide too). A small tab at the top edge brings it back; so does typing showtri.
Command triangle|Main page > CustomizationSRestore tab while hiddenKeeps the small restore tab visible while the triangle is hidden.
Command triangle|Main page > CustomizationBReset Triangle PositionPuts the triangle back at the top centre if it ended up off-screen.
Delta customization|Main page > CustomizationSDelta customizer (built in, applies on next start)Master switch for the Delta customizer (only runs on the Delta executor).
Delta customization|Main page > CustomizationSNooby triangle as Delta iconUses the Nooby triangle as the Delta icon.
Delta customization|Main page > CustomizationSSmooth Delta page transitionsSmooth transitions in Delta pages.
Delta customization|Main page > CustomizationSSubtle blur during transitionsLight blur during Delta transitions.
Delta customization|Main page > CustomizationS5-second Delta mini-intro (after Nooby's intro)Short Delta intro after the main intro.
Delta customization|Main page > CustomizationLDelta page animation speedSpeed of Delta animations.
Delta customization|Main page > CustomizationTDelta customizer source override (file path or https URL, optional - empty = built-in)Optional custom source for the Delta customizer.
Delta customization|Main page > CustomizationSDelta fast execute (cached compile + cached downloads, applies to the next script you run)Caches compile and downloads so scripts you run start faster.
Delta customization|Main page > CustomizationSDelta script helpers API (cached compile + paced queue)Exposes a cached-compile helper API with a paced queue.
Delta customization|Main page > CustomizationBDelta Script Cache: Show Stats + ClearShows the script cache stats then clears the cache.
Delta customization|Main page > CustomizationBPreview Delta IntroPlays the Delta mini-intro.
Delta customization|Main page > CustomizationBReset All CustomizationResets every customization option to default.
Roblox engine settings|Main pageSRender Streamed RegionsRoblox engine setting NetworkSettings.RenderStreamedRegions (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSPrint Join Size BreakdownRoblox engine setting NetworkSettings.PrintJoinSizeBreakdown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSPrint Stream Instance QuotaRoblox engine setting NetworkSettings.PrintStreamInstanceQuota (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSShow Active Animation AssetRoblox engine setting NetworkSettings.ShowActiveAnimationAsset (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSRandomize Join Instance OrderRoblox engine setting NetworkSettings.RandomizeJoinInstanceOrder (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSPhysics Allow SleepRoblox engine setting PhysicsSettings.AllowSleep (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSPhysics Anchors ShownRoblox engine setting PhysicsSettings.AreAnchorsShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSPhysics Assemblies ShownRoblox engine setting PhysicsSettings.AreAssembliesShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSPhysics Body Types ShownRoblox engine setting PhysicsSettings.AreBodyTypesShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSCollision Costs ShownRoblox engine setting PhysicsSettings.AreCollisionCostsShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSJoint Coordinates ShownRoblox engine setting PhysicsSettings.AreJointCoordinatesShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSPhysics Owners ShownRoblox engine setting PhysicsSettings.AreOwnersShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSPhysics Regions ShownRoblox engine setting PhysicsSettings.AreRegionsShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSAwake Parts HighlightedRoblox engine setting PhysicsSettings.AreAwakePartsHighlighted (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSContact Points ShownRoblox engine setting PhysicsSettings.AreContactPointsShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSMechanisms ShownRoblox engine setting PhysicsSettings.AreMechanismsShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSUnaligned Parts ShownRoblox engine setting PhysicsSettings.AreUnalignedPartsShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSReceive Age ShownRoblox engine setting PhysicsSettings.IsReceiveAgeShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSInterpolation Throttle ShownRoblox engine setting PhysicsSettings.IsInterpolationThrottleShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSPhysics Tree ShownRoblox engine setting PhysicsSettings.IsTreeShown (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSDecomposition GeometryRoblox engine setting PhysicsSettings.ShowDecompositionGeometry (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSDraw Contacts Net ForceRoblox engine setting PhysicsSettings.DrawContactsNetForce (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSDraw Constraints Net ForceRoblox engine setting PhysicsSettings.DrawConstraintsNetForce (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSDraw Total Net ForceRoblox engine setting PhysicsSettings.DrawTotalNetForce (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSForce Instance NamesRoblox engine setting PhysicsSettings.ShowInstanceNamesForDrawnForcesAndTorques (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSRender Bounding BoxesRoblox engine setting RenderSettings.ShowBoundingBoxes (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSRender CSG Triangles DebugRoblox engine setting RenderSettings.RenderCSGTrianglesDebug (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSFrame Rate ManagerRoblox engine setting RenderSettings.EnableFRM (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSEager Bulk ExecutionRoblox engine setting RenderSettings.EagerBulkExecution (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSExport Merge By MaterialRoblox engine setting RenderSettings.ExportMergeByMaterial (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSReport Sound WarningsRoblox engine setting DebugSettings.ReportSoundWarnings (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageSVideo Capture EnabledRoblox engine setting GameSettings.VideoCaptureEnabled (copied from Nameless Admin's settings page). Saved and re-applied on the next start; mostly a debug overlay or rendering switch.
Roblox engine settings|Main pageTForce Draw ScaleNumber box for the Roblox engine setting PhysicsSettings.ForceDrawScale. Saved and re-applied on the next start.
Roblox engine settings|Main pageTTorque Draw ScaleNumber box for the Roblox engine setting PhysicsSettings.TorqueDrawScale. Saved and re-applied on the next start.
Roblox engine settings|Main pageTFluid Force Draw ScaleNumber box for the Roblox engine setting PhysicsSettings.FluidForceDrawScale. Saved and re-applied on the next start.
Roblox engine settings|Main pageTForce Smoothing StepsNumber box for the Roblox engine setting PhysicsSettings.ForceVisualizationSmoothingSteps. Saved and re-applied on the next start.
Roblox engine settings|Main pageTThrottle Adjust TimeNumber box for the Roblox engine setting PhysicsSettings.ThrottleAdjustTime. Saved and re-applied on the next start.
Roblox engine settings|Main pageTAuto FRM LevelNumber box for the Roblox engine setting RenderSettings.AutoFRMLevel. Saved and re-applied on the next start.
Roblox engine settings|Main pageTMesh Cache SizeNumber box for the Roblox engine setting RenderSettings.MeshCacheSize. Saved and re-applied on the next start.
Roblox engine settings|Main pageTIncoming Replication Lag (seconds)Number box for the Roblox engine setting NetworkSettings.IncomingReplicationLag. Saved and re-applied on the next start.
Roblox engine settings|Main pageTPhysics Environmental Throttle (1 default, 2 disabled)Number box for the Roblox engine setting PhysicsSettings.PhysicsEnvironmentalThrottle. Saved and re-applied on the next start.
]=====]
-- cats line: Section <US> Feature Center category it is listed under
D.cats = [=====[
Owner broadcast (owner only)Live Players / Moderation
Intro settingsMusic / Sound
NavigationCustomization / Settings
Visual Effects (Roblox engine)Customization / Settings
Asset loadingCustomization / Settings
ReanimatorReanimation / Character
Limb Reanimator configReanimation / Character
Ragdoll Reanimator configReanimation / Character
Hats Reanimator configReanimation / Character
Tool Reanimation configReanimation / Character
Unanchored Reanimation configReanimation / Character
Extra Unanchored Reanimation (Limb / Ragdoll)Reanimation / Character
Tool Reanimation Extras (Hats)Reanimation / Character
Reanimate Character SettingsReanimation / Character
Fly & WalkSpeedReanimation / Character
PerformancePerformance / Graphics
FlingFling / Interaction
TeleportTeleport / Servers
Server HopTeleport / Servers
Internals SettingsReanimation / Character
Movesets / DancesMovesets / Dances
MarketplaceMarketplace
Modules managementScript Hub / Modules
Live playersLive Players / Moderation
SecuritySecurity / Danger Zone
External Script ProtectionSecurity / Danger Zone
Color systemCustomization
TriangleCustomization
Intro (customization)Customization
NotificationsCustomization
Extra UICustomization
Roblox icon / top barCustomization
ChatCustomization
Character proportionsCustomization
Command triangleCustomization
Delta customizationCustomization
Roblox engine settingsCustomization / Settings
]=====]
D.cmds = [=====[
scriptls,s,runscript <source> (ls, s, run)Run the code requested
executorexecutorVery simple executor
scripthubscripthubThanks to scriptblox api
noobyscripthubnooby's script hubNooby's script hub (NOT FROM SCRIPTHUB)
standstand <player>Makes a player your stand
valkvalkOnly works on dollhouse
httpgethl,gethttpget <url> (hl, get)Run the contents of a given URL
resizechatrcresizechat (rc)Makes chat resizable and draggable
laglag <player>Chat lag
pluginspluginsLists your admin plugins stored in UhhhhhhReanim/AdminPlugins
prefixprefix <prefix>Changes and saves the admin prefix
saveprefixsaveprefix <prefix>Changes and saves the admin prefix
chatlogsclogschatlogs (clogs)Open the chat logs
gotocampostocampos,tcpgotocampos (tocampos, tcp)Teleports you to your camera position works with free cam but freezes you
kanyekanyeRandom kanye quote
hatorbithohatorbit (ho)Hat orbit
ospeedorbitspeedorbitspeed <speed> (ospeed)Hat orbit command
omodeorbitmodeorbitmode <1-17> (omode)Hat orbit command
orbitpoweropowerorbitpower <power> (opower)Hat orbit command
orbitheightoheightorbitheight <height> (oheight)Hat orbit command
orbitoffsetoffsetorbitoffset <height> (offset)Hat orbit command
godmodegodgodmode (god)Makes you unable to be killed
clickflingmouseflingmousefling (clickfling)Fling a player by clicking them
pingpingShows your ping
fpsfpsShows your fps
commandscmdscommands (cmds)Open the command list
hidetrihidetrianglehidetri (hidetriangle)Hides the floating command triangle. Bring it back with showtri (or the Customization page)
showtrishowtriangleshowtri (showtriangle)Shows the floating command triangle again
resettritripositionresettri (triposition)Moves the floating command triangle back to the top centre of the screen
tritoggletritri (toggletri)Hides / shows the floating command triangle
walkflingwflingwalkfling (wfling)Enable walkfling
unwalkflingunwflingunwalkfling (unwfling)Disable walkfling
commandcountcccommandcount (cc)Counds how many commands NA has
fling3fling3 <player>another variant of fling
rjrerejoinrefreshrjre (rejoinrefresh)Rejoins and teleports you to the position where you were before
rejoinrjrejoin (rj)Rejoin the game
jokejokeRandom joke generator
idiotidiot <player>Tell someone that they are an idiot
bringtobringto (playertobring) [playertobringto]Brings a player to another player
accountageaccageaccountage <player> (accage)Tells the account age of a player in the server
notoolscriptsntsnotoolscripts (nts)Destroy all scripts in backpack
spblockspamstarterblockscamspblockspam (starterblockspam)Spam blocks in any game that has the starter place
febtoolsfebtoolsMove parts that are your hats
unspblockspamunstarterblockscamunspblockspam (unstarterblockspam)Stops the starterblockspam command
blockspamblockspam [amount]Spawn blocks by the given amount
hitboxeshitboxesshows all the hitboxes
unhitboxesunhitboxesremoves the hitboxes outline
punchpunchpunch tool that flings
vflyvehicleflyvehiclefly (vfly)be able to fly vehicles
unvflyunvehicleflyunvehiclefly (unvfly)disable vehicle fly
traptrapmakes your tool be away from you making it look like its dropped
killkill <player>after a while i have added a working kill script thats almost instant to this admin
toolblockspamtoolblockspam [amount]Spawn blocks by the given amount
equiptoolsequipallequiptoolsEquip all of your tools
tweentotweengototweengoto (tweento)Teleportation method that bypassses some anticheats
reachreach {number}Sword reach
auraaura {number}Sword aura
droptoolsdropalltoolsDrop all of your tools
notoolsnotoolsRemove your tools
breaklayeredclothingblcbreaklayeredclothing (blc)Streches your layered clothing
fpsboosterlowgraphics,boostfps,lowgfpsbooster (lowgraphics, boostfps, lowg)Low graphics mode if the game is laggy
vrclovr,vrscript,fevrvr (clovr, vrscript, fevr)FE VR SCRIPT AKA CLOVR
flashflash <player>Flashes the targets screen
voidvoid <player>Kill the given players without FE god
annoyannoy <player>Annoys the given player
unannoyunannoyStops the annoy command
seatseatFinds a seat and automatically sits on it
banishpunish,jailpunish <player> (banish, jail)Banishes the player using a void script, can make them not respawn if the game is old
syncsyncSyncs all in-game audios
unsyncunsyncUnsyncs all in-game audios
infvoidinfvoid <player>Makes a players avatar glitch
attachattach <player>Attach the given player(s)
enableinventoryenableinvenableinv (enableinventory)Lets you see what you have in your inventory since some games hide it
copytoolsctoolscopytools <player> (ctools)Copies the tools the given player has
bringbring <player>Bring the given player(s)
skydiveskyskydive <player> (sky)Skydives the player
localtimeyourtimelocaltime (yourtime)Chats your current time
cartornadoctornadocartornado (ctornado)Tornados a car just sit in the car
tornadotornado <player>Tornados the player to be in the sky
unspamunlag,unchatspam,unanimlag,unremotespamunspamStop all attempts to lag/spam
respawnrerespawnRespawn your character
seizureseizureGives you a seizure
unseizureunseizureStops you from having a seizure not in real life noob
antisitantisitAntisit
unantisitunantisitDisable antisit command
laylayzzzzzzzz
triptripget up NOW
checkrfecheckrfeChecks if the game has respect filtering enabled off
sitsitSit your player
spinspin {amount}Makes your character spin as fast as you want
oldrobloxoldrobloxOld skybox and studs
f3xfexf3xF3X for client
dupetoolsdupetools [amount]Probably the fastest tool duping method
harkedcometharked (comet)Executes Comet which is like harked
triggerbottbottriggerbot (tbot)Executes a script that automatically clicks the mouse when the mouse is on a player
nofognofogRemoves all fog from the game
antiafknoafkantiafk (noafk)Makes you not be kicked for being afk for 20 mins
antiattachnoattachantiattach (noattach)Makes you not be able to be attached by using a item
unantiattachunnoattachunantiattach (unnoattach)Makes you to be able for others to attach you
setspawnspawnpoint,sssetspawn (spawnpoint, ss)Makes your spawn point be in the place where your character is
hamsterhamster <speed>Hamster ball
unantiafkunnoafkunantiafk (unnoafk)Makes you able to be kicked for being afk for 20 mins
toolguitoolguicool tool ui aka replication ui made by 0866
clicktpclicktpTeleport where your mouse is
dexdexUsing this you can see the parts / guis / scripts etc with this. A really good and helpful script.
antikillantikillMakes exploiters not be able to kill you
gayrategayrate <player>Gay scale of a player
coolratecoolrate <player>Cool scale of a player
unantikillunantikillMakes exploiters to be able to kill you
gravitygungravitygunProbably the best gravity gun script thats fe
flingnpcsflingnpcsFlings NPCs
voidnpcsvoidnpcsVoids NPCs
npcfollownpcfollowMakes NPCS follow you
loopnpcfollowloopnpcfollowMakes NPCS follow you in a loop
unloopnpcfollowunloopnpcfollowMakes NPCS not follow you in a loop
sitnpcssitnpcsMakes NPCS sit
unsitnpcsunsitnpcsMakes NPCS unsit
vehiclespeedvspeedvehiclespeed <amount> (vspeed)Change the vehicle speed
unvehiclespeedunvspeedunvehiclespeed (unvspeed)Stops the vehiclespeed command
killnpcskillnpcsKills NPCs
bringnpcsbringnpcsBrings NPCs
controlnpcscnpcscontrolnpcs (cnpcs)Keybind: CTRL + LEFTCLICK
attachpartattachpartKeybind: CTRL + LEFTCLICK
shiftlockslshiftlock (sl)Enable shiftlock
unshiftlockunslunshiftlock (unsl)Disables shiftlock if you're on mobile
ctrlshiftlockctrlslctrlshiftlock (ctrlsl)Enables shift lock if you press Control
espespESP
unespunespDisables esp
creepctp,scarectp <player> (creep, scare)Teleports from a player behind them and under the floor to the top
netlessnetnetless (net)Executes netless which makes scripts more stable
rocketrocket <player>rockets a player
kidnapkidnap <player>Kidnaps a player
quicksandquicksand <player>Quicksands a player
hatsleashhlhatsleashMakes you be able to carry your hats
toolleashtltoolleashMakes you be able to carry your tools
controlcontrol <player>Control a player
uncontroluncontrolUncontrol a player
resetresetMakes your health be 0
adminadminwhitelist someone to allow them to use commands
unadminunadmin <player>removes someone from being admin
201620162016 CORE GUI
removednnodn,nodpnremovedn (nodn, nodpn)Removes all display names
anticlientkickantickickanticlientkick (antickick)Makes local scripts not able to kick you
backdoorscanbackdoorbackdoorscan (backdoor)Scans for any backdoors using FraktureSS
jobidjobidCopies your job id
joinjobidjjobidjoinjobid <jobid> (jjid)Joins the job id you put in
serverhopshopserverhop (shop)Serverhop
autorejoinautorjautorejoinRejoins the server if you get kicked / disconnected
functionspyfunctionspyCheck console
flyfly [speed]Enable flight
unflyunflyDisable flight
noclipnclip,ncnoclipDisable your player's collision
clipcclipEnable your player's collision
r15r15Prompts a message asking to make you R15
r6r6Prompts a message asking to make you R6
freecamfc,fcamfreecam [speed] (fc, fcam)Enable free camera
unfreecamunfc,unfcamunfreecam (unfc, unfcam)Disable free camera
drophatsdrophatsDrop all of your hats
hatspinhatspin <height>Make your hats spin
limbbouncelimbbounce [height] [distance]Make your limbs bounce around your head
limborbitlimborbit [height] [distance]Make your limbs orbit around your head
fakelagflagfakelag (flag)fake lag
unfakelagunflagunfakelag (unflag)stops the fake lag command
circlemathcmcirclemath <mode> <size>Gay circle math\nModes: abc...
toolanimatetoolanimate <mode> <int>Make your tools epic\nModes: ufo/ring/shutter/saturn/portal/wtf/ball/tor
hideunshowhide <player> (unshow)places the selected player to lighting
unhideshowshow <player> (unhide)places the selected player back to workspace
aimbotaimbotui,aimbotguiaimbot (aimbotui, aimbotgui)aimbot and yeah
febypassbypassfefebypass (bypassfe)dont execute (literally) btw this script does not do harm
checkgrabbercheckgrabberChecks if anyone is using a grab tools script
loopgrabtoolsloopgrabtoolsLoop grabs dropped tools
unloopgrabtoolsunloopgrabtoolsStops the loop grab command
dancedanceDoes a random dance
undanceundanceStops the dance command
animspooferanimationspoofer,spoofanim,animspoofanimationspoofer (animspoof, spoofanim)Loads up an animation spoofer, spoofs animations that use rbxassetid
tooldancetdtooldance <mode> <size>Make your tools dance\nModes: tor/sph/inf/rng/whl/wht/voi
copygameidcgameidcopygameid (cgameid)Copies the id of the game youre in
lowholdlowholdBoombox low hold
copynamecnamecopyname <player> (cname)Copies the username of the target
copydisplaycdisplaycopydisplay <player> (cdisplay)Copies the display name of the target
nodanceuntooldancenodanceStop making tools dance
toolvisaudiovistoolvis <size>Turn your tools into an audio visualizer
rarmrarmRemoves your right arm
toolspintoolspin [height] [amount]Make your tools spin on your head
toolorbittoolorbit [height] [distance] [amount]Make your tools orbit around your head
blockhatsblockhatsRemove the meshes in your hats
blocktoolsblocktoolsRemove the meshes in your tools
notoolmeshntm,notoolmeshesnotoolmesh (ntm)Makes tools not have meshes
nomeshesnomesh,blocksnomeshesRemove all character meshes
nodecalsnodecal,notexturesnodecalsRemove all character images
spinflingsflingspinfling (sfling)Fling by spinning
unspinflingunsflingunspinfling (unsfling)Stop the spinfling command
claimuaclaimunanchoredclaimunanchored (claimua)Teleports to every single unanchored part meaning that the ownership is yours
orbitorbit <player> <distance>Orbit around a player
uporbituporbit <player> <distance>Orbit around a player on the Y axis
iploginfologiplog <playet>Stop orbiting a player
unorbitunorbitStop orbiting a player
antikillbrickantikbantikillbrick (antikb)Makes it so kill bricks cant kill you
unantikillbrickunantikbunantikillbrick (unantikb)Makes it so kill bricks can kill you
heighthipheight,hhheight <number> (hipheight, hh)Changes your hipheight
uadeleteunanchoreddeleteunanchoreddelete (uadelete)Gives you btools to delete unanchored parts
netbypassnetbnetbypass (netb)Net bypass
daydayMakes it day
nightnightMakes it night
antichatloggeraclantichatlogger (acl)Anti chat logger
chatmessagechat <text> (message)Chats you, useful if youre muted
fixcamfixfixcamFix your camera
fling2fling2 <player>Fling the given player 2
toolflingpushtoolfling (push)Tool fling
lflinglfling <player>Fling the given player using leg resize
flingfling <player>Fling the given player
commitoofcommitoofFE KILL YOURSELF SCRIPT this will be bad when taken out of context
volumevolvolume <1-10> (vol)Changes your volume
sensitivitysenssensitivity <1-10> (tr)Changes your sensitivity
torandomtrtorandom (tr)Teleports to a random player
gototo,tp,teleportgoto <player/X,Y,Z>Teleport to the given player or X,Y,Z coordinates
lookatstarestare <player> (lookat)Stare at a player
unlookatunstareunstare (unlookat)Stops staring
watchview,specateview <player>Watch the given player
unwatchunview,unspectateunviewStop watching a player
stealaudiogetaudio,steal,logaudiostealaudio <player> (getaudio, logaudio, steal)Save all sounds a player is playing to a file  -Cyrus
followstalk,walkfollow <player>Follow a player wherever they go
pathfindpathfind <player>Follow a player using the pathfinder API wherever they go
unfollowunstalk,unwalk,unpathfindunfollowStop all attempts to follow a player
bubblechatbubblechat <player>fake chat as your target
translatechattranslatechattranslates the chat using google translate api
freezethaw,anchorfreeze (thaw, anchor)Freezes your character
unfreezeunthaw,unanchorunfreeze (unthaw, unanchor)Unfreezes your character
disableanimationsdisableanimsdisableanimations (disableanims)Freezes your animations
undisableanimationsundisableanimsundisableanimations (undisableanims)Unfreezes your animations
headkillhkillheadkill <player> (hkill)Need an rthro head
headbringhbringheadbring <player> (headbring)Need an rthro head
headvoidhvoidheadvoid <player> (hvoid)Need an rthro head
headresizeheadresizeMakes your head very big r15 only
hatresizehatresizeMakes your hats very big r15 only
discorddiscordOfficial Discord server invite link
nadiscordnadiscordNameless Admin discord server link
exitexitClose down roblox
legresizelegresizeMakes your legs very big r15 only
fatnikocadoavocadofat (nikocadoavocado)fat
smallsmallMakes you short r15 only
loopflingloopfling <player>Loop voids a player
freegamepassfreegpfreegamepass (freegp)Makes the client think you own every gamepass in the game
headsitheadsit <player>Head sit.
unheadsitunheadsitStop the headsit command
jumpjumpjump.
headstandheadstand <player>Stand on someones head
unheadstandunheadstand <player>Stop the headstand command
loopwalkspeedloopwsloopwalkspeed <speed> (loopws)Loop walkspeed
unloopwalkspeedunloopwsunloopwalkspeed <speed> (unloopws)Disable loop walkspeed
loopwaveatloopwatloopwaveat <player> (loopwat)Wave to a player in a loop
unloopwaveatunloopwatunloopwaveat <player> (unloopwat)Stops the loopwaveat command
waveatwatwaveat <player> (wat)Wave to a player
spookscarespook <player> (scare)Teleports next to a player for a few seconds
loopspookloopscareloopspook <player> (loopscare)Teleports next to a player for a few seconds and then again and again
unloopspookunloopscareunloopspook <player> (unloopscare)Stops the loopspook command
unairwalkunawunairwalk (unaw)Stops the airwalk command
airwalkawairwalk (aw)Press space to go up, unairwalk to stop
cbringclientbringclientbring <player> (cbring)Brings the player on your client
uncbringunclientbringunclientbring (uncbring)Disable Client bring command
mutemuteboomboxmute <player> (muteboombox)Mutes the players boombox
antivoidantivoidAnti void.
tpwalktpwalktpwalk <speed>More undetectable walkspeed script
untpwalkuntpwalkStops the tpwalk command
loopmuteloopmuteboomboxloopmute <player> (loopmuteboombox)Loop mutes the players boombox
unloopmuteunloopmuteboomboxunloopmute <player> (unloopmuteboombox)Unloop mutes the players boombox
glitchglitchboomboxglitch <player> (glitchboombox)Glitches the players boombox
unglitchunglitchboomboxunglitch <player> (unglitchboombox)Unglitches the players boombox
unlooplbringunlooplegbringunlooplbring <player> (unlooplegbring)Stop the looplbring command
unlooplvoidunlooplegvoidunlooplvoid <player> (unlooplegvoid)Stop the looplvoid command
unlooplkillunlooplegkillunlooplkill <player> (unlooplegkill)Stop the looplkill command
looplbringlooplegbringlooplbring <player> (looplegbring)Leg resize loop bring
getmassgetmass <player>Get your mass
dvoiddvoiddvoid <player> (dvoid)Delay void
dbringdelaybringdelaybring <player> (dbring)Delay bring
looplkilllooplegkilllooplkill <player> (looplegkill)Leg resize loop kill
looplvoidlooplegvoidlooplvoid <player> (looplegvoid)Leg resize loop void
lvoidlegvoidlvoid <player> (legvoid)Leg resize void
lbringlegbringlbring <player> (legbring)Leg resize bring
lkilllegkilllkill <player> (legkill)Leg resize kill
loopvoidloopvloopvoid <player> (loopv)Voids the player
loopbringloopbring <player>Loopbrings a player
unloopbringunloopbringStops loopbringing a player
unloopvoidloopvunloopvoid (unloopv)Unloopingly voiding a player
looptornadolooptornado <player>Loop tornados a player endlessly
unlooptornadounlooptornadoUnloop tornadoes a player endlessly
loopcuffloopjailloopcuff <player> (loopjail)Loop cuffs a player endlessly
unloopcuffunloopjailunloopcuff <player> (unloopjail)Unloop cuffs a player endlessly
loopstandloopstand <player>Loop stands a player endlessly
unloopstandunloopstandUnloop stands a player endlessly
loopbanishlooppunish,loopjailloopbanish <player> (loopbanish, loopjail)Banishes a player endlessly
unloopbanishunloopjail,unlooppunishunloopbanish (unloopjail, unlooppunish)Stops loopingly punishing a player
unloopflingunloopflingStops loop flinging a player
loopkillloopkill <player>Loop kills a player
unloopkillunloopkillStops loop killing a player
netlagnetlag <player>If the person is using netless, or any reanimation it glitches them
unnetlagunnetlagStops netlegging
nopromptnopurchasepromptsnoprompt (nopurchaseprompts)remove the stupid purchase prompt
promptpurchasepromptsprompt (purchaseprompts)allows the stupid purchase prompt
namelessnamelessMakes your hats visible but not your name or your body
wallwalkwallwalkMakes you walk on walls
sizesizeMakes you big
holdpartshp,grabpartsholdparts (hpr, grabparts)Holds any unanchored part press ctrl + click
hideguishideguisHides guis
showguisshowguisShow guis that were hidden using hideguis
unspinunspinMakes your character unspin
notepadnotepadnotepad for making scripts / etc
rc7rc7RC7 Internal UI
scriptviewerviewscriptsscriptviewer (viewscripts)Can view scripts made by 0866
hidenamehnamehidenameHides your name only works on billboard uis
hydroxidehydroxideexecutes hydroxide
remotespysimplespyremotespy (simplespy)executes simplespy v3
gravitygravgravity <amount> (grav)sets game gravity to whatever u want
uanogravunanchorednograv,unanchorednogravityuanograv (unanchorednograv)Makes unanchored parts have 0 gravity
funfactfunfactSays a random fun fact
fireclickdetectorsfcdfireclickdetectors (fcd)Fires every click detector that's in workspace
tweengotocampostweentocampos,tweentcptweengotocampos (tweentcp)Another version of goto camera position but bypassing more anti-cheats
gotoparttopartgotopart {partname} (topart)Makes you teleport to a part you want
swimswim {speed}Swim in the air
unswimunswimStops the swim script
esppartpartespesppart {partname} (partesp)Makes you be able to see any part
unesppartunpartespunesppart (unpartesp)Removes the esp from the parts
viewpartviewpviewpart {partname} (vpart)Views a part
unviewpartunviewpunviewpart (unviewp)Unviews the part
consoleconsoleOpens developer console
hitboxhboxhitbox {amount}Makes everyones hitbox as much as you want
unhitboxunhboxunhitboxDisables hitbox
breakcarsbcarsbreakcars (bcars)Breaks any car
firetouchinterestsftifiretouchinterests (fti)Fires every Touch Interest that's in workspace
infjumpinfinitejumpinfjump (infinitejump)Makes you be able to jump infinitly
uninfjumpuninfinitejumpuninfjump (uninfinitejump)Makes you NOT be able to infinitly jump
xrayxrayonxray (xrayon)Makes you be able to see through walls
unxrayxrayoffunxray (xrayoff)Makes you not be able to see through walls
pastebinscraperpastebinscrapepastebinscraper (pastebinscrape)Scrapes paste bin posts
amongusamogusamongus (amogus)among us in real life, sus sus.
blackholeblackholeMakes unanchored parts teleport to the black hole
fullbrightfullbfullbright (fullb)Makes games that are really dark to have no darkness and be really light
givehatgivehatuigivehat (givehatui)Executes a hat giver gui check in console for hat names
fireproximitypromptsfppfireproximityprompts (fpp)Fires every Touch Interest that's in workspace
nanamelessna {command} (nameless)Runs a Nameless Admin command line through NA's own runtime
chatspychatspySpies on chat, enables chat, spies whispers etc.
bhopbhopbhop bhop bhop bhop bhop bhop bhop bla bla bla idk what im saying
firstp1stp,firstpersonfirstperson (1stp, firstp)Makes you 1st person mode
thirdp3rdp,thirdpersonthirdperson (3rdp, thirdp)Makes you 3rd person mode
maxzoomcamzoommaxzoom <amount> (camzoom)Set your maximum camera distance
cameranoclipcamnoclip,cnoclipcameranoclip (camnoclip, cnoclip)Makes your camera clip through walls
uncameranoclipuncamnoclip,uncnoclipuncameranoclip (uncamnoclip, uncnoclip)Makes your camera not clip through walls
2016anims2016anims2016 animations
oganimsoganimsOld animations from 2007
fakechatfakechatFake a chat gui
fpscapfpscap <number>Sets the fps cap to whatever you want
holdhatholdhatCan make you hold your hats execute the command and you will have them in your inventory
toolinvisibletoolinvisibleBe invisible while still be able to use tools
invisibleinvisibleSets invisibility to scare people or something
unchatspyunchatUnspies on chat, enables chat, spies whispers etc.
fireremotesfireremotesFires every remote.
uafollowunanchoredfollowuafollow (unanchoredfollow)Makes unanchored parts follow you
fovfov <number>Makes your FOV to something custom you want (1-120 FOV)
homebrewhomebrewExecutes homebrew admin
fatesadminfatesadminExecutes fates admin
savetoolsstoolssavetools (stools)puts your tools in players.localplayer
loadtoolsltoolsloadtools (ltools)puts your tools back in the backpack
grabtoolsgtgrabtoolsGrabs any dropped tools
wsspeed,walkspeedwalkspeed <number> (speed, ws)Makes your WalkSpeed whatever you want
cuffjailcuff <player> (jail)Cuffs the player
jpjumppowerjumppower <number> (jp)Makes your JumpPower whatever you want
oofspamoofspamSpams oof
partgrabberpartgrabberPress Q
tpuabringuatpua <player> (bringua)brings every unanchored part on the map
freezeuathawuafreezeua (thawua)freezes every unanchored part on the map
unfreezeuaunthawuaunfreezeua (unthawua)unfreezes every unanchored part on the map
highlightuahighlightunanchoredhighlightua (hightlightunanchored)Highlights all unanchored parts
unhighlightuaunhighlightunanchoredunhighlightua (unhightlightunanchored)Unhighlights all unanchored parts
countuacountunanchoreedcountua (countunanchored)Counts all unanchored parts in the console
httpspyhttspyHTTP Spy
keystrokekeystrokeExecutes a keystroke ui script
owneridowneridChanges the client id to the owner's. Can give special things
errorchaterrorchatMakes the chat error appear when roblox chat is slow
tpstyletpstyle <orbit|radar|prism|scan|random>Sets the teleport loading screen style
tptesttpscreentptest (tpscreen)Previews the teleport loading screen for 5 seconds (no teleport)
unloadunloadna,exitnaunloadUnload Nameless Admin and clean up its active runtime
pluginmakermakeplugin,pluginbuilder,plugmaker,pmakerpluginmakerOpen the no-code .na/.iy plugin builder
addallpluginsaddplugins,aap,aaplugsaddallpluginsMove all .na to Nameless-Admin/Plugins and all .iy to Nameless-Admin/PluginsIY, then load them
addpluginaddplug,ap,aplugaddpluginMove one .na to Plugins or one .iy to PluginsIY, then load it
reloadpluginrelplug,rpreloadplugin [name]Reload plugin files (reloads all if no name provided)
removepluginrmplugin,delplugin,rmpremovepluginMove a plugin file from Nameless-Admin/Plugins or Nameless-Admin/PluginsIY back to workspace
removeallpluginsrmaplugins,clearplugins,rmap,rmaplugsremoveallpluginsMove all plugins from Nameless-Admin/Plugins and Nameless-Admin/PluginsIY back to workspace
cmdbar2cbar2cmdbar2 (cbar2)Opens a HD-Admin style cmdbar (black & white)
urlurl <link>Run the script using URL
loadstringls,lstring,loads,executeloadstring <code> (ls, lstring, loads, execute)Run code using loadstring
nocooldownncdnocooldown <number> (ncd)Override game-script cooldown timing with the chosen number of seconds; defaults to 0 when omitted
unnocooldownunncdunnocooldown (unncd)Disable the game-script cooldown timing override
waitcapmaxwaitwaitcap <seconds> (maxwait)Caps game-script wait/delay durations without shortening waits already below the cap
unwaitcapunmaxwaitunwaitcap (unmaxwait)Disables the game-script wait/delay cap
notweeninstanttweennotween [seconds] (instanttween)Forces all TweenService-created tweens, including NA/executor UI tweens, to the chosen duration; def
unnotweenuninstanttweenunnotween (uninstanttween)Stops overriding game-created tween durations
gcsearchgcsgcsearch <text> (gcs)Searches getgc tables, function metadata, constants, and upvalues for text
autopatchtoolaptautopatchtool [tool|all] (apt)Aggressively patches common cooldown, reload, recoil, spread, ammo, fire-rate, range, and damage set
patchtoolptpatchtool [tool|all] [category] (pt)Lightweight tool patcher for cooldown, reload, recoil, spread, ammo, fire-rate, range, or damage wit
unpatchtoolunptunpatchtool (unpt)Restores values changed by Patch Tool and disables its guards
unautopatchtoolunaptunautopatchtool (unapt)Restores values changed by Auto Patch Tool and disables its guards
tailswaytailwag,tailwagging,tailswayingtailsway (tailwag, tailwagging, tailswaying)Load the TailSway physics/wagging script
scriptloggersslogger,securescriptslogger,secureloggerscriptlogger [gui/console/both] (sslogger, securLoad SecureScripts Logger before running a suspicious script
tastascreator,toolassistedspeedrun,toolassistantspeedruntas [file] [smooth] [fps] [path] [velocity] [nocLaunch TAS Recorder Redux; optionally auto-load and play a saved run
scriptloadsload,loadscript,runsavedscriptscriptload <name> (sload, loadscript)Run a saved script from the NA executor saved scripts folder
shadersshader,rtx,hdshaders (shader, rtx, hd)Enable a shader preset for Lighting
unshadersshadersoff,rtxoffunshaders (shadersoff, rtxoff)Disable the shader preset and restore Lighting
ibtoolsibtoolsLoad the iBuild Tools helper tool
unibtoolsunibtoolsRemove the iBuild Tools helper tool
setfflagsetffsetfflag <flag> <value> [save] (setff)Set a fast flag (use 'save' to store it)
addaliasaddalias <command> <alias>Adds a persistent alias for an existing command
removealiasremovealiasSelect and remove a saved alias
clearaliasesclearaliasesRemoves all aliases created using addalias.
addbuttonabaddbutton <command> <label> [<command2>] (ab)Add a mobile button
removebuttonrbremovebutton (rb)Remove a user button
clearbuttonsclearbtns,cbclearbuttons (clearbtns, cb)Clear all user buttons
addautoexecaaexec,addae,addauto,aexecaddaddautoexec <command> [arguments] (aaexec, addaeAdd a command to autoexecute
removeautoexecraexec,removeae,removeauto,aexecremoveremoveautoexec (raexec, removeae, removeauto, aeRemove a command from autoexecute
clearautoexeccaexec,clearauto,autoexecclear,aexecclear,aeclearclearautoexec (caexec, clearauto, autoexecclear,Clear all AutoExec commands
lastcommandlastcmdlastcommand (lastcmd)Re-run your previously executed command
ifundoneifnotdone,ifnewifundone <command> [arguments]Runs a command only if that exact command has not been done this session
commandloopcmdloopcommandloop
stoploopuncmdloop,sloop,stoplstoploopStop a running loop
gamescriptssupportedscripts,gamesupportgamescripts [refresh/on/off] (supportedscripts, Show scripts listed for the current game
uiscaleuscale,guiscale,gscaleuiscale (uscale)Adjust the scale of the 
musicmusicplayer,songplayermusic (musicplayer)Open the NA music player
teleportguitpui,universeviewer,uviewerteleportguiOpen the universe subplace and public-server viewer
imagescannerimgscanner,imgscan,imgs,imagesimagescannerGives an UI that grabs all images on the game
audiologgeralogger,audiol,alog,alaudiologgerGives an UI that grabs all audios on the game
serverremotespysrs,sremotespyserverremotespy (srs,sremotespy)Gives an UI that logs all the remotes being called from the server (thanks SolSpy lol)
ciggivecig,cigarettecig (givecig,cigarette)Gives a cigarette pack (client R6)
cigargivecigarcigar (givecigar)Gives a cigar (client R6)
pipegivepipepipe (givepipe)Gives a smoking pipe (client R6)
unclickflingunmouseflingunclickfling (unmousefling)disables clickfling
offsetoffpos,offoffset [x y z|y]Offsets and rotates your character for others using the Character-tab customization
upsidedownflipcharupsidedownFlips your character upside down for others using the offset replication method
unoffsetunoffpos,unoffunoffsetDisables offset customization and restores your character
unupsidedownunflipcharunupsidedownDisables the upside down replication and restores your character
clickscareclickspookclickscare (clickspook)Teleports next to a clicked player for a few seconds
unclickscareunclickspookunclickscare (unclickspook)Disables clickscare
hovernamenamehoverhovernameShows player's username on hover
unhovernameunnamehoverunhovernameDisables hovername
hoverinventoryhoverinvhoverinventory (hoverinv)Shows a player's inventory on hover
unhoverinventoryunhoverinv,nohoverinventoryunhoverinventory (unhoverinv)Disables hoverinventory
resetfilterrefresetfilterIf Pedoblox keeps tagging your messages, run this to reset the filter
fpspingpingfps,fpsp,pfpsfpsping (pingfps)Shows the legacy FPS and ping panel
statsdevstats,loadstatsstats (devstats, loadstats)Shows FPS, physics, network and memory stats
speedometersps,speedospeedometer (sps,speedo)Toggles a NA-themed speedometer
closespeedometerstopspeedometer,nosps,unspeedoclosespeedometer (nosps,unspeedo)Closes the speedometer
settingssettingsOpen the settings menu
commandkeybindscmdkeybinds,ckeybindscommandkeybinds (cmdkeybinds, ckeybinds)Open the command keybinds window
inspectoutfitoutfitinspectinspectoutfit <user/player/userid|outfit:id>Open a user's saved outfits and inspect a selected outfit
avatarpreviewapreview,clientavataravatarpreview <me/player/userId/outfitId>Creates a client-only avatar preview rig
charchar <me/player/userId> | char outfit <outfitId>Transforms your client character to a user's avatar appearance
uncharresetchar,charresetunchar (resetchar, charreset)Restores your appearance
clearavatarpreviewunavatarpreview,capreviewclearavatarpreviewRemoves the client-only avatar preview rig
waypointswpwaypointsOpen the waypoints menu
bindersbindsbindersOpen the event binder menu
showwaypointsshowwp,showwps,waypointesp,wpespshowwaypointsShow saved waypoint ESP markers for this place
hidewaypointshidewp,hidewps,unshowwaypoints,unwpesphidewaypointsHide saved waypoint ESP markers
showpathwaypointshowpathwp,pathwaypoint,pathwp,showwppathshowpathwaypoint <name...>Show PathfindingService route nodes to a saved waypoint
hidepathwaypointhidepathwp,unpathwaypoint,unpathwp,stoppathwaypoint,stoppathhidepathwaypointHide waypoint path route nodes and stop waypoint pathfinding
pathfindwaypointpathfindwp,pfwaypoint,pfwppathfindwaypoint <name...>Pathfind to a saved waypoint and show the route nodes
looppathlooppathwaypoint,loopwaypoint,loopwplooppath [tween|teleport|walk] <waypoint name...Continuously path to a saved waypoint after death or respawn
looptweenpathlooptweenwp,tweenlooppathlooptweenpath <waypoint name...>Loop path to a waypoint using tween movement
loopteleportpathlooptppath,looptpwp,tplooppathloopteleportpath <waypoint name...>Loop path to a waypoint by teleporting between route nodes
loopwalkpathloopwalkwp,walklooppathloopwalkpath <waypoint name...>Loop path to a waypoint using walking movement
unlooppathstoplooppath,nolooppath,unloopwpunlooppathStop persistent waypoint pathfinding
looppathtweenspeedlooppathspeed,pathloopspeedlooppathtweenspeed <speed>Set loop path tween speed in studs per second
looppathteleportdelaylooppathtpdelay,pathloopdelaylooppathteleportdelay <seconds>Set loop path teleport delay between route nodes
setwaypointsetwpsetwaypoint <name...> [x y z]Store your current position, or create/update with custom coordinates
setwaypointpossetwppos,waypointpos,wppos,editwaypoint,editwpsetwaypointpos <name...> <x> <y> <z>Create or edit a waypoint using custom coordinates
gotowaypointgotowpgotowaypoint <name...>Teleport to a saved waypoint
removewaypointremovewp,rwpremovewaypoint <name...>Remove a saved waypoint
chardebugcdebugchardebug (cdebug)debug your character
unchardebuguncdebugunchardebug (uncdebug)disable character debug
somersaultfrontflipsomersault (frontflip)Makes you do a clean front flip
unsomersaultunfrontflipunsomersault (unfrontflip)Disable somersault button and keybind
rolewatchrolewatch <groupId> <role name>Notify if someone from a watched group joins with a specific role
rolewatchstoprolewatchstopDisable Rolewatch monitoring
rolewatchleaveunrolewatchrolewatchleave (unrolewatch)Toggle leaving the server if the watched role joins
joingroupgroupjoinjoingroup [groupId] (groupjoin)Open the Pedoblox join prompt for a group
trackstaffstaffwatchtrackstaff (staffwatch)Track, highlight, and notify when a staff member joins the server
stoptrackstaffuntrackstaff,unstaffwatchstoptrackstaff (untrackstaff, unstaffwatch)Stop tracking staff members
antistaffstaffescape,staffavoidantistaff [leave/serverhop] (staffescape, staffaAutomatically leave or advanced-serverhop when staff is detected
unantistaffunstaffescape,unstaffavoidunantistaff (unstaffescape, unstaffavoid)Disable automatic staff avoidance
rewindrewind [seconds]Enable rewind with hold-R on PC or a draggable mobile button
unrewindstoprewindunrewind (stoprewind)Disable rewind and clear its saved frames
rewindspeedrewindspeed <frames>Set rewind frames skipped per heartbeat
rewindtimerewindsecondsrewindtime <seconds>Set how many seconds rewind stores
freemousetogglefreemouse,wfcpfreemousefreemouseToggle cursor unlock while world model first person is active
hideaccaccessorieshideacc (accessories)Hide or restore local accessory parts
backviewrearview,rear,f5backview (rearview, rear, f5)Flip the camera behind you and invert movement controls
worldmodelfpwfcpfp,realfirstperson,fpmodelworldmodelfp (wfcpfp, realfirstperson, fpmodel)WFCP world-model first person camera
frontviewresetcamfrontview (resetcam)Reset WFCP camera state and return to a normal front view
deletevelocitydv,removevelocity,removeforcesdeletevelocity (dv, removevelocity, removeforcesremoves any velocity/force instanceson your character
screenorientationscreenorient,scrorientation,scrorient,screenrotation,scrrotascreenorientation [type]Manage ScreenOrientation
sensorrotationscreensensorscreen,senscreensensorrotationscreenChanges ScreenOrientation to Sensor
landscaperotationscreenlandscapescreen,landscreenlandscaperotationscreenChanges ScreenOrientation to Landscape Sensor
portraitrotationscreenportraitscreen,portscreenportraitrotationscreenChanges ScreenOrientation to Portrait
defaultrotationscreendefaultrotaionscreen,defaultscreen,defscreendefaultrotationscreenChanges ScreenOrientation to Default
flyflingffflyfling (ff)makes you fly and fling
unflyflingunffunflyfling (unff)stops fly and fling
touchflingtfling,tftouchfling (tfling,tf) <speed>walkfling only when touching a player or NPC
untouchflinguntfling,untfuntouchfling (untfling,untf)stop the touchfling command
cancelteleportcanceltpcancelteleportCancel an in-progress teleport and dismiss the teleport UI
cancelteleportloopcanceltploop,loopcancelteleport,loopcanceltpcancelteleportloop [interval]Repeatedly cancels in-progress teleport
uncancelteleportloopuncanceltploop,unloopcancelteleport,unloopcanceltpuncancelteleportloopDisable cancelteleport loop
teleporttoplacetoplace,ttp,gametpteleporttoplace <id>Teleports you using PlaceId
adonisbypassbypassadonis,badonis,adonisbadonisbypass (bypassadonis,badonis,adonisb)bypasses adonis admin detection
antinilanticharnil,antinilchar,charantinil,keepcharantinil (anticharnil, antinilchar, charantinil, Prevents your character from being parented to nil
unantinilunanticharnil,unantinilchar,allowcharnil,unkeepcharunantinil (unanticharnil, unantinilchar, allowchStops preventing your character from being parented to nil
nilcharnilcharacter,charnil,ncharnilchar (nilcharacter, charnil, nchar)Parents your character to nil
unnilcharunnilcharacter,uncharnil,nonilchar,restorechar,bringcharunnilchar (unnilcharacter, uncharnil, nonilchar,Restores your nil-parented character
usetoolsusetusetools (uset)Equips all tools, uses them, and unequips them
settweenspeedtweenspeedtweenspeed [seconds]Set how long tween teleport commands take
tpupuptpup <studs>Teleports you up by the given amount of studs
tpdowndowntpdown <studs>Teleports you down by the given amount of studs
boxreachboxreach [number] [part]Creates a box-shaped hitbox around your tool
resetreachnormalreach,unreachresetreach (normalreach, unreach)Resets tool to normal size
unauraunauraStops aura loop and removes visualizer
npcauranpcaura [distance]Continuously damages nearby NPCs with equipped tool
unnpcauraunnpcauraStops NPC aura loop and removes visualizer
unantivoidunantivoidDisables antivoid
nofallnofalldamage,antifall,nofalldmgnofall [limit] [slow]Prevents fall damage by slowing falls and cancelling landing velocity (STILL IN BETA)
unnofallunnofalldamage,unantifall,unnofalldmgunnofallDisables nofall
fakeoutfakeouttp to void and back
invisflinginvisflingEnables invisible fling (the invis part is patched, try using the god command before using this)
splitsplitDestroys waist joint
antivoid2antivoid2sets FallenPartsDestroyHeight to -inf
unantivoid2unantivoid2reverts FallenPartsDestroyHeight
antivelocityantivelo,av,velcapantivelocity [limit]Limits your character's velocity to the provided value
unantivelocityunantivelo,unav,unvelcapunantivelocityDisables the antivelocity limiter
antivelocityinstancesantivelocityobjects,antimovers,avinstances,aviantivelocityinstances (antimovers)Continuously destroys force, torque, position, orientation, and velocity mover instances inside your
unantivelocityinstancesunantivelocityobjects,unantimovers,unavinstances,unaviunantivelocityinstances (unantimovers)Stops removing force and velocity mover instances from your character
antiknockbackakbantiknockback (akb)Disables knockback
unantiknockbackunakbunantiknockback (unakb)Disables antiknockback
showcomcenterofmass,comshowcom [radiusStuds]Create a glass sphere with a Highlight at your center of mass
predictpredict <player> [leadSeconds]Visualize predicted player movement
unpredictunpredict <player>Remove prediction orb
hidecomunshowcom,uncomhidecomRemove COM tracker
droptooldropatool,dtooldroptoolDrop one of your tools
loopdroptoolsloopdrop,ldtools,ldtlsloopdroptoolsLoop drops your tools
unloopdroptoolsunloopdrop,unldtools,unldtlsunloopdroptoolsStops loop dropping tools
deleteinvispartsdeleteinvisibleparts,dipdeleteinvispartsDeletes invisible parts
invisiblepartsinvispartsinvisiblepartsShows invisible parts
uninvisiblepartsuninvispartsuninvisiblepartsMakes parts affected by invisparts return to normal
datalimitdatalimit <kbps>Set outgoing bandwidth limit in KBps
removeadsadblockremoveads (adblock)Removes billboard advertisements as they appear
unremoveadsnoadblock,disableadsunremoveads (noadblock,disableads)Stop removing billboard advertisements
reloadassetsrenderreloadassetsreloadassetsSet RenderSettings.ReloadAssets
enginesettingsinfoenginedebug,rblxsettingsinfoenginesettingsinfoShow Roblox settings service diagnostics
replicationlagbacktrackreplicationlag (backtrack)Set IncomingReplicationLag
animdataanimdataShows you information about your current animations
unanimdataunanimdata
sleeponsleeponEnable AllowSleep
unsleeponunsleeponDisable AllowSleep
throttlethrottleSet PhysicsEnvironmentalThrottle (1 = default, 2 = disabled)
qualityqualitylevelquality <1-21>Manage rendering quality settings
logphysicslogphysicsEnable Physics Error Logging
nologphysicsnologphysicsDisable Physics Error Logging
norendernorenderDisable 3d Rendering to decrease the amount of CPU the client uses
renderrenderEnable 3d Rendering
noresetdisableresetnoresetdisable reset button
resetbtnenableresetresetbtnenable reset button
loopoofloopoofLoops everyone's character sounds (everyone can hear)
unloopoofunloopoofStops the oof chaos
strengthenstrengthenMakes your character more dense (CustomPhysicalProperties)
unweakenunstrengthenunweaken (unstrengthen)Sets your characters CustomPhysicalProperties to default
weakenweakenMakes your character less dense
setmassmasssetmass <mass>Sets your character mass as close as Roblox allows
vehicleseatvseatvehicleseat (vseat)Sits you in a vehicle seat, useful for trying to find cars in games
localdateyourdatelocaldate (yourdate)Shows your current date
servertimesvtimeservertime (svtime)Shows the server's current time
serverdatesvdateserverdate (svdate)Shows the server's current date
datetimelocaldatetimedatetime (localdatetime)Shows your full local date and time
uptimeuptimeShows how long the game/session has been running
timestampepochtimestamp (epoch)Shows current Unix timestamp
unctestuncUNCTest (UNC)Test how many functions your executor supports
vulnerabilitytestvulntestvulnerabilitytest (vulntest)Test if your executor is Vulnerable
antikicknokick,bypasskick,bkantikick (nokick, bypasskick, bk)Bypass Kick on Most Games
antiteleportnoteleport,blocktpantiteleport (noteleport, blocktp)Prevents TeleportService from moving you to another place
unantikickunnokick,unbypasskick,unbkunantikickDisables Anti-Kick protection
unantiteleportunnoteleport,unblocktpunantiteleportDisables Anti-Teleport protection
anticframeteleportacframetp,acftpanticframeteleport (acframetp,acftp)Prevents client teleports
unanticframeteleportunacframetp,unacftpunanticframeteleport (unacframetp,unacftp)Disables Anti CFrame Teleport
permtripptrippermtrip (ptrip)Permanent trip that keeps you down
unpermtripunptripunpermtrip (unptrip)Disable permanent trip
antitripantiragdollantitripno tripping today bruh
unantitripunantitriptripping allowed now
disablehumanoidstatedisablehumanoidstates,disablehumstatesdisablehumanoidstateOpens a picker to disable one humanoid state
enablehumanoidstateenablehumanoidstates,restorehumanoidstate,restorehumstatesenablehumanoidstate [state/all]Restores one humanoid state or all disabled states
unoldrobloxunoldrobloxRestore skybox and studs
20122012Makes your Pedoblox CoreGui look like the 2012 CoreGui
20132013Makes your Pedoblox CoreGui look like the 2013 CoreGui
20142014Makes your Pedoblox CoreGui look like the 2014 CoreGui
20152015Makes your Pedoblox CoreGui look like the 2015 CoreGui
telekinesistelekinesistool that controls unanchored parts (depending if you have ownership of that part)
disablespawnunsetspawn,dsdisablespawn (unsetspawn, ds)Disables the previously set spawn point
autoflashbackautodeathpos,deathback,adeath,dbautoflashbackAuto-teleports you to your last death point on respawn
unautoflashbackundeathback,unadeath,undbunautoflashbackDisables auto deathpos
flashbackdeathpos,deathtp,diedtpflashbackTeleports you to your last death point
flashbackaltfba,safeplaceflashbackalt (fba)Teleports you to the 0 HP flashback point
autoflashbackaltautodeathposalt,deathbackalt,afbaautoflashbackalt (afba)Auto-teleports you to the 0 HP flashback point on respawn
unautoflashbackaltunafba,undeathbackaltunautoflashbackaltDisables auto flashback alt
tospawntstospawn (ts)Teleports you to a SpawnLocation
unhamsterunhamsterDisable hamster ball
tptoolclicktptooltptool [ui|tools]Create click/tween teleport buttons or backpack tools
unclicktptooluntptoolunclicktptoolRemove teleport buttons or tools
clickteleportclicktpclickteleportBind-only click teleport (hold bind + left click)
clickdeleteclickdelclickdeleteBind-only click delete (hold bind + left click)
thruthru <distance>Move forward by distance
olddexolddexUsing this you can see the parts / guis / scripts etc with this. A really good and helpful script.
minimapminimapjust a minimap lol
animationplayeranimplayer,aplayer,animpanimationplayerdropdown menu with all the animations the game has to be played
decompilerdecompilerChoose lua.expert or Luacid to decompile LocalScript/ModuleScript bytecode
getidfromusernamegidugetidfromusername (gidu)Copy a user's UserId by Username
getuserfromidguidgetuserfromid (guid)Copy a user's Username by ID
useriduserid <id>changes your UserId to any ID you enter
usernamenameusername <name>changes your Username to any name you enter
spoofclientidspoofclidspoofclientid <value> (spoofclid)Spoofs GetClientId() to the value you provide
unspoofclientidunspoofclidunspoofclientid (unspoofclid)Restores normal GetClientId() behavior
synapsedexsdexsynapsedex (sdex)Loads SynapseX's dex explorer
antiflingantiflingmakes other players non-collidable with you
unantiflingunantiflingrestores collision for other players
antiflingpartsantiunanchoredfling,afpartsantiflingparts [linearVelocity] [angularVelocityDisables collision on nearby unanchored non-player parts above the velocity threshold
unantiflingpartsunantiunanchoredfling,unafpartsunantiflingpartsRestores collision for unanchored parts changed by antiflingparts
lockwslockworkspacelockws (lockworkspace)Locks the whole workspace
unlockwsunlockworkspaceunlockws (unlockworkspace)Unlocks everything in Workspace
enableenableEnables a specific CoreGui
disabledisableDisables a specific CoreGui
reverbreverbcontrolreverb (reverbcontrol)Manage sound reverb settings
forcereverbfreverbforcereverbLock ambient reverb and auto-restore if changed
unforcereverbufreverb,ufr,stopforcereverbunforcereverb (ufreverb, ufr)Stop forcing ambient reverb
camcamera,cameratypecam (camera, cameratype)Manage camera type settings
forcecamforcecamLock camera type and auto-restore if changed
unforcecamufcam,ufc,stopforcecamunforcecam (ufcam, ufc)Stop forcing camera type
alignmentkeysalignkeys,akalignmentkeysEnable alignment keys
disablealignmentkeysdisablealignkeys,dakdisablealignmentkeysDisable alignment keys
espallallesp,espallplayersespall (allesp)ESP all players and clear team filtering
espenemiesespenemy,espnonteam,espnonteams,espnoteam,espnoteams,enemyesespenemies (espnonteam, espnoteam)ESP players outside your team; no-team games fall back to all others
espalliesespally,espteammates,espteamates,allyesp,alliesesp,teammateeespallies (espteammates)ESP players on your current team
espteamteamesp,espteamname,espbyteam,locateteamespteam <team prefix>ESP players in a specific team; no args = current team/allies
chamschamsESP but without the text :shock:
chamsenemieschamsenemy,chamsnonteam,enemychams,nonteamchamschamsenemies (chamsnonteam)Chams players outside your team
chamsallieschamsally,chamsteammates,allychams,teammatechamschamsallies (chamsteammates)Chams players on your current team
chamsteamteamchams,chamsteamname,chamsbyteamchamsteam <team prefix>Chams players in a specific team; no args = current team/allies
locatelocate <player|npc:filter> ... (optional)Locate specific players or NPCs
npcespespnpcnpcesp [npc:name|filter] (espnpc)Locate NPCs with highlights and labels
npcchamschamsnpcnpcchams [npc:name|filter] (chamsnpc)Highlight NPCs without labels; independent of player chams
unnpcespunespnpc,unnpcchams,unchamsnpcunnpcesp (unnpcchams)Disable NPC ESP or NPC Chams without changing player ESP
unlocateunlocate <player|npc:filter> ...
vehiclenoclipvnoclipvehiclenoclip (vnoclip)Disables vehicle collision
vehicleclipvclip,unvnoclip,unvehiclenoclipvehicleclip (vclip, unvnoclip, unvehiclenoclip)Enables vehicle collision
handlekillhkillhandlekill <player|npc:filter> (hkill)Kills a player or NPC using a tool that deals damage on touch
gethealthcurrenthealth,hpgethealthShows your current health
antibreakjointsantibjoints,nobreakjointsantibreakjointsPrevents local character joints from breaking when possible
unantibreakjointsunantibjoints,breakjointsallowedunantibreakjointsDisables AntiBreakJoints
breakjointsbjointsbreakjointsBreak your character joints and die
desyncngrepdesync (ngrep)Toggle offset desync / sync (run again to disable)
undesyncundg,syncdesyncundesync (undg,syncdesync)Disable offset desync
raknetdesyncrkdesync,rkds,rkdraknetdesync (rkdesync,rkds,rkd)Enables RakNet desync using raknet.desync(true)
unraknetdesyncunrkdesync,unrkds,unrkdunraknetdesync (unrkdesync,unrkds,unrkd)Disables RakNet desync using raknet.desync(false)
runanimplayanim,animrunanim <id> [speed] (playanim,anim)Plays an animation by ID with optional speed multiplier
animbuilderabuilderanimbuilder (abuilder)Opens animation builder GUI
setkillerkilleranimsetkiller (killeranim)Sets killer animation set
setpsychopsychoanimsetpsycho (psychoanim)Sets psycho animation set
resetanimsdefaultanims,animsresetresetanims (defaultanims,animsreset)Restores your previous animations
animcopycoreanimcopy,copyanim,copyananimcopycore <player|npc:filter>Copy core animations from a player or NPC
syncanimanimsyncsyncanim <player|npc:filter>Mirror player or NPC animations (live)
syncstopstopsync,syncend,endsync,syncoffsyncstopStop live sync and restore defaults
animresetcoreanimreset,resetanim,resetananimresetcoreReset core animations to saved
unsyncresetunsync,unsres,unsrunsyncresetStop sync and reset saved
mimicmirror,mclone,mcopy,mimimimic <player|npc:filter> [delay]Clone player or NPC movement with optional delay
mstopmoff,stopmimic,mendmstopStop mimic and restore defaults
unbubblechatunbchatunbubblechat (unbchat)Disabled BubbleChat
hideiconiconhidehideiconHides the NA icon
showiconiconshowshowiconShows the NA icon
topbarshowtopbartopbar (showtopbar)Shows the NA topbar
untopbarhidetopbaruntopbar (hidetopbar)Hides the NA topbar
lockiconpositionlockiconlockiconpositionLocks the NA icon's position (can't be dragged)
unlockiconpositionunlockiconunlockiconpositionUnlocks the NA icon's position (can be dragged again)
saveinstancesavegamesaveinstance (savegame)Saves the game with SaveInstance 420 Edition using your saved options
partnamepartpath,partgrabberpartname (partpath,partgrabber)gives a ui and allows you click on a part to grab it's path
copyteleportctcopyteleport (ct)Copies a script that teleports you to your coordinates
copytweenctwcopytween (ctw)Copies a TweenService script that moves you to your coordinates
copymovetocmtcopymoveto (cmt)Copies a Humanoid:MoveTo script that moves you to your coordinates
copylerpclcopylerp (cl)Copies a CFrame:Lerp script that moves you to your coordinates
copytptogamecttgcopytptogame (cttg)Copies a script for teleporting to the game you are currently in
copytptoservercttscopytptoserver (ctts)Copies a script for teleporting to your current game server
smallserverhopsshopsmallserverhop [legacy/rovalra] (sshop)serverhop to a small server using Roblox data or RoValra
pingserverhoppshoppingserverhop [legacy/rovalra] (pshop)serverhop by Roblox-reported ping or RoValra estimated latency
oldserverhopoldhopoldserverhop (oldhop)serverhop to one of the oldest active servers
newserverhopnewhopnewserverhop (newhop)serverhop to one of the newest active servers
versionhopvhopversionhop <version> (vhop)serverhop to a server running a specific active place version
oldversionhopovhopoldversionhop (ovhop)serverhop to the oldest currently active place version
regionhoprhopregionhop <region/city> (rhop)serverhop to a public server in a requested RoValra region
unautorejoinunautorjunautorejoin (unautorj)Disables auto rejoin command
cframeflycflycframefly [speed] (cfly)Enable CFrame-based flight with respawn-safe cleanup
uncframeflyuncflyuncflyDisable CFrame-based flight
tflytweenflytfly [speed] (tweenfly)Enables smooth flying
untflyuntweenflyuntflyDisables tween flying
tpflytranslateflytpfly [speed] (translatefly)Enable TranslateBy-based flight without forcing PlatformStand
untpflyuntranslateflyuntpflyDisable TranslateBy-based flight
antianchoraaantianchorPrevent your parts from being anchored
unantianchorunaaunantianchorAllow your parts to be anchored
freecamgotofcgoto,fcgo,fcg,freecamto,fctofreecamgoto <player|npc:filter> (fcgoto,fcgo,fcgStart or move freecam to a player or NPC
freecamgotopartfcgotopart,fcgpart,fcgp,freecamtopart,fctopart,fctpfreecamgotopart <partname> (fcgotopart,fcgpart,fStart or move freecam to an exact part name
nohatsdrophatsnohats (drophats)Drop all of your hats
instantrespawninstantr,irespawninstantrespawn (instantr, irespawn)respawn instantly
grippossetgripgrippos (setgrip)Opens a UI to manually input grip offset and rotation.
grabtoolsfindgtoolsfind,gtlsfind,grabfindgrabtoolsfind <tool name> [range]Grabs dropped tools whose names contain the given text
badgeviewerbadgeview,bviewer,badgev,bvbadgeviewer (badgeview, bviewer, badgev, bv)loads up a badge viewer UI that views all badges in the game you're in
bodytransparencybtransparency,bodytbodytransparency <number> [part1] [part2] ... (bSets LocalTransparencyModifier on selected body parts (no Head) to a value (0-1). UI supports multi-
unbodytransparencyunbtransparency,unbodytunbodytransparency (unbtransparency,unbodyt)Stops transparency loop
materialmat,charmaterial,cmat,bodymaterial,bmatmaterial <material> (mat, charmaterial, cmat, boSets every BasePart in your character to a selected material
unmaterialunmat,uncharmaterial,uncmat,unbodymaterial,unbmat,resetmaterunmaterial (unmat, uncharmaterial, uncmat, unbodRestores character materials changed by material
animationspeedanimspeed,aspeedanimationspeed <speed> (animspeed,aspeed)Adjusts the speed of currently playing animations
unanimationspeedunanimspeed,unaspeedunanimationspeed (unanimspeed,unaspeed)Stops the animation speed adjustment loop
placeidpidplaceid (pid)Copies the PlaceId of the game you're in
gameiduniverseid,gidgameid (universeid,gid)Copies the GameId/Universe Id of the game you're in
fireworkfireworkpop
placenamepnameplacename (pname)Copies the game's place name to your clipboard
gameinfoginfogameinfo (ginfo)shows info about the game you're playing
userpreviewuserp,upreviewuserpreviewshow info about a user you name
copyididcopyid <player> (id)Copies the UserId of the target
antitouchantikillbrick,antikbantitouch [remove/cantouch/advanced/loop] (antikDisables touchable parts
loopantitouchloopantikillbrick,loopantikbloopantitouch (loopantikillbrick, loopantikb)Enables AntiTouch live tracking without opening the method popup
unantitouchunantikillbrick,unantikbunantitouch (unantikillbrick, unantikb)Re-enables touchable parts
timetime <number>Sets the time
uwuifycutechatuwuify <text> (cutechat)Stylizes and sends chat text
autouwuifyautocutechatautouwuify (autocutechat)Stylizes chat input before sending
unautouwuifyunautocutechatunautouwuify (unautocutechat)Stops chat input styling
uwustutterchatstutteruwustutter (chatstutter)Enables stutter styling
unuwustutterunchatstutterunuwustutter (unchatstutter)Disables stutter styling
uwuaffixchataffixuwuaffix (chataffix)Enables suffix styling
unuwuaffixunchataffixunuwuaffix (unchataffix)Disables suffix styling
privatemessagepmprivatemessage <player> <text> (pm)Sends a private message to a player
mimicchatmimicmimicchat <player> (mimic)Mimics the chat of a player
stopmimicchatunmimicchatstopmimicchat (unmimicchat)Stops mimicking a player
verticalflingvfling,updownfling,udflingverticalfling <player|npc:filter> (vfling, updowFling a player or NPC vertically by moving above and below them
horizontalflinghfling,sidefling,lrflinghorizontalfling <player|npc:filter> (hfling, sidFling a player or NPC horizontally by moving left and right through them
perfstatsperfstats <on/off>Shows or hides performance stats
preftransparencyprefalphapreftransparency <0-15>Preferred UI transparency
timestoptstoptimestop (tstop)freezes all players (ZA WARUDO)
untimestopuntstopuntimestop (untstop)unfreeze all players
teamteam <team name>Changes your team (for the client)
reselectcharreselectcharacter,pickchar,charpickerreselectcharRe-open the character picker
starenearstarecloseststarenear (stareclosest)Stare at the closest player
unstarenearunstareclosestunstarenear (unstareclosest)Stop staring at closest player
watch2view2,spectate2watch2
unwatch2unview2unwatch2
autofollowautostalk,proxfollowautofollow (autostalk,proxfollow)Automatically follow any player who comes close
unautofollowstopautofollow,unproxfollowunautofollow (stopautofollow,unproxfollow)Stop automatically following nearby players
firekeyfkeyfirekey [key] (fkey)makes you fire a keybind using VirtualInputManager
loopverticalflingloopvfling,loopupdownfling,loopudflingloopverticalfling <player|npc:filter> (loopvflinContinuously vertical-flings a player or NPC
unloopverticalflingunloopvfling,unloopupdownfling,unloopudflingunloopverticalfling (unloopvfling, unloopupdownfStops loop vertical fling
loophorizontalflingloophfling,loopsidefling,looplrflingloophorizontalfling <player|npc:filter> (loophflContinuously horizontal-flings a player or NPC
unloophorizontalflingunloophfling,unloopsidefling,unlooplrflingunloophorizontalfling (unloophfling, unloopsidefStops loop horizontal fling
devproductsproductsdevproducts (products)Lists Developer Products
gamepassespassesgamepasses (passes)Prompt & list Game Passes (manual IDs)
listenlisten <player>Listen to your target's voice chat
vcworldvcdefaultvcworld <on/off>Toggle default spatial voice routing
unlistenunlistenStops listening
geargear [id]This is client sided and will probably not work
lockmouselockmlockmouse (lockm)Default Mouse Behaviour (idk any description)
unlockmouseunlockmunlockmouse (unlockm)Unlocks your mouse (fr this time)
lockmouse2lockm2lockmouse2 (lockm2)Locks your mouse in the center
unlockmouse2unlockm2unlockmouse2 (unlockm2)Unlocks your mouse
cursorvisiblemousevisiblecursorvisible (mousevisible)Forces the mouse cursor to remain visible without changing its lock mode
cursorfreemousefreecursorfree (mousefree)Forces the mouse cursor to remain visible and unlocked
cursorresetmouseresetcursorreset (mousereset)Forces Roblox's default visible and unlocked cursor
cursorrestoremouserestorecursorrestore (mouserestore)Stops cursor enforcement and restores the saved game cursor state
piggybackpbackpiggyback <player> (pback)Attach to a player's back while sitting
unpiggybackunpbackunpiggyback (unpback)Stop piggybacking a player
walltpwtpwalltpToggles wall top teleport (BETA)
unwalltpnowalltpunwalltp (nowalltp)Disables wall top teleport
wallhopwallhopwallhop helper
unwallhopunwallhopdisable wallhop helper
joinvoicejoinvcjoinvoicelet's you use vc if you were suspended
loopjumpbhoploopjump (bhop)Continuously jump.
unloopjumpunbhopunloopjump (unbhop)Stop continuous jumping.
jumpboostjboostjumpboost <number> (jboost)Adds extra jump velocity without changing JumpPower
unjumpboostunjboostunjumpboost (unjboost)Disables extra jump boost
trussjumptj,trussjtrussjumpBoost off trusses when you jump
untrussjumpuntj,untrussjuntrussjumpDisable trussjump
chattranslatectranslate,chattchattranslatethe very old chat translator came back after years
loopjumppowerloopjp,ljploopjumppower <number> (loopjp,ljp)Loop JumpPower
unloopjumppowerunloopjp,unljpunloopjumppower (unloopjp,unljp)Disable loop jump power
stopanimationsstopanims,stopanim,noanimstopanimations (stopanims,stopanim,noanim)Stops running animations
refreshanimationsrefreshanimation,refreshanims,refreshanimrefreshanimations (refreshanimation,refreshanimsReload character animations
toolsgearstools (gears)Copies tools from ReplicatedStorage and Lighting
toolviewtviewtoolview <player> (tview)3D tool viewer above a player's head
untoolviewuntviewuntview <player> (untview)Removes the tool viewer above a player's head
toolview2tview2toolview2 (tview2)Live-updating tool viewer
improvetexturesimprovetexturesSwitches Textures
undotexturesundotexturesSwitches Textures
serverlistserverlister,slistserverlist (serverlister,slist)open the native server browser
keyboardkeyboardprovides a keyboard gui for mobile users
autoclickerautoclickerprovides a autoclicker gui
backpackbackpackprovides a custom backpack gui
unloadbackpackunbackpackunloadbackpack (unbackpack)unloads the custom backpack gui
edgejumpejumpedgejump (ejump)Automatically jumps when you get to the edge of an object
unedgejumpnoedgejump,noejump,unejumpunedgejump (noedgejump, noejump, unejump)Disables edgejump
unequiptoolsunequiptoolsUnequips every tool you are currently holding
equiptooletoolequiptool (etool)Equip a specific tool by name or selection
loopequiptoollequiptool,loopetloopequiptool <tool name>Keeps a specific tool equipped until disabled
unloopequiptoolunloopet,unlequiptoolunloopequiptoolStops the loop equip behaviour
multitoolmtoolmultitool (mtool)Allows stacking equipped tools from your inventory
unmultitoolnomultitoolunmultitool (nomultitool)Disables multitool mode
carpetcarpet <player>Be someone's carpet
uncarpetnocarpetuncarpet (nocarpet)Undoes carpet
climbclimbAllows you to climb while in air
unclimbunclimbDisables climb
suslaylaysussuslay (laysus)Lay down in a suspicious way
unsuslayunsuslayStand up from the sussy lay
hugclickhughug (clickhug)huggies time (click on a target to hug)
unhugunhugno huggies :(
glueloopgoto,lgotoglue <player|npc:filter>Loop teleport to a player or NPC
unglueunloopgoto,noloopgotounglue (unloopgoto, noloopgoto)Stops teleporting you to a player or NPC
gluebackloopbehind,lbehindglueback <player>Loop teleport behind a player
ungluebackunloopbehind,unlbehindungluebackStops teleporting you to a player
airmomentumamomentum,aircontrolairmomentum (amomentum, aircontrol)Overrides default in-air horizontal movement with custom air control
unairmomentumunamomentum,unaircontrolunairmomentum (unamomentum, unaircontrol)Stops the custom air momentum command
loopcbringloopclientb,loppclientb,loopclientbring,lcbring,lclientbloopcbring <player|npc:filter> [distance]Continuously brings a player or NPC on your client
unloopcbringunloopclientb,unloopcientb,unlcbring,unlclientb,uncbring,uncunloopcbringDisable looped client bring
offsetwalkowalk,offsetspeed,ospeedoffsetwalk <number|off> (owalk,offsetspeed,ospeemoves the character by teleporting it a set number of studs every frame
unoffsetwalkunowalk,unoffsetspeed,unospeedunoffsetwalk (unowalk,unoffsetspeed,unospeed)Stops Offset Walk
tpjumptjumptpjump <number>
untpjumpuntjumpuntpjumpStops the tpjump command
copypositioncopypos,cposcopyposition <player|npc:filter>Get the position of a player or NPC
removeterrainrterrain,noterrainremoveterrain (rterrain, noterrain)clears terrain
memorymemmemoryShows you your current memory usage
clearnilinstancesnonilinstances,cniclearnilinstances (nonilinstances, cni)Removes nil instances
inspectinspectchecks a user's items
nonetworkpausedisablenetworkpause,nnw,nnpausenonetworkpause (disableNetworkPause,nnw,nnpause)Disable Roblox network pause overlay
networkpauseenablenetworkpause,nw,npausenetworkpause (enablenetworkpause,nw,npause)Re-enable Roblox network pause overlay
unhideguisunhideguisRestores GUIs hidden by hideguis
hidecurrentguishidecurrentgui,hidecguis,hcguis,hcgui,cguis,currentguishidecurrentguisHides only currently visible GUIs
unhidecurrentguisunhidecurrentgui,unhidecguis,unhcguis,unhcgui,uncguis,restorunhidecurrentguisRestores GUIs hidden by hidecurrentguis
unshowguisunshowguisRestores UI states set by showguis
hidetargetguihideguihidetargetgui <name>Hides a specific GUI by name
unhidetargetguiunhideguiunhidetargetguiRestores GUIs hidden by hidetargetgui
showtargetguionlyguishowtargetgui <name>Shows only a specific GUI by name
unshowtargetguirestoreguisunshowtargetguiRestores GUI states changed by showtargetgui
moduleeditormoduletable,modulartable,mtable,mtmoduleeditorloads the module editor UI
upvalueeditorupvaleditor,uveditor,upeditor,uveupvalueeditorloads the upvalue editor UI
cobaltspycobalt,cspycobaltspy (cobalt,cspy)
turtlespytspyturtlespy (tspy)executes Turtle Spy that supports both pc and mobile
fireclickdetectorsfindfcdfind,firecdfindfireclickdetectorsfind <target> (fcdfind,firecdfFires ClickDetectors substring-matching [target] in Workspace
fireproximitypromptsfindfppfind,fireppfindfireproximitypromptsfind <target> (fppfind,firepFires ProximityPrompts substring-matching [target] in Workspace
firetouchinterestsfindftifind,firetifindfiretouchinterestsfind <target> (ftifind,firetifFires TouchInterests substring-matching [target] in Workspace
proximitypromptgotopromptgoto,ppgotoproximitypromptgoto [name] (promptgoto, ppgoto)Teleports to the nearest ProximityPrompt part, optionally matching its name/object/action/parent/mod
clickdetectorgotoclickgoto,cdgotoclickdetectorgoto [name] (clickgoto, cdgoto)Teleports to the nearest ClickDetector part, optionally matching its name/parent/model
touchinterestgototouchgoto,tigototouchinterestgoto [name] (touchgoto, tigoto)Teleports to the nearest TouchInterest part, optionally matching its name/parent/part/model
autofireproxiafpautofireproxi <interval> [target]Automatically fires ProximityPrompts matching [target] every <interval> seconds
autofireproxifindafpfindautofireproxifind <interval> [target]Automatically fires ProximityPrompts matching [target] using substring matching every <interval> sec
autofireclickafcautofireclick <interval> [target]Automatically fires ClickDetectors matching [target] every <interval> seconds
autofireclickfindafcfindautofireclickfind <interval> [target]Automatically fires ClickDetectors matching [target] using substring matching every <interval> secon
autotouchatautotouch <interval> [target]Automatically fires TouchInterests on parts matching [target] every <interval> seconds
autotouchfindatfindautotouchfind <interval> [target]Automatically fires TouchInterests on parts matching [target] using substring matching every <interv
autofireremoteafrautofireremote <interval> [target]Automatically fires remotes matching [target] every <interval> seconds
autofireremotefindafrfindautofireremotefind <interval> [target]Automatically fires remotes matching [target] using substring matching every <interval> seconds
unautofireproxiuafpunautofireproxi (uafp)Stops all AutoFireProxi loops
unautofireclickuafcunautofireclick (uafc)Stops all AutoFireClick loops
unautotouchuatunautotouch (uat)Stops all AutoTouch loops
unautofireremoteuafrunautofireremote (uafr)Stops all AutoFireRemote loops
unautotouchfinduatfindunautotouchfind (uatfind)Stops substring-matching AutoTouch loops
unautofireproxifinduafpfindunautofireproxifind (uafpfind)Stops substring-matching AutoFireProxi loops
unautofireclickfinduafcfindunautofireclickfind (uafcfind)Stops substring-matching AutoFireClick loops
unautofireremotefinduafrfindunautofireremotefind (uafrfind)Stops substring-matching AutoFireRemote loops
noclickdetectorlimitsnocdlimits,removecdlimitsnoclickdetectorlimits <limit> (nocdlimits,removeSets all click detectors MaxActivationDistance to math.huge
noproximitypromptlimitsnopplimits,removepplimitsnoproximitypromptlimits <limit> (nopplimits,remoSets all proximity prompts MaxActivationDistance to math.huge
instantproximitypromptsinstantpp,ippinstantproximityprompts (instantpp,ipp)Sets proximity prompt HoldDuration values to 0
uninstantproximitypromptsuninstantpp,unippuninstantproximityprompts (uninstantpp,unipp)Restores tracked proximity prompt HoldDuration values
fastpromptsfastproximityprompts,fastppfastprompts [speed] (fastproximityprompts,fastppMakes proximity prompts use the specified speed multiplier, defaulting to 2x
unfastpromptsunfastproximityprompts,unfastppunfastprompts (unfastproximityprompts,unfastpp)Restores tracked proximity prompt HoldDuration values
promptwallsproximitypromptwalls,ppwallspromptwalls (proximitypromptwalls,ppwalls)Allows proximity prompts to be used through walls
unpromptwallsunproximitypromptwalls,unppwallsunpromptwalls (unproximitypromptwalls,unppwalls)Restores the original proximity prompt wall checks
enableproximitypromptserviceenablepps,epps,ppson,pponenableproximitypromptservice (enablepps,epps,ppsenable proximity prompt buttons
disableproximitypromptservicedisablepps,dpps,ppsoff,ppoffdisableproximitypromptservice (disablepps,dpps,pdisable proximity prompt buttons
enableproximitypromptsenableprox,enprox,enprx,enppenableproximityprompts [name]Enable ProximityPrompts (all or matching)
disableproximitypromptsdisableprox,disprox,dprx,dppdisableproximityprompts [name]Disable ProximityPrompts (all or matching)
loopenableproximitypromptsloopenableprox,lenprox,lenpploopenableproximityprompts [name]Continuously enable ProximityPrompts (all or matching)
unloopenableproximitypromptsunloopenableprox,unlenprox,unlenppunloopenableproximitypromptsStop enabling loop
breakvelocitybreakv,bvel,zvel,zerovel,stopvel,brkvelbreakvelocity (breakv,bvel,zvel,zerovel,stopvel,Sets your character's velocity to zero momentarily
maxslopeanglemsamaxslopeangle <number> (msa)Changes your character's MaxSlopeAngle
loopmaxslopeangleloopmsa,lmsaloopmaxslopeangle <number> (loopmsa,lmsa)Loop MaxSlopeAngle
unloopmaxslopeangleunloopmsa,unlmsaunloopmaxslopeangle (unloopmsa,unlmsa)Disable loop MaxSlopeAngle
ungodmodeungodungodmode (ungod)Disable invincibility
controllockctrllockcontrollock (ctrllock)Set Shiftlock keys to Control for this session
uncontrollockunctrllockuncontrollock (unctrllock)Restore Shiftlock keys to default (Shift)
resetlockresetlockResets your Shiftlock keybinds to default (LeftShift)
flashlightflflashlight (fl)Gives you a flashlight tool
lightlight <range> <brightness> <hexColor>Gives your player dynamic light
unlightnolightunlight (nolight)Removes dynamic light from your player
lightinglightingcontrollighting (lightingcontrol)Manage lighting technology settings
friendfriend <player>Sends a friend request to your target
unfriendunfriend <player>Prompts to unfriend your target
blockblockuserblock <player> (blockuser)Open block / unblock prompt for target player
unblockunblockuserunblock <player> (unblockuser)Open unblock prompt for target player
invitefriendsinviteinvitefriends [username/userId] (invite)Opens Roblox's client invite prompt, optionally targeting a user
experienceeventseventsexperienceevents (events)Shows upcoming experience events with copy/details/RSVP options
eventinfoeventinfo <eventId>Shows an experience event with copy/details/RSVP options
rsvpeventeventrsvprsvpevent <eventId> (eventrsvp)Opens Roblox's RSVP prompt for an experience event
feedbackfeedbackOpens Roblox's client experience feedback prompt
friendwebfwebfriendweb (fweb)Finds friend circles in the current server
massfollowedintomassfollowedintoShows everyone in the server that followed someone into the game
deleteremove,deldelete
deletefindremovefind,delfinddeletefind
deletelightingremovelighting,removel,ldeldeletelighting (removelighting, removel, ldel)Removes all descendants (objects) within Lighting.
lightingdisabledisablelighting,ldisablelightingdisable (disablelighting, ldisable)Disables all post-processing effects in Lighting instead of deleting them.
autodeleteautoremove,autodelautodelete
unautodeleteunautoremove,unautodelunautodelete
autodeletefindautoremovefind,autodelfindautodeletefind
unautodeletefindunautoremovefind,unautodelfindunautodeletefind (unautoremovefind,unautodelfindStops autodeletefind
deleteclassremoveclass,dcdeleteclass
autodeleteclassautoremoveclass,autodcautodeleteclass
unautodeleteclassunautoremoveclass,unautodcunautodeleteclass
chardeletecharremove,chardel,cdelete,cremove,cdelchardelete
chardeletefindcharremovefind,chardelfind,cdeletefind,cremovefind,cdelfindchardeletefind
chardeleteclasscharremoveclass,chardeleteclassname,cdcchardeleteclass
gotopartnextgpngotopartnext [prefix] <start> [end] [delay] (gpnTeleport sequentially to parts with optional prefix and duplicate handling.
gotomodelnextgmngotomodelnext [prefix] <start> [end] [delay] (gmTeleport sequentially to models with optional prefix and duplicate handling.
gotofoldernextgfngotofoldernext [prefix] <start> [end] [delay] (gTeleport sequentially through folder contents with optional prefix.
gotobreakgbgotobreak (gb)Stop the active goto sequence and clear duplicate selections.
tweengotoparttgotopart,ttopart,ttoprttweengotopart <partName>Tween to each matching part by name once
gotopartfindtopartfind,toprtfindgotopartfind
tweengotopartfindtgotopartfind,ttopartfind,ttoprtfindtweengotopartfind
gotopartclassgpc,gotopartc,gotoprtcgotopartclass
bringpartbpart,bprtbringpart
bringpartfindbpartfind,bprtfindbringpartfind
bringmodelbmodelbringmodel
bringmodelfindbmodelfindbringmodelfind
bringfolderbfldrbringfolder
gotomodeltomodelgotomodel
gotomodelfindtomodelfindgotomodelfind
gotofoldergofldrgotofolder
blackholefollowbhf,bhpull,bhfollowblackholefollowPulls unanchored parts to you with spin
noblackholefollownobhf,nobhpull,stopbhfnoblackholefollowStops blackhole follow and clears constraints
swordfightersfighter,swordf,swordbot,sfswordfighter (sfighter, swordf, swordbot, sf)Activates a sword fighting bot that engages in automated PvP combat
touchesptesptouchesp
untouchespuntespuntouchesp
proximityespprxesp,proxiespproximityesp
unproximityespunprxesp,unproxiespunproximityesp
clickespcespclickesp
unclickespuncespunclickesp
itemesptoolesp,iespitemespHighlight dropped in-game tools/items
unitemespuntoolesp,uniespunitemespDisable dropped item ESP
sitespsspsitesp
unsitespunsspunsitesp
vehiclesitespvsitesp,vspvehiclesitesp
unvehiclesitespunvsitesp,unvspunvehiclesitesp
pespesppart,partesppesp
unpespunesppart,unpartespunpesp [name|All]Remove exact-name part ESP by name or All
pespfindpartespfind,esppartfindpespfind
unpespfindunpartespfind,unesppartfindunpespfind [name|All]Remove partial-name part ESP by name or All
unanchoredunanchoredesp,uaespunanchored
ununanchoredununanchoredesp,unuaespununanchored
collisionespcolespcollisionesp
uncollisionespuncolespuncollisionesp
nocollisionespncolespnocollisionesp
unnocollisionespunncolespunnocollisionesp
propertyesppropesp,espproperty,propertyfinder,findpropertypropertyesp <Property> <Value> [class:ClassName]ESP instances with a matching readable property value
unpropertyespunpropesp,unespproperty,unpropertyfinder,unfindpropertyunpropertyesp [Property] [Value|All]Disable property ESP entries
shapeespshapesp,partshapeesp,shapefinder,shapefinderespshapeesp [Block|Ball|Cylinder|Wedge|CornerWedge]ESP Part instances with the selected Shape
unshapeespunshapesp,unpartshapeesp,unshapefinder,unshapefinderespunshapeesp [shape|All]Disable Shape ESP entries
esplocatorlocator,trackespesplocator
unesplocatorunlocator,untrackespunesplocator
folderespfespfolderesp
unfolderespunfespunfolderesp [folderName]Disables folder ESP for a folder or all
viewpartfindviewpfind,vpartfindviewpartfind
oldconsoleolddebugoldconsoleopens old version of the developer console
exportconsoleconsoleexport,conexportexportconsole [txt|json] (consoleexport, conexpoExports the current NA Console records with timestamps, duplicate counts, and structured context
partsizepsize,sizepartpartsize
partsizefindpsizefind,sizefind,partsizefpartsizefind
unpartsizeunsizepart,unpsizeunpartsizeUndo partsize—return those parts back to their original size and collision.
unpartsizefindunsizefind,unpsizefindunpartsizefindUndo partsizefind—return those resized parts back to their original size and collision.
netclaimclaimnetwork,networkclaimnetclaim [radius|all] (claimnetwork, networkclaiTry to acquire network ownership using SimulationRadius, automatic ownership, and awake physics with
unnetclaimunclaimnetwork,unnetworkclaimunnetclaim (unclaimnetwork, unnetworkclaim)Stop network ownership attempts and restore changed ownership rules, radius, and physics settings
setsimradiusssr,simradsetsimradius <number>Set sim radius using available methods. Usage: setsimradius <radius>
flyjumpflyjumpAllows you to hold space to fly up
unflyjumpnoflyjumpunflyjump (noflyjump)Disables flyjump
echolocationecho,echolocateecholocation (echo, echolocate)[BETA] Darkens the world and reveals geometry and entities from movement, landings, and spatial Soun
unecholocationunecho,noechounecholocation (unecho, noecho)Disable echolocation and restore Lighting
echopingeping,sonarpingechoping (eping, sonarping)Emit a strong manual echolocation ping
loopdayldayloopdaySunshiiiine!
unloopdayunldayunloopdayNo more sunshine
loopfullbrightloopfb,lfbloopfullbrightSunshiiiine!
unloopfullbrightunloopfb,unlfbunloopfullbrightNo more sunshine
loopnightloopn,lnloopnightMoonlight.
unloopnightunloopn,unlnunloopnightNo more moonlight.
loopnoeffectlnoeffect,loopne,lneloopnoeffectKeeps Lighting and CurrentCamera effects disabled
unloopnoeffectunlnoeffect,unloopne,unlneunloopnoeffectRestores Lighting and CurrentCamera effects
noeffectcleareffects,disableeffectsnoeffectDisables Lighting and CurrentCamera effects
loopnofoglnofog,lnf,loopnfloopnofogSee clearly forever!
unloopnofogunlnofog,unlnf,unloopnf,unnfunloopnofogNo more sight.
nightmarenmnightmareMake it dark and spooky
unnightmareunnmunnightmare (unnm)Disable nightmare mode
brightnessbrightness <number>Changes the brightness lighting property
loopbrightnessloopbri,loopbloopbrightness (loopbri,loopb)Lock the brightness lighting property
unloopbrightnessunloopbri,unloopbunloopbrightness (unloopbri,unloopb)Stop locking brightness
globalshadowsgshadowsglobalshadowsEnables global shadows
unglobalshadowsnogshadows,ungshadows,noglobalshadowsunglobalshadows (nogshadows,ungshadows,noglobalsDisables global shadows
gammaexposuregamma (exposure)gamma vision (real)
loopgammaloopexposureloopgamma (loopexposure)loop gamma vision (mega real)
unloopgammaunlgamma,unloopexposure,unlexposureunloopgamma (unlgamma, unloopexposure, unlexposustop gamma vision (real)
minzoomminzoom <amount>Set your minimum camera distance
loopmaxzoomlmaxzoom,lmzoom,lmz,forcemaxzoom,fmaxzoomloopmaxzoom <amount> (lmaxzoom,lmzoom,lmz,forcemLoop your maximum camera distance and restore it when changed
unloopmaxzoomunlmaxzoom,unlmzoom,unlmz,unforcemaxzoom,unfmaxzoomunloopmaxzoom (unlmaxzoom,unlmzoom,unlmz,unforceStop looping your maximum camera distance
loopminzoomlminzoom,lnzoom,lnz,forceminzoom,fminzoomloopminzoom <amount> (lminzoom,lnzoom,lnz,forcemLoop your minimum camera distance and restore it when changed
unloopminzoomunlminzoom,unlnzoom,unlnz,unforceminzoom,unfminzoomunloopminzoom (unlminzoom,unlnzoom,unlnz,unforceStop looping your minimum camera distance
visiblevisvisibleturn visible
invisbindinvisiblebind,bindinvisinvisbind (invisiblebind, bindinvis)set a custom keybind for the 'Invisible' command
fireremotefremote,frmtfireremote [select|remote name/full name] (fremoFire one remote by selection, name, or full path
keepnakeepnakeep executing 
unkeepnaunkeepnaStop executing 
loopfovlfovloopfov <number> (lfov)Locks your FOV target (1–300)
unloopfovunlfovunloopfov (unlfov)Stops FOV loop
preventtoolsnoequip,antiequippreventtools (noequip,antiequip)Prevents any item from being equipped
unpreventtoolsunnoequip,unantiequipunpreventtools (unnoequip,unantiequip)Self-explanatory
blockremoteblockremotes,brblockremote [name|path|#id]Choose matching remotes and block with Hooks, Signals, or Both
unblockremoteunblockremotes,ubrunblockremote [name|path|#id|all]Choose a blocked remote to restore, or unblock all
bypassspeedbps,bypasswalkspeed,bpwsbypassspeed <number> (bps,bpws)Set WalkSpeed (bypass variant)
loopbypassspeedlbps,loopbypasswalkspeed,lbwsloopbypassspeed <number|off> (lbps,lbws)Loop WalkSpeed (bypass variant)
unloopbypassspeedunlbps,unloopbypasswalkspeed,unlbwsunloopbypassspeed (unlbps,unlbws)Disable loop WalkSpeed (bypass variant)
clearerrornoerrorclearerrorClears any current error or disconnected UI immediately
antierrorantierrorContinuously blocks and clears any future error or disconnected UI
unantierrornoantierrorunantierrorDisables Anti Error
npcwalkspeednpcwsnpcwalkspeed <speed>Sets all NPC WalkSpeed to <speed> (default 16)
npcjumppowernpcjpnpcjumppower <power>Sets all NPC JumpPower to <power> (default 50)
loopbringnpcslbnpcs,loopbnpcs,lbringnpcs,lbringnpc,loopbringnpcloopbringnpcs [distance] (lbnpcs, loopbnpcs, lbrLoops NPC bringing
unloopbringnpcsunlbnpcs,unloopbnpcs,unlbringnpcs,unlbringnpc,unloopbringnpcunloopbringnpcs (unlbnpcs, unloopbnpcs, unlbringStops NPC bring loop
gotonpcsgotonpcsTeleports to each NPC
actnpcactnpcStart acting like an NPC
unactnpcstopnpcunactnpc (stopnpc)Stop acting like an NPC
clicktouchctouchclicktouch (ctouch)Click a TouchTransmitter part to fire a touch
unclicktouchunctouchunclicktouch (unctouch)Disable clicktouch
clickkillnpccknpcclickkillnpc (cknpc)Click on an NPC to kill it
unclickkillnpcuncknpcunclickkillnpc (uncknpc)Disable clickkillnpc
clickvoidnpccvnpcclickvoidnpc (cvnpc)Click to void NPCs
unclickvoidnpcuncvnpcunclickvoidnpc (uncvnpc)Disable click-void
clicknpcwscnpcwsclicknpcwsClick on an NPC to set its WalkSpeed
unclicknpcwsuncnpcwsunclicknpcwsDisable clicknpcws
clicknpcjpcnpcjpclicknpcjpClick on an NPC to set its JumpPower
unclicknpcjpuncnpcjpunclicknpcjpDisable clicknpcjp
renamerename <text>Renames the admin UI placeholder to the given name
unnameunnameResets the admin UI placeholder name to default
autorespawnautore,arespawnautorespawn (autore,arespawn)Teleports you back to your death position after respawn
unautorespawnunautore,unarespawnunautorespawn (unautore,unarespawn)Stops AutoRespawn
guideletegdel,guidelguidelete (gdel,guidel)Deletes GUI under mouse with Backspace/Delete, or under tap on mobile
unguideletenoguidelete,ungdel,unguidelunguidelete (noguidelete,ungdel,unguidel)Disables GUI delete
deleteselectedtooldst,dstool,delstooldeleteselectedtool (dst,dstool,delstool)Deletes currently equipped tools
removespecifictoolrstool,rsptool,rmsptoolremovespecifictool <name> (rstool,rsptool,rmsptoAutomatically removes a specific tool from backpack/character
unremovespecifictoolunrstool,unrsptool,unrmsptoolunremovespecifictool <name> (unrstool,unrsptool,Stops removing a specific tool
clearremovespecifictoolclrrstool,clearrstool,crstoolclearremovespecifictool (clrrstool,clearrstool,cStops all specific tool removal loops
propertychangedchanged,pchanged,propchangedpropertychanged <path> <property> <command> [argRuns a command when an instance property changes
unpropertychangedunchanged,unpchanged,unpropchangedunpropertychanged [path] [property]Stops propertychanged listeners
looploop [delay] <command> [args]Directly starts a command loop without opening the loop popup
unloopunloopStops all active command loops
repeatrepeat [amount] [delay] <command> [args]Runs a command a repeated amount of times
freezeunanchoredfreezeua,fuafreezeunanchored (freezeua,fua)Freezes unanchored non-character parts
thawunanchoredthawua,unfreezeunanchored,unfreezeua,tuathawunanchored (thawua,unfreezeua,tua)Thaws parts frozen by freezeunanchored
modelespmespmodelesp
modelespfindmespfind,mfindesp,modelfindespmodelespfind
unmodelespfindunmespfind,unmfindesp,unmodelfindespunmodelespfind [modelName|All]Stops partial-name model ESP tracking rules
unmodelespunmespunmodelesp [modelName]Stops a model ESP tracking rule or all rules
spooftransformstfspooftransform [x y z pitch yaw roll]Spoofs replicated character position/rotation while restoring the local render transform
unspooftransformunstfunspooftransformDisables character transform spoofing
spoofwalkswalkspoofwalk [realSpeed maskedSpeed]Uses one WalkSpeed for local simulation while exposing another around replication
unspoofwalkunswalkunspoofwalkDisables WalkSpeed masking and restores the original value
spoofvelocitysvelspoofvelocity [linX linY linZ angX angY angZ]Preserves local simulation velocity while exposing masked linear/angular assembly velocity
unspoofvelocityunsvelunspoofvelocityDisables linear/angular velocity spoofing
spoofpartspart,spoofvehiclespoofpart [x y z pitch yaw roll]Spoofs the unanchored assembly under your cursor while restoring it locally
unspoofpartunspart,unspoofvehicleunspoofpartDisables the current part/vehicle transform spoof
posesplitsposeposesplitFreezes the locally rendered Motor6D pose while animation tracks continue
unposesplitunsposeunposesplitDisables the local pose split
humspoofshumhumspoof [property realValue maskValue]Masks selected Humanoid physics properties between simulation and replication
unhumspoofunshumunhumspoof [property|all]Disables one Humanoid property mask or all masks
spoofstatussstatusspoofstatusShows currently enabled spoof features
unloadspoofsunspoofallunloadspoofsStops every spoof feature and restores saved state
nachatnachatui,nachatboxnachatOpen the Nameless Admin chat UI
nadisguisenachatdisguisenadisguise <roblox username|off> (nachatdisguiseDisguise your NA Chat appearance as another Roblox user
renderstreamedregionsstreamedregionsrenderstreamedregions [on/off]Set Render Streamed Regions
unrenderstreamedregionsnostreamedregionsunrenderstreamedregionsDisable Render Streamed Regions
joinbreakdownprintjoinsizejoinbreakdown [on/off]Set Print Join Size Breakdown
unjoinbreakdownnoprintjoinsizeunjoinbreakdownDisable Print Join Size Breakdown
streamquotaprintstreamquotastreamquota [on/off]Set Print Stream Instance Quota
unstreamquotanoprintstreamquotaunstreamquotaDisable Print Stream Instance Quota
animationassetdatashowanimationassetanimationassetdata [on/off]Set Show Active Animation Asset
unanimationassetdatanoanimationassetunanimationassetdataDisable Show Active Animation Asset
randomizejoinorderrandomjoinorderrandomizejoinorder [on/off]Set Randomize Join Instance Order
unrandomizejoinordernorandomjoinorderunrandomizejoinorderDisable Randomize Join Instance Order
physallowsleepallowsleepphysallowsleep [on/off]Set Physics Allow Sleep
unphysallowsleepnoallowsleepunphysallowsleepDisable Physics Allow Sleep
physanchorsanchorsshownphysanchors [on/off]Set Physics Anchors Shown
unphysanchorsnoanchorsshownunphysanchorsDisable Physics Anchors Shown
physassembliesassembliesshownphysassemblies [on/off]Set Physics Assemblies Shown
unphysassembliesnoassembliesshownunphysassembliesDisable Physics Assemblies Shown
physbodytypesbodytypesshownphysbodytypes [on/off]Set Physics Body Types Shown
unphysbodytypesnobodytypesshownunphysbodytypesDisable Physics Body Types Shown
collisioncostsphyscollisioncostscollisioncosts [on/off]Set Collision Costs Shown
uncollisioncostsnophyscollisioncostsuncollisioncostsDisable Collision Costs Shown
jointcoordsphysjointcoordsjointcoords [on/off]Set Joint Coordinates Shown
unjointcoordsnophysjointcoordsunjointcoordsDisable Joint Coordinates Shown
physownersownersshownphysowners [on/off]Set Physics Owners Shown
unphysownersnoownersshownunphysownersDisable Physics Owners Shown
physregionsregionsshownphysregions [on/off]Set Physics Regions Shown
unphysregionsnoregionsshownunphysregionsDisable Physics Regions Shown
awakepartsawakehighlightawakeparts [on/off]Set Awake Parts Highlighted
unawakepartsnoawakehighlightunawakepartsDisable Awake Parts Highlighted
contactpointsphyscontactpointscontactpoints [on/off]Set Contact Points Shown
uncontactpointsnophyscontactpointsuncontactpointsDisable Contact Points Shown
mechanismsshownphysmechanismsmechanismsshown [on/off]Set Mechanisms Shown
unmechanismsshownnophysmechanismsunmechanismsshownDisable Mechanisms Shown
unalignedpartsshowunalignedunalignedparts [on/off]Set Unaligned Parts Shown
ununalignedpartsnounalignedpartsununalignedpartsDisable Unaligned Parts Shown
receiveageshowreceiveagereceiveage [on/off]Set Receive Age Shown
unreceiveagenoreceiveageunreceiveageDisable Receive Age Shown
interpolationthrottleshowinterpolationthrottleinterpolationthrottle [on/off]Set Interpolation Throttle Shown
uninterpolationthrottlenointerpolationthrottleuninterpolationthrottleDisable Interpolation Throttle Shown
phystreephysicstreephystree [on/off]Set Physics Tree Shown
unphystreenophysicstreeunphystreeDisable Physics Tree Shown
decompositiongeometryshowdecompositiondecompositiongeometry [on/off]Set Decomposition Geometry
undecompositiongeometrynodecompositionundecompositiongeometryDisable Decomposition Geometry
drawcontactsforcecontactsnetforcedrawcontactsforce [on/off]Set Draw Contacts Net Force
undrawcontactsforcenocontactsnetforceundrawcontactsforceDisable Draw Contacts Net Force
drawconstraintsforceconstraintsnetforcedrawconstraintsforce [on/off]Set Draw Constraints Net Force
undrawconstraintsforcenoconstraintsnetforceundrawconstraintsforceDisable Draw Constraints Net Force
drawtotalforcetotalnetforcedrawtotalforce [on/off]Set Draw Total Net Force
undrawtotalforcenototalnetforceundrawtotalforceDisable Draw Total Net Force
forceinstancenamesdrawforcenamesforceinstancenames [on/off]Set Force Instance Names
unforceinstancenamesnoforcenamesunforceinstancenamesDisable Force Instance Names
renderboundingboxesshowboundingboxesrenderboundingboxes [on/off]Set Render Bounding Boxes
unrenderboundingboxesnoboundingboxesunrenderboundingboxesDisable Render Bounding Boxes
rendercsgtrianglesrendercsgdebugrendercsgtriangles [on/off]Set Render CSG Triangles Debug
unrendercsgtrianglesnorendercsgdebugunrendercsgtrianglesDisable Render CSG Triangles Debug
renderfrmenablefrmrenderfrm [on/off]Set Frame Rate Manager
unrenderfrmdisablefrmunrenderfrmDisable Frame Rate Manager
eagerbulkexecutionrenderbulkeagerbulkexecution [on/off]Set Eager Bulk Execution
uneagerbulkexecutionnorenderbulkuneagerbulkexecutionDisable Eager Bulk Execution
exportmergebymaterialmergebymaterialexportmergebymaterial [on/off]Set Export Merge By Material
unexportmergebymaterialnomergebymaterialunexportmergebymaterialDisable Export Merge By Material
soundwarningsreportsoundwarningssoundwarnings [on/off]Set Report Sound Warnings
unsoundwarningsnoreportsoundwarningsunsoundwarningsDisable Report Sound Warnings
videocapturevideocaptureenabledvideocapture [on/off]Set Video Capture Enabled
unvideocapturenovideocaptureunvideocaptureDisable Video Capture Enabled
forcedrawscaleforcevisualscaleforcedrawscale <number>Set Force Draw Scale
torquedrawscaletorquevisualscaletorquedrawscale <number>Set Torque Draw Scale
fluidforcedrawscalefluidforcescalefluidforcedrawscale <number>Set Fluid Force Draw Scale
forcesmoothingstepsforcevisualstepsforcesmoothingsteps <0-100>Set Force Smoothing Steps
throttleadjusttimephysadjusttimethrottleadjusttime <seconds>Set Throttle Adjust Time
renderautofrmautofrmlevelrenderautofrm <number>Set Auto FRM Level
meshcachesizerendermeshcachemeshcachesize <number>Set Mesh Cache Size
reserveserverprivateserver,ps,rsreserveserver [code/link] [instanceId] | reserveTeleports to a reserved server or creates one if code is missing
]=====]
D.uhCount = 380
return D
