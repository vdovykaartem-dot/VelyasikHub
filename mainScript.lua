-- =================================================================
-- ВЕЛЯСІК MENU v2.3 (Оновлено ESP, Admin System, UI, Mobile Fly)
-- =================================================================
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ===================== СИСТЕМА ДОСТУПУ (АДМІНИ ТА WHITELIST) =====================
local Admins = {
	[8015934144] = true,
	[1561052387] = true,
	[2399044719] = true
}

local scriptAccessFile = "VeliasikScriptAccess.json"
local ScriptWhitelist = {}

if isfile and readfile and isfile(scriptAccessFile) then
	local s, data = pcall(function() return HttpService:JSONDecode(readfile(scriptAccessFile)) end)
	if s and type(data) == "table" then
		ScriptWhitelist = data
	end
end

local function saveScriptWhitelist()
	if writefile then
		pcall(function()
			writefile(scriptAccessFile, HttpService:JSONEncode(ScriptWhitelist))
		end)
	end
end

local isAccessAllowed = false
if Admins[LocalPlayer.UserId] or ScriptWhitelist[LocalPlayer.Name] then
	isAccessAllowed = true
end

if not isAccessAllowed then
	LocalPlayer:Kick("You don't have access to this script.")
	return
end

-- ===================== АНТИ-ПОВТОРНИЙ ЗАПУСК =====================
local existingGui = CoreGui:FindFirstChild("VeliasikMenuGui") or LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("VeliasikMenuGui")
if existingGui then
	existingGui:Destroy()
	task.wait(0.2)
end

-- ===================== ЗБЕРЕЖЕННЯ КОНФІГІВ =====================
local espConfigFile = "VeliasikESPConfig.json"
local teamWhitelistFile = "VeliasikTeamWhitelist.json"
local playerConfigFile = "VeliasikPlayerConfig.json"

local ESPSettings = {
	Master = false,
	Highlight = true,
	Box = false,
	Name = false,
	HP = false,
	Studs = false,
	Color = {R = 255, G = 50, B = 50}
}

local PlayerSettings = {
	FlySpeed = 50
}

if isfile and readfile and isfile(espConfigFile) then
	local s, data = pcall(function() return HttpService:JSONDecode(readfile(espConfigFile)) end)
	if s and type(data) == "table" then
		for k, v in pairs(data) do
			if ESPSettings[k] ~= nil then ESPSettings[k] = v end
		end
	end
end

if isfile and readfile and isfile(playerConfigFile) then
	local s, data = pcall(function() return HttpService:JSONDecode(readfile(playerConfigFile)) end)
	if s and type(data) == "table" then
		if data.FlySpeed ~= nil then PlayerSettings.FlySpeed = data.FlySpeed end
	end
end

local function saveESPConfig()
	if writefile then pcall(function() writefile(espConfigFile, HttpService:JSONEncode(ESPSettings)) end) end
end

local function savePlayerConfig()
	if writefile then pcall(function() writefile(playerConfigFile, HttpService:JSONEncode(PlayerSettings)) end) end
end

local ESPColor = Color3.fromRGB(ESPSettings.Color.R, ESPSettings.Color.G, ESPSettings.Color.B)

local WhitelistedNames = {} -- Для Aimbot Team Check
if isfile and readfile and isfile(teamWhitelistFile) then
	local s, data = pcall(function() return HttpService:JSONDecode(readfile(teamWhitelistFile)) end)
	if s and type(data) == "table" then
		WhitelistedNames = data
	end
end

local function saveTeamWhitelist()
	if writefile then pcall(function() writefile(teamWhitelistFile, HttpService:JSONEncode(WhitelistedNames)) end) end
end

if setfpscap then setfpscap(9999) end

-- Змінні стану
local HitboxEnabled = false
local HitboxSize = 10
local KickStuffEnabled = true

local SpeedEnabled = false
local TargetSpeed = 16
local NoclipEnabled = false
local InfJumpEnabled = false
local FlyEnabled = false

local AimbotEnabled = false
local AimbotTarget = "Head"
local WallCheckEnabled = true
local FOVEnabled = false
local FOVRadius = 180
local Smoothness = 0

local NoFogEnabled = false
local FullbrightEnabled = false
local FOVChangerEnabled = false
local CustomFOV = 90
local FPSUnlockerEnabled = true
local CamUnlockerEnabled = false

local FreeCamEnabled = false
local FreezeDuringEnabled = false
local FC_Speed = 60
local fwdDown, bwdDown = false, false

local OriginalSizes = {}
local OriginalCollisions = {}
local OriginalNoclipStates = {}

-- ===================== ІНТЕРФЕЙС =====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VeliasikMenuGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local success, err = pcall(function() ScreenGui.Parent = CoreGui end)
if not success then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Folder для малювання 2D ESP
local ESP_Folder = Instance.new("Folder", ScreenGui)
ESP_Folder.Name = "ESP_Drawings"
local ESP_Elements = {}

local function makeDraggable(dragPart, targetFrame)
	local dragging, dragStart, startPos
	dragPart.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; dragStart = input.Position; startPos = targetFrame.Position
		end
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

-- КНОПКА ВІДКРИТТЯ
local OpenButton = Instance.new("TextButton")
OpenButton.Size = UDim2.new(0, 50, 0, 50)
OpenButton.Position = UDim2.new(0.85, 0, 0.05, 0)
OpenButton.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
OpenButton.Text = "⚡"
OpenButton.TextSize = 24
OpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
OpenButton.Font = Enum.Font.GothamBold
OpenButton.Active = true
OpenButton.ZIndex = 100
OpenButton.Parent = ScreenGui
Instance.new("UICorner", OpenButton).CornerRadius = UDim.new(1, 0)
makeDraggable(OpenButton, OpenButton)

local ButtonStroke = Instance.new("UIStroke", OpenButton)
ButtonStroke.Thickness = 2.5
ButtonStroke.Transparency = 0

task.spawn(function()
	while OpenButton and OpenButton.Parent do
		local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
		local colors = {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255), Color3.fromRGB(255,255,0), Color3.fromRGB(255,0,255)}
		for _, c in ipairs(colors) do
			if not ButtonStroke or not ButtonStroke.Parent then break end
			local t = TweenService:Create(ButtonStroke, tweenInfo, {Color = c}); t:Play(); t.Completed:Wait()
		end
	end
end)

