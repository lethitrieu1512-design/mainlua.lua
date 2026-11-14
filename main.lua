-- CodeBot V1.8 | Roblox Luau (Delta compatible)
-- JJS Item ESP  |  Atom-style GUI  |  HvH tab (orbit / spin)  |  Roblox notifications
-- Categories, C4/item alerts, radar, off-screen arrows, item list (TP/Hide),
-- instant/auto pickup, auto collect (TP), player ESP, movement/fly/noclip, utility, save/load config

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")
local StatsService = game:GetService("Stats")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- stop a previous copy before starting a new one
if getgenv().ItemESP_Cleanup then pcall(getgenv().ItemESP_Cleanup) end

---------------------------------------------------------------------
-- CONFIG (+ save / load)
---------------------------------------------------------------------
local Config = {
	-- ESP
	Enabled = true, Highlight = true, Boxes = false, NameTag = true, CategoryTag = true, Distance = true,
	Tracers = false, FadeWithDistance = false, PulseAlerts = true,
	MaxDistance = 2000, TextSize = 15, FillTransparency = 60, TracerOrigin = "Bottom",

	-- categories shown
	ShowExplosive = true, ShowWeapon = true, ShowHealing = true, ShowCursed = true,
	ShowCurrency = true, ShowCustom = true, ShowOther = true,

	-- detection
	ScanMode = "Smart", ScanInterval = 10, ExtraNames = "", HiddenNames = "",

	-- alerts
	AlertEnabled = true, AlertNames = "C4", AlertSound = true, AlertSoundType = "Ping", AlertVolume = 5,
	AlertDistance = 0, AlertRemind = 0, AlertOnDespawn = false, AlertArrows = true,
	AlertCatExplosive = false, AlertCatWeapon = false, AlertCatHealing = false,
	AlertCatCursed = false, AlertCatCurrency = false, AlertCatCustom = false,

	-- radar
	ShowRadar = false, RadarRange = 300, RadarSize = 200, RadarAlertOnly = false,

	-- pickup
	InstantPrompt = false, AutoPickup = false, AutoPickupRange = 12, AutoPickupAlertOnly = false,

	-- item list
	ListSearch = "", ListSort = "Distance",

	-- misc
	ToggleKey = "None", AutoSave = true, HideUsername = false,
	DragSpeed = 65, LogoSize = 64, ClickSound = true, RippleOn = true, Whitelist = "", WhitelistFriends = true, Crosshair = false, CrossSize = 12, CrossGap = 4, ColorCross = Color3.fromRGB(0, 226, 212), TimeOn = false, TimeVal = 14, Profile = "1",
	BypassEnabled = false, BypassSpot = "Sky Platform", BypassMax = 12, MenuKey = "RightShift", DeathReturn = false, FPSBoost = false, JoinAlerts = true, WPSlot = "1", ClickSoundType = "Click", ClickVolume = 5, -- drag speed in % (60 = 0.6), minimized logo size in px

	-- notifications (Roblox's own notification popup)
	StatusNotify = true, NotifyDuration = 6, NotifyStyle = "Hub",
	AutoClick = false, ClickCPS = 10, AutoRejoin = false, JoinJobId = "",

	-- auto collect / prompt tweaks
	WalkCollect = false, WalkNames = "", WalkItemSpeed = 60, WalkRange = 2000, WalkTimeout = 40,
	AutoCollect = false, AutoCollectAlertOnly = true, AutoCollectReturn = true, AutoCollectRange = 1500,
	ExtendPrompts = false, PromptRange = 100,

	-- player ESP
	PlayerESP = false, PBox = true, PName = true, PHealth = true, PDistance = true, PTracers = false,
	PTeamCheck = false, PMaxDistance = 3000, ColorPlayer = Color3.fromRGB(255, 80, 80),

	-- movement
	SpeedOn = false, WalkSpeedVal = 50, JumpOn = false, JumpPowerVal = 100, InfJump = false,
	Noclip = false, Fly = false, FlySpeed = 80,
	ClickTP = false, SpectateOn = false, TPName = "",

	-- HvH
	OrbitOn = false, OrbitSpeed = 2000, OrbitRadius = 8, OrbitHeight = 0, OrbitTarget = "", OrbitStableCam = true,
	OrbitMode = "Circle", OrbitTargetMode = "Closest", OrbitLock = true, OrbitFace = true, OrbitTeamCheck = true,
	OrbitMaxDist = 1000, OrbitKey = "None", OrbitAttack = false, OrbitAttackCPS = 12,
	SpinOn = false, SpinSpeed = 1500,
	TargetHL = true, NotifyKill = true, HitboxOn = false, HitboxSize = 10, VoidSafe = true, VoidY = -500,
	AimOn = false, AimPart = "Head", AimSmooth = 40, AimFOV = 250, ShowFOV = true, AimTeamCheck = true, AimWallCheck = false,
	AuraOn = false, AuraRange = 15, AuraCPS = 10, AutoFace = false,
	PanicOn = false, PanicHP = 25, PanicHeight = 200,
	CFrameSpeed = false, CFrameSpeedVal = 40, Bhop = false, LowGravity = false, GravityVal = 60,
	FlyKey = "None", NoclipKey = "None", SpeedKey = "None",
	WP1 = "", WP2 = "", WP3 = "",
	OrbitWalk = true, OrbitEngage = 10, OrbitWalkSpeed = 60, TargetHUD = true, HUDSize = 33, OutlineRipple = true, PGlow = true, InfZoom = false, HideKey = "None",

	-- utility
	AntiAFK = true, Fullbright = false, FOVOn = false, FOVVal = 90,

	-- colors
	ColorExplosive = Color3.fromRGB(255, 140, 28),
	ColorWeapon = Color3.fromRGB(80, 170, 255),
	ColorHealing = Color3.fromRGB(0, 255, 120),
	ColorCursed = Color3.fromRGB(170, 80, 255),
	ColorCurrency = Color3.fromRGB(255, 220, 0),
	ColorCustom = Color3.fromRGB(0, 230, 230),
	ColorOther = Color3.fromRGB(230, 230, 235),
	AlertColor = Color3.fromRGB(255, 60, 60),
	TracerColor = Color3.fromRGB(255, 255, 255),
}
getgenv().ItemESPConfig = Config

local DEFAULTS = {}
for k, v in pairs(Config) do DEFAULTS[k] = v end

local FILE = "CodeBot_ItemESP.json"

local function saveConfig(file)
	if not writefile then return false end
	local data = {}
	for k, v in pairs(Config) do
		local t = typeof(v)
		if t == "Color3" then
			data[k] = { math.floor(v.R * 255 + 0.5), math.floor(v.G * 255 + 0.5), math.floor(v.B * 255 + 0.5) }
		elseif t == "boolean" or t == "number" or t == "string" then
			data[k] = v
		end
	end
	local ok = pcall(function() writefile(file or FILE, HttpService:JSONEncode(data)) end)
	return ok
end

local function loadConfig(file)
	if not (readfile and isfile) then return false end
	local ok, raw = pcall(function()
		if isfile(file or FILE) then return readfile(file or FILE) end
		return nil
	end)
	if not ok or not raw then return false end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 or type(data) ~= "table" then return false end
	for k, v in pairs(data) do
		local cur = Config[k]
		if typeof(cur) == "Color3" and type(v) == "table" then
			Config[k] = Color3.fromRGB(v[1] or 255, v[2] or 255, v[3] or 255)
		elseif cur ~= nil and type(v) == type(cur) then
			Config[k] = v
		end
	end
	return true
end

loadConfig() -- settings from last time
-- risky toggles never start switched on
Config.Fly, Config.Noclip, Config.AutoCollect, Config.WalkCollect, Config.OrbitOn = false, false, false, false, false
Config.SpectateOn, Config.ClickTP, Config.AutoClick, Config.SpinOn, Config.OrbitAttack = false, false, false, false, false
Config.BypassEnabled = false
Config.AimOn, Config.AuraOn, Config.AutoFace, Config.CFrameSpeed, Config.Bhop, Config.LowGravity = false, false, false, false, false, false
Config.HitboxOn = false

local connections = {}
local running = true
local UI = {}      -- filled by the GUI
local Actions = {} -- filled by the ESP logic
local Feat = {}    -- extra features (player ESP, movement, utility, auto collect, HvH)

---------------------------------------------------------------------
-- SHARED HELPERS + ITEM CATEGORIES
---------------------------------------------------------------------
local function parseList(str)
	local list = {}
	for w in string.gmatch(string.lower(str or ""), "[^,]+") do
		w = string.match(w, "^%s*(.-)%s*$")
		if w ~= "" then list[#list + 1] = w end
	end
	return list
end

local function nameHas(lname, list)
	for _, w in ipairs(list) do
		if string.find(lname, w, 1, true) then return true end
	end
	return false
end

local CATEGORIES = {
	{ id = "Explosive", label = "Explosives", words = { "c4", "bomb", "grenade", "mine", "dynamite", "tnt", "explosive" } },
	{ id = "Weapon", label = "Weapons", words = { "sword", "blade", "katana", "knife", "dagger", "gun", "pistol", "rifle", "bow", "spear", "axe", "weapon", "staff", "scythe" } },
	{ id = "Healing", label = "Healing", words = { "heal", "potion", "medkit", "bandage", "food", "ramen", "soda", "drink", "pill", "snack" } },
	{ id = "Cursed", label = "Cursed", words = { "cursed", "finger", "talisman", "charm", "relic", "orb", "scroll", "seal", "shard", "spirit" } },
	{ id = "Currency", label = "Currency", words = { "coin", "cash", "gold", "money", "gem", "yen", "token" } },
	{ id = "Custom", label = "Custom", words = {} },
	{ id = "Other", label = "Other", words = {} },
}
local CAT = {}
for _, c in ipairs(CATEGORIES) do CAT[c.id] = c end

local alertList = parseList(Config.AlertNames)
local extraList = parseList(Config.ExtraNames)
local hiddenList = parseList(Config.HiddenNames)

local function categorize(lname)
	if nameHas(lname, extraList) then return CAT.Custom end
	for _, c in ipairs(CATEGORIES) do
		if #c.words > 0 and nameHas(lname, c.words) then return c end
	end
	return CAT.Other
end

local function getGuiParent()
	local ok, result = pcall(function()
		if gethui then return gethui() end
		return game:GetService("CoreGui")
	end)
	if ok and result then return result end
	return player:WaitForChild("PlayerGui")
end

-- notification: "Hub" = card in the GUI style (bottom-right), "Roblox" = Roblox's own popup. `isStatus` = non-alert message.
local function notify(title, text, isStatus)
	if isStatus and not Config.StatusNotify then return end
	if Config.NotifyStyle ~= "Roblox" and UI.toast then
		pcall(UI.toast, title, text, isStatus and "info" or "alert")
		return
	end
	task.spawn(function()
		for _ = 1, 8 do -- the core script may not be ready yet right after execution
			local ok = pcall(function()
				StarterGui:SetCore("SendNotification", { Title = tostring(title), Text = tostring(text or ""), Duration = Config.NotifyDuration })
			end)
			if ok then return end
			task.wait(0.5)
		end
	end)
end

---------------------------------------------------------------------
-- GUI (same look as The S hub)
---------------------------------------------------------------------
local screenGui

do
	local DESIGN_W, DESIGN_H = 1515, 860
	local SIDE_W, HEAD_H, PROFILE_H = 415, 147, 120

	local F = {
		Reg = Enum.Font.Gotham, Med = Enum.Font.GothamMedium, Semi = Enum.Font.GothamSemibold,
		Bold = Enum.Font.GothamBold, Black = Enum.Font.GothamBlack,
	}
	local C = {
		Window = Color3.fromRGB(15, 18, 20), Side = Color3.fromRGB(15, 18, 20), Panel = Color3.fromRGB(23, 28, 30),
		Tile = Color3.fromRGB(17, 21, 23), Input = Color3.fromRGB(12, 15, 17), Line = Color3.fromRGB(36, 44, 46),
		Bar = Color3.fromRGB(70, 82, 86), BarLight = Color3.fromRGB(150, 160, 164), White = Color3.fromRGB(240, 244, 244),
		SubText = Color3.fromRGB(135, 146, 150), ToggleOff = Color3.fromRGB(40, 48, 50), Knob = Color3.fromRGB(10, 14, 16),
		Selected = Color3.fromRGB(32, 40, 42), IconBox = Color3.fromRGB(30, 37, 39), Check = Color3.fromRGB(0, 226, 212), Accent = Color3.fromRGB(0, 226, 212),
	}

	local function create(className, props, parent)
		local inst = Instance.new(className)
		for k, v in pairs(props) do inst[k] = v end
		inst.Parent = parent
		return inst
	end
	local function corner(parent, r) create("UICorner", { CornerRadius = UDim.new(0, r or 8) }, parent) end
	local function stroke(parent, color, th)
		return create("UIStroke", { Color = color or C.Line, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
	end
	local function txt(parent, str, size, color, font, align)
		return create("TextLabel", {
			BackgroundTransparency = 1, Text = str, TextSize = size, TextColor3 = color, Font = font or F.Reg,
			TextXAlignment = align or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.new(0, 300, 0, size + 10),
		}, parent)
	end
	local function hexOf(c)
		return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	local function loadAvatar(img)
		task.spawn(function()
			local ok, url = pcall(function() return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end)
			if ok and url then img.Image = url end
		end)
	end

	local guiParent = getGuiParent()
	local old = guiParent:FindFirstChild("ItemESP_Gui")
	if old then old:Destroy() end

	screenGui = create("ScreenGui", { Name = "ItemESP_Gui", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, guiParent)

	local main = create("Frame", {
		Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(DESIGN_W, DESIGN_H), BackgroundColor3 = C.Window, BackgroundTransparency = 0.08, BorderSizePixel = 0,
	}, screenGui)
	corner(main, 30)
	local mainStroke = stroke(main, Color3.fromRGB(32, 72, 72), 2)
	UI.main = main

	-- outline ripple: rings keep expanding out of the window border (same effect as the small logo)
	local function outlineRing(strong)
		local grow = strong and 220 or 140
		local ring = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0 }, main)
		local rc = create("UICorner", { CornerRadius = UDim.new(0, 30) }, ring)
		local st = stroke(ring, Color3.fromRGB(58, 140, 255), 4)
		st.Transparency = strong and 0 or 0.35
		local info = TweenInfo.new(strong and 0.9 or 1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(ring, info, { Size = UDim2.new(1, grow, 1, grow) }):Play()
		TweenService:Create(rc, info, { CornerRadius = UDim.new(0, 30 + grow / 2) }):Play()
		TweenService:Create(st, info, { Transparency = 1 }):Play()
		task.delay(1.8, function() ring:Destroy() end)
	end
	UI.outlineRing = outlineRing
	task.spawn(function()
		while running do
			if main.Visible and Config.OutlineRipple then pcall(outlineRing, false) end
			task.wait(1.2)
		end
	end)

	-- click sound (one reusable Sound, volume / type from Settings)
	local CLICK_IDS = { Click = "rbxasset://sounds/button.wav", Snap = "rbxasset://sounds/snap.mp3", Switch = "rbxasset://sounds/switch.mp3" }
	local clickSnd = Instance.new("Sound")
	clickSnd.Name = "CodeBotClick"
	pcall(function() clickSnd.Parent = SoundService end)
	UI.clickSnd = clickSnd
	local lastClickId
	function UI.click()
		if not Config.ClickSound then return end
		local id = CLICK_IDS[Config.ClickSoundType] or CLICK_IDS.Click
		if id ~= lastClickId then
			lastClickId = id
			clickSnd.SoundId = id
		end
		clickSnd.Volume = Config.ClickVolume / 5
		clickSnd.TimePosition = 0
		pcall(function() clickSnd:Play() end)
	end

	local uiScale = create("UIScale", { Scale = 1 }, main)
	local function updateScale()
		local s = screenGui.AbsoluteSize
		if s.X > 0 and s.Y > 0 then uiScale.Scale = math.min(s.X * 0.66 / DESIGN_W, s.Y * 0.80 / DESIGN_H) * (UI.scaleMul or 1) end
	end
	updateScale()
	table.insert(connections, screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale))

	-- generic drag helper: moves `target`; scaled = divide by the window UIScale. Drag speed = Config.DragSpeed / 100
	-- ripple effect: the whole window ripples where you tap, and every button / card / tab gets its own ripple
	local mainRipple = create("CanvasGroup", { Name = "MainRipple", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 0, Active = false }, main)
	create("UICorner", { CornerRadius = UDim.new(0, 30) }, mainRipple)
	local function spawnRipple(holder, target, x, y, alpha, spread)
		if not Config.RippleOn then return end
		pcall(function()
			local ap, as = target.AbsolutePosition, target.AbsoluteSize
			local sc = math.max(uiScale.Scale, 0.01)
			local lx = math.clamp((x - ap.X) / sc, 0, as.X / sc)
			local ly = math.clamp((y - ap.Y) / sc, 0, as.Y / sc)
			local maxd = math.max(as.X, as.Y) / sc * (spread or 2.3)
			local c = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(lx, ly), Size = UDim2.fromOffset(0, 0), BackgroundColor3 = C.Accent, BackgroundTransparency = alpha, BorderSizePixel = 0 }, holder)
			create("UICorner", { CornerRadius = UDim.new(1, 0) }, c)
			local info = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			TweenService:Create(c, info, { Size = UDim2.fromOffset(maxd, maxd), BackgroundTransparency = 1 }):Play()
			task.delay(0.65, function() c:Destroy() end)
		end)
	end
	local function addRipple(target, trigger, radius)
		trigger.MouseButton1Down:Connect(function(x, y)
			local holder = target:FindFirstChild("RippleHolder")
			if not holder then
				holder = create("CanvasGroup", { Name = "RippleHolder", Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ZIndex = 50, Active = false }, target)
				local cr = target:FindFirstChildOfClass("UICorner")
				create("UICorner", { CornerRadius = cr and cr.CornerRadius or UDim.new(0, radius or 22) }, holder)
			end
			spawnRipple(holder, target, x, y, 0.72)
		end)
	end
	table.insert(connections, UserInputService.InputBegan:Connect(function(input)
		if not main.Visible then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local ap, as = main.AbsolutePosition, main.AbsoluteSize
		local x, y = input.Position.X, input.Position.Y
		if x >= ap.X and x <= ap.X + as.X and y >= ap.Y and y <= ap.Y + as.Y then
			spawnRipple(mainRipple, main, x, y, 0.86, 1.3)
		end
	end))

	local function makeDraggable(handle, target, scaled)
		local dragging, dragStart, startPos = false, nil, nil
		handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging, dragStart, startPos = true, input.Position, target.Position
			end
		end)
		table.insert(connections, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = (input.Position - dragStart) * (Config.DragSpeed / 100)
				if scaled then delta = delta / uiScale.Scale end
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end))
		table.insert(connections, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
		end))
	end

	-- header (same layout as the Vxeze hub) -----------------------------
	local header = create("Frame", { Size = UDim2.new(1, 0, 0, HEAD_H), BackgroundTransparency = 1, Active = true }, main)
	makeDraggable(header, main, true)
	create("TextLabel", {
		BackgroundTransparency = 1, Text = "Item ESP Hub [ Free ]", TextSize = 46, Font = F.Semi, TextColor3 = C.White,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 55, 0, 26), Size = UDim2.new(0, 800, 0, 60),
	}, header)
	local subTitle = create("TextLabel", {
		BackgroundTransparency = 1, Text = "", TextSize = 32, Font = F.Reg, TextColor3 = C.SubText,
		TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 55, 0, 84), Size = UDim2.new(0, 800, 0, 40),
	}, header)
	-- "Hide Username" support (the name lives in the subtitle)
	local usernameLabels = { { label = subTitle, real = "Jujutsu Shenanigans  -  @" .. player.Name, hidden = "Jujutsu Shenanigans  -  @********" } }
	function UI.applyUsername()
		for _, h in ipairs(usernameLabels) do
			h.label.Text = Config.HideUsername and h.hidden or h.real
		end
	end

	-- round avatar badge, top-center, sticking out of the window like the reference
	local badge = create("ImageLabel", {
		Size = UDim2.fromOffset(96, 96), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -12),
		BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Image = "", ZIndex = 5,
	}, main)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, badge)
	stroke(badge, Color3.fromRGB(58, 140, 255), 4)
	loadAvatar(badge)

	-- header buttons (drawn with frames so no font glyph is needed)
	local function hbtn(offsetFromRight)
		return create("TextButton", {
			Size = UDim2.fromOffset(70, 70), Position = UDim2.new(0, DESIGN_W - offsetFromRight, 0, 38),
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
		}, header)
	end
	local searchBtn, minBtn, maxBtn, closeBtn = hbtn(335), hbtn(250), hbtn(165), hbtn(80)
	do -- search icon
		local ring = create("Frame", { Size = UDim2.fromOffset(26, 26), Position = UDim2.fromOffset(16, 14), BackgroundTransparency = 1 }, searchBtn)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
		stroke(ring, C.BarLight, 3)
		create("Frame", { Size = UDim2.fromOffset(15, 3), Position = UDim2.fromOffset(38, 46), Rotation = 45, BackgroundColor3 = C.BarLight, BorderSizePixel = 0 }, searchBtn)
		-- minimize
		create("Frame", { Size = UDim2.fromOffset(30, 3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = C.BarLight, BorderSizePixel = 0 }, minBtn)
		-- maximize
		local sq = create("Frame", { Size = UDim2.fromOffset(28, 28), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1 }, maxBtn)
		corner(sq, 7)
		stroke(sq, C.BarLight, 3)
		-- close
		for _, rot in ipairs({ 45, -45 }) do
			create("Frame", { Size = UDim2.fromOffset(34, 3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Rotation = rot, BackgroundColor3 = C.BarLight, BorderSizePixel = 0 }, closeBtn)
		end
	end
	UI.closeBtn = closeBtn
	addRipple(searchBtn, searchBtn, 35)
	addRipple(minBtn, minBtn, 35)
	addRipple(maxBtn, maxBtn, 35)
	addRipple(closeBtn, closeBtn, 35)
	UI.scaleMul = 1
	maxBtn.MouseButton1Click:Connect(function()
		UI.click()
		UI.scaleMul = (UI.scaleMul == 1) and 1.18 or 1
		updateScale()
	end)
	local searchBox = create("TextBox", {
		Visible = false, Size = UDim2.fromOffset(360, 62), Position = UDim2.new(0, DESIGN_W - 335 - 380, 0, 42),
		BackgroundColor3 = C.Input, BorderSizePixel = 0, Text = "", PlaceholderText = "Search tab...", PlaceholderColor3 = C.SubText,
		TextColor3 = C.White, TextSize = 28, Font = F.Reg, ClearTextOnFocus = true,
	}, header)
	corner(searchBox, 18)
	searchBtn.MouseButton1Click:Connect(function()
		UI.click()
		searchBox.Visible = not searchBox.Visible
		if searchBox.Visible then searchBox:CaptureFocus() end
	end)
	searchBox.FocusLost:Connect(function()
		if UI.search then UI.search(searchBox.Text) end
		searchBox.Visible = false
	end)

	-- teal line under the header (fades at both ends)
	local accentLine = create("Frame", { Size = UDim2.new(1, -20, 0, 3), Position = UDim2.new(0, 10, 0, HEAD_H), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, main)
	create("UIGradient", { Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.12, 0.25), NumberSequenceKeypoint.new(0.88, 0.25), NumberSequenceKeypoint.new(1, 1),
	}) }, accentLine)

	-- sidebar ------------------------------------------------------
	local sidebar = create("Frame", { Position = UDim2.new(0, 0, 0, HEAD_H + 3), Size = UDim2.new(0, SIDE_W, 1, -(HEAD_H + 3)), BackgroundTransparency = 1, BorderSizePixel = 0 }, main)
	create("Frame", { Size = UDim2.new(0, 2, 1, -50), Position = UDim2.new(1, -2, 0, 14), BackgroundColor3 = C.Line, BorderSizePixel = 0 }, sidebar)
	local sideScroll = create("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 1, -PROFILE_H), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, sidebar)
	create("UIPadding", { PaddingTop = UDim.new(0, 18), PaddingLeft = UDim.new(0, 40), PaddingRight = UDim.new(0, 44) }, sideScroll)
	create("UIListLayout", { Padding = UDim.new(0, 11), SortOrder = Enum.SortOrder.LayoutOrder }, sideScroll)
	local heartBtn = create("TextButton", {
		Size = UDim2.fromOffset(82, 80), Position = UDim2.new(0, 40, 1, -(PROFILE_H - 14)), BackgroundColor3 = C.Selected, BorderSizePixel = 0,
		Text = "♥", TextSize = 38, Font = F.Bold, TextColor3 = C.White, AutoButtonColor = false,
	}, sidebar)
	corner(heartBtn, 22)
	addRipple(heartBtn, heartBtn, 22)
	heartBtn.MouseButton1Click:Connect(function()
		UI.click()
		if UI.openPage then UI.openPage("Settings") end
	end)

	-- content: pill tabs on top, pages below ---------------------------
	local CONTENT_W = DESIGN_W - SIDE_W
	local TAB_H = 146
	local content = create("Frame", { Position = UDim2.new(0, SIDE_W, 0, HEAD_H + 3), Size = UDim2.new(1, -SIDE_W, 1, -(HEAD_H + 3)), BackgroundTransparency = 1 }, main)
	local tabBar = create("Frame", { Size = UDim2.new(1, 0, 0, TAB_H), BackgroundTransparency = 1 }, content)
	create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, tabBar)
	create("UIPadding", { PaddingLeft = UDim.new(0, 44) }, tabBar)
	local pageHolder = create("Frame", { Position = UDim2.new(0, 0, 0, TAB_H), Size = UDim2.new(1, -16, 1, -(TAB_H + 24)), BackgroundTransparency = 1 }, content)

	-- pages / sections / rows -----------------------------------------
	local pages = {}
	local function newPage(name)
		local sf = create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Bar,
			AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false,
		}, pageHolder)
		local col = create("Frame", { Size = UDim2.new(0, CONTENT_W - 118, 0, 0), Position = UDim2.new(0, 48, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y }, sf)
		create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, col)
		pages[name] = { frame = sf, left = col, right = col } -- one wide column, like the reference
		return pages[name]
	end

	-- section header: ──── icon  Title ────          v
	local function section(parent, title, order, icon)
		local n = (parent:GetAttribute("n") or 0) + 1
		parent:SetAttribute("n", n)
		local s = create("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = n }, parent)
		create("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder }, s)
		local obj = { frame = s, n = 0, collapsed = false, rows = {}, dividers = {} }
		local hdr = create("TextButton", { Size = UDim2.new(1, 0, 0, 112), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 0 }, s)
		local mid = create("Frame", { Size = UDim2.new(0, 0, 0, 50), AutomaticSize = Enum.AutomaticSize.X, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1 }, hdr)
		create("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 20), SortOrder = Enum.SortOrder.LayoutOrder }, mid)
		local l1 = create("Frame", { Size = UDim2.fromOffset(110, 3), BackgroundColor3 = C.Accent, BorderSizePixel = 0, LayoutOrder = 1 }, mid)
		create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) }) }, l1)
		create("TextLabel", { Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = (icon or "◎") .. "  " .. title, TextSize = 36, Font = F.Med, TextColor3 = C.White, LayoutOrder = 2 }, mid)
		local l2 = create("Frame", { Size = UDim2.fromOffset(110, 3), BackgroundColor3 = C.Accent, BorderSizePixel = 0, LayoutOrder = 3 }, mid)
		create("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }) }, l2)
		local chev = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -150, 0.5, 0), Text = "v", TextSize = 26, Font = F.Bold, TextColor3 = C.BarLight }, hdr)
		addRipple(hdr, hdr, 18)
		hdr.MouseButton1Click:Connect(function()
			UI.click()
			obj.collapsed = not obj.collapsed
			chev.Text = obj.collapsed and ">" or "v"
			for _, r in ipairs(obj.rows) do r.Visible = (not obj.collapsed) and not r:GetAttribute("hidden") end
		end)
		return obj
	end

	-- every option is a dark rounded card with a teal bar on the left
	local function row(sec, height)
		local r = create("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundColor3 = C.Panel, BackgroundTransparency = 0.05, BorderSizePixel = 0, LayoutOrder = sec.n + 1 }, sec.frame)
		corner(r, 26)
		local bar = create("Frame", { Size = UDim2.new(0, 8, 0, math.clamp(height * 0.46, 44, 84)), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 34, 0.5, 0), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, r)
		corner(bar, 4)
		sec.n = sec.n + 1
		table.insert(sec.rows, r)
		return r
	end

	local function finish(sec)
		create("Frame", { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = 9999 }, sec.frame)
	end

	local function rowLabel(r, name, cy)
		local l = txt(r, name, 34, C.White, F.Med)
		l.Position = UDim2.new(0, 72, 0, cy)
		l.Size = UDim2.new(1, -330, 0, 44)
		return l
	end

	-- controls (all bound to a Config key, so Load/Reset can refresh them) ------
	local syncers = {}
	function UI.sync()
		for _, f in ipairs(syncers) do pcall(f) end
		UI.applyUsername()
		if UI.applyLogo then pcall(UI.applyLogo) end
	end

	local function addCheckbox(sec, name, key, onChange)
		local r = row(sec, 112)
		rowLabel(r, name, 56).Size = UDim2.new(1, -260, 0, 44)
		local track = create("TextButton", {
			Size = UDim2.fromOffset(100, 54), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -44, 0.5, 0),
			BackgroundColor3 = Config[key] and C.Accent or C.ToggleOff, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
		}, r)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
		addRipple(r, track)
		local knob = create("Frame", { Size = UDim2.fromOffset(42, 42), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, Config[key] and 52 or 6, 0.5, 0), BackgroundColor3 = C.White, BorderSizePixel = 0 }, track)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
		local function apply(v)
			TweenService:Create(track, TweenInfo.new(0.14), { BackgroundColor3 = v and C.Accent or C.ToggleOff }):Play()
			TweenService:Create(knob, TweenInfo.new(0.14), { Position = UDim2.new(0, v and 52 or 6, 0.5, 0) }):Play()
		end
		table.insert(syncers, function() apply(Config[key]) end)
		track.MouseButton1Click:Connect(function()
			UI.click()
			local v = not Config[key]
			Config[key] = v
			apply(v)
			if onChange then onChange(v) end
		end)
		return function(v) -- setter (used by the hotkeys)
			Config[key] = v
			apply(v)
			if onChange then onChange(v) end
		end
	end

	local function addSlider(sec, name, key, minV, maxV, suffix, onChange, zeroText)
		local r = row(sec, 152)
		rowLabel(r, name, 46)
		local valLabel = txt(r, "", 31, C.Accent, F.Semi, Enum.TextXAlignment.Right)
		valLabel.AnchorPoint = Vector2.new(1, 0.5)
		valLabel.Size = UDim2.new(0, 280, 0, 40)
		valLabel.Position = UDim2.new(1, -50, 0, 46)
		local area = create("TextButton", { Size = UDim2.new(1, -140, 0, 56), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 72, 0, 110), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, r)
		local track = create("Frame", { Size = UDim2.new(1, 0, 0, 10), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = C.ToggleOff, BorderSizePixel = 0 }, area)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
		local fill = create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, track)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
		local knob = create("Frame", { Size = UDim2.fromOffset(38, 38), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = C.White, BorderSizePixel = 0 }, track)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
		local function show(v)
			local rel = math.clamp((v - minV) / (maxV - minV), 0, 1)
			fill.Size = UDim2.new(rel, 0, 1, 0)
			knob.Position = UDim2.new(rel, 0, 0.5, 0)
			valLabel.Text = (v == 0 and zeroText) or (tostring(v) .. (suffix or ""))
		end
		show(Config[key])
		table.insert(syncers, function() show(Config[key]) end)
		local dragging = false
		local function update(x)
			local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			local v = math.floor(minV + rel * (maxV - minV) + 0.5)
			Config[key] = v
			show(v)
			if onChange then onChange(v) end
		end
		area.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				UI.click()
				update(input.Position.X)
			end
		end)
		table.insert(connections, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input.Position.X) end
		end))
		table.insert(connections, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
		end))
	end

	local function addColor(sec, name, key, onChange)
		local r = row(sec, 112)
		rowLabel(r, name, 56).Size = UDim2.new(1, -400, 0, 44)
		local box = create("TextButton", { Size = UDim2.new(0, 250, 0, 68), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -40, 0.5, 0), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = "", AutoButtonColor = true }, r)
		corner(box, 18)
		addRipple(box, box, 18)
		local swatch = create("Frame", { Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 18, 0.5, -19), BackgroundColor3 = Config[key], BorderSizePixel = 0 }, box)
		corner(swatch, 10)
		local hex = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -74, 1, 0), Position = UDim2.new(0, 70, 0, 0), Text = hexOf(Config[key]), TextSize = 24, Font = F.Reg, TextColor3 = C.SubText, TextXAlignment = Enum.TextXAlignment.Left }, box)
		local palette = {
			Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 140, 28), Color3.fromRGB(255, 220, 0), Color3.fromRGB(0, 255, 120),
			Color3.fromRGB(0, 230, 230), Color3.fromRGB(80, 170, 255), Color3.fromRGB(170, 80, 255), Color3.fromRGB(255, 120, 200), Color3.fromRGB(240, 240, 244),
		}
		local i = 0
		table.insert(syncers, function()
			swatch.BackgroundColor3 = Config[key]
			hex.Text = hexOf(Config[key])
		end)
		box.MouseButton1Click:Connect(function()
			UI.click()
			i = i % #palette + 1
			Config[key] = palette[i]
			swatch.BackgroundColor3 = palette[i]
			hex.Text = hexOf(palette[i])
			if onChange then onChange(palette[i]) end
		end)
	end

	local function addInput(sec, name, key, placeholder, onChange)
		local r = row(sec, 176)
		rowLabel(r, name, 46)
		local box = create("Frame", { Size = UDim2.new(1, -112, 0, 68), Position = UDim2.new(0, 72, 0, 84), BackgroundColor3 = C.Input, BorderSizePixel = 0 }, r)
		corner(box, 18)
		stroke(box, C.Line, 1)
		local tb = create("TextBox", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -34, 1, 0), Position = UDim2.new(0, 17, 0, 0), Text = Config[key],
			PlaceholderText = placeholder, PlaceholderColor3 = C.SubText, TextColor3 = C.White, TextSize = 26, Font = F.Reg,
			TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false,
		}, box)
		table.insert(syncers, function() tb.Text = Config[key] end)
		tb.FocusLost:Connect(function()
			Config[key] = tb.Text
			if onChange then onChange(tb.Text) end
		end)
		return tb
	end

	local function addDropdown(sec, name, key, options, onChange)
		local baseH, itemH = 176, 64
		local r = row(sec, baseH)
		rowLabel(r, name, 46)
		local box = create("TextButton", { Size = UDim2.new(1, -112, 0, 70), Position = UDim2.new(0, 72, 0, 84), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, r)
		corner(box, 18)
		addRipple(box, box, 18)
		local cur = txt(box, Config[key], 27, C.White, F.Reg)
		cur.Position = UDim2.new(0, 26, 0.5, 0)
		cur.Size = UDim2.new(1, -90, 0, 34)
		local arrow = txt(box, "v", 20, C.BarLight, F.Bold, Enum.TextXAlignment.Center)
		arrow.AnchorPoint = Vector2.new(0.5, 0.5)
		arrow.Size = UDim2.new(0, 30, 0, 30)
		arrow.Position = UDim2.new(1, -36, 0.5, 0)
		local list = create("Frame", { Size = UDim2.new(1, -112, 0, #options * itemH), Position = UDim2.new(0, 72, 0, baseH - 4), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Visible = false }, r)
		corner(list, 18)
		local open = false
		local function setOpen(v)
			open = v
			list.Visible = v
			arrow.Text = v and "^" or "v"
			r.Size = UDim2.new(1, 0, 0, v and (baseH + #options * itemH + 14) or baseH)
		end
		for i, opt in ipairs(options) do
			local b = create("TextButton", {
				Size = UDim2.new(1, 0, 0, itemH), Position = UDim2.new(0, 0, 0, (i - 1) * itemH), BackgroundTransparency = 1,
				Text = opt, TextSize = 27, Font = F.Reg, TextColor3 = C.White, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
			}, list)
			create("UIPadding", { PaddingLeft = UDim.new(0, 26) }, b)
			b.MouseButton1Click:Connect(function()
				UI.click()
				Config[key] = opt
				cur.Text = opt
				setOpen(false)
				if onChange then onChange(opt) end
			end)
		end
		table.insert(syncers, function() cur.Text = Config[key] end)
		box.MouseButton1Click:Connect(function()
			UI.click()
			setOpen(not open)
		end)
	end

	local function addKeybind(sec, name, key, onChange)
		local r = row(sec, 112)
		rowLabel(r, name, 56).Size = UDim2.new(1, -330, 0, 44)
		local btn = create("TextButton", {
			Size = UDim2.new(0, 210, 0, 70), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -40, 0.5, 0),
			BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = Config[key], TextSize = 26, Font = F.Med, TextColor3 = C.White, AutoButtonColor = true,
		}, r)
		corner(btn, 18)
		addRipple(btn, btn, 18)
		local waiting = false
		table.insert(syncers, function() btn.Text = Config[key] end)
		btn.MouseButton1Click:Connect(function()
			UI.click()
			waiting = not waiting
			btn.Text = waiting and "press a key..." or Config[key]
		end)
		table.insert(connections, UserInputService.InputBegan:Connect(function(input)
			if not waiting or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
			waiting = false
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
				Config[key] = "None"
			else
				Config[key] = input.KeyCode.Name
			end
			btn.Text = Config[key]
			if onChange then onChange(Config[key]) end
		end))
	end

	-- whole card is the button
	local function addButton(sec, text, callback)
		local r = row(sec, 104)
		local btn = create("TextButton", {
			Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = text, TextSize = 34, Font = F.Med, TextColor3 = C.White, AutoButtonColor = false,
		}, r)
		addRipple(r, btn)
		btn.MouseEnter:Connect(function() TweenService:Create(r, TweenInfo.new(0.12), { BackgroundColor3 = C.Selected }):Play() end)
		btn.MouseLeave:Connect(function() TweenService:Create(r, TweenInfo.new(0.15), { BackgroundColor3 = C.Panel }):Play() end)
		btn.MouseButton1Click:Connect(function()
			UI.click()
			r.BackgroundColor3 = Color3.fromRGB(24, 70, 70)
			TweenService:Create(r, TweenInfo.new(0.3), { BackgroundColor3 = C.Panel }):Play()
			callback(btn)
		end)
		return btn
	end

	-- info card: white title, teal value (just a white line when no title is given)
	local function addInfo(sec, text, title)
		if title then
			local r = row(sec, 164)
			local t = txt(r, title, 38, C.White, F.Med)
			t.Position = UDim2.new(0, 72, 0, 50)
			t.Size = UDim2.new(1, -110, 0, 48)
			local v = txt(r, text, 35, C.Accent, F.Med)
			v.Position = UDim2.new(0, 72, 0, 116)
			v.Size = UDim2.new(1, -110, 0, 44)
			return v
		end
		local r = row(sec, 100)
		local v = txt(r, text, 33, C.White, F.Med)
		v.Position = UDim2.new(0, 72, 0.5, 0)
		v.Size = UDim2.new(1, -110, 0, 44)
		return v
	end

	local function flash(btn, msg, orig)
		btn.Text = msg
		task.delay(1.4, function() if btn.Parent then btn.Text = orig end end)
	end

	-- tabs ------------------------------------------------------------
	local function tabFail(name) return function(e) warn("Item ESP: tab '" .. name .. "' failed: " .. tostring(e)) end end

	xpcall(function() -- Status (main page, same cards as the reference)
		local p = newPage("Status")
		local a = section(p.left, "Script Check", 1, "▣")
		UI.srvStatus = addInfo(a, "Fps - | Ping - | Executor", "Status Script")
		UI.homeItems = addInfo(a, "Tracked 0 | Alerts 0 | Picked 0", "Item Scanner")
		UI.srvPlayers = addInfo(a, "Players: -", "Server")
		UI.sessInfo = addInfo(a, "Kills 0 | Deaths 0 | 0:00:00", "Session")
		finish(a)

		UI.stats = { ["Items Tracked"] = { Text = "0" }, ["Alert Items"] = { Text = "0" }, ["FPS"] = { Text = "-" }, ["Ping"] = { Text = "-" } }

		local b = section(p.left, "Session", 2, "◈")
		addCheckbox(b, "Hide Username", "HideUsername", function() UI.applyUsername() end)
		finish(b)

		local c = section(p.left, "Item Breakdown", 3, "◈")
		UI.catInfo = {}
		for _, cat in ipairs(CATEGORIES) do
			UI.catInfo[cat.id] = addInfo(c, cat.label .. ": 0")
		end
		finish(c)
	end, tabFail("Status"))

	xpcall(function() -- Item ESP
		local p = newPage("Item ESP")

		local a = section(p.left, "Item ESP", 1, "◎")
		UI.setEnabled = addCheckbox(a, "Item ESP (Master)", "Enabled")
		addCheckbox(a, "Highlight Glow", "Highlight")
		addCheckbox(a, "Boxes (3D)", "Boxes")
		addCheckbox(a, "Name Tag", "NameTag")
		addCheckbox(a, "Category Tag", "CategoryTag")
		addCheckbox(a, "Distance", "Distance")
		addCheckbox(a, "Tracers (needs Drawing)", "Tracers")
		addCheckbox(a, "Fade Tags With Distance", "FadeWithDistance")
		addCheckbox(a, "Pulse Alert Items", "PulseAlerts")
		addSlider(a, "Max Distance", "MaxDistance", 100, 5000, " st")
		addSlider(a, "Text Size", "TextSize", 10, 28, "")
		addSlider(a, "Fill Transparency", "FillTransparency", 0, 100, "%")
		addDropdown(a, "Tracer Origin", "TracerOrigin", { "Bottom", "Center", "Top" })
		finish(a)

		local b = section(p.right, "Categories", 1, "◈")
		for _, cat in ipairs(CATEGORIES) do
			addCheckbox(b, "Show " .. cat.label, "Show" .. cat.id)
		end
		finish(b)

		local c = section(p.right, "Radar", 2, "◎")
		addCheckbox(c, "Show Radar", "ShowRadar")
		addCheckbox(c, "Alert Items Only", "RadarAlertOnly")
		addSlider(c, "Radar Range", "RadarRange", 50, 1000, " st")
		addSlider(c, "Radar Size", "RadarSize", 120, 340, " px")
		finish(c)
	end, tabFail("Item ESP"))

	xpcall(function() -- Alerts
		local p = newPage("Alerts")

		local a = section(p.left, "Alerts · Main", 1, "▲")
		addCheckbox(a, "Notify When Item Appears", "AlertEnabled")
		addInput(a, "Alert Item Names", "AlertNames", "C4, another item...", function() Actions.reapply() end)
		addCheckbox(a, "Alert Sound", "AlertSound")
		addDropdown(a, "Alert Sound Type", "AlertSoundType", { "Ping", "Bass", "Snap", "Switch" })
		addSlider(a, "Alert Volume", "AlertVolume", 1, 10, "")
		addButton(a, "Test Alert", function() Actions.testAlert() end)
		UI.alertInfo = addInfo(a, "Alert items on map: 0")
		finish(a)

		local b = section(p.right, "Alerts · Rules", 1, "▲")
		addSlider(b, "Only Alert Within", "AlertDistance", 0, 5000, " st", nil, "Any distance")
		addSlider(b, "Remind Every", "AlertRemind", 0, 120, "s", nil, "Off")
		addCheckbox(b, "Alert When Item Disappears", "AlertOnDespawn")
		addCheckbox(b, "Off-screen Arrows (needs Drawing)", "AlertArrows")
		addButton(b, "Re-alert Existing Items", function(btn)
			Actions.realert()
			flash(btn, "Done!", "Re-alert Existing Items")
		end)
		finish(b)

		local c = section(p.right, "Alert By Category", 2, "▲")
		for _, cat in ipairs(CATEGORIES) do
			if cat.id ~= "Other" then
				addCheckbox(c, "Alert: " .. cat.label, "AlertCat" .. cat.id, function() Actions.reapply() end)
			end
		end
		finish(c)
	end, tabFail("Alerts"))

	xpcall(function() -- Item List
		local p = newPage("Item List")
		local a = section(p.left, "Nearby Items", 1, "◈")
		UI.listRows = {}
		UI.listEntries = {}
		for i = 1, 40 do
			local r = row(a, 100)
			local nameL = txt(r, "", 30, C.White, F.Med)
			nameL.Position = UDim2.new(0, 72, 0.5, 0)
			nameL.Size = UDim2.new(0, 380, 0, 38)
			local distL = txt(r, "", 28, C.Accent, F.Med)
			distL.Position = UDim2.new(0, 470, 0.5, 0)
			distL.Size = UDim2.new(0, 170, 0, 36)
			local tp = create("TextButton", { Size = UDim2.fromOffset(78, 46), Position = UDim2.new(1, -240, 0.5, -27), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = "TP", TextSize = 18, Font = F.Bold, TextColor3 = C.White, AutoButtonColor = true }, r)
			corner(tp, 12)
			local hide = create("TextButton", { Size = UDim2.fromOffset(78, 46), Position = UDim2.new(1, -140, 0.5, -27), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = "Hide", TextSize = 18, Font = F.Bold, TextColor3 = C.White, AutoButtonColor = true }, r)
			corner(hide, 12)
			tp.MouseButton1Click:Connect(function()
				UI.click()
				if UI.listEntries[i] then Actions.teleport(UI.listEntries[i]) end
			end)
			hide.MouseButton1Click:Connect(function()
				UI.click()
				if UI.listEntries[i] then Actions.hide(UI.listEntries[i]) end
			end)
			r.Visible = false
			r:SetAttribute("hidden", true)
			UI.listRows[i] = { frame = r, name = nameL, dist = distL }
		end
		finish(a)

		local b = section(p.right, "List Options", 1, "◈")
		addInput(b, "Search", "ListSearch", "item name or category...")
		addDropdown(b, "Sort By", "ListSort", { "Distance", "Name" })
		UI.listCount = addInfo(b, "Showing 0 of 0")
		finish(b)

		local c = section(p.right, "Hidden Items", 2, "◈")
		addInput(c, "Hidden Names", "HiddenNames", "names to never show, comma separated", function() Actions.reapply() end)
		addButton(c, "Clear Hidden", function(btn)
			Config.HiddenNames = ""
			UI.sync()
			Actions.reapply()
			flash(btn, "Cleared!", "Clear Hidden")
		end)
		finish(c)
	end, tabFail("Item List"))

	xpcall(function() -- Pickup
		local p = newPage("Pickup")
		local a = section(p.left, "Pickup", 1, "◆")
		addCheckbox(a, "Instant Prompt (no hold)", "InstantPrompt", function(v) if not v then Actions.restoreHold() end end)
		addCheckbox(a, "Auto Pickup", "AutoPickup")
		addSlider(a, "Auto Pickup Range", "AutoPickupRange", 3, 60, " st")
		addCheckbox(a, "Auto Pickup: Alert Items Only", "AutoPickupAlertOnly")
		UI.pickupInfo = addInfo(a, "Auto picked up: 0")
		finish(a)

		local b = section(p.right, "Teleport", 1, "◆")
		addButton(b, "Teleport To Closest Alert Item", function(btn)
			flash(btn, Actions.tpClosest(true) and "Teleported!" or "No alert item", "Teleport To Closest Alert Item")
		end)
		addButton(b, "Teleport To Closest Item", function(btn)
			flash(btn, Actions.tpClosest(false) and "Teleported!" or "No item", "Teleport To Closest Item")
		end)
		finish(b)

		local c = section(p.left, "Auto Collect (TP)", 2, "◆")
		addCheckbox(c, "Auto Collect (teleports to items)", "AutoCollect", function(v)
			notify("Auto Collect", v and "ON - teleporting to items" or "OFF", true)
		end)
		addCheckbox(c, "Alert Items Only", "AutoCollectAlertOnly")
		addCheckbox(c, "Return To Start After", "AutoCollectReturn")
		addSlider(c, "Max Distance", "AutoCollectRange", 50, 5000, " st")
		UI.collectInfo = addInfo(c, "Auto collected: 0")
		finish(c)

		local d = section(p.right, "Prompt Tweaks", 2, "◆")
		addCheckbox(d, "Extend Prompt Range", "ExtendPrompts", function(v) if not v then Feat.restorePrompts() end end)
		addSlider(d, "Prompt Range", "PromptRange", 10, 500, " st")
		finish(d)

		local w = section(p.left, "Walk To Selected Items", 3, "◆")
		addCheckbox(w, "Walk & Collect (script takes control)", "WalkCollect", function(v)
			notify("Walk & Collect", v and "ON - walking to selected items when they spawn" or "OFF", true)
		end)
		addInput(w, "Selected Items (empty = alert items)", "WalkNames", "C4, sword, ... comma separated")
		addSlider(w, "Walk Speed To Item", "WalkItemSpeed", 16, 300, "")
		addSlider(w, "Max Distance", "WalkRange", 50, 5000, " st")
		addSlider(w, "Give Up After", "WalkTimeout", 10, 90, "s")
		finish(w)
	end, tabFail("Pickup"))

	xpcall(function() -- Colors
		local p = newPage("Colors")
		local a = section(p.left, "Category Colors", 1, "◐")
		for _, cat in ipairs(CATEGORIES) do
			addColor(a, cat.label, "Color" .. cat.id)
		end
		finish(a)
		local b = section(p.right, "Other Colors", 1, "◐")
		addColor(b, "Alert Items", "AlertColor")
		addColor(b, "Tracers", "TracerColor")
		finish(b)
	end, tabFail("Colors"))

	xpcall(function() -- Settings
		local p = newPage("Settings")

		local a = section(p.left, "Config", 1, "◍")
		UI.configInfo = addInfo(a, "Config: ready")
		addButton(a, "Save Config", function()
				local ok = saveConfig()
				UI.configInfo.Text = ok and "Config saved" or "Save failed (no writefile)"
				notify("Config", ok and "Config saved" or "Save failed (no writefile)", true)
			end)
		addButton(a, "Load Config", function()
			if loadConfig() then
				UI.sync()
				Actions.reapply()
				UI.configInfo.Text = "Config loaded"
				notify("Config", "Config loaded", true)
			else
				UI.configInfo.Text = "No saved config found"
			end
		end)
		addButton(a, "Reset To Default", function()
			for k, v in pairs(DEFAULTS) do Config[k] = v end
			UI.sync()
			Actions.reapply()
			UI.configInfo.Text = "Reset to default"
		end)
		addCheckbox(a, "Auto Save When Closing", "AutoSave")
		addDropdown(a, "Profile Slot", "Profile", { "1", "2", "3" })
		addButton(a, "Save To Profile Slot", function(btn)
			local ok = saveConfig("CodeBot_ItemESP_P" .. Config.Profile .. ".json")
			flash(btn, ok and "Saved!" or "Save failed", "Save To Profile Slot")
		end)
		addButton(a, "Load From Profile Slot", function(btn)
			if loadConfig("CodeBot_ItemESP_P" .. Config.Profile .. ".json") then
				UI.sync()
				Actions.reapply()
				flash(btn, "Loaded!", "Load From Profile Slot")
			else
				flash(btn, "Slot empty", "Load From Profile Slot")
			end
		end)
		finish(a)

		local b = section(p.right, "Detection", 1, "◍")
		addDropdown(b, "Scan Mode", "ScanMode", { "Smart", "Pickups", "Aggressive" }, function() Actions.rescan() end)
		addSlider(b, "Rescan Every", "ScanInterval", 3, 30, "s")
		addInput(b, "Extra Item Names", "ExtraNames", "extra names to track, comma separated", function() Actions.reapply() end)
		addButton(b, "Rescan Map", function(btn)
			Actions.rescan()
			flash(btn, "Scanning...", "Rescan Map")
		end)
		finish(b)

		local c = section(p.right, "Hotkey & Script", 2, "◍")
		addKeybind(c, "ESP Toggle Key", "ToggleKey")
		addKeybind(c, "Hide / Show GUI Key", "HideKey")
		addButton(c, "Unload Script", function() Actions.unload() end)
		finish(c)

		local d = section(p.left, "Notifications", 2, "◍")
		addDropdown(d, "Notification Style", "NotifyStyle", { "Hub", "Roblox" })
		addCheckbox(d, "Status Notifications", "StatusNotify")
		addCheckbox(d, "Player Join / Leave Alerts", "JoinAlerts")
		addSlider(d, "Notification Time", "NotifyDuration", 2, 15, "s")
		addButton(d, "Test Roblox Notification", function() notify("Item ESP", "Roblox notifications are working") end)
		finish(d)

		local w = section(p.left, "Window", 3, "◍")
		addSlider(w, "Drag Speed (65% = 0.65)", "DragSpeed", 20, 150, "%")
		addSlider(w, "Minimized Logo Size", "LogoSize", 36, 160, " px", function() if UI.applyLogo then UI.applyLogo() end end)
		addCheckbox(w, "Click Sound", "ClickSound")
		addCheckbox(w, "Ripple Effect", "RippleOn")
		addCheckbox(w, "Window Outline Ripple", "OutlineRipple")
		addDropdown(w, "Click Sound Type", "ClickSoundType", { "Click", "Snap", "Switch" }, function() UI.click() end)
		addSlider(w, "Click Volume", "ClickVolume", 1, 10, "")
		finish(w)
	end, tabFail("Settings"))

	xpcall(function() -- Player ESP
		local p = newPage("Player ESP")
		local a = section(p.left, "Player ESP", 1, "◉")
		addCheckbox(a, "Player ESP (Master)", "PlayerESP")
		addCheckbox(a, "Box Outline", "PBox")
		addCheckbox(a, "Glow (fill)", "PGlow")
		addCheckbox(a, "Name", "PName")
		addCheckbox(a, "Health", "PHealth")
		addCheckbox(a, "Distance", "PDistance")
		addCheckbox(a, "Tracers (needs Drawing)", "PTracers")
		addCheckbox(a, "Hide Teammates", "PTeamCheck")
		addSlider(a, "Max Distance", "PMaxDistance", 100, 5000, " st")
		finish(a)
		local b = section(p.right, "Colors", 1, "◐")
		addColor(b, "Players", "ColorPlayer")
		finish(b)
	end, tabFail("Player ESP"))

	xpcall(function() -- Movement
		local p = newPage("Movement")
		local a = section(p.left, "Speed & Jump", 1, "▶")
		UI.setSpeed = addCheckbox(a, "Walk Speed", "SpeedOn")
		addSlider(a, "Speed Value", "WalkSpeedVal", 16, 300, "")
		addCheckbox(a, "Jump Power", "JumpOn")
		addSlider(a, "Jump Value", "JumpPowerVal", 50, 400, "")
		addCheckbox(a, "Infinite Jump", "InfJump")
		finish(a)
		local b = section(p.right, "Fly & Noclip", 1, "▶")
		UI.setFly = addCheckbox(b, "Fly (move with the stick, look to steer)", "Fly")
		addSlider(b, "Fly Speed", "FlySpeed", 10, 300, "")
		UI.setNoclip = addCheckbox(b, "Noclip", "Noclip")
		finish(b)
	end, tabFail("Movement"))

	xpcall(function() -- HvH (orbit, target, spin)
		local p = newPage("HvH")

		local o = section(p.left, "Orbit", 1, "◆")
		UI.setOrbit = addCheckbox(o, "Orbit (spin around target)", "OrbitOn", function(v)
			notify("Orbit", v and "ON - orbiting the target" or "OFF", true)
		end)
		addDropdown(o, "Orbit Mode", "OrbitMode", { "Circle", "Behind", "Random", "Vertical" })
		addSlider(o, "Orbit Speed (deg/s)", "OrbitSpeed", 100, 20000, "")
		addSlider(o, "Radius", "OrbitRadius", 2, 40, " st")
		addSlider(o, "Height", "OrbitHeight", -10, 20, " st")
		addCheckbox(o, "Face Target", "OrbitFace")
		addCheckbox(o, "Stable Camera (watch the target)", "OrbitStableCam")
		addKeybind(o, "Orbit Toggle Key", "OrbitKey")
		UI.orbitInfo = addInfo(o, "Orbit off", "Orbit Status")
		finish(o)

		local t = section(p.left, "Target", 2, "◆")
		addDropdown(t, "Target Mode", "OrbitTargetMode", { "Closest", "Lowest HP" })
		addInput(t, "Target Name (empty = auto)", "OrbitTarget", "player name...")
		addCheckbox(t, "Lock Target Until Dead", "OrbitLock")
		addCheckbox(t, "Skip Teammates", "OrbitTeamCheck")
		addCheckbox(t, "Skip Roblox Friends", "WhitelistFriends")
		addInput(t, "Whitelist (never target)", "Whitelist", "names, comma separated...")
		addButton(t, "Next Target (cycle)", function(btn)
			flash(btn, Feat.nextTarget() and "Switched!" or "No target", "Next Target (cycle)")
		end)
		addButton(t, "Clear Target (use closest)", function(btn)
			Config.OrbitTarget = ""
			UI.sync()
			flash(btn, "Cleared!", "Clear Target (use closest)")
		end)
		addCheckbox(t, "Walk To Next Target", "OrbitWalk")
		addSlider(t, "Engage Distance (orbit starts at)", "OrbitEngage", 4, 40, " st")
		addSlider(t, "Walk Speed To Target", "OrbitWalkSpeed", 16, 200, "")
		addCheckbox(t, "Target HUD (name + health bar)", "TargetHUD")
		addSlider(t, "Target HUD Size", "HUDSize", 15, 100, "%")
		addSlider(t, "Max Target Distance", "OrbitMaxDist", 50, 5000, " st")
		addButton(t, "Teleport Behind Target", function(btn)
			flash(btn, Feat.tpBehind() and "Teleported!" or "No target", "Teleport Behind Target")
		end)
		finish(t)

		local c = section(p.left, "Combat", 3, "◆")
		addCheckbox(c, "Auto Attack While Orbiting", "OrbitAttack")
		addSlider(c, "Attack Speed (per sec)", "OrbitAttackCPS", 1, 30, "")
		addCheckbox(c, "Spin In Place (anti-aim)", "SpinOn", function(v)
			notify("Spin", v and "ON - spinning in place" or "OFF", true)
		end)
		addSlider(c, "Spin Speed (deg/s)", "SpinSpeed", 100, 20000, "")
		addCheckbox(c, "Highlight Target", "TargetHL")
		addCheckbox(c, "Notify When Target Dies", "NotifyKill")
		finish(c)

		local h = section(p.left, "Hitbox & Safety", 4, "◆")
		addCheckbox(h, "Hitbox Expander (other players)", "HitboxOn", function(v)
			notify("Hitbox", v and "ON - enemy hitboxes enlarged" or "OFF", true)
			if not v then Feat.hitboxRestore() end
		end)
		addSlider(h, "Hitbox Size", "HitboxSize", 3, 40, " st")
		addCheckbox(h, "Void Safe (auto return)", "VoidSafe")
		addSlider(h, "Void Height (Y)", "VoidY", -1000, 0, "")
		finish(h)
	end, tabFail("HvH"))

	xpcall(function() -- Utility
		local p = newPage("Utility")
		local a = section(p.left, "Visual Utility", 1, "■")
		addCheckbox(a, "Fullbright", "Fullbright")
		addCheckbox(a, "Infinite Zoom Out", "InfZoom")
		addCheckbox(a, "Custom FOV", "FOVOn")
		addSlider(a, "FOV", "FOVVal", 30, 200, "")
		addCheckbox(a, "Custom Time Of Day", "TimeOn")
		addSlider(a, "Time (hour)", "TimeVal", 0, 24, "h")
		addCheckbox(a, "Crosshair (needs Drawing)", "Crosshair")
		addSlider(a, "Crosshair Size", "CrossSize", 4, 40, "")
		addSlider(a, "Crosshair Gap", "CrossGap", 0, 20, "")
		addColor(a, "Crosshair Color", "ColorCross")
		finish(a)
		local b = section(p.right, "Server & Character", 1, "■")
		addCheckbox(b, "Anti AFK", "AntiAFK")
		addButton(b, "Server Hop", function(btn)
			flash(btn, "Hopping...", "Server Hop")
			Feat.hop()
		end)
		addButton(b, "Rejoin Server", function(btn)
			flash(btn, "Rejoining...", "Rejoin Server")
			Feat.rejoin()
		end)
		addButton(b, "Reset Character", function(btn)
			Feat.reset()
			flash(btn, "Reset!", "Reset Character")
		end)
		addButton(b, "Teleport To Spawn", function(btn)
			flash(btn, Feat.tpSpawn() and "Teleported!" or "No spawn found", "Teleport To Spawn")
		end)
		finish(b)

		local t = section(p.left, "Teleport & Spectate", 2, "■")
		addInput(t, "Player Name", "TPName", "type part of a name...")
		addButton(t, "Teleport To Player", function(btn)
			flash(btn, Feat.findPlayer(Config.TPName) and "Teleported!" or "Not found", "Teleport To Player")
			Feat.tpPlayer(Config.TPName)
		end)
		addCheckbox(t, "Spectate Player", "SpectateOn")
		addCheckbox(t, "Click / Tap Teleport", "ClickTP", function(v)
			notify("Click Teleport", v and "ON - tap the world to teleport" or "OFF", true)
		end)
		finish(t)
	end, tabFail("Utility"))

	xpcall(function() -- Server
		local p = newPage("Server")
		local a = section(p.left, "Server Info", 1, "■")
		UI.srvAge = addInfo(a, "Server time: -", "Server Time")
		finish(a)
		local b = section(p.left, "Server Tools", 2, "■")
		addButton(b, "Copy Job ID", function(btn)
			local ok = pcall(function() setclipboard(game.JobId) end)
			flash(btn, ok and "Copied!" or "No clipboard", "Copy Job ID")
		end)
		addInput(b, "Join Job ID", "JoinJobId", "paste a Job ID...")
		addButton(b, "Join This Job ID", function(btn)
			flash(btn, "Joining...", "Join This Job ID")
			Feat.joinJob(Config.JoinJobId)
		end)
		addButton(b, "Server Hop", function(btn)
			flash(btn, "Hopping...", "Server Hop")
			Feat.hop()
		end)
		finish(b)
		local c = section(p.left, "Auto", 3, "■")
		addCheckbox(c, "Auto Rejoin When Disconnected", "AutoRejoin")
		addCheckbox(c, "Auto Clicker (equipped tool)", "AutoClick")
		addSlider(c, "Clicks Per Second", "ClickCPS", 1, 30, "")
		finish(c)
	end, tabFail("Server"))

	xpcall(function() -- Combat (aim assist, kill aura, panic escape)
		local p = newPage("Combat")

		local a = section(p.left, "Aim Assist", 1, "▶")
		addCheckbox(a, "Aim Assist (camera lock)", "AimOn", function(v)
			notify("Aim Assist", v and "ON - camera locks onto the nearest player" or "OFF", true)
		end)
		addDropdown(a, "Aim Part", "AimPart", { "Head", "UpperTorso", "HumanoidRootPart" })
		addSlider(a, "Smoothness (100 = instant)", "AimSmooth", 5, 100, "%")
		addSlider(a, "Aim FOV (pixels)", "AimFOV", 50, 800, " px")
		addCheckbox(a, "Show FOV Circle (needs Drawing)", "ShowFOV")
		addCheckbox(a, "Skip Teammates", "AimTeamCheck")
		addCheckbox(a, "Wall Check (visible only)", "AimWallCheck")
		finish(a)

		local b = section(p.left, "Kill Aura", 2, "▶")
		addCheckbox(b, "Kill Aura (auto attack in range)", "AuraOn", function(v)
			notify("Kill Aura", v and "ON - attacking players in range" or "OFF", true)
		end)
		addSlider(b, "Aura Range", "AuraRange", 5, 60, " st")
		addSlider(b, "Attacks Per Second", "AuraCPS", 1, 30, "")
		addCheckbox(b, "Auto Face Nearest Player", "AutoFace")
		finish(b)

		local c = section(p.left, "Panic Escape", 3, "▶")
		addCheckbox(c, "Panic Escape (low HP)", "PanicOn")
		addSlider(c, "Trigger Below HP", "PanicHP", 5, 90, "%")
		addSlider(c, "Escape Height", "PanicHeight", 50, 500, " st")
		addInfo(c, "Teleports you up and freezes you for 4 seconds")
		finish(c)
	end, tabFail("Combat"))

	xpcall(function() -- Players list (TP / Spectate / Orbit)
		local p = newPage("Players")
		local a = section(p.left, "Server Players", 1, "◉")
		UI.plRows = {}
		UI.plEntries = {}
		for i = 1, 30 do
			local r = row(a, 100)
			local nameL = txt(r, "", 28, C.White, F.Med)
			nameL.Position = UDim2.new(0, 72, 0.5, 0)
			nameL.Size = UDim2.new(0, 330, 0, 38)
			local distL = txt(r, "", 26, C.Accent, F.Med)
			distL.Position = UDim2.new(0, 410, 0.5, 0)
			distL.Size = UDim2.new(0, 150, 0, 36)
			local function small(label, xOff)
				local b = create("TextButton", { Size = UDim2.fromOffset(78, 46), Position = UDim2.new(1, xOff, 0.5, -27), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = label, TextSize = 18, Font = F.Bold, TextColor3 = C.White, AutoButtonColor = true }, r)
				corner(b, 12)
				return b
			end
			local tpB, specB, orbB = small("TP", -330), small("Spec", -240), small("Orbit", -150)
			tpB.MouseButton1Click:Connect(function()
				UI.click()
				local e = UI.plEntries[i]
				if e then Feat.tpPlayer(e.plr.Name) end
			end)
			specB.MouseButton1Click:Connect(function()
				UI.click()
				local e = UI.plEntries[i]
				if e then
					Config.TPName = e.plr.Name
					Config.SpectateOn = true
					UI.sync()
					notify("Spectate", "Watching " .. e.plr.DisplayName .. " (turn off in Utility)", true)
				end
			end)
			orbB.MouseButton1Click:Connect(function()
				UI.click()
				local e = UI.plEntries[i]
				if e then
					Config.OrbitTarget = e.plr.Name
					UI.sync()
					notify("Orbit target", e.plr.DisplayName .. " (enable Orbit in the HvH tab)", true)
				end
			end)
			r.Visible = false
			r:SetAttribute("hidden", true)
			UI.plRows[i] = { frame = r, name = nameL, dist = distL }
		end
		finish(a)
		local b = section(p.left, "Info", 2, "◉")
		UI.plCount = addInfo(b, "Players: 0")
		finish(b)
	end, tabFail("Players"))

	xpcall(function() -- Extra movement + hotkeys (added to the Movement page)
		local p = pages["Movement"]
		local a = section(p.left, "Extra Movement", 3, "▶")
		addCheckbox(a, "CFrame Speed (extra boost)", "CFrameSpeed")
		addSlider(a, "Boost (studs/s)", "CFrameSpeedVal", 5, 200, "")
		addCheckbox(a, "Bunny Hop (auto jump while moving)", "Bhop")
		addCheckbox(a, "Low Gravity", "LowGravity")
		addSlider(a, "Gravity", "GravityVal", 5, 190, "")
		finish(a)
		local b = section(p.left, "Hotkeys", 4, "▶")
		addKeybind(b, "Fly Key", "FlyKey")
		addKeybind(b, "Noclip Key", "NoclipKey")
		addKeybind(b, "Walk Speed Key", "SpeedKey")
		finish(b)
	end, tabFail("Movement extras"))

	xpcall(function() -- Waypoints (added to the Utility page, saved with the config)
		local p = pages["Utility"]
		local w = section(p.right, "Waypoints", 2, "■")
		UI.wpInfo = addInfo(w, "Save a spot, then teleport back to it any time")
		for i = 1, 3 do
			addButton(w, "Save Waypoint " .. i, function(btn)
				flash(btn, Feat.saveWP(i) and "Saved!" or "No character", "Save Waypoint " .. i)
				if UI.wpInfo then UI.wpInfo.Text = "Slot " .. i .. ": " .. Config["WP" .. i] end
			end)
			addButton(w, "Go To Waypoint " .. i, function(btn)
				flash(btn, Feat.goWP(i) and "Teleported!" or "Empty slot", "Go To Waypoint " .. i)
			end)
		end
		finish(w)
	end, tabFail("Waypoints"))

	xpcall(function() -- Help (quick guide to every tab)
		local p = newPage("Help")
		local a = section(p.left, "Quick Guide", 1, "?")
		addInfo(a, "Status: FPS, ping, item counts, hide username", "Main")
		addInfo(a, "Item ESP / Player ESP: glow, boxes, names, tracers", "Visuals")
		addInfo(a, "Alerts: notification + sound when chosen items spawn", "Alerts")
		addInfo(a, "Item List / Pickup: teleport, auto pickup, auto collect", "Items")
		addInfo(a, "Movement / Players / Utility: speed, fly, waypoints", "Player")
		addInfo(a, "HvH / Combat: orbit, spin, aim assist, kill aura", "HvH")
		finish(a)

		local b = section(p.left, "HvH Tips", 2, "?")
		addInfo(b, "Orbit: pick a mode, then turn Orbit on", "Start")
		addInfo(b, "Lock Target keeps one player until they die", "Lock")
		addInfo(b, "If a teleport is blocked the script walks to the target", "Walk")
		addInfo(b, "Panic Escape and Void Safe protect you while fighting", "Safety")
		addInfo(b, "Players tab: tap Orbit next to a name to pick them", "Target")
		finish(b)

		local c = section(p.left, "Controls", 3, "?")
		addInfo(c, "Drag the header to move the window, tap the dash to minimize")
		addInfo(c, "Tap the round logo to bring the window back")
		addInfo(c, "Settings > Window changes drag speed and logo size")
		addInfo(c, "Risky toggles always start off when the script loads")
		addInfo(c, "Settings > Save Config keeps your options for next time")
		finish(c)
	end, tabFail("Help"))

	xpcall(function() -- Tools
		local p = newPage("Tools")
		local z = section(p.left, "Bypass Anticheat", 1, "◆")
		addCheckbox(z, "Bypass Anticheat", "BypassEnabled", function(v)
			if v then Feat.bypassRun() else Feat.bypassStop() end
		end)
		addDropdown(z, "Teleport Spot", "BypassSpot", { "Sky Platform", "Random Player", "Spawn", "Waypoint" })
		addSlider(z, "Max Attempts", "BypassMax", 3, 40, "")
		UI.bypassInfo = addInfo(z, "Idle", "Bypass Status")
		addButton(z, "Strong Reset Character", function(btn)
			flash(btn, "Resetting...", "Strong Reset Character")
			task.spawn(function()
				local nc = Feat.strongReset()
				Feat.bpStatus(nc and "Reset worked" or "Reset failed")
			end)
		end)
		finish(z)
		local a = section(p.left, "Waypoint Slots", 1, "◆")
		addDropdown(a, "Slot", "WPSlot", { "1", "2", "3", "4", "5" }, function() Feat.wpInfo() end)
		UI.wpInfo = addInfo(a, "Slot 1: empty", "Saved Position")
		addButton(a, "Save Current Position", function(btn)
			flash(btn, Feat.wpSave() and "Saved!" or "No character", "Save Current Position")
		end)
		addButton(a, "Teleport To Slot", function(btn)
			flash(btn, Feat.wpGo() and "Teleported!" or "Slot empty", "Teleport To Slot")
		end)
		finish(a)
		local b = section(p.left, "Auto", 2, "◆")
		addCheckbox(b, "Death Return (respawn where you died)", "DeathReturn")
		addCheckbox(b, "Player Join / Leave Alerts", "JoinAlerts")
		addCheckbox(b, "FPS Boost", "FPSBoost", function(v) Feat.fps(v) end)
		finish(b)
		local c = section(p.left, "Menu", 3, "◆")
		addKeybind(c, "Show / Hide Menu Key", "MenuKey")
		finish(c)
	end, tabFail("Tools"))

	-- sidebar entries (categories) + pill tabs (pages), like the reference ---
	local catBtns, pillBtns, catPages, pageCat, lastPage = {}, {}, {}, {}, {}
	local function selectPage(name)
		for n, page in pairs(pages) do
			local show = (n == name)
			if show and not page.frame.Visible then
				page.frame.Position = UDim2.new(0, 0, 0, 22)
				TweenService:Create(page.frame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
			end
			page.frame.Visible = show
		end
		UI.currentPage = name
		local cat = pageCat[name]
		lastPage[cat] = name
		for c, b in pairs(catBtns) do
			local sel = (c == cat)
			b.btn.BackgroundTransparency = sel and 0 or 1
			b.marker.Visible = sel
			b.text.TextColor3 = sel and C.White or C.SubText
			b.icon.TextColor3 = sel and C.White or C.SubText
		end
		for n, p in pairs(pillBtns) do
			local sel = (n == name)
			p.btn.Visible = (pageCat[n] == cat)
			p.btn.BackgroundTransparency = sel and 0 or 1
			p.btn.TextColor3 = sel and C.White or C.SubText
		end
	end
	UI.openPage = selectPage
	UI.search = function(q)
		q = string.lower(q or "")
		if q == "" then return end
		for n in pairs(pages) do
			if string.find(string.lower(n), q, 1, true) then
				selectPage(n)
				return
			end
		end
	end

	local catOrder = 0
	local function addCategory(title, subs)
		catOrder = catOrder + 1
		catPages[title] = {}
		local btn = create("TextButton", { Size = UDim2.new(1, 0, 0, 96), BackgroundColor3 = C.Selected, BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = catOrder }, sideScroll)
		corner(btn, 24)
		local marker = create("Frame", { Size = UDim2.new(0, 6, 0, 52), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = C.Accent, BorderSizePixel = 0, Visible = false }, btn)
		corner(marker, 3)
		local ic = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(46, 46), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 34, 0.5, 0), Text = subs[1][2], TextSize = 36, Font = F.Med, TextColor3 = C.SubText }, btn)
		local st = txt(btn, title, 36, C.SubText, F.Med)
		st.Position = UDim2.new(0, 104, 0.5, 0)
		st.Size = UDim2.new(1, -120, 0, 46)
		catBtns[title] = { btn = btn, marker = marker, text = st, icon = ic }
		addRipple(btn, btn, 24)
		btn.MouseButton1Click:Connect(function()
			UI.click()
			selectPage(lastPage[title] or subs[1][1])
		end)
		for i, entry in ipairs(subs) do
			local name, ico = entry[1], entry[2]
			pageCat[name] = title
			table.insert(catPages[title], name)
			local pb = create("TextButton", {
				Size = UDim2.new(0, 0, 0, 90), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.Selected, BackgroundTransparency = 1, BorderSizePixel = 0,
				Text = ico .. "  " .. name, TextSize = 34, Font = F.Med, TextColor3 = C.SubText, AutoButtonColor = false, Visible = false, LayoutOrder = catOrder * 10 + i,
			}, tabBar)
			corner(pb, 24)
			create("UIPadding", { PaddingLeft = UDim.new(0, 32), PaddingRight = UDim.new(0, 32) }, pb)
			pillBtns[name] = { btn = pb }
			addRipple(pb, pb, 24)
			pb.MouseButton1Click:Connect(function()
				UI.click()
				selectPage(name)
			end)
		end
	end

	addCategory("Main", { { "Status", "⌂" }, { "Server", "■" }, { "Help", "?" } })
	addCategory("Visuals", { { "Item ESP", "◎" }, { "Player ESP", "◉" } })
	addCategory("Alerts", { { "Alerts", "▲" } })
	addCategory("Items", { { "Item List", "◈" }, { "Pickup", "◆" } })
	addCategory("Player", { { "Movement", "▶" }, { "Players", "◉" }, { "Utility", "■" }, { "Tools", "◆" } })
	addCategory("HvH", { { "HvH", "◆" }, { "Combat", "▶" } })
	addCategory("Settings", { { "Colors", "◐" }, { "Settings", "◍" } })
	selectPage("Status")
	UI.applyUsername()

	-- small round logo while minimized (tap = restore, drag = move). Size comes from Config.LogoSize --
	local logoBtn = create("TextButton", {
		Name = "MiniLogo", Visible = false, Text = "", Size = UDim2.fromOffset(Config.LogoSize, Config.LogoSize), AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -110, 0, 30), BackgroundColor3 = C.Window, BorderSizePixel = 0, AutoButtonColor = false,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, logoBtn)
	local logoStroke = stroke(logoBtn, Color3.fromRGB(58, 140, 255), 4)
	local miniAv = create("ImageLabel", { Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), BackgroundTransparency = 1, Image = "" }, logoBtn)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, miniAv)
	loadAvatar(miniAv)
	local logoScale = create("UIScale", { Scale = 1 }, logoBtn)

	-- ripple effect: rings expand out of the logo (continuously while minimized, bigger on tap)
	local function ripple(strong)
		local s = Config.LogoSize
		local ring = create("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(s, s), BackgroundTransparency = 1, BorderSizePixel = 0, ZIndex = 0 }, logoBtn)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
		local st = stroke(ring, Color3.fromRGB(58, 140, 255), math.max(2, math.floor(s / 20)))
		st.Transparency = strong and 0 or 0.35
		local goal = s * (strong and 3 or 2.2)
		local info = TweenInfo.new(strong and 0.8 or 1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(ring, info, { Size = UDim2.fromOffset(goal, goal) }):Play()
		TweenService:Create(st, info, { Transparency = 1 }):Play()
		task.delay(1.6, function() ring:Destroy() end)
	end
	UI.ripple = ripple
	task.spawn(function()
		while running do
			if logoBtn.Visible then ripple(false) end
			task.wait(1.2)
		end
	end)
	function UI.applyLogo()
		local s = math.clamp(Config.LogoSize, 36, 160)
		logoBtn.Size = UDim2.fromOffset(s, s)
		logoStroke.Thickness = math.max(2, math.floor(s / 24))
	end
	UI.applyLogo()

	-- open animation: window scales up with a bounce, slides in and fades in; its page slides up
	local busy = false
	local function popIn()
		updateScale()
		local full = uiScale.Scale
		local pos = main.Position
		uiScale.Scale = full * 0.8
		main.Position = pos + UDim2.fromOffset(0, 40)
		main.BackgroundTransparency = 1
		mainStroke.Transparency = 1
		TweenService:Create(uiScale, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = full }):Play()
		TweenService:Create(main, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = pos, BackgroundTransparency = 0.08 }):Play()
		TweenService:Create(mainStroke, TweenInfo.new(0.5), { Transparency = 0 }):Play()
		local pg = pages[UI.currentPage or "Status"]
		if pg then
			pg.frame.Position = UDim2.new(0, 0, 0, 34)
			TweenService:Create(pg.frame, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
		end
	end
	UI.popIn = popIn

	-- logo animation: spins in with a bounce
	local function logoIn()
		logoScale.Scale = 0.2
		logoBtn.Rotation = -180
		ripple(true)
		TweenService:Create(logoScale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
		TweenService:Create(logoBtn, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Rotation = 0 }):Play()
	end

	local function showMain(v)
		if busy then return end
		busy = true
		if v then
			-- logo shrinks away, then the window pops in
			TweenService:Create(logoScale, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0 }):Play()
			task.delay(0.16, function()
				logoBtn.Visible = false
				main.Visible = true
				popIn()
				busy = false
			end)
		else
			-- window shrinks and fades, then the logo spins in
			local full = uiScale.Scale
			TweenService:Create(uiScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = full * 0.85 }):Play()
			TweenService:Create(main, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
			task.delay(0.21, function()
				main.Visible = false
				main.BackgroundTransparency = 0.08
				mainStroke.Transparency = 0
				updateScale()
				logoBtn.Visible = true
				logoIn()
				busy = false
			end)
		end
	end
	do
		local dragging, moved, dragStart, startPos = false, false, nil, nil
		logoBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging, moved, dragStart, startPos = true, false, input.Position, logoBtn.Position
				ripple(true)
			end
		end)
		table.insert(connections, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local raw = input.Position - dragStart
				if raw.Magnitude > 8 then moved = true end
				if moved then
					local delta = raw * (Config.DragSpeed / 100)
					logoBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
				end
			end
		end))
		table.insert(connections, UserInputService.InputEnded:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				dragging = false
				if not moved then
					UI.click()
					showMain(true)
				end
			end
		end))
	end
	UI.showMain = showMain
	minBtn.MouseButton1Click:Connect(function()
		UI.click()
		showMain(false)
	end)
	task.defer(popIn) -- opening animation when the script starts

	-- radar overlay (drag it anywhere; stays visible while minimized) -----
	local radar = create("Frame", {
		Name = "Radar", Size = UDim2.fromOffset(200, 200), Position = UDim2.new(0, 30, 0, 130), BackgroundColor3 = C.Window,
		BackgroundTransparency = 0.2, BorderSizePixel = 0, Visible = false, Active = true,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, radar)
	stroke(radar, Color3.fromRGB(70, 73, 90), 2)
	create("Frame", { Size = UDim2.new(1, -16, 0, 1), Position = UDim2.new(0, 8, 0.5, 0), BackgroundColor3 = C.Line, BorderSizePixel = 0 }, radar)
	create("Frame", { Size = UDim2.new(0, 1, 1, -16), Position = UDim2.new(0.5, 0, 0, 8), BackgroundColor3 = C.Line, BorderSizePixel = 0 }, radar)
	local halfRing = create("Frame", { Size = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1 }, radar)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, halfRing)
	stroke(halfRing, C.Line, 1)
	local me = create("Frame", { Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = C.White, BorderSizePixel = 0, ZIndex = 4 }, radar)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, me)
	local radarDots = {}
	for i = 1, 60 do
		local d = create("Frame", { Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = C.White, BorderSizePixel = 0, Visible = false, ZIndex = 3 }, radar)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, d)
		radarDots[i] = d
	end
	makeDraggable(radar, radar, false)

	local lastRadarSize = 0
	function UI.radarUpdate(arr, origin, cam)
		if not Config.ShowRadar or not cam then
			radar.Visible = false
			return
		end
		radar.Visible = true
		local size = Config.RadarSize
		if size ~= lastRadarSize then
			lastRadarSize = size
			radar.Size = UDim2.fromOffset(size, size)
		end
		local look = cam.CFrame.LookVector
		local f = Vector3.new(look.X, 0, look.Z)
		if f.Magnitude < 0.01 then return end
		f = f.Unit
		local rgt = f:Cross(Vector3.yAxis)
		local R = size / 2 - 8
		local range = Config.RadarRange
		local n = 0
		local function put(e)
			if n >= #radarDots then return end
			local rel = e.part.Position - origin
			local x, y = rel:Dot(rgt), rel:Dot(f)
			local d = math.sqrt(x * x + y * y)
			if d > range then
				if not e.alert then return end
				x, y = x / d * range, y / d * range
			end
			n = n + 1
			local dotF = radarDots[n]
			dotF.Position = UDim2.new(0.5, x / range * R, 0.5, -y / range * R)
			local s = e.alert and 14 or 8
			dotF.Size = UDim2.fromOffset(s, s)
			dotF.BackgroundColor3 = e.alert and Config.AlertColor or Config["Color" .. e.cat.id]
			dotF.Visible = true
		end
		for _, e in ipairs(arr) do
			if e.alert and e.shown then put(e) end
		end
		if not Config.RadarAlertOnly then
			for _, e in ipairs(arr) do
				if not e.alert and e.shown then put(e) end
			end
		end
		for i = n + 1, #radarDots do radarDots[i].Visible = false end
	end

	-- hub-style notifications: dark card bottom-right with icon, title, text and a countdown bar (like the reference)
	local toastHolder = create("Frame", { Name = "Toasts", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -24), Size = UDim2.fromOffset(700, 700), BackgroundTransparency = 1, ZIndex = 200 }, screenGui)
	local toastScale = create("UIScale", { Scale = 1 }, toastHolder)
	local function fitToast() toastScale.Scale = math.clamp(screenGui.AbsoluteSize.Y / 1080, 0.45, 1.3) end
	fitToast()
	table.insert(connections, screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitToast))
	create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Right }, toastHolder)
	local toastN = 0
	function UI.toast(title, text, kind)
		toastN = toastN + 1
		local alert = (kind == "alert")
		local accent = alert and Color3.fromRGB(255, 150, 40) or Color3.fromRGB(70, 140, 255)
		local dur = math.max(Config.NotifyDuration or 6, 2)
		local card = create("CanvasGroup", { Size = UDim2.fromOffset(700, 170), BackgroundColor3 = Color3.fromRGB(24, 26, 28), BorderSizePixel = 0, LayoutOrder = toastN, GroupTransparency = 1, ZIndex = 201 }, toastHolder)
		corner(card, 26)
		local ic = create("TextLabel", { Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(30, 26), BackgroundTransparency = 1, Text = alert and "!" or "i", TextSize = 28, Font = F.Bold, TextColor3 = accent }, card)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, ic)
		stroke(ic, accent, 3)
		create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -120, 0, 48), Position = UDim2.fromOffset(98, 25), Text = tostring(title), TextSize = 36, Font = F.Bold, TextColor3 = C.White, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, card)
		create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -60, 0, 40), Position = UDim2.fromOffset(30, 88), Text = tostring(text or ""), TextSize = 29, Font = F.Reg, TextColor3 = Color3.fromRGB(150, 153, 160), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, card)
		local bar = create("Frame", { Size = UDim2.new(1, -60, 0, 8), Position = UDim2.fromOffset(30, 140), BackgroundColor3 = Color3.fromRGB(52, 54, 58), BorderSizePixel = 0 }, card)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
		local fill = create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0 }, bar)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
		TweenService:Create(card, TweenInfo.new(0.25), { GroupTransparency = 0 }):Play()
		TweenService:Create(fill, TweenInfo.new(dur, Enum.EasingStyle.Linear), { Size = UDim2.new(1, 0, 1, 0) }):Play()
		task.delay(dur, function()
			if not card.Parent then return end
			TweenService:Create(card, TweenInfo.new(0.3), { GroupTransparency = 1 }):Play()
			task.delay(0.35, function() if card.Parent then card:Destroy() end end)
		end)
		local kids = {}
		for _, k in ipairs(toastHolder:GetChildren()) do
			if k:IsA("CanvasGroup") then kids[#kids + 1] = k end
		end
		table.sort(kids, function(x, y) return x.LayoutOrder < y.LayoutOrder end)
		while #kids > 3 do
			kids[1]:Destroy()
			table.remove(kids, 1)
		end
	end

	-- target HUD: name + health bar of the orbit target (bottom centre, draggable)
	local hud = create("Frame", {
		Name = "TargetHUD", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.fromOffset(360, 74),
		BackgroundColor3 = Color3.fromRGB(24, 26, 28), BackgroundTransparency = 0.1, BorderSizePixel = 0, Visible = false, Active = true,
	}, screenGui)
	corner(hud, 16)
	stroke(hud, Color3.fromRGB(32, 72, 72), 2)
	local hudScale = create("UIScale", { Scale = Config.HUDSize / 100 }, hud)
	local hudName = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 28), Position = UDim2.fromOffset(12, 6), Text = "", TextSize = 19, Font = F.Bold, TextColor3 = C.White, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, hud)
	local hudHp = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -24, 0, 28), Position = UDim2.fromOffset(12, 6), Text = "", TextSize = 17, Font = F.Med, TextColor3 = C.SubText, TextXAlignment = Enum.TextXAlignment.Right }, hud)
	local hudBg = create("Frame", { Size = UDim2.new(1, -24, 0, 14), Position = UDim2.fromOffset(12, 44), BackgroundColor3 = C.ToggleOff, BorderSizePixel = 0 }, hud)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, hudBg)
	local hudFill = create("Frame", { Size = UDim2.new(1, 0, 1, 0), BackgroundColor3 = C.Accent, BorderSizePixel = 0 }, hudBg)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, hudFill)
	makeDraggable(hud, hud, false)
	function UI.targetHud(name, hp, mhp, kills)
		if not name or not Config.TargetHUD then
			hud.Visible = false
			return
		end
		hud.Visible = true
		hudScale.Scale = math.clamp(Config.HUDSize, 10, 150) / 100
		hudName.Text = tostring(name) .. "  |  kills " .. tostring(kills or 0)
		hudHp.Text = "HP " .. math.floor(hp) .. "/" .. math.floor(mhp)
		local rel = math.clamp(hp / math.max(mhp, 1), 0, 1)
		TweenService:Create(hudFill, TweenInfo.new(0.15), {
			Size = UDim2.new(rel, 0, 1, 0), BackgroundColor3 = Color3.fromRGB(math.floor(255 * (1 - rel)), math.floor(70 + 160 * rel), 90),
		}):Play()
	end

	function UI.refreshList(entries, total)
		for i, r in ipairs(UI.listRows or {}) do
			local e = entries[i]
			UI.listEntries[i] = e
			if e then
				r.frame:SetAttribute("hidden", false)
				r.frame.Visible = true
				r.name.Text = e.name
				r.name.TextColor3 = e.alert and Config.AlertColor or Config["Color" .. e.cat.id]
				r.dist.Text = math.floor(e.dist) .. " st"
			else
				r.frame:SetAttribute("hidden", true)
				r.frame.Visible = false
			end
		end
		if UI.listCount then UI.listCount.Text = "Showing " .. #entries .. " of " .. total end
	end
