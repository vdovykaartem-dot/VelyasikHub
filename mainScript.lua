-- =================================================================
-- AETHER HUB (Redesigned UI / Protected)
-- =================================================================

local function getSvc(serviceName)
	local s = game:GetService(serviceName)
	return (cloneref and cloneref(s)) or s
end

local CoreGui = getSvc("CoreGui")
local Players = getSvc("Players")
local RunService = getSvc("RunService")
local UserInputService = getSvc("UserInputService")
local GuiService = getSvc("GuiService")
local TweenService = getSvc("TweenService")
local HttpService = getSvc("HttpService")
local TeleportService = getSvc("TeleportService")
local Lighting = getSvc("Lighting")
local TextChatService = getSvc("TextChatService")
local ReplicatedStorage = getSvc("ReplicatedStorage")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local function RndName()
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	local str = ""
	for i = 1, math.random(12, 18) do
		local r = math.random(1, #chars)
		str = str .. string.sub(chars, r, r)
	end
	return str
end

local ObfuscatedNames = { GUI = RndName(), FCPart = RndName(), Highlight = RndName() }
local TargetGuiParent = (gethui and gethui()) or CoreGui

local existingGui = TargetGuiParent:FindFirstChild(ObfuscatedNames.GUI) or LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild(ObfuscatedNames.GUI)
if existingGui then
	existingGui:Destroy()
	task.wait(0.2)
end

-- ===================== ЗБЕРЕЖЕННЯ КОНФІГІВ =====================
local espConfigFile, teamWhitelistFile, playerConfigFile = "AH_ESPConfig.json", "AH_TeamWhitelist.json", "AH_PlayerConfig.json"

local ESPSettings = { Master = false, Highlight = true, Box = false, Name = false, HP = false, Studs = false, Color = {R = 140, G = 80, B = 255} }
local PlayerSettings = { FlySpeed = 50 }
local WhitelistedNames = {}

if isfile and readfile then
	pcall(function() local d = HttpService:JSONDecode(readfile(espConfigFile)) if type(d)=="table" then for k,v in pairs(d) do if ESPSettings[k]~=nil then ESPSettings[k]=v end end end end)
	pcall(function() local d = HttpService:JSONDecode(readfile(playerConfigFile)) if type(d)=="table" then if d.FlySpeed~=nil then PlayerSettings.FlySpeed=d.FlySpeed end end end)
	pcall(function() local d = HttpService:JSONDecode(readfile(teamWhitelistFile)) if type(d)=="table" then WhitelistedNames = d end end)
end

local function saveESPConfig() if writefile then pcall(function() writefile(espConfigFile, HttpService:JSONEncode(ESPSettings)) end) end end
local function savePlayerConfig() if writefile then pcall(function() writefile(playerConfigFile, HttpService:JSONEncode(PlayerSettings)) end) end end
local function saveTeamWhitelist() if writefile then pcall(function() writefile(teamWhitelistFile, HttpService:JSONEncode(WhitelistedNames)) end) end end

local ESPColor = Color3.fromRGB(ESPSettings.Color.R, ESPSettings.Color.G, ESPSettings.Color.B)
if setfpscap then setfpscap(9999) end

-- Змінні стану
local HitboxEnabled, HitboxSize, KickStuffEnabled = false, 10, true
local SpeedEnabled, TargetSpeed, NoclipEnabled, InfJumpEnabled, FlyEnabled = false, 16, false, false, false
local AimbotEnabled, AimbotTarget, WallCheckEnabled, FOVEnabled, FOVRadius, Smoothness = false, "Head", true, false, 180, 0
local NoFogEnabled, FullbrightEnabled, FOVChangerEnabled, CustomFOV = false, false, false, 90
local FPSUnlockerEnabled, CamUnlockerEnabled = true, false
local FreeCamEnabled, FreezeDuringEnabled, FC_Speed, fwdDown, bwdDown = false, false, 60, false, false
local SpectateEnabled, SpectateTargetPlayer = false, nil
local OriginalSizes, OriginalNoclipStates = {}, {}
local Scripters = {[LocalPlayer.UserId] = true}

-- ===================== НОВИЙ ДИЗАЙН (THEME) =====================
local Theme = {
	Background = Color3.fromRGB(12, 12, 18),
	Panel = Color3.fromRGB(22, 22, 32),
	Accent = Color3.fromRGB(140, 80, 255), -- Неоново-фіолетовий
	Text = Color3.fromRGB(240, 240, 255),
	TextDim = Color3.fromRGB(150, 150, 170),
	Font = Enum.Font.Jura
}

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = ObfuscatedNames.GUI
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
local success = pcall(function() ScreenGui.Parent = TargetGuiParent end)
if not success then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local ESP_Folder = Instance.new("Folder", ScreenGui)
local ESP_Elements = {}

local function makeDraggable(dragPart, targetFrame)
	local dragging, dragStart, startPos
	dragPart.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = targetFrame.Position end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

-- Кнопка відкриття
local OpenButton = Instance.new("TextButton", ScreenGui)
OpenButton.Size = UDim2.new(0, 50, 0, 50)
OpenButton.Position = UDim2.new(0.85, 0, 0.05, 0)
OpenButton.BackgroundColor3 = Theme.Background
OpenButton.Text = "🌀"
OpenButton.TextSize = 28
OpenButton.TextColor3 = Theme.Accent
OpenButton.Font = Theme.Font
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(1, 0)
local BtnStroke = Instance.new("UIStroke", OpenButton)
BtnStroke.Color = Theme.Accent; BtnStroke.Thickness = 2
makeDraggable(OpenButton, OpenButton)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 600, 0, 400)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.Visible = false
MainFrame.ClipsDescendants = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
local MainStroke = Instance.new("UIStroke", MainFrame)
MainStroke.Color = Theme.Accent; MainStroke.Thickness = 1.5

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 35)
TopBar.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
TopBar.BorderSizePixel = 0
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 8)
makeDraggable(TopBar, MainFrame)