-- ГОЛОВНИЙ ІНТЕРФЕЙС
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 540, 0, 360)
MainFrame.Position = UDim2.new(0.5, -270, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.ClipsDescendants = true
MainFrame.ZIndex = 1
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(45, 45, 45)

local TopBar = Instance.new("Frame", MainFrame)
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TopBar.BorderSizePixel = 0
TopBar.ZIndex = 2
Instance.new("UICorner", TopBar).CornerRadius = UDim.new(0, 10)
makeDraggable(TopBar, MainFrame)

local TitleText = Instance.new("TextLabel", TopBar)
TitleText.Size = UDim2.new(1, -50, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "Велясік Menu v2.3"
TitleText.Font = Enum.Font.GothamBold
TitleText.TextColor3 = Color3.fromRGB(240, 240, 240)
TitleText.TextSize = 16
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.ZIndex = 3

local CloseBtn = Instance.new("TextButton", TopBar)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 14
CloseBtn.ZIndex = 4
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
	local tw = TweenService:Create(MainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 0, 0, 0)})
	tw:Play() tw.Completed:Wait()
	MainFrame.Visible = false
	MainFrame.Size = UDim2.new(0, 540, 0, 360)
end)

OpenButton.MouseButton1Click:Connect(function()
	if MainFrame.Visible then
		MainFrame.Visible = false
	else
		MainFrame.Size = UDim2.new(0, 0, 0, 0)
		MainFrame.Visible = true
		TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 540, 0, 360)}):Play()
	end
end)

local TabButtonsFrame = Instance.new("ScrollingFrame", MainFrame)
TabButtonsFrame.Size = UDim2.new(0, 130, 1, -45)
TabButtonsFrame.Position = UDim2.new(0, 0, 0, 45)
TabButtonsFrame.BackgroundTransparency = 1
TabButtonsFrame.ScrollBarThickness = 2
TabButtonsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
TabButtonsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
TabButtonsFrame.ZIndex = 2

local TabListLayout = Instance.new("UIListLayout", TabButtonsFrame)
TabListLayout.Padding = UDim.new(0, 5)
TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local PagesContainer = Instance.new("Frame", MainFrame)
PagesContainer.Size = UDim2.new(1, -135, 1, -50)
PagesContainer.Position = UDim2.new(0, 135, 0, 48)
PagesContainer.BackgroundTransparency = 1
PagesContainer.ZIndex = 2

local tabs = {}
local function createTab(name, isRed)
	local TabBtn = Instance.new("TextButton", TabButtonsFrame)
	TabBtn.Size = UDim2.new(1, -10, 0, 36)
	TabBtn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	TabBtn.Text = name
	TabBtn.Font = Enum.Font.GothamMedium
	TabBtn.TextColor3 = isRed and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(160, 160, 160)
	TabBtn.TextSize = 13
	TabBtn.ZIndex = 3
	Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

	local Page = Instance.new("ScrollingFrame", PagesContainer)
	Page.Size = UDim2.new(1, 0, 1, 0)
	Page.BackgroundTransparency = 1
	Page.ScrollBarThickness = 3
	Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Page.CanvasSize = UDim2.new(0, 0, 0, 0)
	Page.Visible = false
	Page.ZIndex = 2
	
	local PageLayout = Instance.new("UIListLayout", Page)
	PageLayout.Padding = UDim.new(0, 8)
	PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	TabBtn.MouseButton1Click:Connect(function()
		for _, t in pairs(tabs) do
			t.page.Visible = false
			TweenService:Create(t.btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(24, 24, 24), TextColor3 = t.isRed and Color3.fromRGB(255, 80, 80) or Color3.fromRGB(160, 160, 160)}):Play()
		end
		Page.Visible = true
		TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(45, 45, 45), TextColor3 = isRed and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)}):Play()
	end)

	table.insert(tabs, {btn = TabBtn, page = Page, isRed = isRed})
	if #tabs == 1 then
		Page.Visible = true
		TabBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
		TabBtn.TextColor3 = isRed and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
	end
	return Page
end

-- UI Хелпери
local function createToggle(parent, text, defaultState, callback)
	local Holder = Instance.new("Frame", parent)
	Holder.Size = UDim2.new(1, -12, 0, 42)
	Holder.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 6)

	local Label = Instance.new("TextLabel", Holder)
	Label.Size = UDim2.new(0.7, 0, 1, 0)
	Label.Position = UDim2.new(0.04, 0, 0, 0)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.Font = Enum.Font.GothamMedium
	Label.TextColor3 = Color3.fromRGB(220, 220, 220)
	Label.TextSize = 13
	Label.TextXAlignment = Enum.TextXAlignment.Left

	local Button = Instance.new("TextButton", Holder)
	Button.Size = UDim2.new(0, 36, 0, 22)
	Button.Position = UDim2.new(1, -44, 0.5, -11)
	Button.BackgroundColor3 = defaultState and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(50, 50, 50)
	Button.Text = ""
	Instance.new("UICorner", Button).CornerRadius = UDim.new(1, 0)

	local Circle = Instance.new("Frame", Button)
	Circle.Size = UDim2.new(0, 18, 0, 18)
	Circle.Position = defaultState and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
	Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Circle.Interactable = false
	Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

	Button.MouseButton1Click:Connect(function()
		defaultState = not defaultState
		local targetColor = defaultState and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(50, 50, 50)
		local targetPos = defaultState and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
		TweenService:Create(Button, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
		TweenService:Create(Circle, TweenInfo.new(0.15), {Position = targetPos}):Play()
		if callback then callback(defaultState) end
	end)
end

local function createBox(parent, text, default, min, max, callback)
	local Holder = Instance.new("Frame", parent)
	Holder.Size = UDim2.new(1, -12, 0, 60)
	Holder.BackgroundTransparency = 1

	local Label = Instance.new("TextLabel", Holder)
	Label.Size = UDim2.new(1, 0, 0, 20)
	Label.BackgroundTransparency = 1
	Label.Text = text
	Label.Font = Enum.Font.GothamMedium
	Label.TextColor3 = Color3.fromRGB(200, 200, 200)
	Label.TextSize = 12
	Label.TextXAlignment = Enum.TextXAlignment.Left

	local Box = Instance.new("TextBox", Holder)
	Box.Size = UDim2.new(1, 0, 0, 32)
	Box.Position = UDim2.new(0, 0, 0, 24)
	Box.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	Box.Text = tostring(default)
	Box.Font = Enum.Font.GothamMedium
	Box.TextColor3 = Color3.fromRGB(255, 255, 255)
	Box.TextSize = 13
	Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 6)

	Box.FocusLost:Connect(function()
		local n = tonumber(Box.Text) or default
		if min and max then n = math.clamp(n, min, max) end
		Box.Text = tostring(n)
		if callback then callback(n) end
	end)
end

local function createButtonUI(parent, text, callback)
	local Btn = Instance.new("TextButton", parent)
	Btn.Size = UDim2.new(1, -12, 0, 36)
	Btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	Btn.Text = text
	Btn.Font = Enum.Font.GothamMedium
	Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	Btn.TextSize = 13
	Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
	Btn.MouseButton1Click:Connect(function() if callback then callback() end end)
end