end

---------------------------------------------------------------------
-- ITEM DETECTION
---------------------------------------------------------------------
local EXCLUDE = { "door", "portal", "gate", "npc", "shop", "baseplate", "terrain", "spawnlocation", "wall", "floor", "road", "camera" }
local CONTAINERS = { "item", "drop", "pickup", "loot", "collectible" }
local PICK_WORDS = { "pick", "take", "grab", "collect", "equip", "loot" }

-- true when the object belongs to a player or an NPC (we only want items)
local function inCreature(inst)
	local a = inst.Parent
	while a and a ~= Workspace do
		if a:IsA("Model") and (a:FindFirstChildOfClass("Humanoid") or Players:GetPlayerFromCharacter(a)) then return true end
		a = a.Parent
	end
	return false
end

local function mainPart(root)
	if root:IsA("BasePart") then return root end
	if root:IsA("Tool") then return root:FindFirstChild("Handle") or root:FindFirstChildWhichIsA("BasePart", true) end
	if root:IsA("Model") then return root.PrimaryPart or root:FindFirstChildWhichIsA("BasePart", true) end
	return nil
end

local function finalize(r)
	if not r or r == Workspace or not r.Parent then return nil end
	if r:IsA("Model") and r:FindFirstChildOfClass("Humanoid") then return nil end
	if inCreature(r) then return nil end
	local lname = string.lower(r.Name)
	if nameHas(lname, hiddenList) then return nil end
	if nameHas(lname, EXCLUDE) and not nameHas(lname, alertList) then return nil end
	local part = mainPart(r)
	if not part then return nil end
	local size = part.Size
	if r:IsA("Model") then
		local okSize, ext = pcall(function() return r:GetExtentsSize() end)
		if okSize then size = ext end
	end
	if size.Magnitude > 50 then return nil end -- map geometry, not an item
	return r, part