local TitleText = Instance.new("TextLabel", TopBar)
TitleText.Size = UDim2.new(1, -50, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "AETHER HUB"
TitleText.Font = Enum.Font.Jura
TitleText.TextColor3 = Theme.Accent
TitleText.TextSize = 18
TitleText.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -35, 0, 0)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.TextDim
CloseBtn.Font = Theme.Font
CloseBtn.TextSize = 16

CloseBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false end)
OpenButton.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

-- ГОРИЗОНТАЛЬНІ ВКЛАДКИ
local TabButtonsFrame = Instance.new("ScrollingFrame", MainFrame)
TabButtonsFrame.Size = UDim2.new(1, -20, 0, 35)
TabButtonsFrame.Position = UDim2.new(0, 10, 0, 45)
TabButtonsFrame.BackgroundTransparency = 1
TabButtonsFrame.ScrollBarThickness = 0
TabButtonsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
TabButtonsFrame.AutomaticCanvasSize = Enum.AutomaticSize.X

local TabListLayout = Instance.new("UIListLayout", TabButtonsFrame)
TabListLayout.FillDirection = Enum.FillDirection.Horizontal
TabListLayout.Padding = UDim.new(0, 8)
TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local PagesContainer = Instance.new("Frame", MainFrame)
PagesContainer.Size = UDim2.new(1, -20, 1, -95)
PagesContainer.Position = UDim2.new(0, 10, 0, 85)
PagesContainer.BackgroundTransparency = 1