local function createSectionTitle(parent, text)
	local Lbl = Instance.new("TextLabel", parent)
	Lbl.Size = UDim2.new(1, -12, 0, 25)
	Lbl.BackgroundTransparency = 1
	Lbl.Text = text
	Lbl.Font = Enum.Font.GothamBold
	Lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	Lbl.TextSize = 14
	Lbl.TextXAlignment = Enum.TextXAlignment.Left
end

-- ===================== СТВОРЕННЯ ВКЛАДОК =====================
local TabAdmin = nil
if Admins[LocalPlayer.UserId] then
	TabAdmin = createTab("ADMIN", true)
end
local TabInfo = createTab("Info")
local TabMain = createTab("Main")
local TabVisuals = createTab("Visuals")
local TabPlayer = createTab("Player")
local TabCombat = createTab("Combat")
local TabTeamCheck = createTab("Team Check")
local TabFreeCam = createTab("Free Camera")

-- ===================== ADMIN ВКЛАДКА =====================
if TabAdmin then
	local ConfirmationPopup = Instance.new("Frame", MainFrame)
	ConfirmationPopup.Size = UDim2.new(1, 0, 1, 0)
	ConfirmationPopup.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ConfirmationPopup.BackgroundTransparency = 0.3
	ConfirmationPopup.Visible = false
	ConfirmationPopup.ZIndex = 10
	
	local ConfirmBox = Instance.new("Frame", ConfirmationPopup)
	ConfirmBox.Size = UDim2.new(0, 300, 0, 120)
	ConfirmBox.Position = UDim2.new(0.5, -150, 0.5, -60)
	ConfirmBox.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
	Instance.new("UICorner", ConfirmBox).CornerRadius = UDim.new(0, 8)
	Instance.new("UIStroke", ConfirmBox).Color = Color3.fromRGB(60, 60, 60)
	
	local ConfirmText = Instance.new("TextLabel", ConfirmBox)
	ConfirmText.Size = UDim2.new(1, -20, 0, 60)
	ConfirmText.Position = UDim2.new(0, 10, 0, 10)
	ConfirmText.BackgroundTransparency = 1
	ConfirmText.Text = "Are you sure?"
	ConfirmText.Font = Enum.Font.GothamMedium
	ConfirmText.TextColor3 = Color3.fromRGB(255, 255, 255)
	ConfirmText.TextSize = 14
	ConfirmText.TextWrapped = true
	
	local BtnYes = Instance.new("TextButton", ConfirmBox)
	BtnYes.Size = UDim2.new(0.4, 0, 0, 30)
	BtnYes.Position = UDim2.new(0.06, 0, 0.65, 0)
	BtnYes.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
	BtnYes.Text = "Yes"
	BtnYes.Font = Enum.Font.GothamBold
	BtnYes.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", BtnYes).CornerRadius = UDim.new(0, 6)
	
	local BtnNo = Instance.new("TextButton", ConfirmBox)
	BtnNo.Size = UDim2.new(0.4, 0, 0, 30)
	BtnNo.Position = UDim2.new(0.54, 0, 0.65, 0)
	BtnNo.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
	BtnNo.Text = "No"
	BtnNo.Font = Enum.Font.GothamBold
	BtnNo.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", BtnNo).CornerRadius = UDim.new(0, 6)

	createSectionTitle(TabAdmin, "Add/Remove Players:")
	
	local SearchFrame = Instance.new("Frame", TabAdmin)
	SearchFrame.Size = UDim2.new(1, -12, 0, 42)
	SearchFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	Instance.new("UICorner", SearchFrame).CornerRadius = UDim.new(0, 6)
	
	local SearchBox = Instance.new("TextBox", SearchFrame)
	SearchBox.Size = UDim2.new(1, -20, 1, 0)
	SearchBox.Position = UDim2.new(0, 10, 0, 0)
	SearchBox.BackgroundTransparency = 1
	SearchBox.Text = ""
	SearchBox.PlaceholderText = "Enter Username to search..."
	SearchBox.Font = Enum.Font.GothamMedium
	SearchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	SearchBox.TextSize = 13
	SearchBox.TextXAlignment = Enum.TextXAlignment.Left
	
	local ResultFrame = Instance.new("Frame", TabAdmin)
	ResultFrame.Size = UDim2.new(1, -12, 0, 50)
	ResultFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	ResultFrame.Visible = false
	Instance.new("UICorner", ResultFrame).CornerRadius = UDim.new(0, 6)
	
	local ResAvatar = Instance.new("ImageLabel", ResultFrame)
	ResAvatar.Size = UDim2.new(0, 40, 0, 40)
	ResAvatar.Position = UDim2.new(0, 5, 0, 5)
	ResAvatar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	Instance.new("UICorner", ResAvatar).CornerRadius = UDim.new(1, 0)
	
	local ResName = Instance.new("TextLabel", ResultFrame)
	ResName.Size = UDim2.new(0.6, 0, 1, 0)
	ResName.Position = UDim2.new(0, 55, 0, 0)
	ResName.BackgroundTransparency = 1
	ResName.Font = Enum.Font.GothamBold
	ResName.TextColor3 = Color3.fromRGB(255, 255, 255)
	ResName.TextSize = 14
	ResName.TextXAlignment = Enum.TextXAlignment.Left
	
	local ResBtn = Instance.new("TextButton", ResultFrame)
	ResBtn.Size = UDim2.new(0, 36, 0, 36)
	ResBtn.Position = UDim2.new(1, -42, 0.5, -18)
	ResBtn.Font = Enum.Font.GothamBold
	ResBtn.TextSize = 18
	ResBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	Instance.new("UICorner", ResBtn).CornerRadius = UDim.new(0, 6)
	
	local currentTargetName, currentTargetIsWhitelist = "", false
	
	local function refreshWhitelistUI()
		for _, child in pairs(TabAdmin:GetChildren()) do
			if child:IsA("Frame") and child.Name == "WL_Entry" then child:Destroy() end
		end
		for name, _ in pairs(ScriptWhitelist) do
			local Entry = Instance.new("Frame", TabAdmin)
			Entry.Name = "WL_Entry"
			Entry.Size = UDim2.new(1, -12, 0, 30)
			Entry.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
			Instance.new("UICorner", Entry).CornerRadius = UDim.new(0, 6)
			
			local Lbl = Instance.new("TextLabel", Entry)
			Lbl.Size = UDim2.new(1, -10, 1, 0)
			Lbl.Position = UDim2.new(0, 10, 0, 0)
			Lbl.BackgroundTransparency = 1
			Lbl.Text = name
			Lbl.Font = Enum.Font.GothamMedium
			Lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
			Lbl.TextSize = 13
			Lbl.TextXAlignment = Enum.TextXAlignment.Left
		end
	end
	
	createSectionTitle(TabAdmin, "Whitelisted Players:")
	refreshWhitelistUI()
	
	SearchBox.FocusLost:Connect(function(enterPressed)
		if enterPressed and SearchBox.Text ~= "" then
			local targetName = SearchBox.Text
			task.spawn(function()
				local s, targetId = pcall(function() return Players:GetUserIdFromNameAsync(targetName) end)
				if s and targetId then
					ResultFrame.Visible = true
					ResName.Text = targetName
					ResAvatar.Image = "rbxthumb://type=AvatarHeadShot&id="..targetId.."&w=150&h=150"
					currentTargetName = targetName
					
					if Admins[targetId] then
						ResBtn.Text = "👑"
						ResBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
						ResBtn.Interactable = false
					elseif ScriptWhitelist[targetName] then
						ResBtn.Text = "-"
						ResBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
						ResBtn.Interactable = true
						currentTargetIsWhitelist = true
					else
						ResBtn.Text = "+"
						ResBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
						ResBtn.Interactable = true
						currentTargetIsWhitelist = false
					end
				else
					ResultFrame.Visible = false
				end
			end)
		end
	end)
	
	local confirmConnectionYes, confirmConnectionNo
	
	ResBtn.MouseButton1Click:Connect(function()
		ConfirmText.Text = currentTargetIsWhitelist and ("Remove " .. currentTargetName .. " from whitelist?") or ("Add " .. currentTargetName .. " to whitelist?")
		ConfirmationPopup.Visible = true
		
		if confirmConnectionYes then confirmConnectionYes:Disconnect() end
		if confirmConnectionNo then confirmConnectionNo:Disconnect() end
		
		confirmConnectionYes = BtnYes.MouseButton1Click:Connect(function()
			if currentTargetIsWhitelist then
				ScriptWhitelist[currentTargetName] = nil
				ResBtn.Text = "+"
				ResBtn.BackgroundColor3 = Color3.fromRGB(50, 205, 50)
				currentTargetIsWhitelist = false
			else
				ScriptWhitelist[currentTargetName] = true
				ResBtn.Text = "-"
				ResBtn.BackgroundColor3 = Color3.fromRGB(210, 50, 50)
				currentTargetIsWhitelist = true
			end
			saveScriptWhitelist()
			refreshWhitelistUI()
			ConfirmationPopup.Visible = false
		end)
		
		confirmConnectionNo = BtnNo.MouseButton1Click:Connect(function() ConfirmationPopup.Visible = false end)
	end)