end

-- returns (itemRoot, itemPart, prompt) when `inst` looks like a pickup item
local function classify(inst)
	local cn = inst.ClassName
	local mode = Config.ScanMode
	local root, alt, prompt

	if cn == "ProximityPrompt" or (cn == "ClickDetector" and mode == "Aggressive") then
		local par = inst.Parent
		if par and par:IsA("Attachment") then par = par.Parent end
		if not par then return nil end
		root = par
		local m = par:FindFirstAncestorOfClass("Model")
		if par:IsA("Model") then
			root = par
		elseif m and not m:FindFirstChildOfClass("Humanoid") then
			root = m
			if par:IsA("BasePart") then alt = par end
		end
		local lname = string.lower(root.Name)
		local ok = false
		if mode == "Aggressive" then
			ok = true
		else
			local ptxt = ""
			if cn == "ProximityPrompt" then ptxt = string.lower((inst.ActionText or "") .. " " .. (inst.ObjectText or "")) end
			ok = nameHas(ptxt, PICK_WORDS) or nameHas(lname, alertList) or nameHas(lname, extraList)
			if not ok and mode == "Smart" and root.Parent then ok = nameHas(string.lower(root.Parent.Name), CONTAINERS) end
		end
		if not ok then return nil end
		if cn == "ProximityPrompt" then prompt = inst end
	elseif cn == "Tool" then
		root = inst
	elseif cn == "Model" or inst:IsA("BasePart") then
		local lname = string.lower(inst.Name)
		local ok = nameHas(lname, alertList) or nameHas(lname, extraList)
		if not ok and mode ~= "Pickups" and inst.Parent and inst.Parent ~= Workspace then
			if nameHas(string.lower(inst.Parent.Name), CONTAINERS) then
				ok = (cn == "Model") or inst.Parent:IsA("Folder")
			end
		end
		if not ok then return nil end
		root = inst
	else
		return nil
	end

	local r, p = finalize(root)
	if not r and alt then r, p = finalize(alt) end
	if not r then return nil end
	if not prompt then prompt = r:FindFirstChildWhichIsA("ProximityPrompt", true) end
	return r, p, prompt