local tabs = {}
local function createTab(name)
	local TabBtn = Instance.new("TextButton", TabButtonsFrame)
	TabBtn.Size = UDim2.new(0, 100, 1, 0)
	TabBtn.BackgroundColor3 = Theme.Panel
	TabBtn.Text = name
	TabBtn.Font = Theme.Font
	TabBtn.TextColor3 = Theme.TextDim
	TabBtn.TextSize = 14
	Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 4)
	
	local Indicator = Instance.new("Frame", TabBtn)
	Indicator.Size = UDim2.new(1, 0, 0, 2)
	Indicator.Position = UDim2.new(0, 0, 1, -2)
	Indicator.BackgroundColor3 = Theme.Accent
	Indicator.BorderSizePixel = 0
	Indicator.BackgroundTransparency = 1

	local Page = Instance.new("ScrollingFrame", PagesContainer)
	Page.Size = UDim2.new(1, 0, 1, 0)
	Page.BackgroundTransparency = 1
	Page.ScrollBarThickness = 2
	Page.ScrollBarImageColor3 = Theme.Accent
	Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
	Page.Visible = false
	
	local PageLayout = Instance.new("UIListLayout", Page)
	PageLayout.Padding = UDim.new(0, 8)
	PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	TabBtn.MouseButton1Click:Connect(function()
		for _, t in pairs(tabs) do
			t.page.Visible = false
			TweenService:Create(t.btn, TweenInfo.new(0.2), {TextColor3 = Theme.TextDim, BackgroundColor3 = Theme.Panel}):Play()
			TweenService:Create(t.indicator, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
		end
		Page.Visible = true
		TweenService:Create(TabBtn, TweenInfo.new(0.2), {TextColor3 = Theme.Text, BackgroundColor3 = Color3.fromRGB(32, 32, 45)}):Play()
		TweenService:Create(Indicator, TweenInfo.new(0.2), {BackgroundTransparency = 0}):Play()
	end)

	table.insert(tabs, {btn = TabBtn, page = Page, indicator = Indicator})
	if #tabs == 1 then
		Page.Visible = true
		TabBtn.TextColor3 = Theme.Text
		TabBtn.BackgroundColor3 = Color3.fromRGB(32, 32, 45)
		Indicator.BackgroundTransparency = 0
	end
	return Page
end

-- НОВІ ЧЕКБОКСИ ЗАМІСТЬ ПЕРЕМИКАЧІВ
local function createToggle(parent, text, defaultState, callback)
	local Holder = Instance.new("TextButton", parent)
	Holder.Size = UDim2.new(1, -10, 0, 40)
	Holder.BackgroundColor3 = Theme.Panel
	Holder.Text = ""
	Holder.AutoButtonColor = false
	Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 6)

	local Label = Instance.new("TextLabel", Holder)
	Label.Size = UDim2.new(0.8, 0, 1, 0)
	Label.Position = UDim2.new(0.05, 0, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.Font = Theme.Font
	Label.TextColor3 = Theme.Text
	Label.TextSize = 14
	Label.TextXAlignment = Enum.TextXAlignment.Left

	local Checkbox = Instance.new("Frame", Holder)
	Checkbox.Size = UDim2.new(0, 20, 0, 20)
	Checkbox.Position = UDim2.new(1, -30, 0.5, -10)
	Checkbox.BackgroundColor3 = defaultState and Theme.Accent or Theme.Background
	Instance.new("UICorner", Checkbox).CornerRadius = UDim.new(0, 4)
	local CheckStroke = Instance.new("UIStroke", Checkbox)
	CheckStroke.Color = Theme.Accent
	CheckStroke.Thickness = 1.5

	Holder.MouseButton1Click:Connect(function()
		defaultState = not defaultState
		TweenService:Create(Checkbox, TweenInfo.new(0.15), {BackgroundColor3 = defaultState and Theme.Accent or Theme.Background}):Play()
		if callback then callback(defaultState) end
	end)
end

local function createBox(parent, text, default, min, max, callback)
	local Holder = Instance.new("Frame", parent)
	Holder.Size = UDim2.new(1, -10, 0, 60)
	Holder.BackgroundColor3 = Theme.Panel
	Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 6)

	local Label = Instance.new("TextLabel", Holder)
	Label.Size = UDim2.new(1, -20, 0, 25)
	Label.Position = UDim2.new(0, 10, 0, 5)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.Font = Theme.Font
	Label.TextColor3 = Theme.TextDim
	Label.TextSize = 12
	Label.TextXAlignment = Enum.TextXAlignment.Left

	local Box = Instance.new("TextBox", Holder)
	Box.Size = UDim2.new(1, -20, 0, 25)
	Box.Position = UDim2.new(0, 10, 0, 30)
	Box.BackgroundColor3 = Theme.Background
	Box.Text = tostring(default)
	Box.Font = Theme.Font
	Box.TextColor3 = Theme.Text
	Box.TextSize = 14
	Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)
	local BoxStroke = Instance.new("UIStroke", Box)
	BoxStroke.Color = Theme.Accent; BoxStroke.Thickness = 1

	Box.FocusLost:Connect(function()
		local n = tonumber(Box.Text) or default
		if min and max then n = math.clamp(n, min, max) end
		Box.Text = tostring(n)
		if callback then callback(n) end
	end)
end