end

-- ===================== INFO ВКЛАДКА =====================
local InfoHolder = Instance.new("Frame", TabInfo)
InfoHolder.Size = UDim2.new(1, -12, 0, 180)
InfoHolder.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
Instance.new("UICorner", InfoHolder).CornerRadius = UDim.new(0, 8)

local AvatarImg = Instance.new("ImageLabel", InfoHolder)
AvatarImg.Size = UDim2.new(0, 60, 0, 60)
AvatarImg.Position = UDim2.new(0, 15, 0, 15)
AvatarImg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
AvatarImg.Image = "rbxthumb://type=AvatarHeadShot&id="..LocalPlayer.UserId.."&w=150&h=150"
Instance.new("UICorner", AvatarImg).CornerRadius = UDim.new(1, 0)

local NameLbl = Instance.new("TextLabel", InfoHolder)
NameLbl.Size = UDim2.new(0, 200, 0, 25)
NameLbl.Position = UDim2.new(0, 85, 0, 20)
NameLbl.BackgroundTransparency = 1
NameLbl.Text = LocalPlayer.DisplayName
NameLbl.Font = Enum.Font.GothamBold
NameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
NameLbl.TextSize = 18
NameLbl.TextXAlignment = Enum.TextXAlignment.Left

local UserLbl = Instance.new("TextLabel", InfoHolder)
UserLbl.Size = UDim2.new(0, 200, 0, 20)
UserLbl.Position = UDim2.new(0, 85, 0, 45)
UserLbl.BackgroundTransparency = 1
UserLbl.Text = "@" .. LocalPlayer.Name
UserLbl.Font = Enum.Font.GothamMedium
UserLbl.TextColor3 = Color3.fromRGB(150, 150, 150)
UserLbl.TextSize = 14
UserLbl.TextXAlignment = Enum.TextXAlignment.Left

local StatsFrame = Instance.new("Frame", InfoHolder)
StatsFrame.Size = UDim2.new(1, -30, 0, 80)
StatsFrame.Position = UDim2.new(0, 15, 0, 85)
StatsFrame.BackgroundTransparency = 1
local StatsLayout = Instance.new("UIListLayout", StatsFrame)
StatsLayout.Padding = UDim.new(0, 4)

local function makeStatRow(text)
	local Lbl = Instance.new("TextLabel", StatsFrame)
	Lbl.Size = UDim2.new(1, 0, 0, 16)
	Lbl.BackgroundTransparency = 1
	Lbl.Text = text
	Lbl.Font = Enum.Font.GothamMedium
	Lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
	Lbl.TextSize = 13
	Lbl.TextXAlignment = Enum.TextXAlignment.Left
	return Lbl
end

local FPSLabel = makeStatRow("FPS: Calculating...")
local PingLabel = makeStatRow("Ping: Calculating...")
makeStatRow("Player ID: " .. LocalPlayer.UserId)
makeStatRow("Place ID: " .. game.PlaceId)

-- ===================== MAIN ВКЛАДКА (ESP ТА ІНШЕ) =====================
local ESPHeader = Instance.new("Frame", TabMain)
ESPHeader.Size = UDim2.new(1, -12, 0, 42)
ESPHeader.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
Instance.new("UICorner", ESPHeader).CornerRadius = UDim.new(0, 6)

local ESPLabel = Instance.new("TextLabel", ESPHeader)
ESPLabel.Size = UDim2.new(0.6, 0, 1, 0)
ESPLabel.Position = UDim2.new(0.04, 0, 0, 0)
ESPLabel.BackgroundTransparency = 1
ESPLabel.Text = "ESP Toggle"
ESPLabel.Font = Enum.Font.GothamMedium
ESPLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
ESPLabel.TextSize = 13
ESPLabel.TextXAlignment = Enum.TextXAlignment.Left

local ESPBtn = Instance.new("TextButton", ESPHeader)
ESPBtn.Size = UDim2.new(0, 36, 0, 22)
ESPBtn.Position = UDim2.new(1, -85, 0.5, -11)
ESPBtn.BackgroundColor3 = ESPSettings.Master and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(50, 50, 50)
ESPBtn.Text = ""
Instance.new("UICorner", ESPBtn).CornerRadius = UDim.new(1, 0)

local ESPCircle = Instance.new("Frame", ESPBtn)
ESPCircle.Size = UDim2.new(0, 18, 0, 18)
ESPCircle.Position = ESPSettings.Master and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
ESPCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
ESPCircle.Interactable = false
Instance.new("UICorner", ESPCircle).CornerRadius = UDim.new(1, 0)

