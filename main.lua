-- CodeBot V1 | Roblox Luau (Delta compatible)
-- JJS Item ESP  |  Atom-style GUI  |  Roblox notifications
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

	-- notifications (Roblox's own notification popup)
	StatusNotify = true, NotifyDuration = 6,

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

local function saveConfig()
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
	local ok = pcall(function() writefile(FILE, HttpService:JSONEncode(data)) end)
	return ok
end

local function loadConfig()
	if not (readfile and isfile) then return false end
	local ok, raw = pcall(function()
		if isfile(FILE) then return readfile(FILE) end
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
Config.Fly, Config.Noclip, Config.AutoCollect, Config.WalkCollect = false, false, false, false

local connections = {}
local running = true
local UI = {}      -- filled by the GUI
local Actions = {} -- filled by the ESP logic
local Feat = {}    -- extra features (player ESP, movement, utility, auto collect)

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

-- Roblox's own notification popup (bottom-right). `isStatus` = non-alert message, can be switched off in Settings.
local function notify(title, text, isStatus)
	if isStatus and not Config.StatusNotify then return end
	task.spawn(function()
		for _ = 1, 8 do -- the core script may not be ready yet right after execution
			local ok = pcall(function()
				StarterGui:SetCore("SendNotification", {
					Title = tostring(title),
					Text = tostring(text or ""),
					Duration = Config.NotifyDuration,
				})
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
	local DESIGN_W, DESIGN_H = 1816, 950
	local SIDE_W, HEAD_H, PROFILE_H = 405, 125, 120

	local F = {
		Reg = Enum.Font.Gotham, Med = Enum.Font.GothamMedium, Semi = Enum.Font.GothamSemibold,
		Bold = Enum.Font.GothamBold, Black = Enum.Font.GothamBlack,
	}
	local C = {
		Window = Color3.fromRGB(13, 14, 17), Side = Color3.fromRGB(16, 17, 20), Panel = Color3.fromRGB(21, 22, 26),
		Tile = Color3.fromRGB(15, 16, 19), Input = Color3.fromRGB(11, 12, 15), Line = Color3.fromRGB(40, 42, 50),
		Bar = Color3.fromRGB(70, 73, 90), BarLight = Color3.fromRGB(150, 153, 168), White = Color3.fromRGB(240, 240, 244),
		SubText = Color3.fromRGB(135, 138, 152), ToggleOff = Color3.fromRGB(42, 44, 56), Knob = Color3.fromRGB(14, 14, 18),
		Selected = Color3.fromRGB(35, 36, 43), IconBox = Color3.fromRGB(28, 29, 35), Check = Color3.fromRGB(228, 229, 235),
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

	screenGui = create("ScreenGui", { Name = "ItemESP_Gui", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, guiParent)

	local main = create("Frame", {
		Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(DESIGN_W, DESIGN_H), BackgroundColor3 = C.Window, BorderSizePixel = 0, ClipsDescendants = true,
	}, screenGui)
	corner(main, 30)
	stroke(main, Color3.fromRGB(46, 48, 58), 2)

	local uiScale = create("UIScale", { Scale = 1 }, main)
	local function updateScale()
		local s = screenGui.AbsoluteSize
		if s.X > 0 and s.Y > 0 then uiScale.Scale = math.min(s.X * 0.78 / DESIGN_W, s.Y * 0.88 / DESIGN_H) end
	end
	updateScale()
	table.insert(connections, screenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale))

	-- generic drag helper: moves `target`; scaled = divide by the window UIScale
	local function makeDraggable(handle, target, scaled)
		local dragging, dragStart, startPos = false, nil, nil
		handle.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging, dragStart, startPos = true, input.Position, target.Position
			end
		end)
		table.insert(connections, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				if scaled then delta = delta / uiScale.Scale end
				target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
			end
		end))
		table.insert(connections, UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
		end))
	end

	-- sidebar ------------------------------------------------------
	local sidebar = create("Frame", { Size = UDim2.new(0, SIDE_W, 1, 0), BackgroundColor3 = C.Side, BorderSizePixel = 0 }, main)
	create("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = C.Line, BorderSizePixel = 0, ZIndex = 2 }, sidebar)

	local logoArea = create("Frame", { Size = UDim2.new(1, 0, 0, HEAD_H), BackgroundTransparency = 1, Active = true }, sidebar)
	makeDraggable(logoArea, main, true)
	create("TextLabel", {
		BackgroundTransparency = 1, RichText = true, Text = 'ITEM ESP <font color="#7A7D8A" size="30">HUB</font>',
		TextSize = 38, Font = F.Black, TextColor3 = C.White, TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 40, 0, 62), Size = UDim2.new(1, -60, 0, 60),
	}, logoArea)

	local sideScroll = create("ScrollingFrame", {
		Position = UDim2.new(0, 0, 0, HEAD_H), Size = UDim2.new(1, 0, 1, -(HEAD_H + PROFILE_H)), BackgroundTransparency = 1,
		BorderSizePixel = 0, ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
	}, sidebar)
	create("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 18), PaddingBottom = UDim.new(0, 12) }, sideScroll)
	create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, sideScroll)

	-- "Hide Username" support
	local usernameLabels = {}
	function UI.applyUsername()
		for _, h in ipairs(usernameLabels) do
			h.label.Text = Config.HideUsername and h.hidden or h.real
		end
	end

	local profileBar = create("Frame", { Size = UDim2.new(1, -1, 0, PROFILE_H), Position = UDim2.new(0, 0, 1, -PROFILE_H), BackgroundColor3 = C.Side, BorderSizePixel = 0 }, sidebar)
	create("Frame", { Size = UDim2.new(1, -40, 0, 1), Position = UDim2.new(0, 20, 0, 0), BackgroundColor3 = C.Line, BorderSizePixel = 0 }, profileBar)
	local pAvatar = create("ImageLabel", { Size = UDim2.fromOffset(70, 70), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 28, 0.5, 0), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Image = "" }, profileBar)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, pAvatar)
	stroke(pAvatar, Color3.fromRGB(200, 202, 212), 2)
	loadAvatar(pAvatar)
	local pName = txt(profileBar, player.Name, 24, C.White, F.Bold)
	pName.Position = UDim2.new(0, 114, 0.5, -16)
	pName.Size = UDim2.new(1, -130, 0, 32)
	table.insert(usernameLabels, { label = pName, real = player.Name, hidden = "Hidden" })
	local pGame = txt(profileBar, "Jujutsu Shenanigans", 20, C.SubText, F.Reg)
	pGame.Position = UDim2.new(0, 114, 0.5, 18)
	pGame.Size = UDim2.new(1, -130, 0, 28)

	-- content + header ---------------------------------------------
	local CONTENT_W = DESIGN_W - SIDE_W
	local content = create("Frame", { Position = UDim2.new(0, SIDE_W, 0, 0), Size = UDim2.new(1, -SIDE_W, 1, 0), BackgroundTransparency = 1 }, main)
	local header = create("Frame", { Size = UDim2.new(1, 0, 0, HEAD_H), BackgroundTransparency = 1, Active = true }, content)
	makeDraggable(header, main, true)

	local headIcon = create("TextLabel", {
		Size = UDim2.fromOffset(64, 64), Position = UDim2.new(0, 26, 0, 30), BackgroundColor3 = C.IconBox, BorderSizePixel = 0,
		Text = "◎", TextSize = 30, Font = F.Med, TextColor3 = C.White,
	}, header)
	corner(headIcon, 16)
	local crumb = create("TextLabel", {
		BackgroundTransparency = 1, RichText = true, Text = "", TextSize = 28, Font = F.Med, TextColor3 = C.White,
		TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 112, 0, 62), Size = UDim2.new(0, 560, 0, 44),
	}, header)

	local minBtn = create("TextButton", { Size = UDim2.fromOffset(62, 62), Position = UDim2.new(0, CONTENT_W - 24 - 62 - 10 - 62, 0, 32), BackgroundTransparency = 1, Text = "" }, header)
	create("Frame", { Size = UDim2.new(0, 24, 0, 3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = C.BarLight, BorderSizePixel = 0 }, minBtn)
	local closeBtn = create("TextButton", { Size = UDim2.fromOffset(62, 62), Position = UDim2.new(0, CONTENT_W - 24 - 62, 0, 32), BackgroundTransparency = 1, Text = "" }, header)
	for _, rot in ipairs({ 45, -45 }) do
		create("Frame", { Size = UDim2.new(0, 30, 0, 3), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Rotation = rot, BackgroundColor3 = C.White, BorderSizePixel = 0 }, closeBtn)
	end
	UI.closeBtn = closeBtn

	local pageHolder = create("Frame", { Position = UDim2.new(0, 0, 0, HEAD_H), Size = UDim2.new(1, 0, 1, -HEAD_H), BackgroundTransparency = 1 }, content)

	-- pages / sections / rows -----------------------------------------
	local pages = {}
	local function newPage(name)
		local sf = create("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.Bar,
			AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Visible = false,
		}, pageHolder)
		local function column(x, w)
			local col = create("Frame", { Size = UDim2.new(0, w, 0, 0), Position = UDim2.new(0, x, 0, 6), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y }, sf)
			create("UIListLayout", { Padding = UDim.new(0, 18), SortOrder = Enum.SortOrder.LayoutOrder }, col)
			return col
		end
		pages[name] = { frame = sf, left = column(24, 662), right = column(712, 676) }
		return pages[name]
	end

	local function section(parent, title, order, icon)
		local s = create("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundColor3 = C.Panel, BorderSizePixel = 0, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order or 1 }, parent)
		corner(s, 24)
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, s)
		local obj = { frame = s, n = 0, collapsed = false, rows = {}, dividers = {} }
		local hdr = create("TextButton", { Size = UDim2.new(1, 0, 0, 98), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 0 }, s)
		local ib = create("TextLabel", { Size = UDim2.fromOffset(58, 58), Position = UDim2.new(0, 24, 0.5, -29), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = icon or "◎", TextSize = 28, Font = F.Med, TextColor3 = C.White }, hdr)
		corner(ib, 14)
		local t = txt(hdr, title, 27, C.White, F.Bold)
		t.Position = UDim2.new(0, 100, 0.5, 0)
		t.Size = UDim2.new(1, -200, 0, 40)
		local chev = txt(hdr, "v", 18, C.BarLight, F.Bold, Enum.TextXAlignment.Center)
		chev.AnchorPoint = Vector2.new(0.5, 0.5)
		chev.Size = UDim2.new(0, 30, 0, 30)
		chev.Position = UDim2.new(1, -44, 0.5, 0)
		create("Frame", { Size = UDim2.new(1, -48, 0, 2), Position = UDim2.new(0, 24, 1, -2), BackgroundColor3 = C.Line, BorderSizePixel = 0 }, hdr)
		hdr.MouseButton1Click:Connect(function()
			obj.collapsed = not obj.collapsed
			chev.Text = obj.collapsed and ">" or "v"
			for _, r in ipairs(obj.rows) do r.Visible = (not obj.collapsed) and not r:GetAttribute("hidden") end
		end)
		return obj
	end

	local function row(sec, height)
		local r = create("Frame", { Size = UDim2.new(1, 0, 0, height), BackgroundTransparency = 1, LayoutOrder = sec.n + 1 }, sec.frame)
		local div = create("Frame", { Size = UDim2.new(1, -62, 0, 1), Position = UDim2.new(0, 31, 1, -1), BackgroundColor3 = C.Line, BorderSizePixel = 0 }, r)
		sec.n = sec.n + 1
		table.insert(sec.rows, r)
		table.insert(sec.dividers, div)
		return r
	end

	local function finish(sec)
		local last = sec.dividers[#sec.dividers]
		if last then last.Visible = false end
		create("Frame", { Size = UDim2.new(1, 0, 0, 14), BackgroundTransparency = 1, LayoutOrder = 9999 }, sec.frame)
	end

	local function rowLabel(r, name, cy)
		local l = txt(r, name, 23, C.White, F.Semi)
		l.Position = UDim2.new(0, 31, 0, cy)
		l.Size = UDim2.new(1, -170, 0, 33)
		return l
	end

	-- controls (all bound to a Config key, so Load/Reset can refresh them) ------
	local syncers = {}
	function UI.sync()
		for _, f in ipairs(syncers) do pcall(f) end
		UI.applyUsername()
	end

	local function addCheckbox(sec, name, key, onChange)
		local r = row(sec, 82)
		local box = create("TextButton", {
			Size = UDim2.fromOffset(44, 44), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 31, 0, 41),
			BackgroundColor3 = Config[key] and C.Check or C.IconBox, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
		}, r)
		corner(box, 12)
		local mark = create("Frame", { Size = UDim2.fromOffset(24, 24), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundTransparency = 1, Visible = Config[key] }, box)
		local a = create("Frame", { Size = UDim2.fromOffset(10, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(6, 15), Rotation = 45, BackgroundColor3 = C.Knob, BorderSizePixel = 0 }, mark)
		corner(a, 2)
		local b = create("Frame", { Size = UDim2.fromOffset(18, 4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(14, 12), Rotation = -45, BackgroundColor3 = C.Knob, BorderSizePixel = 0 }, mark)
		corner(b, 2)
		local l = txt(r, name, 23, C.White, F.Semi)
		l.Position = UDim2.new(0, 98, 0, 41)
		l.Size = UDim2.new(1, -130, 0, 33)
		local function apply(v)
			mark.Visible = v
			TweenService:Create(box, TweenInfo.new(0.12), { BackgroundColor3 = v and C.Check or C.IconBox }):Play()
		end
		table.insert(syncers, function() apply(Config[key]) end)
		box.MouseButton1Click:Connect(function()
			local v = not Config[key]
			Config[key] = v
			apply(v)
			if onChange then onChange(v) end
		end)
		return function(v) -- setter (used by the hotkey)
			Config[key] = v
			apply(v)
			if onChange then onChange(v) end
		end
	end

	local function addSlider(sec, name, key, minV, maxV, suffix, onChange, zeroText)
		local r = row(sec, 124)
		rowLabel(r, name, 34)
		local valLabel = txt(r, "", 20, C.White, F.Bold, Enum.TextXAlignment.Right)
		valLabel.AnchorPoint = Vector2.new(1, 0.5)
		valLabel.Size = UDim2.new(0, 160, 0, 26)
		valLabel.Position = UDim2.new(1, -31, 0, 34)
		local area = create("TextButton", { Size = UDim2.new(1, -70, 0, 44), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 35, 0, 86), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, r)
		local track = create("Frame", { Size = UDim2.new(1, 0, 0, 8), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = C.ToggleOff, BorderSizePixel = 0 }, area)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
		local fill = create("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = C.White, BorderSizePixel = 0 }, track)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
		local knob = create("Frame", { Size = UDim2.new(0, 34, 0, 34), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), BackgroundColor3 = C.White, BorderSizePixel = 0 }, track)
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
		local r = row(sec, 90)
		local l = rowLabel(r, name, 45)
		l.Size = UDim2.new(1, -290, 0, 33)
		local box = create("TextButton", { Size = UDim2.new(0, 232, 0, 64), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0, 45), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = "", AutoButtonColor = true }, r)
		corner(box, 16)
		local swatch = create("Frame", { Size = UDim2.new(0, 34, 0, 34), Position = UDim2.new(0, 16, 0.5, -17), BackgroundColor3 = Config[key], BorderSizePixel = 0 }, box)
		corner(swatch, 9)
		local hex = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, -66, 1, 0), Position = UDim2.new(0, 62, 0, 0), Text = hexOf(Config[key]), TextSize = 20, Font = F.Reg, TextColor3 = C.SubText, TextXAlignment = Enum.TextXAlignment.Left }, box)
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
			i = i % #palette + 1
			Config[key] = palette[i]
			swatch.BackgroundColor3 = palette[i]
			hex.Text = hexOf(palette[i])
			if onChange then onChange(palette[i]) end
		end)
	end

	local function addInput(sec, name, key, placeholder, onChange)
		local r = row(sec, 136)
		rowLabel(r, name, 34)
		local box = create("Frame", { Size = UDim2.new(1, -62, 0, 58), Position = UDim2.new(0, 31, 0, 62), BackgroundColor3 = C.Input, BorderSizePixel = 0 }, r)
		corner(box, 16)
		stroke(box, Color3.fromRGB(40, 42, 54), 1)
		local tb = create("TextBox", {
			BackgroundTransparency = 1, Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 15, 0, 0), Text = Config[key],
			PlaceholderText = placeholder, PlaceholderColor3 = C.SubText, TextColor3 = C.White, TextSize = 20, Font = F.Reg,
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
		local baseH, itemH = 136, 56
		local r = row(sec, baseH)
		rowLabel(r, name, 34)
		local box = create("TextButton", { Size = UDim2.new(1, -62, 0, 64), Position = UDim2.new(0, 31, 0, 62), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = "", AutoButtonColor = false }, r)
		corner(box, 16)
		local cur = txt(box, Config[key], 21, C.White, F.Reg)
		cur.Position = UDim2.new(0, 24, 0.5, 0)
		cur.Size = UDim2.new(1, -90, 0, 30)
		local arrow = txt(box, "v", 16, C.BarLight, F.Bold, Enum.TextXAlignment.Center)
		arrow.AnchorPoint = Vector2.new(0.5, 0.5)
		arrow.Size = UDim2.new(0, 24, 0, 24)
		arrow.Position = UDim2.new(1, -34, 0.5, 0)
		local list = create("Frame", { Size = UDim2.new(1, -62, 0, #options * itemH), Position = UDim2.new(0, 31, 0, baseH - 4), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Visible = false }, r)
		corner(list, 16)
		local open = false
		local function setOpen(v)
			open = v
			list.Visible = v
			arrow.Text = v and "^" or "v"
			r.Size = UDim2.new(1, 0, 0, v and (baseH + #options * itemH + 12) or baseH)
		end
		for i, opt in ipairs(options) do
			local b = create("TextButton", {
				Size = UDim2.new(1, 0, 0, itemH), Position = UDim2.new(0, 0, 0, (i - 1) * itemH), BackgroundTransparency = 1,
				Text = opt, TextSize = 21, Font = F.Reg, TextColor3 = C.White, TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
			}, list)
			create("UIPadding", { PaddingLeft = UDim.new(0, 24) }, b)
			b.MouseButton1Click:Connect(function()
				Config[key] = opt
				cur.Text = opt
				setOpen(false)
				if onChange then onChange(opt) end
			end)
		end
		table.insert(syncers, function() cur.Text = Config[key] end)
		box.MouseButton1Click:Connect(function() setOpen(not open) end)
	end

	local function addKeybind(sec, name, key, onChange)
		local r = row(sec, 90)
		local l = rowLabel(r, name, 45)
		l.Size = UDim2.new(1, -250, 0, 33)
		local btn = create("TextButton", {
			Size = UDim2.new(0, 190, 0, 66), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -24, 0, 45),
			BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = Config[key], TextSize = 22, Font = F.Med, TextColor3 = C.White, AutoButtonColor = true,
		}, r)
		corner(btn, 16)
		local waiting = false
		table.insert(syncers, function() btn.Text = Config[key] end)
		btn.MouseButton1Click:Connect(function()
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

	local function addButton(sec, text, callback)
		local r = row(sec, 88)
		sec.dividers[#sec.dividers].Visible = false
		local btn = create("TextButton", {
			Size = UDim2.new(1, -62, 0, 68), Position = UDim2.new(0, 31, 0, 10), BackgroundColor3 = C.IconBox, BorderSizePixel = 0,
			Text = text, TextSize = 22, Font = F.Bold, TextColor3 = C.White, AutoButtonColor = true,
		}, r)
		corner(btn, 16)
		btn.MouseButton1Click:Connect(function() callback(btn) end)
		return btn
	end

	local function addInfo(sec, text)
		local r = row(sec, 84)
		sec.dividers[#sec.dividers].Visible = false
		local box = create("Frame", { Size = UDim2.new(1, -62, 0, 68), Position = UDim2.new(0, 31, 0, 8), BackgroundColor3 = C.IconBox, BorderSizePixel = 0 }, r)
		corner(box, 16)
		return create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0), Text = text, TextSize = 22, Font = F.Bold, TextColor3 = C.White }, box)
	end

	local function flash(btn, msg, orig)
		btn.Text = msg
		task.delay(1.4, function() if btn.Parent then btn.Text = orig end end)
	end

	-- tabs ------------------------------------------------------------
	local function tabFail(name) return function(e) warn("Item ESP: tab '" .. name .. "' failed: " .. tostring(e)) end end

	xpcall(function() -- Home
		local p = newPage("Home")
		local a = section(p.left, "Overview", 1, "⌂")

		local wr = row(a, 190)
		local card = create("Frame", { Size = UDim2.new(1, -48, 0, 158), Position = UDim2.new(0, 24, 0, 16), BackgroundColor3 = C.Tile, BorderSizePixel = 0 }, wr)
		corner(card, 22)
		local av = create("ImageLabel", { Size = UDim2.fromOffset(112, 112), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 24, 0.5, 0), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Image = "" }, card)
		create("UICorner", { CornerRadius = UDim.new(1, 0) }, av)
		stroke(av, Color3.fromRGB(200, 202, 212), 2)
		loadAvatar(av)
		local wl = txt(card, "WELCOME " .. string.upper(player.Name), 30, C.White, F.Bold)
		wl.Position = UDim2.new(0, 160, 0.5, -20)
		wl.Size = UDim2.new(1, -180, 0, 40)
		table.insert(usernameLabels, { label = wl, real = "WELCOME " .. string.upper(player.Name), hidden = "WELCOME ********" })
		local hl = txt(card, "@" .. player.Name, 24, C.SubText, F.Reg)
		hl.Position = UDim2.new(0, 160, 0.5, 24)
		hl.Size = UDim2.new(1, -180, 0, 34)
		table.insert(usernameLabels, { label = hl, real = "@" .. player.Name, hidden = "@********" })

		local sr = row(a, 262)
		UI.stats = {}
		local function tile(name, xScale, xOff, y)
			local t = create("Frame", { Size = UDim2.new(0.5, -30, 0, 116), Position = UDim2.new(xScale, xOff, 0, y), BackgroundColor3 = C.Tile, BorderSizePixel = 0 }, sr)
			corner(t, 20)
			local l1 = txt(t, name, 20, C.SubText, F.Reg)
			l1.Position = UDim2.new(0, 22, 0, 34)
			l1.Size = UDim2.new(1, -40, 0, 28)
			local l2 = txt(t, "-", 32, C.White, F.Bold)
			l2.Position = UDim2.new(0, 22, 0, 80)
			l2.Size = UDim2.new(1, -40, 0, 44)
			UI.stats[name] = l2
		end
		tile("Items Tracked", 0, 24, 8)
		tile("Alert Items", 0.5, 6, 8)
		tile("FPS", 0, 24, 136)
		tile("Ping", 0.5, 6, 136)
		for _, d in ipairs(a.dividers) do d.Visible = false end
		finish(a)

		local b = section(p.right, "Session", 1, "⌂")
		addCheckbox(b, "Hide Username", "HideUsername", function() UI.applyUsername() end)
		finish(b)

		local c = section(p.right, "Item Breakdown", 2, "◈")
		UI.catInfo = {}
		for _, cat in ipairs(CATEGORIES) do
			UI.catInfo[cat.id] = addInfo(c, cat.label .. ": 0")
		end
		finish(c)
	end, tabFail("Home"))

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
			local r = row(a, 66)
			local nameL = txt(r, "", 21, C.White, F.Semi)
			nameL.Position = UDim2.new(0, 31, 0, 33)
			nameL.Size = UDim2.new(0, 290, 0, 30)
			local distL = txt(r, "", 19, C.SubText, F.Reg)
			distL.Position = UDim2.new(0, 326, 0, 33)
			distL.Size = UDim2.new(0, 130, 0, 28)
			local tp = create("TextButton", { Size = UDim2.fromOffset(78, 46), Position = UDim2.new(0, 466, 0, 10), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = "TP", TextSize = 18, Font = F.Bold, TextColor3 = C.White, AutoButtonColor = true }, r)
			corner(tp, 12)
			local hide = create("TextButton", { Size = UDim2.fromOffset(78, 46), Position = UDim2.new(0, 552, 0, 10), BackgroundColor3 = C.IconBox, BorderSizePixel = 0, Text = "Hide", TextSize = 18, Font = F.Bold, TextColor3 = C.White, AutoButtonColor = true }, r)
			corner(hide, 12)
			tp.MouseButton1Click:Connect(function()
				if UI.listEntries[i] then Actions.teleport(UI.listEntries[i]) end
			end)
			hide.MouseButton1Click:Connect(function()
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
		addButton(c, "Unload Script", function() Actions.unload() end)
		finish(c)

		local d = section(p.left, "Notifications", 2, "◍")
		addCheckbox(d, "Status Notifications", "StatusNotify")
		addSlider(d, "Notification Time", "NotifyDuration", 2, 15, "s")
		addButton(d, "Test Roblox Notification", function() notify("Item ESP", "Roblox notifications are working") end)
		finish(d)
	end, tabFail("Settings"))

	xpcall(function() -- Player ESP
		local p = newPage("Player ESP")
		local a = section(p.left, "Player ESP", 1, "◉")
		addCheckbox(a, "Player ESP (Master)", "PlayerESP")
		addCheckbox(a, "Box Outline", "PBox")
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
		addCheckbox(a, "Walk Speed", "SpeedOn")
		addSlider(a, "Speed Value", "WalkSpeedVal", 16, 300, "")
		addCheckbox(a, "Jump Power", "JumpOn")
		addSlider(a, "Jump Value", "JumpPowerVal", 50, 400, "")
		addCheckbox(a, "Infinite Jump", "InfJump")
		finish(a)
		local b = section(p.right, "Fly & Noclip", 1, "▶")
		addCheckbox(b, "Fly (move with the stick, look to steer)", "Fly")
		addSlider(b, "Fly Speed", "FlySpeed", 10, 300, "")
		addCheckbox(b, "Noclip", "Noclip")
		finish(b)
	end, tabFail("Movement"))

	xpcall(function() -- Utility
		local p = newPage("Utility")
		local a = section(p.left, "Visual Utility", 1, "■")
		addCheckbox(a, "Fullbright", "Fullbright")
		addCheckbox(a, "Custom FOV", "FOVOn")
		addSlider(a, "FOV", "FOVVal", 40, 120, "")
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
		finish(b)
	end, tabFail("Utility"))

	-- sidebar entries -----------------------------------------------
	local subButtons, catOf, iconOf = {}, {}, {}
	local function selectPage(name)
		for n, page in pairs(pages) do page.frame.Visible = (n == name) end
		for n, b in pairs(subButtons) do
			local sel = (n == name)
			b.btn.BackgroundTransparency = sel and 0 or 1
			b.marker.Visible = sel
			b.text.TextColor3 = sel and C.White or C.SubText
			b.icon.TextColor3 = sel and C.White or C.SubText
		end
		crumb.Text = string.format('<font color="#C9CBD6">%s</font>  <font color="#6F7280">v</font>  <b>%s</b>', catOf[name] or "", name)
		headIcon.Text = iconOf[name] or "◎"
	end

	local catOrder = 0
	local function addCategory(title, subs)
		catOrder = catOrder + 1
		local cat = create("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = catOrder }, sideScroll)
		create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, cat)
		local hdr = create("TextButton", { Size = UDim2.new(1, 0, 0, 72), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, LayoutOrder = 0 }, cat)
		local t = txt(hdr, string.upper(title), 22, C.SubText, F.Semi)
		t.Position = UDim2.new(0, 30, 0.5, 0)
		local chev = txt(hdr, "v", 16, C.BarLight, F.Bold, Enum.TextXAlignment.Center)
		chev.AnchorPoint = Vector2.new(0.5, 0.5)
		chev.Size = UDim2.new(0, 24, 0, 24)
		chev.Position = UDim2.new(1, -40, 0.5, 0)
		local subFrame = create("Frame", { Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = 1 }, cat)
		create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, subFrame)
		hdr.MouseButton1Click:Connect(function()
			subFrame.Visible = not subFrame.Visible
			chev.Text = subFrame.Visible and "v" or ">"
		end)
		for i, entry in ipairs(subs) do
			local name, icon = entry[1], entry[2]
			catOf[name], iconOf[name] = title, icon
			local btn = create("TextButton", { Size = UDim2.new(1, 0, 0, 86), BackgroundColor3 = C.Selected, BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = i }, subFrame)
			corner(btn, 18)
			local marker = create("Frame", { Size = UDim2.new(0, 5, 0, 44), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = C.White, BorderSizePixel = 0, Visible = false }, btn)
			corner(marker, 3)
			local ic = create("TextLabel", { BackgroundTransparency = 1, Size = UDim2.fromOffset(40, 40), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 26, 0.5, 0), Text = icon, TextSize = 28, Font = F.Med, TextColor3 = C.SubText }, btn)
			local st = txt(btn, name, 26, C.SubText, F.Reg)
			st.Position = UDim2.new(0, 86, 0.5, 0)
			st.Size = UDim2.new(1, -100, 0, 36)
			subButtons[name] = { btn = btn, marker = marker, text = st, icon = ic }
			btn.MouseButton1Click:Connect(function() selectPage(name) end)
		end
	end

	addCategory("Main", { { "Home", "⌂" } })
	addCategory("Visuals", { { "Item ESP", "◎" }, { "Player ESP", "◉" } })
	addCategory("Alerts", { { "Alerts", "▲" } })
	addCategory("Items", { { "Item List", "◈" }, { "Pickup", "◆" } })
	addCategory("Player", { { "Movement", "▶" }, { "Utility", "■" } })
	addCategory("Settings", { { "Colors", "◐" }, { "Settings", "◍" } })
	selectPage("Home")
	UI.applyUsername()

	-- small round logo while minimized (tap = restore, drag = move) --
	local logoBtn = create("TextButton", {
		Name = "MiniLogo", Visible = false, Text = "", Size = UDim2.fromOffset(96, 96), AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -110, 0, 30), BackgroundColor3 = C.Window, BorderSizePixel = 0, AutoButtonColor = false,
	}, screenGui)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, logoBtn)
	stroke(logoBtn, Color3.fromRGB(235, 236, 242), 3)
	local ring = create("Frame", { Size = UDim2.fromOffset(58, 26), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), Rotation = -28, BackgroundTransparency = 1 }, logoBtn)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, ring)
	stroke(ring, C.White, 4)
	local dot = create("Frame", { Size = UDim2.fromOffset(20, 20), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = C.White, BorderSizePixel = 0 }, logoBtn)
	create("UICorner", { CornerRadius = UDim.new(1, 0) }, dot)

	local function showMain(v)
		main.Visible = v
		logoBtn.Visible = not v
	end
	do
		local dragging, moved, dragStart, startPos = false, false, nil, nil
		logoBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging, moved, dragStart, startPos = true, false, input.Position, logoBtn.Position
			end
		end)
		table.insert(connections, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - dragStart
				if delta.Magnitude > 8 then moved = true end
				if moved then logoBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end
			end
		end))
		table.insert(connections, UserInputService.InputEnded:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				dragging = false
				if not moved then showMain(true) end
			end
		end))
	end
	minBtn.MouseButton1Click:Connect(function() showMain(false) end)

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

-- hotkey: toggle the whole ESP
table.insert(connections, UserInputService.InputBegan:Connect(function(input, gp)
	if gp or Config.ToggleKey == "None" then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == Config.ToggleKey and UI.setEnabled then
		UI.setEnabled(not Config.Enabled)
	end
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
		L.ClockTime = 14
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
	end

	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not (hum and hrp) then return end

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
table.insert(connections, RunService.RenderStepped:Connect(function() pcall(Feat.render) end))

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

-- undo everything when the script is unloaded
Feat.cleanup = function()
	Feat.stopFly()
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
	for plr in pairs(Feat.pl) do Feat.dropPlayer(plr) end
end

---------------------------------------------------------------------
-- CLOSE / CLEANUP
---------------------------------------------------------------------
local function cleanup()
	if not running then return end
	running = false
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
end

Actions.unload = cleanup
getgenv().ItemESP_Cleanup = cleanup
if UI.closeBtn then UI.closeBtn.MouseButton1Click:Connect(cleanup) end

print("CodeBot V1: Item ESP loaded (alerts for: " .. Config.AlertNames .. ")")
notify("Item ESP loaded", "Alerts for: " .. Config.AlertNames, true)