local function createButtonUI(parent, text, callback)
	local Btn = Instance.new("TextButton", parent)
	Btn.Size = UDim2.new(1, -10, 0, 40)
	Btn.BackgroundColor3 = Theme.Background
	Btn.Text = text
	Btn.Font = Theme.Font
	Btn.TextColor3 = Theme.Accent
	Btn.TextSize = 14
	Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
	local Stroke = Instance.new("UIStroke", Btn)
	Stroke.Color = Theme.Accent; Stroke.Thickness = 1
	
	Btn.MouseEnter:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Background}):Play() end)
	Btn.MouseLeave:Connect(function() TweenService:Create(Btn, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Background, TextColor3 = Theme.Accent}):Play() end)
	Btn.MouseButton1Click:Connect(function() if callback then callback() end end)
end

-- ===================== СТВОРЕННЯ ВКЛАДОК =====================
local TabInfo = createTab("Info")
local TabMain = createTab("Main")
local TabVisuals = createTab("Visuals")
local TabPlayer = createTab("Player")
local TabCombat = createTab("Combat")
local TabTeamCheck = createTab("Team")
local TabFreeCam = createTab("Camera")

-- INFO
local StatsFrame = Instance.new("Frame", TabInfo)
StatsFrame.Size = UDim2.new(1, -10, 0, 80)
StatsFrame.BackgroundColor3 = Theme.Panel
Instance.new("UICorner", StatsFrame).CornerRadius = UDim.new(0, 6)
local StatsLayout = Instance.new("UIListLayout", StatsFrame); StatsLayout.Padding = UDim.new(0, 5)

local function makeStatRow(text)
	local Lbl = Instance.new("TextLabel", StatsFrame)
	Lbl.Size = UDim2.new(1, -20, 0, 18)
	Lbl.Position = UDim2.new(0, 10, 0, 0)
	Lbl.BackgroundTransparency = 1
	Lbl.Text = text; Lbl.TextColor3 = Theme.Text; Lbl.Font = Theme.Font; Lbl.TextXAlignment = Enum.TextXAlignment.Left
	return Lbl
end

local FPSLabel = makeStatRow(" FPS: Calculating...")
local PingLabel = makeStatRow(" Ping: Calculating...")
makeStatRow(" User: " .. LocalPlayer.Name)
makeStatRow(" Place ID: " .. game.PlaceId)

-- MAIN
createToggle(TabMain, "Master ESP", ESPSettings.Master, function(s) ESPSettings.Master = s; saveESPConfig() end)
createToggle(TabMain, "Highlight", ESPSettings.Highlight, function(s) ESPSettings.Highlight = s; saveESPConfig() end)
createToggle(TabMain, "Boxes", ESPSettings.Box, function(s) ESPSettings.Box = s; saveESPConfig() end)
createToggle(TabMain, "Names", ESPSettings.Name, function(s) ESPSettings.Name = s; saveESPConfig() end)
createToggle(TabMain, "Health", ESPSettings.HP, function(s) ESPSettings.HP = s; saveESPConfig() end)
createToggle(TabMain, "Distance", ESPSettings.Studs, function(s) ESPSettings.Studs = s; saveESPConfig() end)

local PaletteHolder = Instance.new("Frame", TabMain)
PaletteHolder.Size = UDim2.new(1, -10, 0, 70)
PaletteHolder.BackgroundColor3 = Theme.Panel
Instance.new("UICorner", PaletteHolder).CornerRadius = UDim.new(0, 6)

local PaletteTitle = Instance.new("TextLabel", PaletteHolder)
PaletteTitle.Size = UDim2.new(1, 0, 0, 25)
PaletteTitle.Position = UDim2.new(0.05, 0, 0, 5)
PaletteTitle.BackgroundTransparency = 1; PaletteTitle.Text = "ESP Color"; PaletteTitle.TextColor3 = Theme.TextDim; PaletteTitle.Font = Theme.Font; PaletteTitle.TextXAlignment = Enum.TextXAlignment.Left

local ColorsContainer = Instance.new("Frame", PaletteHolder)
ColorsContainer.Size = UDim2.new(1, -20, 0, 30); ColorsContainer.Position = UDim2.new(0, 15, 0, 30); ColorsContainer.BackgroundTransparency = 1
local ColorLayout = Instance.new("UIListLayout", ColorsContainer); ColorLayout.FillDirection = Enum.FillDirection.Horizontal; ColorLayout.Padding = UDim.new(0, 15)