ESPBtn.MouseButton1Click:Connect(function()
	ESPSettings.Master = not ESPSettings.Master
	local targetColor = ESPSettings.Master and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(50, 50, 50)
	local targetPos = ESPSettings.Master and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
	TweenService:Create(ESPBtn, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
	TweenService:Create(ESPCircle, TweenInfo.new(0.15), {Position = targetPos}):Play()
	saveESPConfig()
end)

local ESPArrow = Instance.new("TextButton", ESPHeader)
ESPArrow.Size = UDim2.new(0, 30, 0, 30)
ESPArrow.Position = UDim2.new(1, -35, 0.5, -15)
ESPArrow.BackgroundTransparency = 1
ESPArrow.Text = "▼"
ESPArrow.Font = Enum.Font.GothamBold
ESPArrow.TextColor3 = Color3.fromRGB(255, 255, 255)
ESPArrow.TextSize = 14

local ESPContainer = Instance.new("Frame", TabMain)
ESPContainer.Size = UDim2.new(1, 0, 0, 0)
ESPContainer.BackgroundTransparency = 1
ESPContainer.ClipsDescendants = true

local ESPLayout = Instance.new("UIListLayout", ESPContainer)
ESPLayout.Padding = UDim.new(0, 8)

local espExpanded = false
ESPArrow.MouseButton1Click:Connect(function()
	espExpanded = not espExpanded
	if espExpanded then
		TweenService:Create(ESPContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, ESPLayout.AbsoluteContentSize.Y)}):Play()
		TweenService:Create(ESPArrow, TweenInfo.new(0.3), {Rotation = 180}):Play()
	else
		TweenService:Create(ESPContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 0)}):Play()
		TweenService:Create(ESPArrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
	end
end)

ESPLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	if espExpanded then
		ESPContainer.Size = UDim2.new(1, 0, 0, ESPLayout.AbsoluteContentSize.Y)
	end
end)

createToggle(ESPContainer, "ESP: Highlight", ESPSettings.Highlight, function(s) ESPSettings.Highlight = s; saveESPConfig() end)
createToggle(ESPContainer, "ESP: Box", ESPSettings.Box, function(s) ESPSettings.Box = s; saveESPConfig() end)
createToggle(ESPContainer, "ESP: Name", ESPSettings.Name, function(s) ESPSettings.Name = s; saveESPConfig() end)
createToggle(ESPContainer, "ESP: HP", ESPSettings.HP, function(s) ESPSettings.HP = s; saveESPConfig() end)
createToggle(ESPContainer, "ESP: Studs", ESPSettings.Studs, function(s) ESPSettings.Studs = s; saveESPConfig() end)

local PaletteHolder = Instance.new("Frame", ESPContainer)
PaletteHolder.Size = UDim2.new(1, -12, 0, 65)
PaletteHolder.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
Instance.new("UICorner", PaletteHolder).CornerRadius = UDim.new(0, 6)

local PaletteTitle = Instance.new("TextLabel", PaletteHolder)
PaletteTitle.Size = UDim2.new(1, 0, 0, 25)
PaletteTitle.Position = UDim2.new(0.04, 0, 0, 0)
PaletteTitle.BackgroundTransparency = 1
PaletteTitle.Text = "ESP Color"
PaletteTitle.Font = Enum.Font.GothamMedium
PaletteTitle.TextColor3 = Color3.fromRGB(220, 220, 220)
PaletteTitle.TextSize = 12
PaletteTitle.TextXAlignment = Enum.TextXAlignment.Left

local ColorsContainer = Instance.new("Frame", PaletteHolder)
ColorsContainer.Size = UDim2.new(1, -20, 0, 30)
ColorsContainer.Position = UDim2.new(0, 10, 0, 25)
ColorsContainer.BackgroundTransparency = 1
local ColorLayout = Instance.new("UIListLayout", ColorsContainer)
ColorLayout.FillDirection = Enum.FillDirection.Horizontal
ColorLayout.Padding = UDim.new(0, 10)