end

---------------------------------------------------------------------
-- ESP OBJECTS
---------------------------------------------------------------------
local espFolder = Instance.new("Folder")
espFolder.Name = "ItemESP_Objects"
do
	local ok = pcall(function() espFolder.Parent = game:GetService("CoreGui") end)
	if not ok or not espFolder.Parent then espFolder.Parent = getGuiParent() end
end

local tracked = {}
local lastArr, alertArr = {}, {}
local pickedCount = 0

local function currentOrigin()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then return hrp.Position end
	local cam = Workspace.CurrentCamera
	return cam and cam.CFrame.Position or Vector3.zero
end

local DIRS = { "ahead", "ahead-right", "right", "behind-right", "behind", "behind-left", "left", "ahead-left" }
local function directionText(pos)
	local cam = Workspace.CurrentCamera
	if not cam then return "" end
	local look = cam.CFrame.LookVector
	local f = Vector3.new(look.X, 0, look.Z)
	if f.Magnitude < 0.01 then return "" end
	f = f.Unit
	local rgt = f:Cross(Vector3.yAxis)
	local rel = pos - currentOrigin()
	local angle = math.deg(math.atan2(rel:Dot(rgt), rel:Dot(f)))
	local idx = math.floor(((angle + 22.5) % 360) / 45) + 1
	return DIRS[idx] or ""