local colorButtons = {}
local function addColorBtn(color)
	local btn = Instance.new("TextButton", ColorsContainer)
	btn.Size = UDim2.new(0, 25, 0, 25)
	btn.BackgroundColor3 = color
	btn.Text = ""
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
	local stroke = Instance.new("UIStroke", btn); stroke.Thickness = 2; stroke.Color = Theme.Text; stroke.Transparency = 1
	table.insert(colorButtons, {Button = btn, Stroke = stroke, Color = color})
	
	btn.MouseButton1Click:Connect(function()
		ESPColor = color; ESPSettings.Color = {R = math.floor(color.R*255), G = math.floor(color.G*255), B = math.floor(color.B*255)}; saveESPConfig()
		for _, cb in ipairs(colorButtons) do
			if cb.Color == color then TweenService:Create(cb.Stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()
			else TweenService:Create(cb.Stroke, TweenInfo.new(0.2), {Transparency = 1}):Play() end
		end
	end)
end

addColorBtn(Theme.Accent)
addColorBtn(Color3.fromRGB(0, 255, 255))
addColorBtn(Color3.fromRGB(255, 50, 50))
addColorBtn(Color3.fromRGB(50, 255, 50))
addColorBtn(Color3.fromRGB(255, 255, 255))

createToggle(TabMain, "Hitbox Expander", HitboxEnabled, function(s) HitboxEnabled = s end)
createBox(TabMain, "Hitbox Size", 10, 1, 30, function(v) HitboxSize = v end)

-- VISUALS
createToggle(TabVisuals, "Remove Fog", NoFogEnabled, function(s) NoFogEnabled = s end)
createToggle(TabVisuals, "Fullbright", FullbrightEnabled, function(s) FullbrightEnabled = s end)
createToggle(TabVisuals, "Custom FOV", FOVChangerEnabled, function(s) FOVChangerEnabled = s; if not s then Camera.FieldOfView = 70 end end)
createBox(TabVisuals, "FOV Amount", 90, 10, 120, function(v) CustomFOV = v end)
createToggle(TabVisuals, "FPS Unlocker", FPSUnlockerEnabled, function(s) FPSUnlockerEnabled = s; if setfpscap then pcall(function() setfpscap(s and 9999 or 60) end) end end)
createToggle(TabVisuals, "Spectate Mode", SpectateEnabled, function(s) 
	SpectateEnabled = s
	if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = LocalPlayer.Character.Humanoid end
end)

createButtonUI(TabVisuals, "Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)

-- PLAYER
createToggle(TabPlayer, "Custom Speed", SpeedEnabled, function(s) SpeedEnabled = s; if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 end end)
createBox(TabPlayer, "WalkSpeed Value", 16, 1, 1000, function(v) TargetSpeed = v end)
createToggle(TabPlayer, "Noclip", NoclipEnabled, function(s) 
	NoclipEnabled = s 
	if s and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then OriginalNoclipStates[part] = part.CanCollide end end
	elseif not s and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") and OriginalNoclipStates[part] ~= nil then part.CanCollide = OriginalNoclipStates[part] end end
		table.clear(OriginalNoclipStates)
	end
end)
createToggle(TabPlayer, "Infinite Jump", InfJumpEnabled, function(s) InfJumpEnabled = s end)
createToggle(TabPlayer, "Fly", FlyEnabled, function(s) FlyEnabled = s end)
createBox(TabPlayer, "Fly Speed", PlayerSettings.FlySpeed, 1, 200, function(v) PlayerSettings.FlySpeed = v; savePlayerConfig() end)

-- COMBAT
createToggle(TabCombat, "Aimbot", AimbotEnabled, function(s) AimbotEnabled = s end)
createButtonUI(TabCombat, "Target Part: Head", function()
	AimbotTarget = (AimbotTarget == "Head") and "Torso" or "Head"
	for _, child in pairs(TabCombat:GetChildren()) do if child:IsA("TextButton") and string.find(child.Text, "Target Part") then child.Text = "Target Part: " .. AimbotTarget end end
end)
createToggle(TabCombat, "Wall Check", WallCheckEnabled, function(s) WallCheckEnabled = s end)
createToggle(TabCombat, "Show FOV Circle", FOVEnabled, function(s) FOVEnabled = s end)
createBox(TabCombat, "FOV Circle Size", 180, 20, 500, function(v) FOVRadius = v end)
createBox(TabCombat, "Smoothness", 0, 0, 100, function(v) Smoothness = v end)

local FOVCircleUI = Instance.new("Frame", ScreenGui)
FOVCircleUI.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
FOVCircleUI.Position = UDim2.new(0.5, -FOVRadius, 0.5, -FOVRadius)
FOVCircleUI.BackgroundTransparency = 1; FOVCircleUI.Visible = false
local FOVStroke = Instance.new("UIStroke", FOVCircleUI); FOVStroke.Color = Theme.Accent; FOVStroke.Thickness = 1.5
Instance.new("UICorner", FOVCircleUI).CornerRadius = UDim.new(1, 0)

-- FREECAM
createToggle(TabFreeCam, "Enable Free Camera", FreeCamEnabled, function(s) 
	FreeCamEnabled = s 
	if s then
		local FCPart = workspace:FindFirstChild(ObfuscatedNames.FCPart) or Instance.new("Part")
		FCPart.Name = ObfuscatedNames.FCPart; FCPart.Anchored = true; FCPart.CanCollide = false; FCPart.Transparency = 1
		FCPart.Size = Vector3.new(1, 1, 1); FCPart.Position = Camera.Focus.Position; FCPart.Parent = workspace
		Camera.CameraSubject = FCPart
	else
		local FCPart = workspace:FindFirstChild(ObfuscatedNames.FCPart)
		if FCPart then pcall(function() FCPart:Destroy() end) end
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = LocalPlayer.Character.Humanoid end
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Anchored = false end
	end
end)
createToggle(TabFreeCam, "Freeze Character", FreezeDuringEnabled, function(s) 
	FreezeDuringEnabled = s
	if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Anchored = false end
end)
createBox(TabFreeCam, "Freecam Speed", 60, 10, 300, function(v) FC_Speed = v end)

-- TEAM CHECK
local function refreshTeamCheckList()
	for _, child in pairs(TabTeamCheck:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local btn = Instance.new("TextButton", TabTeamCheck)
			btn.Size = UDim2.new(1, -10, 0, 35)
			local isW = WhitelistedNames[p.Name] == true
			btn.BackgroundColor3 = isW and Theme.Accent or Theme.Panel
			btn.Text = p.Name; btn.Font = Theme.Font; btn.TextColor3 = isW and Theme.Background or Theme.Text; btn.TextSize = 14
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
			btn.MouseButton1Click:Connect(function()
				WhitelistedNames[p.Name] = not WhitelistedNames[p.Name]
				btn.BackgroundColor3 = WhitelistedNames[p.Name] and Theme.Accent or Theme.Panel
				btn.TextColor3 = WhitelistedNames[p.Name] and Theme.Background or Theme.Text
				saveTeamWhitelist()
			end)
		end
	end
end

for _, t in pairs(tabs) do
	if t.page == TabTeamCheck then t.btn.MouseButton1Click:Connect(refreshTeamCheckList) end
end

-- ===================== ЛОГІКА СКРИПТА =====================
local function getTargetPart(char) return AimbotTarget == "Head" and char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart") end

local function isVisible(targetPart)
	if not WallCheckEnabled then return true end
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
	local FCPart = workspace:FindFirstChild(ObfuscatedNames.FCPart)
	params.FilterDescendantsInstances = {LocalPlayer.Character, FCPart}; params.IgnoreWater = true
	local hit = workspace:Raycast(Camera.CFrame.Position, targetPart.Position - Camera.CFrame.Position, params)
	return hit == nil or hit.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosestPlayerToCenter()
	local closestPlayer, shortestDist = nil, math.huge
	local cameraCFrame = Camera.CFrame; local mouseRay = cameraCFrame.LookVector
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and not WhitelistedNames[player.Name] then
			local char = player.Character
			if char and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health > 0 then
				local targetPart = getTargetPart(char)
				if targetPart and isVisible(targetPart) then
					local directionToTarget = (targetPart.Position - cameraCFrame.Position).Unit
					if mouseRay:Dot(directionToTarget) > 0 then
						local pos = Camera:WorldToViewportPoint(targetPart.Position)
						local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
						local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
						if (not FOVEnabled or dist <= FOVRadius) and dist < shortestDist then
							shortestDist, closestPlayer = dist, targetPart
						end
					end
				end
			end
		end
	end
	return closestPlayer
end

local function createPlayerESP(player)
	if ESP_Elements[player] then return ESP_Elements[player] end
	local t = {}
	t.Highlight = Instance.new("Highlight", ESP_Folder); t.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; t.Highlight.Enabled = false
	t.BoxFrame = Instance.new("Frame", ESP_Folder); t.BoxFrame.BackgroundTransparency = 1; t.BoxStroke = Instance.new("UIStroke", t.BoxFrame); t.BoxStroke.Thickness = 1
	t.NameLbl = Instance.new("TextLabel", ESP_Folder); t.NameLbl.BackgroundTransparency = 1; t.NameLbl.Font = Theme.Font; t.NameLbl.TextSize = 13
	t.HPBarBg = Instance.new("Frame", ESP_Folder); t.HPBarBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0); t.HPBarBg.BorderSizePixel = 0
	t.HPBar = Instance.new("Frame", t.HPBarBg); t.HPBar.BorderSizePixel = 0
	t.StudsLbl = Instance.new("TextLabel", ESP_Folder); t.StudsLbl.BackgroundTransparency = 1; t.StudsLbl.TextColor3 = Color3.fromRGB(255, 255, 255); t.StudsLbl.Font = Theme.Font; t.StudsLbl.TextSize = 12
	local StudsStroke = Instance.new("UIStroke", t.StudsLbl); StudsStroke.Thickness = 1
	ESP_Elements[player] = t; return t
end

Players.PlayerRemoving:Connect(function(player)
	if ESP_Elements[player] then for _, v in pairs(ESP_Elements[player]) do if typeof(v) == "Instance" then pcall(function() v:Destroy() end) end end; ESP_Elements[player] = nil end
end)

RunService.Stepped:Connect(function()
	if NoclipEnabled and LocalPlayer.Character then for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
end)

local lastFpsTick = tick()
local origAmbient, origFogEnd = Lighting.Ambient, Lighting.FogEnd

RunService.RenderStepped:Connect(function(dt)
	if not ScreenGui or not ScreenGui.Parent then return end

	if tick() - lastFpsTick >= 0.5 then
		pcall(function() FPSLabel.Text = " FPS: " .. math.round(1 / dt); PingLabel.Text = " Ping: " .. math.floor(LocalPlayer:GetNetworkPing() * 1000) .. " ms" end)
		lastFpsTick = tick()
	end

	FOVCircleUI.Visible = FOVEnabled
	if FOVEnabled then FOVCircleUI.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2); FOVCircleUI.Position = UDim2.new(0.5, -FOVRadius, 0.5, -FOVRadius) end

	if FOVChangerEnabled then Camera.FieldOfView = CustomFOV end
	Lighting.Ambient = FullbrightEnabled and Color3.new(1,1,1) or origAmbient
	Lighting.FogEnd = NoFogEnabled and 100000 or origFogEnd

	if FreeCamEnabled then
		local FCPart = workspace:FindFirstChild(ObfuscatedNames.FCPart)
		if FCPart then
			if FreezeDuringEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Anchored = true end
			local moveDir = Vector3.new(0,0,0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
			FCPart.Position = FCPart.Position + (moveDir * FC_Speed * dt)
		end
	end

	local char = LocalPlayer.Character
	if char then
		local hrp, hum = char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
		if hrp and hum then
			if SpeedEnabled and not FlyEnabled then
				if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
				local moveDir = hum.MoveDirection
				if moveDir.Magnitude > 0.01 then hrp.AssemblyLinearVelocity = Vector3.new((moveDir * TargetSpeed).X, hrp.AssemblyLinearVelocity.Y, (moveDir * TargetSpeed).Z) end
			end
			if FlyEnabled then
				hum.PlatformStand = false
				local moveDir = hum.MoveDirection
				local camCFrame = Camera.CFrame
				local vel = Vector3.zero
				if moveDir.Magnitude > 0.01 then
					local flatLook = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
					local flatRight = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit
					local flyDir = (camCFrame.LookVector * flatLook:Dot(moveDir)) + (camCFrame.RightVector * flatRight:Dot(moveDir))
					if flyDir.Magnitude > 0 then vel = flyDir.Unit * PlayerSettings.FlySpeed end
				end
				local verticalVel = 0
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then verticalVel = PlayerSettings.FlySpeed 
				elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then verticalVel = -PlayerSettings.FlySpeed end
				
				hrp.AssemblyLinearVelocity = vel + Vector3.new(0, verticalVel, 0)
				hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z))
			else
				if not FreeCamEnabled and not SpeedEnabled and not SpectateEnabled then hum.PlatformStand = false end
			end
		end
	end

	if AimbotEnabled then
		local target = getClosestPlayerToCenter()
		if target then Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, target.Position), 1 / ((Smoothness / 5) + 1)) end
	end

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local pchar = player.Character
			local espUI = createPlayerESP(player)
			if pchar and pchar:FindFirstChild("HumanoidRootPart") and pchar:FindFirstChildOfClass("Humanoid") then
				local humanoid, rootPart = pchar:FindFirstChildOfClass("Humanoid"), pchar.HumanoidRootPart
				if not OriginalSizes[rootPart] then OriginalSizes[rootPart] = rootPart.Size end

				if HitboxEnabled and humanoid.Health > 0 then
					pcall(function() rootPart.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize); rootPart.Transparency = 0.75; rootPart.CanCollide = false end)
				elseif OriginalSizes[rootPart] then
					pcall(function() rootPart.Size = OriginalSizes[rootPart]; rootPart.Transparency = 1; rootPart.CanCollide = false end)
				end

				if ESPSettings.Master and humanoid.Health > 0 then
					if ESPSettings.Highlight then espUI.Highlight.Adornee = pchar; espUI.Highlight.FillColor = ESPColor; espUI.Highlight.Enabled = true else espUI.Highlight.Enabled = false end
					local hrpPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
					if onScreen and (ESPSettings.Box or ESPSettings.Name or ESPSettings.HP or ESPSettings.Studs) then
						local topPos = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0))
						local bottomPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3.5, 0))
						local h, w = bottomPos.Y - topPos.Y, (bottomPos.Y - topPos.Y) / 1.8
						local x, y = hrpPos.X - w / 2, topPos.Y

						if ESPSettings.Box then espUI.BoxFrame.Size = UDim2.new(0, w, 0, h); espUI.BoxFrame.Position = UDim2.new(0, x, 0, y); espUI.BoxStroke.Color = ESPColor; espUI.BoxFrame.Visible = true else espUI.BoxFrame.Visible = false end
						if ESPSettings.Name then espUI.NameLbl.Text = player.Name; espUI.NameLbl.TextColor3 = ESPColor; espUI.NameLbl.Size = UDim2.new(0, w, 0, 15); espUI.NameLbl.Position = UDim2.new(0, x, 0, y - 18); espUI.NameLbl.Visible = true else espUI.NameLbl.Visible = false end
						if ESPSettings.HP then
							local hpPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
							espUI.HPBarBg.Size = UDim2.new(0, 3, 0, h); espUI.HPBarBg.Position = UDim2.new(0, x - 6, 0, y)
							espUI.HPBar.Size = UDim2.new(1, 0, hpPercent, 0); espUI.HPBar.Position = UDim2.new(0, 0, 1 - hpPercent, 0)
							espUI.HPBar.BackgroundColor3 = Color3.fromRGB(255 - (hpPercent * 255), hpPercent * 255, 50); espUI.HPBarBg.Visible = true
						else espUI.HPBarBg.Visible = false end
						if ESPSettings.Studs then espUI.StudsLbl.Text = math.floor((Camera.CFrame.Position - rootPart.Position).Magnitude) .. "s"; espUI.StudsLbl.Size = UDim2.new(0, w, 0, 15); espUI.StudsLbl.Position = UDim2.new(0, x, 0, y + h + 2); espUI.StudsLbl.Visible = true else espUI.StudsLbl.Visible = false end
					else
						espUI.BoxFrame.Visible = false; espUI.NameLbl.Visible = false; espUI.HPBarBg.Visible = false; espUI.StudsLbl.Visible = false
					end
				else
					espUI.Highlight.Enabled = false; espUI.BoxFrame.Visible = false; espUI.NameLbl.Visible = false; espUI.HPBarBg.Visible = false; espUI.StudsLbl.Visible = false
				end
			else
				espUI.Highlight.Enabled = false; espUI.BoxFrame.Visible = false; espUI.NameLbl.Visible = false; espUI.HPBarBg.Visible = false; espUI.StudsLbl.Visible = false
			end
		end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if not ScreenGui or not ScreenGui.Parent then return end
	if InfJumpEnabled and LocalPlayer.Character then
		local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end) end
	end
end)