local colorButtons = {}
local function addColorBtn(color)
	local matches = (math.abs(ESPColor.R - color.R) < 0.01 and math.abs(ESPColor.G - color.G) < 0.01 and math.abs(ESPColor.B - color.B) < 0.01)

	local btn = Instance.new("TextButton", ColorsContainer)
	btn.Size = matches and UDim2.new(0, 36, 0, 36) or UDim2.new(0, 30, 0, 30)
	btn.BackgroundColor3 = color
	btn.Text = ""
	btn.Rotation = matches and 5 or 0
	Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)
	
	local stroke = Instance.new("UIStroke", btn)
	stroke.Thickness = matches and 3 or 0
	stroke.Color = Color3.fromRGB(255, 255, 255)
	
	table.insert(colorButtons, {Button = btn, Stroke = stroke, Color = color})
	
	btn.MouseButton1Click:Connect(function()
		ESPColor = color
		ESPSettings.Color = {R = math.floor(color.R*255), G = math.floor(color.G*255), B = math.floor(color.B*255)}
		saveESPConfig()
		
		for _, cb in ipairs(colorButtons) do
			local isCurrent = (math.abs(cb.Color.R - color.R) < 0.01 and math.abs(cb.Color.G - color.G) < 0.01 and math.abs(cb.Color.B - color.B) < 0.01)
			if isCurrent then
				TweenService:Create(cb.Stroke, TweenInfo.new(0.15), {Thickness = 3}):Play()
				local t1 = TweenService:Create(cb.Button, TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {Size = UDim2.new(0, 40, 0, 40), Rotation = 10})
				t1:Play()
				t1.Completed:Connect(function()
					TweenService:Create(cb.Button, TweenInfo.new(0.2, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {Size = UDim2.new(0, 36, 0, 36), Rotation = 5}):Play()
				end)
			else
				TweenService:Create(cb.Stroke, TweenInfo.new(0.2), {Thickness = 0}):Play()
				TweenService:Create(cb.Button, TweenInfo.new(0.2), {Size = UDim2.new(0, 30, 0, 30), Rotation = 0}):Play()
			end
		end
	end)
end

addColorBtn(Color3.fromRGB(255, 50, 50))
addColorBtn(Color3.fromRGB(50, 255, 50))
addColorBtn(Color3.fromRGB(50, 150, 255))
addColorBtn(Color3.fromRGB(255, 255, 50))
addColorBtn(Color3.fromRGB(255, 50, 255))
addColorBtn(Color3.fromRGB(255, 255, 255))

createToggle(TabMain, "Hitbox Expander", HitboxEnabled, function(s) HitboxEnabled = s end)
createBox(TabMain, "Hitbox Size (Max 30)", 10, 1, 30, function(v) HitboxSize = v end)
createToggle(TabMain, "Kick Security (Anti-Dev)", KickStuffEnabled, function(s) KickStuffEnabled = s end)

-- ===================== VISUALS, PLAYER, COMBAT =====================
createToggle(TabVisuals, "No Fog", NoFogEnabled, function(s) NoFogEnabled = s end)
createToggle(TabVisuals, "Fullbright", FullbrightEnabled, function(s) FullbrightEnabled = s end)
createToggle(TabVisuals, "FOV Changer", FOVChangerEnabled, function(s) 
	FOVChangerEnabled = s; if not s then Camera.FieldOfView = 70 end
end)
createBox(TabVisuals, "Custom FOV (10-120)", 90, 10, 120, function(v) CustomFOV = v end)

createButtonUI(TabVisuals, "Serverhop", function()
	local servers = {}
	local req = (syn and syn.request) or request or http_request or (fluxus and fluxus.request)
	if req then
		pcall(function()
			local response = req({Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100", Method = "GET"})
			if response and response.Body then
				local body = HttpService:JSONDecode(response.Body)
				for _, v in ipairs(body.data) do
					if v.playing < v.maxPlayers and v.id ~= game.JobId then table.insert(servers, v.id) end
				end
			end
		end)
		if #servers > 0 then TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer); return end
	end
	TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
createButtonUI(TabVisuals, "Rejoin Server", function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)

createToggle(TabVisuals, "FPS Unlocker", FPSUnlockerEnabled, function(s) FPSUnlockerEnabled = s; if setfpscap then setfpscap(s and 9999 or 60) end end)
createToggle(TabVisuals, "Camera Unlocker (Max 1000)", CamUnlockerEnabled, function(s) CamUnlockerEnabled = s; LocalPlayer.CameraMaxZoomDistance = s and 1000 or 128 end)

createBox(TabPlayer, "WalkSpeed Value", 16, 1, 1000, function(v) TargetSpeed = v end)
createToggle(TabPlayer, "Custom WalkSpeed", SpeedEnabled, function(s) 
	SpeedEnabled = s 
	if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
	end
end)
createToggle(TabPlayer, "Noclip", NoclipEnabled, function(s) 
	NoclipEnabled = s 
	if not s and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") and OriginalNoclipStates[part] ~= nil then part.CanCollide = OriginalNoclipStates[part] end
		end
		table.clear(OriginalNoclipStates)
	end
end)
createToggle(TabPlayer, "Infinite Jump", InfJumpEnabled, function(s) InfJumpEnabled = s end)
createToggle(TabPlayer, "Fly", FlyEnabled, function(s) FlyEnabled = s end)
createBox(TabPlayer, "Fly Speed (1-200)", PlayerSettings.FlySpeed, 1, 200, function(v) 
	PlayerSettings.FlySpeed = v; savePlayerConfig() 
end)

createToggle(TabCombat, "Aimbot", AimbotEnabled, function(s) AimbotEnabled = s end)

local TargetHolder = Instance.new("Frame", TabCombat)
TargetHolder.Size = UDim2.new(1, -12, 0, 42)
TargetHolder.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
Instance.new("UICorner", TargetHolder).CornerRadius = UDim.new(0, 6)

local TargetBtn = Instance.new("TextButton", TargetHolder)
TargetBtn.Size = UDim2.new(1, 0, 1, 0)
TargetBtn.BackgroundTransparency = 1
TargetBtn.Text = "Target Part: Head"
TargetBtn.Font = Enum.Font.GothamMedium
TargetBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
TargetBtn.TextSize = 13
TargetBtn.MouseButton1Click:Connect(function()
	AimbotTarget = (AimbotTarget == "Head") and "Torso" or "Head"
	TargetBtn.Text = "Target Part: " .. AimbotTarget
end)

createToggle(TabCombat, "Wall Check", WallCheckEnabled, function(s) WallCheckEnabled = s end)

local FOVCircleUI = Instance.new("Frame", ScreenGui)
FOVCircleUI.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
FOVCircleUI.Position = UDim2.new(0.5, -FOVRadius, 0.5, -FOVRadius)
FOVCircleUI.BackgroundTransparency = 1
FOVCircleUI.Visible = false
local UIStroke = Instance.new("UIStroke", FOVCircleUI)
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 1.5
Instance.new("UICorner", FOVCircleUI).CornerRadius = UDim.new(1, 0)

createToggle(TabCombat, "FOV Circle", FOVEnabled, function(s) FOVEnabled = s; FOVCircleUI.Visible = s end)
createBox(TabCombat, "FOV Size (20-400)", 180, 20, 400, function(v) 
	FOVRadius = v
	if FOVCircleUI then
		FOVCircleUI.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
		FOVCircleUI.Position = UDim2.new(0.5, -FOVRadius, 0.5, -FOVRadius)
	end
end)
createBox(TabCombat, "Aimbot Smoothness (0-100)", 0, 0, 100, function(v) Smoothness = v end)

-- ===================== TEAM CHECK =====================
local function refreshTeamCheckList()
	for _, child in pairs(TabTeamCheck:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			local btn = Instance.new("TextButton", TabTeamCheck)
			btn.Size = UDim2.new(1, -12, 0, 36)
			local isWhitelisted = WhitelistedNames[p.Name] == true
			btn.BackgroundColor3 = isWhitelisted and Color3.fromRGB(50, 205, 50) or Color3.fromRGB(210, 50, 50)
			btn.Text = p.Name
			btn.Font = Enum.Font.GothamMedium
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextSize = 13
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
			
			btn.MouseButton1Click:Connect(function()
				if WhitelistedNames[p.Name] then
					WhitelistedNames[p.Name] = nil
					TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(210, 50, 50)}):Play()
				else
					WhitelistedNames[p.Name] = true
					TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 205, 50)}):Play()
				end
				saveTeamWhitelist()
			end)
		end
	end
end

for _, t in pairs(tabs) do
	if t.page == TabTeamCheck then t.btn.MouseButton1Click:Connect(refreshTeamCheckList) end
end

-- ===================== FREE CAM =====================
local FCMobileUI = Instance.new("Frame", ScreenGui)
FCMobileUI.Size = UDim2.new(0, 70, 0, 160)
FCMobileUI.Position = UDim2.new(0, 15, 0.5, -80)
FCMobileUI.BackgroundTransparency = 1
FCMobileUI.Visible = false

local btnFwd = Instance.new("TextButton", FCMobileUI)
btnFwd.Size = UDim2.new(1, 0, 0.45, 0)
btnFwd.BackgroundColor3 = Color3.fromRGB(30,30,30)
btnFwd.Text = "▲"; btnFwd.TextColor3 = Color3.fromRGB(255,255,255); btnFwd.TextScaled = true; btnFwd.BackgroundTransparency = 0.5
Instance.new("UICorner", btnFwd).CornerRadius = UDim.new(0.2,0)