end

local SOUNDS = {
	Ping = "rbxasset://sounds/electronicpingshort.wav",
	Bass = "rbxasset://sounds/bass.mp3",
	Snap = "rbxasset://sounds/snap.mp3",
	Switch = "rbxasset://sounds/switch.mp3",
}
local function playAlertSound()
	if not Config.AlertSound then return end
	pcall(function()
		local snd = Instance.new("Sound")
		snd.SoundId = SOUNDS[Config.AlertSoundType] or SOUNDS.Ping
		snd.Volume = Config.AlertVolume / 2
		snd.Parent = SoundService
		snd:Play()
		task.delay(4, function() snd:Destroy() end)
	end)
end

local function sendAlert(e, kind)
	local pos = e.part.Position
	local d = math.floor((pos - currentOrigin()).Magnitude)
	local title
	if kind == "reminder" then
		title = e.name .. " is still on the map"
	elseif kind == "test" then
		title = e.name .. " appeared! (test)"
	else
		title = e.name .. " appeared!"
	end
	local body = d .. " studs | " .. directionText(pos)
	notify(title, body)
	playAlertSound()
end

local function setFlags(e)
	local lname = string.lower(e.name)
	e.cat = categorize(lname)
	e.alert = nameHas(lname, alertList)
	e.notify = e.alert or (Config["AlertCat" .. e.cat.id] == true)
end

local function removeEntry(root, silent)
	local e = tracked[root]
	if not e then return end
	tracked[root] = nil
	pcall(function() e.hl:Destroy() end)
	pcall(function() e.box:Destroy() end)
	pcall(function() e.bb:Destroy() end)
	if e.line then pcall(function() e.line:Remove() end) end
	if e.origHold and e.prompt then pcall(function() e.prompt.HoldDuration = e.origHold end) end
	if not silent and running and Config.AlertOnDespawn and Config.AlertEnabled and e.notify and e.alerted then
		notify(e.name .. " is gone", "picked up or despawned")
	end
end

local function track(root, part, prompt)
	if tracked[root] then return end
	local a = root.Parent
	while a and a ~= Workspace do
		if tracked[a] then return end -- a parent model is already tracked
		a = a.Parent
	end

	local e = { root = root, part = part, prompt = prompt, name = root.Name, dist = 0, shown = false, alerted = false, lastAlert = 0, lastPick = 0 }
	setFlags(e)

	local hl = Instance.new("Highlight")
	hl.Adornee = root
	hl.OutlineTransparency = 0
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Enabled = false
	hl.Parent = espFolder
	e.hl = hl

	local box = Instance.new("SelectionBox")
	box.Adornee = root:IsA("Tool") and part or root
	box.LineThickness = 0.04
	box.SurfaceTransparency = 1
	box.Visible = false
	box.Parent = espFolder
	e.box = box

	local bb = Instance.new("BillboardGui")
	bb.Adornee = part
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(280, 50)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.LightInfluence = 0
	bb.Enabled = false
	bb.Parent = espFolder
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 15
	lbl.TextStrokeTransparency = 0.35
	lbl.TextWrapped = true
	lbl.Text = e.name
	lbl.Parent = bb
	e.bb, e.lbl = bb, lbl

	if Drawing then
		local okLine, line = pcall(function() return Drawing.new("Line") end)
		if okLine and line then
			line.Thickness = 1.5
			line.Visible = false
			e.line = line
		end
	end

	tracked[root] = e
end

local function consider(inst)
	if not running then return end
	local ok, root, part, prompt = pcall(classify, inst)
	if ok and root then track(root, part, prompt) end
end

local function fullScan()
	local list = Workspace:GetDescendants()
	for i, inst in ipairs(list) do
		if not running then return end
		consider(inst)
		if i % 1500 == 0 then task.wait() end
	end
end

-- quick filter so effects/projectiles spawning in combat don't cost anything
local function couldBeItem(inst)
	local cn = inst.ClassName
	if cn == "Tool" or cn == "ProximityPrompt" or cn == "ClickDetector" then return true end
	if cn == "Model" or inst:IsA("BasePart") then
		local lname = string.lower(inst.Name)
		if nameHas(lname, alertList) or nameHas(lname, extraList) then return true end
		local par = inst.Parent
		return par ~= nil and par ~= Workspace and nameHas(string.lower(par.Name), CONTAINERS)
	end
	return false
end

table.insert(connections, Workspace.DescendantAdded:Connect(function(inst)
	if couldBeItem(inst) then
		task.delay(0.3, consider, inst) -- let the item's children load first
	end
end))

task.spawn(function()
	fullScan()
	while running do
		local waited = 0
		while running and waited < Config.ScanInterval do
			task.wait(0.5)
			waited = waited + 0.5
		end
		if running then fullScan() end
	end
end)