local btnBwd = Instance.new("TextButton", FCMobileUI)
btnBwd.Size = UDim2.new(1, 0, 0.45, 0)
btnBwd.Position = UDim2.new(0, 0, 0.55, 0)
btnBwd.BackgroundColor3 = Color3.fromRGB(30,30,30)
btnBwd.Text = "▼"; btnBwd.TextColor3 = Color3.fromRGB(255,255,255); btnBwd.TextScaled = true; btnBwd.BackgroundTransparency = 0.5
Instance.new("UICorner", btnBwd).CornerRadius = UDim.new(0.2,0)

btnFwd.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then fwdDown = true end end)
btnFwd.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then fwdDown = false end end)
btnBwd.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then bwdDown = true end end)
btnBwd.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then bwdDown = false end end)

createToggle(TabFreeCam, "Free Camera", FreeCamEnabled, function(s) 
	FreeCamEnabled = s 
	if s then
		local FCPart = workspace:FindFirstChild("VeliasikFCPart") or Instance.new("Part")
		FCPart.Name = "VeliasikFCPart"; FCPart.Anchored = true; FCPart.CanCollide = false; FCPart.Transparency = 1
		FCPart.Size = Vector3.new(1, 1, 1); FCPart.Position = Camera.Focus.Position; FCPart.Parent = workspace
		Camera.CameraSubject = FCPart
		if UserInputService.TouchEnabled then FCMobileUI.Visible = true end
	else
		FCMobileUI.Visible = false
		local FCPart = workspace:FindFirstChild("VeliasikFCPart")
		if FCPart then FCPart:Destroy() end
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = LocalPlayer.Character.Humanoid end
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Anchored = false end
	end
end)
createToggle(TabFreeCam, "Freeze During", FreezeDuringEnabled, function(s) 
	FreezeDuringEnabled = s
	if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Anchored = false end
end)

-- ===================== ЛОГІКА СКРИПТА =====================
local function getTargetPart(char)
	return AimbotTarget == "Head" and char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
end

local function isVisible(targetPart)
	if not WallCheckEnabled then return true end
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
	local FCPart = workspace:FindFirstChild("VeliasikFCPart")
	params.FilterDescendantsInstances = {LocalPlayer.Character, FCPart}; params.IgnoreWater = true
	local origin = Camera.CFrame.Position
	local hit = workspace:Raycast(origin, targetPart.Position - origin, params)
	return hit == nil or hit.Instance:IsDescendantOf(targetPart.Parent)
end

local function getClosestPlayerToCenter()
	local closestPlayer, shortestDist = nil, math.huge
	local cameraCFrame = Camera.CFrame
	local mouseRay = cameraCFrame.LookVector

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and not WhitelistedNames[player.Name] then
			local char = player.Character
			if char and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health > 0 then
				local targetPart = getTargetPart(char)
				if targetPart and isVisible(targetPart) then
					local directionToTarget = (targetPart.Position - cameraCFrame.Position).Unit
					local dot = mouseRay:Dot(directionToTarget)
					if dot > 0 then
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
	
	t.BoxFrame = Instance.new("Frame", ESP_Folder)
	t.BoxFrame.BackgroundTransparency = 1
	t.BoxStroke = Instance.new("UIStroke", t.BoxFrame)
	t.BoxStroke.Thickness = 1
	
	t.NameLbl = Instance.new("TextLabel", ESP_Folder)
	t.NameLbl.BackgroundTransparency = 1
	t.NameLbl.Font = Enum.Font.GothamBold
	t.NameLbl.TextSize = 13
	
	t.HPBarBg = Instance.new("Frame", ESP_Folder)
	t.HPBarBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	t.HPBarBg.BorderSizePixel = 0
	t.HPBar = Instance.new("Frame", t.HPBarBg)
	t.HPBar.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
	t.HPBar.BorderSizePixel = 0
	
	t.StudsLbl = Instance.new("TextLabel", ESP_Folder)
	t.StudsLbl.BackgroundTransparency = 1
	t.StudsLbl.Font = Enum.Font.GothamBold
	t.StudsLbl.TextSize = 13
	t.StudsLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	local StudsStroke = Instance.new("UIStroke", t.StudsLbl)
	StudsStroke.Thickness = 1.5
	StudsStroke.Color = Color3.fromRGB(0, 0, 0)
	
	t.BoxFrame.Visible = false
	t.NameLbl.Visible = false
	t.HPBarBg.Visible = false
	t.StudsLbl.Visible = false
	
	ESP_Elements[player] = t
	return t
end

Players.PlayerRemoving:Connect(function(player)
	if ESP_Elements[player] then
		for _, v in pairs(ESP_Elements[player]) do
			if typeof(v) == "Instance" then v:Destroy() end
		end
		ESP_Elements[player] = nil
	end
end)

local lastFpsTick = tick()
local origAmbient = Lighting.Ambient
local origFogEnd = Lighting.FogEnd