---------------------------------------------------------------------
-- OFF-SCREEN ARROWS (Drawing)
---------------------------------------------------------------------
local ARROWS = {}
if Drawing then
	for i = 1, 5 do
		local okA, tri = pcall(function() return Drawing.new("Triangle") end)
		local okT, tx = pcall(function() return Drawing.new("Text") end)
		if okA and okT and tri and tx then
			tri.Filled = true
			tri.Thickness = 1
			tri.Visible = false
			tx.Size = 15
			tx.Center = true
			tx.Outline = true
			tx.Visible = false
			pcall(function() tx.Font = Drawing.Fonts.UI end)
			ARROWS[#ARROWS + 1] = { tri = tri, txt = tx }
		end
	end
end

local function renderArrows(cam)
	if #ARROWS == 0 then return end
	local vp = cam.ViewportSize
	local center = Vector2.new(vp.X / 2, vp.Y / 2)
	local radius = math.min(vp.X, vp.Y) / 2 - 70
	local look = cam.CFrame.LookVector
	local f = Vector3.new(look.X, 0, look.Z)
	local used = 0
	if Config.AlertArrows and Config.AlertEnabled and Config.Enabled and f.Magnitude > 0.01 then
		f = f.Unit
		local rgt = f:Cross(Vector3.yAxis)
		local origin = currentOrigin()
		for _, e in ipairs(alertArr) do
			if used >= #ARROWS then break end
			if e.shown and e.part.Parent then
				local v, on = cam:WorldToViewportPoint(e.part.Position)
				if not (on and v.Z > 0) then
					local rel = e.part.Position - origin
					local dir = Vector2.new(rel:Dot(rgt), -rel:Dot(f))
					if dir.Magnitude > 0.01 then
						dir = dir.Unit
						used = used + 1
						local ar = ARROWS[used]
						local perp = Vector2.new(-dir.Y, dir.X)
						local tip = center + dir * (radius + 22)
						local base = center + dir * (radius - 14)
						ar.tri.PointA = tip
						ar.tri.PointB = base + perp * 16
						ar.tri.PointC = base - perp * 16
						ar.tri.Color = Config.AlertColor
						ar.tri.Visible = true
						ar.txt.Text = e.name .. " " .. math.floor(e.dist) .. "st"
						ar.txt.Position = center + dir * (radius - 42) - Vector2.new(0, 8)
						ar.txt.Color = Config.AlertColor
						ar.txt.Visible = true
					end
				end
			end
		end
	end
	for i = used + 1, #ARROWS do
		ARROWS[i].tri.Visible = false
		ARROWS[i].txt.Visible = false
	end
end

---------------------------------------------------------------------
-- UPDATE LOOPS
---------------------------------------------------------------------
local function firePrompt(prompt)
	if fireproximityprompt then
		return (pcall(fireproximityprompt, prompt))
	end
	return false
end

local frames = 0
local acc, listAcc = 0, 0
table.insert(connections, RunService.Heartbeat:Connect(function(dt)
	acc = acc + dt
	if acc < 0.1 then return end
	acc = 0
	listAcc = listAcc + 0.1

	local now = os.clock()
	local origin = currentOrigin()
	local cam = Workspace.CurrentCamera
	local arr = {}
	for root, e in pairs(tracked) do
		if not root:IsDescendantOf(Workspace) or not e.part.Parent then
			removeEntry(root)
		else
			e.dist = (e.part.Position - origin).Magnitude
			arr[#arr + 1] = e
		end
	end
	table.sort(arr, function(x, y) return x.dist < y.dist end)

	local counts = {}
	local alerts = {}
	local hlCount = 0
	for _, e in ipairs(arr) do
		local id = e.cat.id
		counts[id] = (counts[id] or 0) + 1
		if e.alert then alerts[#alerts + 1] = e end

		local show = Config.Enabled and e.dist <= Config.MaxDistance and (Config["Show" .. id] ~= false)
		e.shown = show
		local col = e.alert and Config.AlertColor or Config["Color" .. id]

		-- Roblox only renders ~31 highlights at once, so the nearest 30 get one
		local wantHl = show and Config.Highlight
		if wantHl then
			hlCount = hlCount + 1
			wantHl = hlCount <= 30
		end
		e.hl.Enabled = wantHl
		e.hl.FillColor = col
		e.hl.OutlineColor = col
		if not (e.alert and Config.PulseAlerts) then e.hl.FillTransparency = Config.FillTransparency / 100 end

		e.box.Visible = show and Config.Boxes
		e.box.Color3 = col

		local line1
		if Config.NameTag then
			line1 = e.name
			if Config.CategoryTag and id ~= "Other" then line1 = "[" .. e.cat.label .. "] " .. line1 end
		end
		local line2 = Config.Distance and ("[" .. math.floor(e.dist) .. " studs]") or nil
		local text
		if line1 and line2 then text = line1 .. "\n" .. line2 else text = line1 or line2 end
		e.bb.Enabled = show and text ~= nil
		if text then
			e.lbl.Text = text
			e.lbl.TextColor3 = col
			e.lbl.TextSize = Config.TextSize
			e.bb.Size = UDim2.fromOffset(300, Config.TextSize * 3.4)
			e.lbl.TextTransparency = Config.FadeWithDistance and (math.clamp(e.dist / Config.MaxDistance, 0, 1) * 0.75) or 0
		end

		-- alerts
		if Config.AlertEnabled and e.notify then
			if not e.alerted then
				if Config.AlertDistance == 0 or e.dist <= Config.AlertDistance then
					e.alerted = true
					e.lastAlert = now
					sendAlert(e, "appeared")
				end
			elseif Config.AlertRemind > 0 and now - e.lastAlert >= Config.AlertRemind then
				e.lastAlert = now
				sendAlert(e, "reminder")
			end
		end

		-- pickup helpers
		local prompt = e.prompt
		if prompt and prompt.Parent then
			if Config.InstantPrompt then
				if prompt.HoldDuration ~= 0 then
					e.origHold = e.origHold or prompt.HoldDuration
					pcall(function() prompt.HoldDuration = 0 end)
				end
			end
			if Config.ExtendPrompts then
				if not e.origRange then e.origRange = { prompt.MaxActivationDistance, prompt.RequiresLineOfSight } end
				pcall(function()
					prompt.MaxActivationDistance = Config.PromptRange
					prompt.RequiresLineOfSight = false
				end)
			end
			if Config.AutoPickup and e.dist <= Config.AutoPickupRange and (not Config.AutoPickupAlertOnly or e.alert) and now - e.lastPick > 0.4 then
				e.lastPick = now
				if firePrompt(prompt) then pickedCount = pickedCount + 1 end
			end
		end
	end

	lastArr, alertArr = arr, alerts

	if UI.radarUpdate then UI.radarUpdate(arr, origin, cam) end

	if listAcc >= 1 then
		listAcc = 0

		local ping = 0
		local okPing, v = pcall(function() return StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() end)
		if okPing and v then ping = math.floor(v) end
		if UI.stats then
			if UI.stats["Items Tracked"] then UI.stats["Items Tracked"].Text = tostring(#arr) end
			if UI.stats["Alert Items"] then UI.stats["Alert Items"].Text = tostring(#alerts) end
			if UI.stats["FPS"] then UI.stats["FPS"].Text = tostring(frames) end
			if UI.stats["Ping"] then UI.stats["Ping"].Text = ping .. " ms" end
		end
		frames = 0
		if UI.alertInfo then UI.alertInfo.Text = "Alert items on map: " .. #alerts end
		if UI.pickupInfo then UI.pickupInfo.Text = "Auto picked up: " .. pickedCount end
		if UI.catInfo then
			for _, cat in ipairs(CATEGORIES) do
				local lbl = UI.catInfo[cat.id]
				if lbl then lbl.Text = cat.label .. ": " .. (counts[cat.id] or 0) end
			end
		end

		-- item list (search + sort)
		if UI.refreshList then
			local q = string.lower(Config.ListSearch or "")
			local filtered = {}
			for _, e in ipairs(arr) do
				if q == "" or string.find(string.lower(e.name), q, 1, true) or string.find(string.lower(e.cat.label), q, 1, true) then
					filtered[#filtered + 1] = e
				end
			end
			if Config.ListSort == "Name" then
				table.sort(filtered, function(x, y)
					local a, b = string.lower(x.name), string.lower(y.name)
					if a == b then return x.dist < y.dist end
					return a < b
				end)
			end
			local shownList = {}
			for i = 1, math.min(#filtered, 40) do shownList[i] = filtered[i] end
			UI.refreshList(shownList, #arr)
		end
	end
end))

table.insert(connections, RunService.RenderStepped:Connect(function()
	frames = frames + 1
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local t = os.clock()

	-- pulsing glow on alert items
	if Config.PulseAlerts then
		local tr = 0.2 + 0.4 * (0.5 + 0.5 * math.sin(t * 5))
		for _, e in ipairs(alertArr) do
			if e.hl.Enabled then e.hl.FillTransparency = tr end
		end
	end

	if Drawing then
		local vp = cam.ViewportSize
		local from
		if Config.TracerOrigin == "Center" then
			from = Vector2.new(vp.X / 2, vp.Y / 2)
		elseif Config.TracerOrigin == "Top" then
			from = Vector2.new(vp.X / 2, 0)
		else
			from = Vector2.new(vp.X / 2, vp.Y)
		end
		for _, e in pairs(tracked) do
			local line = e.line
			if line then
				if e.shown and Config.Tracers then
					local v, onScreen = cam:WorldToViewportPoint(e.part.Position)
					if onScreen and v.Z > 0 then
						line.From = from
						line.To = Vector2.new(v.X, v.Y)
						line.Color = e.alert and Config.AlertColor or Config.TracerColor
						line.Visible = true
					else
						line.Visible = false
					end
				else
					line.Visible = false
				end
			end
		end
		pcall(renderArrows, cam)
	end
end))

-- hotkeys: toggle the whole ESP / toggle orbit
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
	if gp or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	local kn = input.KeyCode.Name
	if Config.ToggleKey ~= "None" and kn == Config.ToggleKey and UI.setEnabled then
		UI.setEnabled(not Config.Enabled)
	end
	if Config.OrbitKey ~= "None" and kn == Config.OrbitKey and UI.setOrbit then
		UI.setOrbit(not Config.OrbitOn)
	end
	if Config.HideKey ~= "None" and kn == Config.HideKey then screenGui.Enabled = not screenGui.Enabled end
	if Config.FlyKey ~= "None" and kn == Config.FlyKey and UI.setFly then UI.setFly(not Config.Fly) end
	if Config.NoclipKey ~= "None" and kn == Config.NoclipKey and UI.setNoclip then UI.setNoclip(not Config.Noclip) end
	if Config.SpeedKey ~= "None" and kn == Config.SpeedKey and UI.setSpeed then UI.setSpeed(not Config.SpeedOn) end
end))

---------------------------------------------------------------------
-- GUI ACTIONS
---------------------------------------------------------------------
Actions.rescan = function()
	task.spawn(fullScan)
end

-- re-reads every name list and refreshes categories / alert flags
Actions.reapply = function()
	alertList = parseList(Config.AlertNames)
	extraList = parseList(Config.ExtraNames)
	hiddenList = parseList(Config.HiddenNames)
	for root, e in pairs(tracked) do
		if nameHas(string.lower(e.name), hiddenList) then
			removeEntry(root, true)
		else
			setFlags(e)
		end
	end
	task.spawn(fullScan)
end

Actions.realert = function()
	for _, e in pairs(tracked) do
		e.alerted = false
	end
end

Actions.restoreHold = function()
	for _, e in pairs(tracked) do
		if e.origHold and e.prompt then
			pcall(function() e.prompt.HoldDuration = e.origHold end)
			e.origHold = nil
		end
	end
end

Actions.teleport = function(e)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp and e and e.part and e.part.Parent then
		hrp.CFrame = CFrame.new(e.part.Position + Vector3.new(0, 3, 0))
		return true
	end
	return false
end

Actions.tpClosest = function(alertOnly)
	for _, e in ipairs(lastArr) do
		if (not alertOnly or e.alert) and e.part.Parent then
			return Actions.teleport(e)
		end
	end
	return false
end

Actions.hide = function(e)
	if not e then return end
	local name = e.name
	local cur = Config.HiddenNames
	if cur ~= "" then cur = cur .. ", " end
	Config.HiddenNames = cur .. name
	if UI.sync then UI.sync() end
	Actions.reapply()
end

Actions.testAlert = function()
	local fake = {
		name = "C4",
		part = { Position = currentOrigin() + Vector3.new(0, 0, -50) },
		cat = CAT.Explosive,
		alert = true,
	}
	sendAlert(fake, "test")
end

---------------------------------------------------------------------
-- EXTRA FEATURES (player ESP, movement, utility, auto collect)
---------------------------------------------------------------------
Feat.pl = {}          -- player ESP objects, keyed by Player
Feat.orig = {}        -- values to restore when a feature is switched off
Feat.collected = 0
Feat.acc = 0
Feat.Lighting = game:GetService("Lighting")
Feat.errd = {}

-- runs a function safely; the first error of each kind is shown as a notification + printed (so bugs are visible)
local function guard(name, fn)
	return function(...)
		local ok, err = pcall(fn, ...)
		if not ok and not Feat.errd[name] then
			Feat.errd[name] = true
			warn("CodeBot error [" .. name .. "]: " .. tostring(err))
			pcall(notify, "Script error: " .. name, string.sub(tostring(err), 1, 90), true)
		end
	end
end

Feat.restorePrompts = function()
	for _, e in pairs(tracked) do
		if e.origRange and e.prompt then
			pcall(function()
				e.prompt.MaxActivationDistance = e.origRange[1]
				e.prompt.RequiresLineOfSight = e.origRange[2]
			end)
			e.origRange = nil
		end
	end
end

-- player ESP ----------------------------------------------------------
Feat.dropPlayer = function(plr)
	local ent = Feat.pl[plr]
	if not ent then return end
	Feat.pl[plr] = nil
	pcall(function() ent.box:Destroy() end)
	pcall(function() ent.bb:Destroy() end)
	pcall(function() ent.hl:Destroy() end)
	if ent.line then pcall(function() ent.line:Remove() end) end
end

Feat.makePlayer = function(plr, char)
	local ent = { char = char, dist = 0 }
	local box = Instance.new("SelectionBox")
	box.Adornee = char
	box.LineThickness = 0.04
	box.SurfaceTransparency = 0.88
	box.Parent = espFolder

	local bb = Instance.new("BillboardGui")
	bb.Adornee = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
	bb.AlwaysOnTop = true
	bb.Size = UDim2.fromOffset(260, 60)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.LightInfluence = 0
	bb.Parent = espFolder
	local lbl = Instance.new("TextLabel")
	lbl.BackgroundTransparency = 1
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 15
	lbl.TextStrokeTransparency = 0.35
	lbl.TextWrapped = true
	lbl.Parent = bb
	ent.box, ent.bb, ent.lbl = box, bb, lbl
	local hl = Instance.new("Highlight")
	hl.Adornee = char
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.FillTransparency = 0.7
	hl.Parent = espFolder
	ent.hl = hl

	if Drawing then
		local okLine, line = pcall(function() return Drawing.new("Line") end)
		if okLine and line then
			line.Thickness = 1.5
			line.Visible = false
			ent.line = line
		end
	end
	Feat.pl[plr] = ent
	return ent
end

Feat.updatePlayers = function()
	local origin = currentOrigin()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local char = plr.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local want = Config.PlayerESP and hrp ~= nil and hum ~= nil and hum.Health > 0
			local dist = 0
			if want then
				dist = (hrp.Position - origin).Magnitude
				if dist > Config.PMaxDistance then want = false end
				if want and Config.PTeamCheck and plr.Team ~= nil and plr.Team == player.Team then want = false end
			end
			local ent = Feat.pl[plr]
			if ent and (not want or ent.char ~= char) then
				Feat.dropPlayer(plr)
				ent = nil
			end
			if want then
				if not ent then ent = Feat.makePlayer(plr, char) end
				ent.hrp = hrp
				ent.dist = dist
				local col = Config.ColorPlayer
				ent.box.Visible = Config.PBox
				ent.box.Color3 = col
				ent.box.SurfaceColor3 = col
				ent.hl.Enabled = Config.PGlow
				ent.hl.FillColor = col
				ent.hl.OutlineColor = col
				local parts = {}
				if Config.PName then
					parts[#parts + 1] = (plr.DisplayName ~= plr.Name) and (plr.DisplayName .. " (@" .. plr.Name .. ")") or plr.Name
				end
				if Config.PHealth then
					parts[#parts + 1] = "HP " .. math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
				end
				if Config.PDistance then
					parts[#parts + 1] = "[" .. math.floor(dist) .. " studs]"
				end
				ent.bb.Enabled = #parts > 0
				ent.lbl.Text = table.concat(parts, "\n")
				ent.lbl.TextColor3 = col
				ent.bb.Size = UDim2.fromOffset(280, 19 * math.max(#parts, 1) + 8)
			end
		end
	end
	for plr in pairs(Feat.pl) do
		if not plr.Parent then Feat.dropPlayer(plr) end
	end
end

-- lighting ------------------------------------------------------------
Feat.light = function()
	local L = Feat.Lighting
	if Config.Fullbright then
		if not Feat.orig.light then
			Feat.orig.light = {
				Brightness = L.Brightness, ClockTime = L.ClockTime, FogEnd = L.FogEnd,
				GlobalShadows = L.GlobalShadows, Ambient = L.Ambient, OutdoorAmbient = L.OutdoorAmbient,
			}
		end
		L.Brightness = 2
		L.ClockTime = Config.TimeOn and Config.TimeVal or 14
		L.FogEnd = 100000
		L.GlobalShadows = false
		L.Ambient = Color3.fromRGB(178, 178, 178)
		L.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
	elseif Feat.orig.light then
		for k, v in pairs(Feat.orig.light) do pcall(function() L[k] = v end) end
		Feat.orig.light = nil
	end
end

-- fly -----------------------------------------------------------------
Feat.stopFly = function()
	if Feat.bv then pcall(function() Feat.bv:Destroy() end) Feat.bv = nil end
	if Feat.bg then pcall(function() Feat.bg:Destroy() end) Feat.bg = nil end
	if Feat.flyStand then
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then pcall(function() hum.PlatformStand = false end) end
		Feat.flyStand = false
	end
end

-- main per-frame step (speed, jump, fly) + slower tick (player ESP, lighting)
Feat.step = function(dt)
	Feat.acc = Feat.acc + dt
	if Feat.acc >= 0.1 then
		Feat.acc = 0
		pcall(Feat.updatePlayers)
		pcall(Feat.light)
		pcall(Feat.hitbox)
		pcall(Feat.gravity)
		pcall(Feat.zoom)
	end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) then return end

	-- void safe: remember the last safe spot, return there when falling out of the map
	if Config.VoidSafe then
		local now = os.clock()
		if hrp.Position.Y > Config.VoidY + 40 and hum.FloorMaterial ~= Enum.Material.Air and now - (Feat.safeT or 0) > 1 then
			Feat.safeT, Feat.safePos = now, hrp.CFrame
		end
		if hrp.Position.Y < Config.VoidY and Feat.safePos and not Config.OrbitOn then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = Feat.safePos + Vector3.new(0, 4, 0)
			notify("Void Safe", "Returned to the last safe spot", true)
		end
	end

	-- panic escape: at low HP go high up and freeze for a few seconds
	if Config.PanicOn and hum.Health > 0 and hum.MaxHealth > 0 and (hum.Health / hum.MaxHealth * 100) <= Config.PanicHP
		and os.clock() - (Feat.panicT or 0) > 10 then
		Feat.panicT = os.clock()
		if Config.OrbitOn and UI.setOrbit then UI.setOrbit(false) end
		hrp.CFrame = hrp.CFrame + Vector3.new(0, Config.PanicHeight, 0)
		hrp.Anchored = true
		notify("Panic Escape", "Low HP - teleported up", true)
		task.delay(4, function() if hrp.Parent then hrp.Anchored = false end end)
	end

	if Config.Bhop and not Config.Fly and hum.MoveDirection.Magnitude > 0.1 and hum.FloorMaterial ~= Enum.Material.Air then
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end

	if Config.SpeedOn and not Feat.walking then
		if not Feat.orig.speed then Feat.orig.speed = hum.WalkSpeed end
		hum.WalkSpeed = Config.WalkSpeedVal
	elseif Feat.orig.speed and not Feat.walking then
		hum.WalkSpeed = Feat.orig.speed
		Feat.orig.speed = nil
	end

	if Config.JumpOn then
		if not Feat.orig.jump then Feat.orig.jump = { hum.UseJumpPower, hum.JumpPower } end
		hum.UseJumpPower = true
		hum.JumpPower = Config.JumpPowerVal
	elseif Feat.orig.jump then
		hum.UseJumpPower = Feat.orig.jump[1]
		hum.JumpPower = Feat.orig.jump[2]
		Feat.orig.jump = nil
	end

	if Config.Fly and hum.Health > 0 then
		if not Feat.bv or Feat.bv.Parent ~= hrp then
			if Feat.bv then pcall(function() Feat.bv:Destroy() end) end
			if Feat.bg then pcall(function() Feat.bg:Destroy() end) end
			local bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
			bv.Velocity = Vector3.zero
			bv.Parent = hrp
			local bg = Instance.new("BodyGyro")
			bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
			bg.P = 9e4
			bg.CFrame = hrp.CFrame
			bg.Parent = hrp
			Feat.bv, Feat.bg = bv, bg
		end
		hum.PlatformStand = true
		Feat.flyStand = true
		local cam = Workspace.CurrentCamera
		if cam then
			local look = cam.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			if flat.Magnitude > 0.01 then
				Feat.bg.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flat)
			end
			local md = hum.MoveDirection
			if md.Magnitude > 0.05 then
				local o = cam.CFrame:VectorToObjectSpace(md)
				local dir = cam.CFrame.LookVector * (-o.Z) + cam.CFrame.RightVector * o.X
				if dir.Magnitude > 0.01 then
					Feat.bv.Velocity = dir.Unit * Config.FlySpeed
				else
					Feat.bv.Velocity = Vector3.zero
				end
			else
				Feat.bv.Velocity = Vector3.zero
			end
		end
	elseif Feat.bv or Feat.flyStand then
		Feat.stopFly()
	end
end

table.insert(connections, RunService.Heartbeat:Connect(function(dt)
	local ok, err = pcall(Feat.step, dt)
	if not ok and not Feat.warned then
		Feat.warned = true
		warn("Item ESP: feature step error: " .. tostring(err))
	end
end))

-- FOV + player tracers (every rendered frame)
Feat.render = function()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	if Config.FOVOn then
		if not Feat.orig.fov then Feat.orig.fov = cam.FieldOfView end
		cam.FieldOfView = Config.FOVVal
	elseif Feat.orig.fov then
		cam.FieldOfView = Feat.orig.fov
		Feat.orig.fov = nil
	end
	if Drawing then
		local vp = cam.ViewportSize
		local from = Vector2.new(vp.X / 2, vp.Y)
		for _, ent in pairs(Feat.pl) do
			local line = ent.line
			if line then
				if Config.PTracers and ent.hrp and ent.hrp.Parent then
					local v, on = cam:WorldToViewportPoint(ent.hrp.Position)
					if on and v.Z > 0 then
						line.From = from
						line.To = Vector2.new(v.X, v.Y)
						line.Color = Config.ColorPlayer
						line.Visible = true
					else
						line.Visible = false
					end
				else
					line.Visible = false
				end
			end
		end
	end
end
table.insert(connections, RunService.RenderStepped:Connect(guard("render", Feat.render)))

-- noclip
table.insert(connections, RunService.Stepped:Connect(function()
	if not Config.Noclip then return end
	local char = player.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
	end
end))

-- infinite jump
table.insert(connections, UserInputService.JumpRequest:Connect(function()
	if not Config.InfJump then return end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

-- anti AFK
table.insert(connections, player.Idled:Connect(function()
	if not Config.AntiAFK then return end
	pcall(function()
		local vu = game:GetService("VirtualUser")
		vu:CaptureController()
		vu:ClickButton2(Vector2.new())
	end)
end))

-- auto collect (teleport to the item, fire its prompt, optionally come back)
task.spawn(function()
	while running do
		task.wait(0.4)
		if running and Config.AutoCollect and not Feat.walking then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				local now = os.clock()
				local target
				for _, e in ipairs(lastArr) do
					if e.part.Parent and e.prompt and e.prompt.Parent and e.dist <= Config.AutoCollectRange
						and (not Config.AutoCollectAlertOnly or e.alert) and now - (e.lastCollect or 0) > 4 then
						target = e
						break
					end
				end
				if target then
					target.lastCollect = now
					local home = hrp.CFrame
					local prompt = target.prompt
					local oldHold = prompt.HoldDuration
					pcall(function() prompt.HoldDuration = 0 end)
					hrp.CFrame = CFrame.new(target.part.Position + Vector3.new(0, 3, 0))
					task.wait(0.15)
					for _ = 1, 4 do
						if not (prompt.Parent and target.part.Parent) then break end
						firePrompt(prompt)
						task.wait(0.1)
					end
					task.wait(0.2)
					pcall(function() prompt.HoldDuration = oldHold end)
					if Config.AutoCollectReturn and hrp.Parent then hrp.CFrame = home end
					if not target.root.Parent or not target.part.Parent then
						Feat.collected = Feat.collected + 1
						pickedCount = pickedCount + 1
						if UI.collectInfo then UI.collectInfo.Text = "Auto collected: " .. Feat.collected end
						notify("Auto Collect", target.name .. " collected", true)
					end
				end
			end
		end
	end
end)

-- server / character helpers ---------------------------------------------
Feat.hop = function()
	notify("Server Hop", "Looking for another server...", true)
	task.spawn(function()
		local TS = game:GetService("TeleportService")
		local ok, body = pcall(function()
			return game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
		end)
		if ok and body then
			local ok2, data = pcall(function() return HttpService:JSONDecode(body) end)
			if ok2 and type(data) == "table" and type(data.data) == "table" then
				local cands = {}
				for _, sv in ipairs(data.data) do
					if sv.id ~= game.JobId and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers - 1 then
						cands[#cands + 1] = sv.id
					end
				end
				if #cands > 0 then
					pcall(function() TS:TeleportToPlaceInstance(game.PlaceId, cands[math.random(#cands)], player) end)
					return
				end
			end
		end
		notify("Server Hop", "No server list, using a normal teleport", true)
		pcall(function() TS:Teleport(game.PlaceId, player) end)
	end)
end

Feat.rejoin = function()
	notify("Rejoin", "Rejoining this server...", true)
	local TS = game:GetService("TeleportService")
	if #Players:GetPlayers() <= 1 then
		task.spawn(function()
			pcall(function() TS:Teleport(game.PlaceId, player) end)
		end)
	else
		pcall(function() TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, player) end)
	end
end

Feat.reset = function()
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.Health = 0 end
end

-- walk to selected items (pathfinding, finds a way around obstacles) and collect them
Feat.walking = false
Feat.PFS = game:GetService("PathfindingService")

Feat.walkTo = function(e)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) then return false end
	local deadline = os.clock() + Config.WalkTimeout
	local fails = 0
	local function gone() return not (e.part.Parent and e.root.Parent) end
	local function near() return (hrp.Position - e.part.Position).Magnitude <= 6 end
	local function alive() return running and Config.WalkCollect and hum.Health > 0 and hrp.Parent end

	while alive() and os.clock() < deadline and fails < 8 do
		if gone() then return false end
		if near() then return true end
		local path = Feat.PFS:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, AgentCanClimb = true })
		local okPath = pcall(function() path:ComputeAsync(hrp.Position, e.part.Position) end)
		if okPath and path.Status == Enum.PathStatus.Success then
			local wps = path:GetWaypoints()
			local blockedConn
			local blocked = false
			blockedConn = path.Blocked:Connect(function() blocked = true end)
			for i = 2, #wps do
				if not alive() or gone() or near() or blocked or os.clock() > deadline then break end
				local wp = wps[i]
				if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
				hum:MoveTo(wp.Position)
				local last, lastT, stuck, t0 = hrp.Position, os.clock(), 0, os.clock()
				while alive() and not gone() and not near() and not blocked and os.clock() - t0 < 3 do
					local flat = Vector3.new(hrp.Position.X - wp.Position.X, 0, hrp.Position.Z - wp.Position.Z).Magnitude
					if flat < 3 then break end
					if os.clock() - lastT > 0.5 then
						if (hrp.Position - last).Magnitude < 0.6 then
							stuck = stuck + 1
							hum.Jump = true
							if stuck >= 3 then break end
						else
							stuck = 0
						end
						last, lastT = hrp.Position, os.clock()
					end
					task.wait(0.1)
				end
				if stuck >= 3 then
					fails = fails + 1
					break -- recompute a new path from here
				end
			end
			if blockedConn then blockedConn:Disconnect() end
		else
			-- no path: shove straight at the item, jumping, then try again
			fails = fails + 1
			local dir = e.part.Position - hrp.Position
			hum:MoveTo(e.part.Position)
			hum.Jump = true
			task.wait(0.8)
			if fails >= 4 and dir.Magnitude > 8 then
				-- last resort unstick: short hop toward the item
				hrp.CFrame = hrp.CFrame + dir.Unit * 6 + Vector3.new(0, 2, 0)
			end
		end
	end
	return alive() and not gone() and near()
end

task.spawn(function()
	while running do
		task.wait(0.5)
		if running and Config.WalkCollect and not Config.Fly then
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if hum and hrp and hum.Health > 0 then
				local names = parseList(Config.WalkNames ~= "" and Config.WalkNames or Config.AlertNames)
				local now = os.clock()
				local target
				for _, e in ipairs(lastArr) do
					if e.part.Parent and e.dist <= Config.WalkRange and now >= (e.walkSkip or 0)
						and nameHas(string.lower(e.name), names) then
						target = e
						break
					end
				end
				if target then
					Feat.walking = true
					local oldSpeed = hum.WalkSpeed
					hum.WalkSpeed = Config.WalkItemSpeed
					notify("Walking to item", target.name .. " (" .. math.floor(target.dist) .. " studs)", true)
					local arrived = Feat.walkTo(target)
					if arrived then
						local prompt = target.prompt
						local oldHold = prompt and prompt.HoldDuration
						if prompt then pcall(function() prompt.HoldDuration = 0 end) end
						for _ = 1, 5 do
							if not (target.part.Parent and target.root.Parent) then break end
							if prompt and prompt.Parent then firePrompt(prompt) end
							task.wait(0.15)
						end
						if prompt and oldHold then pcall(function() prompt.HoldDuration = oldHold end) end
					end
					pcall(function() hum:MoveTo(hrp.Position) end)
					pcall(function() hum.WalkSpeed = oldSpeed end)
					if not (target.part.Parent and target.root.Parent) then
						Feat.collected = Feat.collected + 1
						pickedCount = pickedCount + 1
						if UI.collectInfo then UI.collectInfo.Text = "Auto collected: " .. Feat.collected end
						notify("Collected", target.name, true)
					else
						target.walkSkip = os.clock() + 20 -- could not reach it, try again later
						notify("Could not reach", target.name .. " (retrying in 20s)", true)
					end
					Feat.walking = false
				end
			end
		end
	end
end)

-- hitbox expander (client side): enlarges other players' root part
Feat.hbOrig = {}
Feat.hitboxRestore = function()
	for plr, d in pairs(Feat.hbOrig) do
		local r = d.part
		if r and r.Parent then
			pcall(function()
				r.Size, r.Transparency, r.CanCollide = d.size, d.trans, d.coll
			end)
		end
		Feat.hbOrig[plr] = nil
	end
end
Feat.hitbox = function()
	if not Config.HitboxOn then
		if next(Feat.hbOrig) then Feat.hitboxRestore() end
		return
	end
	local s = Config.HitboxSize
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local c = plr.Character
			local r = c and c:FindFirstChild("HumanoidRootPart")
			if r then
				local d = Feat.hbOrig[plr]
				if d and d.part ~= r then d = nil end
				if not d then
					d = { part = r, size = r.Size, trans = r.Transparency, coll = r.CanCollide }
					Feat.hbOrig[plr] = d
				end
				r.Size = Vector3.new(s, s, s)
				r.Transparency = 0.8
				r.CanCollide = false
			end
		end
	end
end

---------------------------------------------------------------------
-- HvH: ORBIT (no shake) + SPIN
-- The position is applied before physics, after physics and right before rendering, velocities are zeroed,
-- the body is put in PlatformStand + no collision, and the camera watches the target.
---------------------------------------------------------------------
Feat.kills = 0
Feat.orbit = { angle = 0, target = nil, hum = nil, lastPick = 0, cf = nil, stand = false, lastClip = 0, lastAtk = 0, lastInfo = 0 }

-- finds the best target: Closest or Lowest HP, optional name filter / team check / max distance
Feat.pickOrbit = function(origin)
	local want = string.lower(Config.OrbitTarget or "")
	local lowHp = Config.OrbitTargetMode == "Lowest HP"
	local best, bestScore, bestHum
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local c = plr.Character
			local r = c and c:FindFirstChild("HumanoidRootPart")
			local h = c and c:FindFirstChildOfClass("Humanoid")
			if r and h and h.Health > 0 then
				local okName = want == "" or string.find(string.lower(plr.Name), want, 1, true) or string.find(string.lower(plr.DisplayName), want, 1, true)
				local okTeam = not (Config.OrbitTeamCheck and plr.Team ~= nil and plr.Team == player.Team) and not Feat.isSafe(plr)
				local d = (r.Position - origin).Magnitude
				if okName and okTeam and d <= Config.OrbitMaxDist then
					local score = lowHp and h.Health or d
					if not bestScore or score < bestScore then best, bestScore, bestHum = r, score, h end
				end
			end
		end
	end
	return best, bestHum
end

Feat.orbitInfo = function(text)
	if UI.orbitInfo then UI.orbitInfo.Text = text end
end

Feat.orbitStop = function()
	local o = Feat.orbit
	o.target, o.hum, o.cf = nil, nil, nil
	if o.hl then pcall(function() o.hl:Destroy() end) o.hl = nil end
	o.engaged = false
	if o.oldSpeed then
		local h0 = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h0 then pcall(function() h0.WalkSpeed = o.oldSpeed end) end
		o.oldSpeed = nil
	end
	if UI.targetHud then UI.targetHud(nil) end
	Feat.orbitInfo("Orbit off")
	if o.stand then
		o.stand = false
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			pcall(function()
				hum.PlatformStand = false
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end
	end
end

Feat.orbitApply = function()
	local o = Feat.orbit
	if not o.cf then return end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	hrp.CFrame = o.cf
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
end

Feat.orbitUpdate = function(dt)
	local o = Feat.orbit
	if not Config.OrbitOn or Feat.walking or Config.Fly then
		if o.cf or o.stand or o.target then Feat.orbitStop() end
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum and hum.Health > 0) then
		o.cf = nil
		return
	end
	local now = os.clock()

	if o.hum and o.hum.Parent and o.hum.Health <= 0 and o.lastDead ~= o.hum then
		o.lastDead = o.hum
		Feat.kills = Feat.kills + 1
		if Config.NotifyKill then notify("Target down", (o.target and o.target.Parent and o.target.Parent.Name or "player") .. (Config.OrbitWalk and " died - walking to the next target" or " died"), true) end
	end

	local prevT = o.target

	-- target selection: lock keeps one player until they die / leave
	local valid = o.target and o.target.Parent and o.hum and o.hum.Parent and o.hum.Health > 0
	if not valid or (not Config.OrbitLock and now - o.lastPick > 0.2) then
		o.lastPick = now
		local cand, candHum = Feat.pickOrbit(hrp.Position)
		if cand then
			if not valid then
				o.target, o.hum = cand, candHum
			elseif cand ~= o.target then
				if Config.OrbitTargetMode == "Lowest HP" or (cand.Position - hrp.Position).Magnitude < (o.target.Position - hrp.Position).Magnitude - 1.5 then
					o.target, o.hum = cand, candHum
				end
			end
		elseif not valid then
			o.target, o.hum = nil, nil
		end
	end
	if o.target ~= prevT then o.engaged = false end
	local t = o.target
	if not t then
		o.cf = nil
		if now - o.lastInfo > 0.3 then
			o.lastInfo = now
			Feat.orbitInfo("No target")
			if UI.targetHud then UI.targetHud(nil) end
		end
		return
	end
	-- approach: WALK to the target first; the orbit starts once we are within the engage distance (about 10 studs)
	local far = (t.Position - hrp.Position).Magnitude
	local engage = Config.OrbitEngage
	if o.engaged then
		if far > math.max(engage, Config.OrbitRadius) + 30 then o.engaged = false end
	elseif far <= engage then
		o.engaged = true
	end
	if not o.engaged then
		o.cf = nil
		if o.stand then
			o.stand = false
			pcall(function()
				hum.PlatformStand = false
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end)
		end
		if not Config.OrbitWalk and now - (o.lastTP or 0) > 5 then
			o.lastTP = now -- walking is off: try a teleport instead
			hrp.CFrame = CFrame.new(t.Position + Vector3.new(engage * 0.5, Config.OrbitHeight + 2, 0))
			return
		end
		if not Config.SpeedOn then
			if not o.oldSpeed then o.oldSpeed = hum.WalkSpeed end
			hum.WalkSpeed = Config.OrbitWalkSpeed
		end
		if now - (o.lastWalk or 0) > 0.2 then
			o.lastWalk = now
			hum:MoveTo(t.Position)
			if hrp.AssemblyLinearVelocity.Magnitude < 2 then hum.Jump = true end
		end
		if now - o.lastInfo > 0.3 then
			o.lastInfo = now
			local tn = t.Parent and t.Parent.Name or "?"
			Feat.orbitInfo("Walking to " .. tn .. "... " .. math.floor(far) .. " st")
			if UI.targetHud then UI.targetHud(tn, o.hum and o.hum.Health or 0, o.hum and o.hum.MaxHealth or 100, Feat.kills) end
		end
		return
	end
	if o.oldSpeed then
		pcall(function() hum.WalkSpeed = o.oldSpeed end)
		o.oldSpeed = nil
	end

	if not o.stand then
		o.stand = true
		hum.PlatformStand = true
	end
	if Config.TargetHL and t.Parent then
		if not o.hl then
			o.hl = Instance.new("Highlight")
			o.hl.FillTransparency = 0.6
			o.hl.OutlineColor = Config.AlertColor
			o.hl.FillColor = Config.AlertColor
			o.hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			o.hl.Parent = espFolder
		end
		if o.hl.Adornee ~= t.Parent then o.hl.Adornee = t.Parent end
	elseif o.hl then
		o.hl:Destroy()
		o.hl = nil
	end
	if now - o.lastClip > 0.25 then
		o.lastClip = now
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
		end
	end

	o.angle = (o.angle + math.rad(Config.OrbitSpeed) * dt) % (math.pi * 2)
	local tp = t.Position
	local R, H = Config.OrbitRadius, Config.OrbitHeight
	local mode = Config.OrbitMode
	local pos, up = nil, Vector3.yAxis
	if mode == "Behind" then
		local lv = t.CFrame.LookVector
		local flat = Vector3.new(lv.X, 0, lv.Z)
		flat = flat.Magnitude > 0.01 and flat.Unit or Vector3.new(0, 0, -1)
		pos = tp - flat * R + Vector3.new(0, H, 0)
	elseif mode == "Random" then
		local a = math.random() * math.pi * 2
		pos = tp + Vector3.new(math.cos(a) * R, H, math.sin(a) * R)
	elseif mode == "Vertical" then
		pos = tp + Vector3.new(math.cos(o.angle) * R, math.sin(o.angle) * R + H, 0)
		up = Vector3.zAxis
	else -- Circle
		pos = tp + Vector3.new(math.cos(o.angle) * R, H, math.sin(o.angle) * R)
	end
	if Config.OrbitFace then
		o.cf = CFrame.lookAt(pos, tp, up)
	else
		o.cf = CFrame.lookAt(pos, Vector3.new(tp.X, pos.Y, tp.Z))
	end
	Feat.orbitApply()

	-- auto attack with the equipped tool
	if Config.OrbitAttack and now - o.lastAtk >= 1 / math.max(Config.OrbitAttackCPS, 1) then
		o.lastAtk = now
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then pcall(function() tool:Activate() end) end
	end

	if now - o.lastInfo > 0.3 then
		o.lastInfo = now
		local tname = t.Parent and t.Parent.Name or "?"
		local hp = o.hum and math.floor(o.hum.Health) or 0
		local mhp = o.hum and math.floor(o.hum.MaxHealth) or 0
		Feat.orbitInfo(tname .. " | HP " .. hp .. "/" .. mhp .. " | " .. math.floor((tp - hrp.Position).Magnitude) .. " st")
		if UI.targetHud then UI.targetHud(tname, hp, mhp, Feat.kills) end
	end
end

table.insert(connections, RunService.Stepped:Connect(guard("orbit-apply", Feat.orbitApply)))
table.insert(connections, RunService.Heartbeat:Connect(guard("orbit", Feat.orbitUpdate)))
table.insert(connections, RunService.RenderStepped:Connect(guard("orbit-apply", Feat.orbitApply)))

-- teleport right behind the current / best target
Feat.tpBehind = function()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local t = Feat.orbit.target
	if not (t and t.Parent) then t = Feat.pickOrbit(hrp.Position) end
	if not t then return false end
	hrp.CFrame = t.CFrame * CFrame.new(0, 0, 4)
	return true
end

-- spin in place (anti-aim)
Feat.spinUpdate = function(dt)
	if not Config.SpinOn or Config.OrbitOn or Config.Fly or Feat.walking then return end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed) * dt, 0) end
end
table.insert(connections, RunService.Heartbeat:Connect(guard("spin", Feat.spinUpdate)))

-- camera: stable view while orbiting (watch the target) + spectate
Feat.findPlayer = function(name)
	name = string.lower(name or "")
	if name == "" then return nil end
	local best
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local n, dn = string.lower(plr.Name), string.lower(plr.DisplayName)
			if n == name or dn == name then return plr end
			if not best and (string.find(n, name, 1, true) or string.find(dn, name, 1, true)) then best = plr end
		end
	end
	return best
end

Feat.camera = function()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local want
	local o = Feat.orbit
	if Config.OrbitOn and Config.OrbitStableCam and o.target and o.target.Parent and o.cf then
		want = o.target.Parent:FindFirstChildOfClass("Humanoid")
	elseif Config.SpectateOn then
		local plr = Feat.findPlayer(Config.TPName)
		local c = plr and plr.Character
		want = c and c:FindFirstChildOfClass("Humanoid")
	end
	if want then
		Feat.camOwned = true
		if cam.CameraSubject ~= want then cam.CameraSubject = want end
	elseif Feat.camOwned then
		Feat.camOwned = false
		local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if h then cam.CameraSubject = h end
	end
end
table.insert(connections, RunService.RenderStepped:Connect(guard("camera", Feat.camera)))

-- teleport helpers
Feat.tpPlayer = function(name)
	local plr = Feat.findPlayer(name)
	local c = plr and plr.Character
	local r = c and c:FindFirstChild("HumanoidRootPart")
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if r and hrp then
		hrp.CFrame = r.CFrame * CFrame.new(0, 0, 3)
		notify("Teleport", "Teleported to " .. plr.DisplayName, true)
		return true
	end
	notify("Teleport", "Player not found", true)
	return false
end

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
	if gp or not Config.ClickTP then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
	local cam = Workspace.CurrentCamera
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (cam and hrp) then return end
	local m = UI.main
	if m and m.Visible then -- ignore taps that land on the window
		local ins = game:GetService("GuiService"):GetGuiInset()
		local x, y = input.Position.X + ins.X, input.Position.Y + ins.Y
		local p, s = m.AbsolutePosition, m.AbsoluteSize
		if x >= p.X and x <= p.X + s.X and y >= p.Y and y <= p.Y + s.Y then return end
	end
	local ray = cam:ScreenPointToRay(input.Position.X, input.Position.Y)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { player.Character }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local hit = Workspace:Raycast(ray.Origin, ray.Direction * 2000, params)
	if hit then hrp.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3.5, 0)) end
end))

-- auto clicker, auto rejoin, job id tools, status card
Feat.joinJob = function(id)
	id = string.gsub(tostring(id or ""), "%s", "")
	if id == "" then
		notify("Join Job ID", "Type a Job ID first", true)
		return
	end
	pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, id, player) end)
end

task.spawn(function()
	while running do
		if Config.AutoClick then
			local char = player.Character
			local tool = char and char:FindFirstChildOfClass("Tool")
			if tool then pcall(function() tool:Activate() end) end
			task.wait(1 / math.max(Config.ClickCPS, 1))
		else
			task.wait(0.25)
		end
	end
end)

task.spawn(function()
	local ok, overlay = pcall(function()
		return game:GetService("CoreGui"):WaitForChild("RobloxPromptGui", 10):WaitForChild("promptOverlay", 10)
	end)
	if ok and overlay then
		table.insert(connections, overlay.ChildAdded:Connect(function(c)
			if Config.AutoRejoin and c.Name == "ErrorPrompt" then
				task.wait(2)
				Feat.rejoin()
			end
		end))
	end
end)

task.spawn(function()
	local exec = "Executor"
	pcall(function()
		local n, v = identifyexecutor()
		exec = tostring(n) .. (v and (" " .. tostring(v)) or "")
	end)
	while running do
		if UI.srvStatus then
			local fps = UI.stats and UI.stats["FPS"] and UI.stats["FPS"].Text or "-"
			local png = UI.stats and UI.stats["Ping"] and UI.stats["Ping"].Text or "-"
			UI.srvStatus.Text = "Fps " .. fps .. " | Ping " .. png .. " | " .. exec
			UI.srvPlayers.Text = "Players " .. #Players:GetPlayers() .. "/" .. Players.MaxPlayers
			if UI.homeItems then UI.homeItems.Text = "Tracked " .. UI.stats["Items Tracked"].Text .. " | Alerts " .. UI.stats["Alert Items"].Text .. " | Picked " .. pickedCount end
			local t = math.floor(Workspace.DistributedGameTime)
			if UI.srvAge then UI.srvAge.Text = string.format("Server time: %dh %02dm %02ds", t // 3600, (t % 3600) // 60, t % 60) end
		end
		pcall(Feat.refreshPlayers)
		task.wait(1)
	end
end)

---------------------------------------------------------------------
-- COMBAT EXTRAS: aim assist, kill aura, auto face, movement extras, waypoints, player list
---------------------------------------------------------------------
Feat.nearestEnemy = function(maxD, teamCheck)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local best, bestD, bestHum
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and not (teamCheck and plr.Team ~= nil and plr.Team == player.Team) and not Feat.isSafe(plr) then
			local c = plr.Character
			local r = c and c:FindFirstChild("HumanoidRootPart")
			local h = c and c:FindFirstChildOfClass("Humanoid")
			if r and h and h.Health > 0 then
				local d = (r.Position - hrp.Position).Magnitude
				if d <= maxD and (not bestD or d < bestD) then best, bestD, bestHum = r, d, h end
			end
		end
	end
	return best, bestD, bestHum
end

-- aim assist: smoothly turns the camera towards the player closest to the screen centre
Feat.fovCircle = nil
Feat.aim = function()
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local vp = cam.ViewportSize
	local center = Vector2.new(vp.X / 2, vp.Y / 2)
	if Drawing then
		if not Feat.fovCircle then
			local ok, c = pcall(function() return Drawing.new("Circle") end)
			if ok and c then
				c.Thickness = 1.5
				c.NumSides = 48
				c.Filled = false
				c.Visible = false
				Feat.fovCircle = c
			end
		end
		local c = Feat.fovCircle
		if c then
			c.Visible = Config.AimOn and Config.ShowFOV
			c.Position = center
			c.Radius = Config.AimFOV
			c.Color = Config.ColorPlayer
		end
	end
	if not Config.AimOn or Config.OrbitOn then return end

	local params
	if Config.AimWallCheck then
		params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character }
	end
	local bestPart, bestD
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player and not (Config.AimTeamCheck and plr.Team ~= nil and plr.Team == player.Team) and not Feat.isSafe(plr) then
			local c = plr.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			local part = c and (c:FindFirstChild(Config.AimPart) or c:FindFirstChild("HumanoidRootPart"))
			if part and h and h.Health > 0 then
				local v, on = cam:WorldToViewportPoint(part.Position)
				if on and v.Z > 0 then
					local d = (Vector2.new(v.X, v.Y) - center).Magnitude
					if d <= Config.AimFOV and (not bestD or d < bestD) then
						local visible = true
						if params then
							local hit = Workspace:Raycast(cam.CFrame.Position, part.Position - cam.CFrame.Position, params)
							if hit and not hit.Instance:IsDescendantOf(c) then visible = false end
						end
						if visible then bestPart, bestD = part, d end
					end
				end
			end
		end
	end
	if bestPart then
		local goal = CFrame.lookAt(cam.CFrame.Position, bestPart.Position)
		cam.CFrame = cam.CFrame:Lerp(goal, math.clamp(Config.AimSmooth / 100, 0.02, 1))
	end
end
table.insert(connections, RunService.RenderStepped:Connect(guard("aim", Feat.aim)))

-- kill aura (activates the equipped tool when a player is in range) + auto face + CFrame speed
Feat.auraAcc = 0
Feat.combat = function(dt)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not (hrp and hum and hum.Health > 0) then return end
	local busy = Config.OrbitOn or Config.Fly or Config.SpinOn or Feat.walking

	if Config.AutoFace and not busy then
		local r = Feat.nearestEnemy(60, Config.OrbitTeamCheck)
		if r then
			local p = r.Position
			hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(p.X, hrp.Position.Y, p.Z))
		end
	end

	if Config.AuraOn then
		Feat.auraAcc = Feat.auraAcc + dt
		if Feat.auraAcc >= 1 / math.max(Config.AuraCPS, 1) then
			Feat.auraAcc = 0
			local r = Feat.nearestEnemy(Config.AuraRange, Config.OrbitTeamCheck)
			if r then
				local tool = char:FindFirstChildOfClass("Tool")
				if tool then pcall(function() tool:Activate() end) end
			end
		end
	end

	if Config.CFrameSpeed and not busy and hum.MoveDirection.Magnitude > 0.1 then
		hrp.CFrame = hrp.CFrame + hum.MoveDirection * (Config.CFrameSpeedVal * dt)
	end
end
table.insert(connections, RunService.Heartbeat:Connect(guard("combat", Feat.combat)))

-- low gravity (restored when switched off / unloaded)
Feat.gravity = function()
	if Config.LowGravity then
		if not Feat.orig.gravity then Feat.orig.gravity = Workspace.Gravity end
		Workspace.Gravity = Config.GravityVal
	elseif Feat.orig.gravity then
		Workspace.Gravity = Feat.orig.gravity
		Feat.orig.gravity = nil
	end
end

-- infinite zoom out + teleport to spawn
Feat.zoom = function()
	if Config.InfZoom then
		if not Feat.orig.zoom then Feat.orig.zoom = player.CameraMaxZoomDistance end
		player.CameraMaxZoomDistance = 100000
	elseif Feat.orig.zoom then
		player.CameraMaxZoomDistance = Feat.orig.zoom
		Feat.orig.zoom = nil
	end
end

Feat.tpSpawn = function()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local sp = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if not (hrp and sp) then return false end
	hrp.CFrame = sp.CFrame + Vector3.new(0, 5, 0)
	return true
end

-- waypoints (stored in the config as "x,y,z" so they are saved too)
Feat.saveWP = function(i)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local p = hrp.Position
	Config["WP" .. i] = string.format("%.1f,%.1f,%.1f", p.X, p.Y, p.Z)
	return true
end

Feat.goWP = function(i)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local x, y, z = string.match(Config["WP" .. i] or "", "^(-?[%d%.]+),(-?[%d%.]+),(-?[%d%.]+)$")
	if not (hrp and x) then return false end
	hrp.CFrame = CFrame.new(tonumber(x), tonumber(y) + 3, tonumber(z))
	return true
end

-- player list page (nearest first)
Feat.refreshPlayers = function()
	if not UI.plRows then return end
	local origin = currentOrigin()
	local arr = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= player then
			local r = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			arr[#arr + 1] = { plr = plr, dist = r and (r.Position - origin).Magnitude or math.huge }
		end
	end
	table.sort(arr, function(x, y) return x.dist < y.dist end)
	for i, r in ipairs(UI.plRows) do
		local e = arr[i]
		UI.plEntries[i] = e
		if e then
			r.frame:SetAttribute("hidden", false)
			r.frame.Visible = true
			r.name.Text = e.plr.DisplayName .. " (@" .. e.plr.Name .. ")"
			r.dist.Text = e.dist < math.huge and (math.floor(e.dist) .. " st") or "-"
		else
			r.frame:SetAttribute("hidden", true)
			r.frame.Visible = false
		end
	end
	if UI.plCount then UI.plCount.Text = "Players: " .. #arr .. " (showing " .. math.min(#arr, #UI.plRows) .. ")" end
end

-- TOOLS: waypoints, death return, join/leave alerts, FPS boost, menu key
Feat.wp = {}
Feat.wpInfo = function()
	if not UI.wpInfo then return end
	local cf = Feat.wp[tonumber(Config.WPSlot) or 1]
	if cf then
		local p = cf.Position
		UI.wpInfo.Text = string.format("Slot %s: %d, %d, %d", Config.WPSlot, p.X, p.Y, p.Z)
	else
		UI.wpInfo.Text = "Slot " .. tostring(Config.WPSlot) .. ": empty"
	end
end
Feat.wpSave = function()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	Feat.wp[tonumber(Config.WPSlot) or 1] = hrp.CFrame
	Feat.wpInfo()
	notify("Waypoint", "Saved to slot " .. tostring(Config.WPSlot), true)
	return true
end
Feat.wpGo = function()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local cf = Feat.wp[tonumber(Config.WPSlot) or 1]
	if hrp and cf then
		hrp.CFrame = cf * CFrame.new(0, 3, 0)
		return true
	end
	return false
end

-- death return: remember the last safe spot, go back there after respawning
Feat.lastAlive = nil
task.spawn(function()
	while running do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 and hrp.Position.Y > (Config.VoidY or -500) then Feat.lastAlive = hrp.CFrame end
		task.wait(0.25)
	end
end)
table.insert(connections, player.CharacterAdded:Connect(function(char)
	if not Config.DeathReturn or not Feat.lastAlive then return end
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end
	task.wait(0.6)
	if running and Config.DeathReturn and hrp.Parent and Feat.lastAlive then
		hrp.CFrame = Feat.lastAlive
		notify("Death Return", "Teleported back to where you died", true)
	end
end))

-- join / leave alerts
table.insert(connections, Players.PlayerAdded:Connect(function(plr)
	if Config.JoinAlerts then notify("Player joined", plr.DisplayName .. " (@" .. plr.Name .. ")", true) end
end))
table.insert(connections, Players.PlayerRemoving:Connect(function(plr)
	if Config.JoinAlerts and plr ~= player then notify("Player left", plr.DisplayName .. " (@" .. plr.Name .. ")", true) end
end))

-- FPS boost: no shadows, lowest quality, effects/particles off (everything is restored when switched off)
Feat.fpsOff = {}
Feat.fpsHeavy = function(o)
	return o:IsA("ParticleEmitter") or o:IsA("Trail") or o:IsA("Smoke") or o:IsA("Fire") or o:IsA("Sparkles") or o:IsA("Beam")
end
Feat.fpsRestore = function()
	for _, o in ipairs(Feat.fpsOff) do pcall(function() o.Enabled = true end) end
	Feat.fpsOff = {}
	if Feat.fpsPrev then
		pcall(function() Feat.Lighting.GlobalShadows = Feat.fpsPrev.shadows end)
		pcall(function() if Feat.fpsPrev.quality then settings().Rendering.QualityLevel = Feat.fpsPrev.quality end end)
		Feat.fpsPrev = nil
	end
end
Feat.fps = function(on)
	if not on then
		Feat.fpsRestore()
		return
	end
	task.spawn(function()
		local L = Feat.Lighting
		if not Feat.fpsPrev then
			Feat.fpsPrev = { shadows = L.GlobalShadows }
			pcall(function() Feat.fpsPrev.quality = settings().Rendering.QualityLevel end)
		end
		L.GlobalShadows = false
		pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
		for _, o in ipairs(L:GetChildren()) do
			if o:IsA("PostEffect") and o.Enabled then
				o.Enabled = false
				Feat.fpsOff[#Feat.fpsOff + 1] = o
			end
		end
		local list = Workspace:GetDescendants()
		for i, o in ipairs(list) do
			if not (running and Config.FPSBoost) then return end
			if Feat.fpsHeavy(o) and o.Enabled then
				o.Enabled = false
				Feat.fpsOff[#Feat.fpsOff + 1] = o
			end
			if i % 2000 == 0 then task.wait() end
		end
		notify("FPS Boost", "Effects and shadows disabled", true)
	end)
end
table.insert(connections, Workspace.DescendantAdded:Connect(function(o)
	if Config.FPSBoost and Feat.fpsHeavy(o) then
		task.defer(function()
			pcall(function()
				o.Enabled = false
				Feat.fpsOff[#Feat.fpsOff + 1] = o
			end)
		end)
	end
end))
if Config.FPSBoost then Feat.fps(true) end

-- menu key: show / hide the window
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
	if gp or Config.MenuKey == "None" or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	if input.KeyCode.Name == Config.MenuKey and UI.showMain and UI.main then UI.showMain(not UI.main.Visible) end
end))

-- BYPASS ANTICHEAT (just a name): teleport -> if the teleport does not stick, reset the character with a
-- chain of reset methods that does NOT use Health = 0 / BreakJoints (those did not work in JJS) -> try again
Feat.bypass = { id = 0, status = "Idle" }
Feat.bpStatus = function(t)
	Feat.bypass.status = t
	if UI.bypassInfo then UI.bypassInfo.Text = t end
end

-- waits for a fresh, living character (different from oldChar)
Feat.waitRespawn = function(oldChar, timeout)
	local t0 = os.clock()
	while running and os.clock() - t0 < timeout do
		local c = player.Character
		if c and c ~= oldChar then
			local h = c:FindFirstChild("HumanoidRootPart")
			local hum = c:FindFirstChildOfClass("Humanoid")
			if h and hum and hum.Health > 0 then return c end
		end
		task.wait(0.1)
	end
	return nil
end

Feat.resetMethods = {
	{ name = "void drop", fn = function(char, hrp, hum)
		-- the server kills anything that falls below FallenPartsDestroyHeight, and our position replicates
		local limit = Workspace.FallenPartsDestroyHeight
		if limit < -100000 then limit = -100000 end
		local y = limit - 80
		local t0 = os.clock()
		while os.clock() - t0 < 3 and player.Character == char and hum.Health > 0 do
			hrp.CFrame = CFrame.new(hrp.Position.X, y, hrp.Position.Z)
			hrp.AssemblyLinearVelocity = Vector3.zero
			task.wait(0.1)
		end
	end },
	{ name = "dead state", fn = function(char, hrp, hum)
		for _ = 1, 3 do
			pcall(function() hum:ChangeState(Enum.HumanoidStateType.Dead) end)
			task.wait(0.3)
		end
	end },
	{ name = "menu reset", fn = function(char, hrp, hum)
		-- Esc -> R -> Enter is Roblox's own reset shortcut
		local vim = game:GetService("VirtualInputManager")
		for _, k in ipairs({ Enum.KeyCode.Escape, Enum.KeyCode.R, Enum.KeyCode.Return }) do
			pcall(function()
				vim:SendKeyEvent(true, k, false, game)
				task.wait(0.08)
				vim:SendKeyEvent(false, k, false, game)
			end)
			task.wait(0.4)
		end
		if game:GetService("GuiService").MenuIsOpen then -- still open: close it again
			pcall(function()
				vim:SendKeyEvent(true, Enum.KeyCode.Escape, false, game)
				task.wait(0.08)
				vim:SendKeyEvent(false, Enum.KeyCode.Escape, false, game)
			end)
		end
	end },
}

-- tries every reset method (twice around) until a new living character appears; returns it or nil
Feat.strongReset = function(aliveFn)
	aliveFn = aliveFn or function() return running end
	for _ = 1, 2 do
		for _, m in ipairs(Feat.resetMethods) do
			if not aliveFn() then return nil end
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if char and hrp and hum and hum.Health > 0 then
				Feat.bpStatus("Resetting (" .. m.name .. ")")
				pcall(m.fn, char, hrp, hum)
			end
			local nc = Feat.waitRespawn(char, 4)
			if nc then
				notify("Reset", "Character reset with: " .. m.name, true)
				return nc
			end
		end
	end
	return nil
end

-- where to teleport
Feat.bpSpot = function(sky)
	local mode = Config.BypassSpot
	if mode == "Random Player" then
		local list = {}
		for _, plr in ipairs(Players:GetPlayers()) do
			local r = plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if r then list[#list + 1] = r end
		end
		if #list > 0 then return list[math.random(#list)].Position + Vector3.new(0, 5, 0) end
	elseif mode == "Spawn" then
		local sp = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
		if sp then return sp.Position + Vector3.new(0, 6, 0) end
	elseif mode == "Waypoint" then
		local cf = Feat.wp and Feat.wp[tonumber(Config.WPSlot) or 1]
		if cf then return cf.Position + Vector3.new(0, 3, 0) end
	end
	return sky -- Sky Platform (also the fallback)
end

-- teleports to `dest` and watches for ~2s; true only if we stayed there (no rubber-band)
Feat.bpTry = function(dest, alive)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	hrp.CFrame = CFrame.new(dest)
	hrp.AssemblyLinearVelocity = Vector3.zero
	for _ = 1, 6 do
		task.wait(0.35)
		if not alive() then return false end
		local h = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if player.Character ~= char or not h then return false end
		if (h.Position - dest).Magnitude > 20 then return false end -- pulled back = stuck
	end
	return true
end

Feat.bypassStop = function()
	Feat.bypass.id = Feat.bypass.id + 1
	Feat.bpStatus("Idle")
end

Feat.bypassRun = function()
	Feat.bypass.id = Feat.bypass.id + 1
	local id = Feat.bypass.id
	local function alive() return running and Config.BypassEnabled and Feat.bypass.id == id end
	task.spawn(function()
		local hrp0 = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		local sky = (hrp0 and hrp0.Position or Vector3.zero) + Vector3.new(0, 350, 0)
		if Feat.bypass.platform then pcall(function() Feat.bypass.platform:Destroy() end) end
		local plat = Instance.new("Part")
		plat.Name = "CodeBotPlatform"
		plat.Size = Vector3.new(80, 2, 80)
		plat.Anchored = true
		plat.Transparency = 0.6
		plat.Material = Enum.Material.Neon
		plat.Color = Color3.fromRGB(0, 226, 212)
		plat.CFrame = CFrame.new(sky - Vector3.new(0, 2, 0))
		plat.Parent = Workspace
		Feat.bypass.platform = plat

		local maxA = Config.BypassMax
		local attempts, ok = 0, false
		while alive() and attempts < maxA do
			attempts = attempts + 1
			Feat.bpStatus("Attempt " .. attempts .. "/" .. maxA .. ": teleporting")
			local dest = Feat.bpSpot(sky)
			if dest and Feat.bpTry(dest, alive) then
				ok = true
				break
			end
			if not alive() then break end
			Feat.bpStatus("Attempt " .. attempts .. ": stuck, resetting")
			local nc = Feat.strongReset(alive)
			if nc then
				task.wait(1.2) -- let the new character settle
			else
				Feat.bpStatus("Reset did not work, retrying")
				task.wait(1)
			end
		end
		if Feat.bypass.id ~= id then return end
		if ok then
			Feat.bpStatus("Teleport worked (attempt " .. attempts .. ")")
			notify("Bypass Anticheat", "Teleport worked on attempt " .. attempts, true)
		elseif alive() then
			Feat.bpStatus("Gave up after " .. attempts .. " attempts")
			notify("Bypass Anticheat", "Gave up after " .. attempts .. " attempts", true)
		end
		Config.BypassEnabled = false
		if UI.sync then UI.sync() end
	end)
end

-- UPGRADES: whitelist, next target, session stats, crosshair, time of day
Feat.friends = {}
local function cacheFriend(plr)
	task.spawn(function()
		local ok, res = pcall(function() return player:IsFriendsWith(plr.UserId) end)
		Feat.friends[plr] = ok and res or false
	end)
end
for _, plr in ipairs(Players:GetPlayers()) do if plr ~= player then cacheFriend(plr) end end
table.insert(connections, Players.PlayerAdded:Connect(cacheFriend))

-- true when HvH features (orbit / aim / aura) must leave this player alone
Feat.isSafe = function(plr)
	if Config.WhitelistFriends and Feat.friends[plr] then return true end
	local list = Config.Whitelist
	if list and list ~= "" then
		local n, dn = string.lower(plr.Name), string.lower(plr.DisplayName)
		for w in string.gmatch(string.lower(list), "[^,]+") do
			w = string.match(w, "^%s*(.-)%s*$")
			if w ~= "" and (n == w or dn == w or string.find(n, w, 1, true)) then return true end
		end
	end
	return false
end

-- cycle the orbit target: closest -> next closest -> ... (writes the name into "Target Name")
Feat.nextTarget = function()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil end
	local list = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local r = plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		local h = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if r and h and h.Health > 0 and not Feat.isSafe(plr) then
			list[#list + 1] = { plr = plr, d = (r.Position - hrp.Position).Magnitude }
		end
	end
	if #list == 0 then return nil end
	table.sort(list, function(a, b) return a.d < b.d end)
	local cur = string.lower(Config.OrbitTarget or "")
	local idx = 0
	for i, e in ipairs(list) do
		if cur ~= "" and string.lower(e.plr.Name) == cur then idx = i end
	end
	local nxt = list[idx % #list + 1].plr
	Config.OrbitTarget = nxt.Name
	if UI.sync then UI.sync() end
	notify("Target", "Now targeting " .. nxt.DisplayName, true)
	return nxt
end

-- session stats
Feat.deaths = 0
Feat.sessStart = os.clock()
local function watchDeath(char)
	local hum = char:WaitForChild("Humanoid", 10)
	if hum then hum.Died:Connect(function() Feat.deaths = Feat.deaths + 1 end) end
end
if player.Character then task.spawn(watchDeath, player.Character) end
table.insert(connections, player.CharacterAdded:Connect(watchDeath))
task.spawn(function()
	while running do
		if UI.sessInfo then
			local t = math.floor(os.clock() - Feat.sessStart)
			UI.sessInfo.Text = string.format("Kills %d | Deaths %d | %d:%02d:%02d", Feat.kills or 0, Feat.deaths, t // 3600, (t % 3600) // 60, t % 60)
		end
		task.wait(1)
	end
end)

-- crosshair (Drawing)
Feat.cross = {}
if Drawing then
	for i = 1, 5 do
		local ok, ln = pcall(function() return Drawing.new(i < 5 and "Line" or "Circle") end)
		if ok and ln then
			ln.Visible = false
			if i < 5 then ln.Thickness = 2 else ln.Radius = 2 ln.Filled = true end
			Feat.cross[i] = ln
		end
	end
end
table.insert(connections, RunService.RenderStepped:Connect(function()
	if #Feat.cross == 0 then return end
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local on = Config.Crosshair
	local c = cam.ViewportSize / 2
	local g, s = Config.CrossGap, Config.CrossSize
	local col = Config.ColorCross
	local dirs = { Vector2.new(1, 0), Vector2.new(-1, 0), Vector2.new(0, 1), Vector2.new(0, -1) }
	for i = 1, 4 do
		local ln = Feat.cross[i]
		if ln then
			ln.Visible = on
			if on then
				ln.From = c + dirs[i] * g
				ln.To = c + dirs[i] * (g + s)
				ln.Color = col
			end
		end
	end
	local dot = Feat.cross[5]
	if dot then
		dot.Visible = on
		if on then
			dot.Position = c
			dot.Color = col
		end
	end
end))

-- time of day
task.spawn(function()
	local orig
	while running do
		local L = Feat.Lighting
		if Config.TimeOn then
			if not orig then orig = L.ClockTime end
			L.ClockTime = Config.TimeVal
		elseif orig then
			L.ClockTime = orig
			orig = nil
		end
		task.wait(0.1)
	end
end)

-- undo everything when the script is unloaded
Feat.cleanup = function()
	pcall(Feat.fpsRestore)
	for _, ln in pairs(Feat.cross) do pcall(function() ln:Remove() end) end
	Config.BypassEnabled = false
	Feat.bypass.id = Feat.bypass.id + 1
	if Feat.bypass.platform then pcall(function() Feat.bypass.platform:Destroy() end) end
	Feat.stopFly()
	Config.OrbitOn, Config.SpectateOn, Config.SpinOn = false, false, false
	pcall(Feat.orbitStop)
	pcall(Feat.camera)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and Feat.orig.speed then pcall(function() hum.WalkSpeed = Feat.orig.speed end) end
	if hum and Feat.orig.jump then
		pcall(function()
			hum.UseJumpPower = Feat.orig.jump[1]
			hum.JumpPower = Feat.orig.jump[2]
		end)
	end
	if Feat.orig.light then
		for k, v in pairs(Feat.orig.light) do pcall(function() Feat.Lighting[k] = v end) end
	end
	local cam = Workspace.CurrentCamera
	if cam and Feat.orig.fov then pcall(function() cam.FieldOfView = Feat.orig.fov end) end
	Feat.restorePrompts()
	Config.HitboxOn = false
	pcall(Feat.hitboxRestore)
	Config.LowGravity, Config.AimOn, Config.AuraOn, Config.InfZoom = false, false, false, false
	pcall(Feat.gravity)
	pcall(Feat.zoom)
	if Feat.fovCircle then pcall(function() Feat.fovCircle:Remove() end) Feat.fovCircle = nil end
	for plr in pairs(Feat.pl) do Feat.dropPlayer(plr) end
end

---------------------------------------------------------------------
-- CLOSE / CLEANUP
---------------------------------------------------------------------
local function cleanup()
	if not running then return end
	running = false
	-- risky toggles are saved as off
	Config.OrbitOn, Config.SpinOn, Config.OrbitAttack = false, false, false
	if Config.AutoSave then saveConfig() end
	if Feat.cleanup then pcall(Feat.cleanup) end
	for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
	for root in pairs(tracked) do removeEntry(root, true) end
	for _, ar in ipairs(ARROWS) do
		pcall(function() ar.tri:Remove() end)
		pcall(function() ar.txt:Remove() end)
	end
	pcall(function() espFolder:Destroy() end)
	pcall(function() screenGui:Destroy() end)
	pcall(function() UI.clickSnd:Destroy() end)
end

Actions.unload = cleanup
getgenv().ItemESP_Cleanup = cleanup
if UI.closeBtn then UI.closeBtn.MouseButton1Click:Connect(cleanup) end

print("CodeBot V1.1: Item ESP loaded (alerts for: " .. Config.AlertNames .. ")")
notify("Item ESP loaded", "Alerts for: " .. Config.AlertNames, true)