RunService.RenderStepped:Connect(function(dt)
	if not ScreenGui or not ScreenGui.Parent then return end

	if tick() - lastFpsTick >= 0.5 then
		FPSLabel.Text = "FPS: " .. math.round(1 / dt)
		PingLabel.Text = "Ping: " .. math.floor(LocalPlayer:GetNetworkPing() * 1000) .. " ms"
		lastFpsTick = tick()
	end

	if FOVChangerEnabled then Camera.FieldOfView = CustomFOV end
	if FullbrightEnabled then Lighting.Ambient = Color3.new(1,1,1) else Lighting.Ambient = origAmbient end
	if NoFogEnabled then Lighting.FogEnd = 100000 else Lighting.FogEnd = origFogEnd end

	if FreeCamEnabled then
		local FCPart = workspace:FindFirstChild("VeliasikFCPart")
		if FCPart then
			if FreezeDuringEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Anchored = true end
			local moveDir = Vector3.new(0,0,0)
			if UserInputService:IsKeyDown(Enum.KeyCode.W) or fwdDown then moveDir += Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) or bwdDown then moveDir -= Camera.CFrame.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
			FCPart.Position = FCPart.Position + (moveDir * FC_Speed * dt)
		end
	end

	local char = LocalPlayer.Character
	if char then
		if SpeedEnabled then
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.WalkSpeed ~= TargetSpeed then humanoid.WalkSpeed = TargetSpeed end
		end
		if NoclipEnabled then
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") then
					if OriginalNoclipStates[part] == nil then OriginalNoclipStates[part] = part.CanCollide end
					part.CanCollide = false 
				end
			end
		end
		
		-- Fly Logic (Supports Mobile Joystick & PC)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hrp and hum then
			if FlyEnabled then
				local flyGyro = hrp:FindFirstChild("VeliasikFlyGyro")
				local flyVel = hrp:FindFirstChild("VeliasikFlyVel")
				
				if not flyGyro then
					flyGyro = Instance.new("BodyGyro", hrp)
					flyGyro.Name = "VeliasikFlyGyro"
					flyGyro.P = 9e4
					flyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
					flyGyro.CFrame = hrp.CFrame
					
					flyVel = Instance.new("BodyVelocity", hrp)
					flyVel.Name = "VeliasikFlyVel"
					flyVel.Velocity = Vector3.zero
					flyVel.MaxForce = Vector3.new(9e9, 9e9, 9e9)
					
					hum.PlatformStand = true
				end
				
				local moveDir = hum.MoveDirection
				local camCFrame = Camera.CFrame
				local vel = Vector3.zero
				
				if moveDir.Magnitude > 0.01 then
					-- Проектуємо ввід джойстика на камеру гравця (дозволяє літати вгору/вниз повертаючи екран)
					local flatLook = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
					local flatRight = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit
					
					local forwardInput = flatLook:Dot(moveDir)
					local rightInput = flatRight:Dot(moveDir)
					
					local flyDir = (camCFrame.LookVector * forwardInput) + (camCFrame.RightVector * rightInput)
					if flyDir.Magnitude > 0 then
						vel = flyDir.Unit * PlayerSettings.FlySpeed
					end
				end
				
				-- Додаткова підтримка клавіатури для PC
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
					vel = vel + Vector3.new(0, PlayerSettings.FlySpeed, 0)
				end
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
					vel = vel - Vector3.new(0, PlayerSettings.FlySpeed, 0)
				end
				
				flyGyro.CFrame = camCFrame
				flyVel.Velocity = vel
			else
				if hrp:FindFirstChild("VeliasikFlyGyro") then hrp.VeliasikFlyGyro:Destroy() end
				if hrp:FindFirstChild("VeliasikFlyVel") then hrp.VeliasikFlyVel:Destroy() end
				if not FreeCamEnabled then hum.PlatformStand = false end
			end
		end
	end

	if AimbotEnabled then
		local target = getClosestPlayerToCenter()
		if target then
			local targetCFrame = CFrame.new(Camera.CFrame.Position, target.Position)
			Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / ((Smoothness / 5) + 1))
		end
	end

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local pchar = player.Character
			local espUI = createPlayerESP(player)
			
			if pchar and pchar:FindFirstChild("HumanoidRootPart") and pchar:FindFirstChildOfClass("Humanoid") then
				local humanoid = pchar:FindFirstChildOfClass("Humanoid")
				local rootPart = pchar.HumanoidRootPart

				if not OriginalSizes[rootPart] then
					OriginalSizes[rootPart] = rootPart.Size
					OriginalCollisions[rootPart] = rootPart.CanCollide
				end

				if HitboxEnabled and humanoid.Health > 0 then
					rootPart.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
					rootPart.Transparency = 0.7
					rootPart.BrickColor = BrickColor.new("Really red")
					rootPart.CanCollide = false
				else
					rootPart.Size = OriginalSizes[rootPart]
					rootPart.Transparency = 1
					rootPart.CanCollide = OriginalCollisions[rootPart]
				end

				-- ESP Logic
				if ESPSettings.Master and humanoid.Health > 0 then
					-- Highlight
					if ESPSettings.Highlight then
						local hl = pchar:FindFirstChild("ESP_Highlight")
						if not hl then
							hl = Instance.new("Highlight", pchar)
							hl.Name = "ESP_Highlight"
							hl.OutlineColor = Color3.fromRGB(255, 255, 255)
							hl.FillTransparency = 0.5
							hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						end
						hl.FillColor = ESPColor
					else
						local hl = pchar:FindFirstChild("ESP_Highlight")
						if hl then hl:Destroy() end
					end

					-- 2D Drawings (Box, Name, HP, Studs)
					local hrpPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
					if onScreen and (ESPSettings.Box or ESPSettings.Name or ESPSettings.HP or ESPSettings.Studs) then
						local topPos = Camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0))
						local bottomPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3.5, 0))
						local h = bottomPos.Y - topPos.Y
						local w = h / 1.8
						local x = hrpPos.X - w / 2
						local y = topPos.Y
						
						local distance = math.floor((Camera.CFrame.Position - rootPart.Position).Magnitude)

						if ESPSettings.Box then
							espUI.BoxFrame.Size = UDim2.new(0, w, 0, h)
							espUI.BoxFrame.Position = UDim2.new(0, x, 0, y)
							espUI.BoxStroke.Color = ESPColor
							espUI.BoxFrame.Visible = true
						else espUI.BoxFrame.Visible = false end

						if ESPSettings.Name then
							espUI.NameLbl.Text = player.Name
							espUI.NameLbl.TextColor3 = ESPColor
							espUI.NameLbl.Size = UDim2.new(0, w, 0, 15)
							espUI.NameLbl.Position = UDim2.new(0, x, 0, y - 18)
							espUI.NameLbl.Visible = true
						else espUI.NameLbl.Visible = false end
						
						if ESPSettings.HP then
							local hpPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
							espUI.HPBarBg.Size = UDim2.new(0, 3, 0, h)
							espUI.HPBarBg.Position = UDim2.new(0, x - 6, 0, y)
							espUI.HPBar.Size = UDim2.new(1, 0, hpPercent, 0)
							espUI.HPBar.Position = UDim2.new(0, 0, 1 - hpPercent, 0)
							espUI.HPBar.BackgroundColor3 = Color3.fromRGB(255 - (hpPercent * 255), hpPercent * 255, 50)
							espUI.HPBarBg.Visible = true
						else espUI.HPBarBg.Visible = false end
						
						if ESPSettings.Studs then
							espUI.StudsLbl.Text = tostring(distance) .. "s"
							espUI.StudsLbl.Size = UDim2.new(0, w, 0, 15)
							espUI.StudsLbl.Position = UDim2.new(0, x, 0, y + h + 2)
							espUI.StudsLbl.Visible = true
						else espUI.StudsLbl.Visible = false end

					else
						espUI.BoxFrame.Visible = false
						espUI.NameLbl.Visible = false
						espUI.HPBarBg.Visible = false
						espUI.StudsLbl.Visible = false
					end
				else
					local hl = pchar:FindFirstChild("ESP_Highlight")
					if hl then hl:Destroy() end
					espUI.BoxFrame.Visible = false
					espUI.NameLbl.Visible = false
					espUI.HPBarBg.Visible = false
					espUI.StudsLbl.Visible = false
				end
			else
				local hl = pchar and pchar:FindFirstChild("ESP_Highlight")
				if hl then hl:Destroy() end
				espUI.BoxFrame.Visible = false
				espUI.NameLbl.Visible = false
				espUI.HPBarBg.Visible = false
				espUI.StudsLbl.Visible = false
			end
		end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if not ScreenGui or not ScreenGui.Parent then return end
	if InfJumpEnabled and LocalPlayer.Character then
		local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)
