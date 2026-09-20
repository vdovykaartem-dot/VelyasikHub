-- =================================================================
-- CHRONO HUB (LinoriaLib UI + VelyasikCode Functions)
-- =================================================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- Функція для безпечного отримання сервісів
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

-- Генератор випадкових імен
local function RndName()
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	local str = ""
	for i = 1, math.random(12, 18) do
		local r = math.random(1, #chars)
		str = str .. string.sub(chars, r, r)
	end
	return str
end

local ObfuscatedNames = {
	GUI = RndName(),
	FCPart = RndName(),
	Highlight = RndName()
}

if setfpscap then setfpscap(9999) end

-- ===================== ЗМІННІ СТАНУ =====================
local ESPSettings = { Master = false, Highlight = true, Box = false, Name = false, HP = false, Studs = false }
local ESPColor = Color3.fromRGB(255, 50, 50)
local HitboxEnabled, HitboxSize, KickStuffEnabled = false, 10, true
local SpeedEnabled, TargetSpeed, NoclipEnabled, InfJumpEnabled, FlyEnabled, FlySpeed = false, 16, false, false, false, 50
local AimbotEnabled, AimbotTarget, WallCheckEnabled, FOVEnabled, FOVRadius, Smoothness = false, "Head", true, false, 180, 0
local NoFogEnabled, FullbrightEnabled, FOVChangerEnabled, CustomFOV = false, false, false, 90
local FPSUnlockerEnabled, CamUnlockerEnabled = true, false
local FreeCamEnabled, FreezeDuringEnabled, FC_Speed, fwdDown, bwdDown = false, false, 60, false, false
local SpectateEnabled, SpectateTargetPlayer = false, nil
local WhitelistedNames = {}
local OriginalSizes, OriginalNoclipStates = {}, {}
local Scripters = {[LocalPlayer.UserId] = true}

-- ===================== OVERLAY GUI ДЛЯ ESP І FOV =====================
local TargetGuiParent = (gethui and gethui()) or CoreGui
local OverlayGui = Instance.new("ScreenGui")
OverlayGui.Name = ObfuscatedNames.GUI
OverlayGui.ResetOnSpawn = false
OverlayGui.IgnoreGuiInset = true
OverlayGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local success, err = pcall(function() OverlayGui.Parent = TargetGuiParent end)
if not success then OverlayGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

local ESP_Folder = Instance.new("Folder", OverlayGui)
ESP_Folder.Name = RndName()
local ESP_Elements = {}

local FOVCircleUI = Instance.new("Frame", OverlayGui)
FOVCircleUI.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
FOVCircleUI.Position = UDim2.new(0.5, -FOVRadius, 0.5, -FOVRadius)
FOVCircleUI.BackgroundTransparency = 1
FOVCircleUI.Visible = false
local UIStroke = Instance.new("UIStroke", FOVCircleUI)
UIStroke.Color = Color3.fromRGB(255, 255, 255)
UIStroke.Thickness = 1.5
Instance.new("UICorner", FOVCircleUI).CornerRadius = UDim.new(1, 0)

local FCMobileUI = Instance.new("Frame", OverlayGui)
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

-- ===================== ІНТЕРФЕЙС CHRONO HUB =====================
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({
	Title = "Chrono Hub",
	Footer = "Premium Edition",
	Icon = 95816097006870,
	NotifySide = "Right",
	ShowCustomCursor = true,
})

local Tabs = {
	Info = Window:AddTab("Info", "info"),
	Main = Window:AddTab("Main", "home"),
	Visuals = Window:AddTab("Visuals", "eye"),
	Player = Window:AddTab("Player", "user"),
	Combat = Window:AddTab("Combat", "swords"),
	TeamCheck = Window:AddTab("Team Check", "users"),
	FreeCam = Window:AddTab("Free Camera", "camera"),
	UISettings = Window:AddTab("UI Settings", "settings"),
}

-- Функція для отримання імен гравців для Dropdowns
local function GetPlayerNames()
    local names = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(names, p.Name) end
    end
    return names
end

-- ===================== ВКЛАДКА: INFO =====================
local InfoBox = Tabs.Info:AddLeftGroupbox("Player Information")
InfoBox:AddLabel("Username: " .. LocalPlayer.Name)
InfoBox:AddLabel("Display Name: " .. LocalPlayer.DisplayName)
InfoBox:AddLabel("Player ID: " .. LocalPlayer.UserId)
InfoBox:AddLabel("Place ID: " .. game.PlaceId)

local StatsBox = Tabs.Info:AddRightGroupbox("Game Stats")
local FPSLabel = StatsBox:AddLabel("FPS: Calculating...")
local PingLabel = StatsBox:AddLabel("Ping: Calculating...")
local ScripterLabel = StatsBox:AddLabel("Scripters detected: None")

local function updateScriptersLabel()
    local scripterNames = {}
    for uid, _ in pairs(Scripters) do
        local p = Players:GetPlayerByUserId(uid)
        if p then table.insert(scripterNames, p.Name) end
    end
    ScripterLabel:SetText("Scripters detected: " .. table.concat(scripterNames, ", "))
end

-- ===================== ВКЛАДКА: MAIN =====================
local ESPBox = Tabs.Main:AddLeftGroupbox("ESP Settings")
ESPBox:AddToggle("ESPMaster", { Text = "Enable ESP", Default = false }):OnChanged(function(v) ESPSettings.Master = v end)
ESPBox:AddToggle("ESPHighlight", { Text = "ESP Highlight", Default = true }):OnChanged(function(v) ESPSettings.Highlight = v end)
ESPBox:AddToggle("ESPBox", { Text = "ESP Box", Default = false }):OnChanged(function(v) ESPSettings.Box = v end)
ESPBox:AddToggle("ESPName", { Text = "ESP Name", Default = false }):OnChanged(function(v) ESPSettings.Name = v end)
ESPBox:AddToggle("ESPHP", { Text = "ESP Health", Default = false }):OnChanged(function(v) ESPSettings.HP = v end)
ESPBox:AddToggle("ESPStuds", { Text = "ESP Distance (Studs)", Default = false }):OnChanged(function(v) ESPSettings.Studs = v end)
ESPBox:AddColorPicker("ESPColor", { Default = Color3.fromRGB(255, 50, 50), Title = "ESP Color" }):OnChanged(function(v) ESPColor = v end)

local HitboxBox = Tabs.Main:AddRightGroupbox("Hitbox Expander")
HitboxBox:AddToggle("Hitbox", { Text = "Enable Hitbox", Default = false }):OnChanged(function(v) HitboxEnabled = v end)
HitboxBox:AddSlider("HitboxSize", { Text = "Hitbox Size", Default = 10, Min = 1, Max = 30, Rounding = 0 }):OnChanged(function(v) HitboxSize = v end)
HitboxBox:AddToggle("KickSec", { Text = "Kick Security (Anti-Dev)", Default = true }):OnChanged(function(v) KickStuffEnabled = v end)

-- ===================== ВКЛАДКА: VISUALS =====================
local EnvBox = Tabs.Visuals:AddLeftGroupbox("Environment")
EnvBox:AddToggle("NoFog", { Text = "No Fog", Default = false }):OnChanged(function(v) NoFogEnabled = v end)
EnvBox:AddToggle("Fullbright", { Text = "Fullbright", Default = false }):OnChanged(function(v) FullbrightEnabled = v end)
EnvBox:AddToggle("FOVChanger", { Text = "FOV Changer", Default = false }):OnChanged(function(v) 
    FOVChangerEnabled = v; if not v then Camera.FieldOfView = 70 end 
end)
EnvBox:AddSlider("CustomFOV", { Text = "Custom FOV", Default = 90, Min = 10, Max = 120, Rounding = 0 }):OnChanged(function(v) CustomFOV = v end)

local SpecBox = Tabs.Visuals:AddRightGroupbox("Spectate")
SpecBox:AddToggle("SpectateToggle", { Text = "Enable Spectate", Default = false }):OnChanged(function(v)
	SpectateEnabled = v
	if not v then
		SpectateTargetPlayer = nil
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
			Camera.CameraSubject = LocalPlayer.Character.Humanoid
		end
	end
end)
local SpectateDropdown = SpecBox:AddDropdown("SpectateTarget", {
	Values = GetPlayerNames(),
	Default = 0,
	Multi = false,
	Text = "Target Player"
})
SpectateDropdown:OnChanged(function(v)
    if v then SpectateTargetPlayer = Players:FindFirstChild(v) end
end)

local MiscBox = Tabs.Visuals:AddRightGroupbox("Misc Settings")
MiscBox:AddToggle("FPSUnlock", { Text = "FPS Unlocker", Default = true }):OnChanged(function(v) 
    FPSUnlockerEnabled = v; if setfpscap then pcall(function() setfpscap(v and 9999 or 60) end) end 
end)
MiscBox:AddToggle("CamUnlock", { Text = "Camera Unlocker", Default = false }):OnChanged(function(v) 
    CamUnlockerEnabled = v; LocalPlayer.CameraMaxZoomDistance = v and 1000 or 128 
end)
MiscBox:AddButton({Text = "Serverhop", Func = function()
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
end})
MiscBox:AddButton({Text = "Rejoin Server", Func = function()
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) 
end})

-- ===================== ВКЛАДКА: PLAYER =====================
local MoveBox = Tabs.Player:AddLeftGroupbox("Movement")
MoveBox:AddToggle("WalkSpeedTog", { Text = "Custom WalkSpeed", Default = false }):OnChanged(function(v)
	SpeedEnabled = v 
	if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16
	end
end)
MoveBox:AddSlider("WalkSpeedVal", { Text = "WalkSpeed Value", Default = 16, Min = 1, Max = 1000, Rounding = 0 }):OnChanged(function(v) TargetSpeed = v end)

MoveBox:AddToggle("Noclip", { Text = "Noclip", Default = false }):OnChanged(function(v)
	NoclipEnabled = v 
	if v and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") then OriginalNoclipStates[part] = part.CanCollide end
		end
	elseif not v and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") and OriginalNoclipStates[part] ~= nil then part.CanCollide = OriginalNoclipStates[part] end
		end
		table.clear(OriginalNoclipStates)
	end
end)
MoveBox:AddToggle("InfJump", { Text = "Infinite Jump", Default = false }):OnChanged(function(v) InfJumpEnabled = v end)

local FlyBox = Tabs.Player:AddRightGroupbox("Fly Settings")
FlyBox:AddToggle("FlyTog", { Text = "Fly", Default = false }):OnChanged(function(v) FlyEnabled = v end)
FlyBox:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 50, Min = 1, Max = 200, Rounding = 0 }):OnChanged(function(v) FlySpeed = v end)

-- ===================== ВКЛАДКА: COMBAT =====================
local AimbotBox = Tabs.Combat:AddLeftGroupbox("Aimbot")
AimbotBox:AddToggle("Aimbot", { Text = "Enable Aimbot", Default = false }):OnChanged(function(v) AimbotEnabled = v end)
AimbotBox:AddDropdown("AimTarget", { Values = {"Head", "Torso"}, Default = 1, Multi = false, Text = "Target Part" }):OnChanged(function(v) AimbotTarget = v end)
AimbotBox:AddToggle("WallCheck", { Text = "Wall Check", Default = true }):OnChanged(function(v) WallCheckEnabled = v end)
AimbotBox:AddSlider("AimSmooth", { Text = "Aimbot Smoothness", Default = 0, Min = 0, Max = 100, Rounding = 0 }):OnChanged(function(v) Smoothness = v end)

local FOVBox = Tabs.Combat:AddRightGroupbox("FOV")
FOVBox:AddToggle("FOVCircle", { Text = "Show FOV Circle", Default = false }):OnChanged(function(v) FOVEnabled = v; FOVCircleUI.Visible = v end)
FOVBox:AddSlider("FOVCircleSize", { Text = "FOV Size", Default = 180, Min = 20, Max = 400, Rounding = 0 }):OnChanged(function(v)
	FOVRadius = v
	if FOVCircleUI then
		FOVCircleUI.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
		FOVCircleUI.Position = UDim2.new(0.5, -FOVRadius, 0.5, -FOVRadius)
	end
end)

-- ===================== ВКЛАДКА: TEAM CHECK =====================
local TeamBox = Tabs.TeamCheck:AddLeftGroupbox("Whitelist")
local WhitelistDropdown = TeamBox:AddDropdown("WhitelistPlayers", {
	Values = GetPlayerNames(),
	Default = 0,
	Multi = true,
	Text = "Whitelisted Players"
})
WhitelistDropdown:OnChanged(function(selected)
    WhitelistedNames = selected -- Зберігає таблицю гравців, яких вибрано
end)

-- Оновлення Dropdowns при заході/виході гравців
Players.PlayerAdded:Connect(function() 
    SpectateDropdown:SetValues(GetPlayerNames()) 
    WhitelistDropdown:SetValues(GetPlayerNames())
end)
Players.PlayerRemoving:Connect(function() 
    SpectateDropdown:SetValues(GetPlayerNames()) 
    WhitelistDropdown:SetValues(GetPlayerNames())
end)

-- ===================== ВКЛАДКА: FREE CAM =====================
local FCBox = Tabs.FreeCam:AddLeftGroupbox("Camera Controls")
FCBox:AddToggle("FCToggle", { Text = "Enable Free Camera", Default = false }):OnChanged(function(s)
	FreeCamEnabled = s 
	if s then
		local FCPart = workspace:FindFirstChild(ObfuscatedNames.FCPart) or Instance.new("Part")
		FCPart.Name = ObfuscatedNames.FCPart; FCPart.Anchored = true; FCPart.CanCollide = false; FCPart.Transparency = 1
		FCPart.Size = Vector3.new(1, 1, 1); FCPart.Position = Camera.Focus.Position; FCPart.Parent = workspace
		Camera.CameraSubject = FCPart
		if UserInputService.TouchEnabled then FCMobileUI.Visible = true end
	else
		FCMobileUI.Visible = false
		local FCPart = workspace:FindFirstChild(ObfuscatedNames.FCPart)
		if FCPart then pcall(function() FCPart:Destroy() end) end
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = LocalPlayer.Character.Humanoid end
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Anchored = false end
	end
end)
FCBox:AddToggle("FCFreeze", { Text = "Freeze Character During Freecam", Default = false }):OnChanged(function(s)
	FreezeDuringEnabled = s
	if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Anchored = false end
end)
FCBox:AddSlider("FCSpeed", { Text = "Free Cam Speed", Default = 60, Min = 10, Max = 300, Rounding = 0 }):OnChanged(function(v) FC_Speed = v end)

-- ===================== ВКЛАДКА: UI SETTINGS (Theme & Config) =====================
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({'WhitelistPlayers', 'SpectateTarget'})
ThemeManager:SetFolder('ChronoHub')
SaveManager:SetFolder('ChronoHub/Configs')
SaveManager:BuildConfigSection(Tabs.UISettings)
ThemeManager:ApplyToTab(Tabs.UISettings)
SaveManager:LoadAutoloadConfig()

-- ===================== ЛОГІКА СКРИПТА (ІЗ ВАШОГО КОДУ) =====================
local function onChatted(player, msg)
	if msg == "/e v2_3_ping" then
		Scripters[player.UserId] = true
		updateScriptersLabel()
	end
end

for _, p in pairs(Players:GetPlayers()) do p.Chatted:Connect(function(msg) onChatted(p, msg) end) end
Players.PlayerAdded:Connect(function(p) p.Chatted:Connect(function(msg) onChatted(p, msg) end) end)
Players.PlayerRemoving:Connect(function(p) Scripters[p.UserId] = nil; updateScriptersLabel() end)

task.spawn(function()
	pcall(function()
		if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			TextChatService.TextChannels.RBXGeneral:SendAsync("/e v2_3_ping")
		else
			ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer("/e v2_3_ping", "All")
		end
	end)
end)

local function getTargetPart(char)
	return AimbotTarget == "Head" and char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")
end

local function isVisible(targetPart)
	if not WallCheckEnabled then return true end
	local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
	local FCPart = workspace:FindFirstChild(ObfuscatedNames.FCPart)
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
	
	t.Highlight = Instance.new("Highlight")
	t.Highlight.Name = ObfuscatedNames.Highlight
	t.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	t.Highlight.FillTransparency = 0.5
	t.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	t.Highlight.Enabled = false
	t.Highlight.Parent = ESP_Folder

	t.BoxFrame = Instance.new("Frame", ESP_Folder)
	t.BoxFrame.BackgroundTransparency = 1
	t.BoxStroke = Instance.new("UIStroke", t.BoxFrame)
	t.BoxStroke.Thickness = 1
	
	t.NameLbl = Instance.new("TextLabel", ESP_Folder)
	t.NameLbl.BackgroundTransparency = 1
    t.NameLbl.Font = Enum.Font.GothamBold
    t.NameLbl.TextSize = 12
	
	t.HPBarBg = Instance.new("Frame", ESP_Folder)
	t.HPBarBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	t.HPBarBg.BorderSizePixel = 0
	t.HPBar = Instance.new("Frame", t.HPBarBg)
	t.HPBar.BackgroundColor3 = Color3.fromRGB(50, 255, 50)
	t.HPBar.BorderSizePixel = 0
	
	t.StudsLbl = Instance.new("TextLabel", ESP_Folder)
	t.StudsLbl.BackgroundTransparency = 1
	t.StudsLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    t.StudsLbl.Font = Enum.Font.GothamBold
    t.StudsLbl.TextSize = 12
	local StudsStroke = Instance.new("UIStroke", t.StudsLbl)
	StudsStroke.Thickness = 1.5
	StudsStroke.Color = Color3.fromRGB(0, 0, 0)
	
	t.BoxFrame.Visible = false; t.NameLbl.Visible = false; t.HPBarBg.Visible = false; t.StudsLbl.Visible = false
	
	ESP_Elements[player] = t
	return t
end

Players.PlayerRemoving:Connect(function(player)
	if ESP_Elements[player] then
		for _, v in pairs(ESP_Elements[player]) do
			if typeof(v) == "Instance" then pcall(function() v:Destroy() end) end
		end
		ESP_Elements[player] = nil
	end
end)

RunService.Stepped:Connect(function()
	if NoclipEnabled and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") then part.CanCollide = false end
		end
	end
end)

local lastFpsTick = tick()
local origAmbient = Lighting.Ambient
local origFogEnd = Lighting.FogEnd

RunService.RenderStepped:Connect(function(dt)
	if tick() - lastFpsTick >= 0.5 then
		pcall(function()
			FPSLabel:SetText("FPS: " .. math.round(1 / dt))
			PingLabel:SetText("Ping: " .. math.floor(LocalPlayer:GetNetworkPing() * 1000) .. " ms")
		end)
		lastFpsTick = tick()
	end

	if FOVChangerEnabled then Camera.FieldOfView = CustomFOV end
	if FullbrightEnabled then Lighting.Ambient = Color3.new(1,1,1) else Lighting.Ambient = origAmbient end
	if NoFogEnabled then Lighting.FogEnd = 100000 else Lighting.FogEnd = origFogEnd end

	if SpectateEnabled and SpectateTargetPlayer and SpectateTargetPlayer.Character then
		local hum = SpectateTargetPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then Camera.CameraSubject = hum end
	end

	if FreeCamEnabled then
		local FCPart = workspace:FindFirstChild(ObfuscatedNames.FCPart)
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
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local hum = char:FindFirstChildOfClass("Humanoid")
		
		if hrp and hum then
			if SpeedEnabled and not FlyEnabled then
				if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
				local moveDir = hum.MoveDirection
				if moveDir.Magnitude > 0.01 then
					local currentVel = hrp.AssemblyLinearVelocity
					local desiredVel = moveDir * TargetSpeed
					hrp.AssemblyLinearVelocity = Vector3.new(desiredVel.X, currentVel.Y, desiredVel.Z)
				end
			end
			
			if FlyEnabled then
				hum.PlatformStand = false
				local moveDir = hum.MoveDirection
				local camCFrame = Camera.CFrame
				local vel = Vector3.zero
				
				if moveDir.Magnitude > 0.01 then
					local flatLook = Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit
					local flatRight = Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit
					local forwardInput = flatLook:Dot(moveDir)
					local rightInput = flatRight:Dot(moveDir)
					
					local flyDir = (camCFrame.LookVector * forwardInput) + (camCFrame.RightVector * rightInput)
					if flyDir.Magnitude > 0 then vel = flyDir.Unit * FlySpeed end
				end
				
				local verticalVel = 0
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then verticalVel = FlySpeed 
				elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then verticalVel = -FlySpeed end
				
				vel = vel + Vector3.new(0, verticalVel, 0)
				hrp.AssemblyLinearVelocity = vel
				hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z))
			else
				if not FreeCamEnabled and not SpeedEnabled and not SpectateEnabled then hum.PlatformStand = false end
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

				if not OriginalSizes[rootPart] then OriginalSizes[rootPart] = rootPart.Size end

				if HitboxEnabled and humanoid.Health > 0 then
					pcall(function()
						rootPart.Size = Vector3.new(HitboxSize, HitboxSize, HitboxSize)
						rootPart.Transparency = 0.75
						rootPart.CanCollide = false
					end)
				else
					if OriginalSizes[rootPart] then
						pcall(function()
							rootPart.Size = OriginalSizes[rootPart]
							rootPart.Transparency = 1
							rootPart.CanCollide = false
						end)
					end
				end

				if ESPSettings.Master and humanoid.Health > 0 then
					if ESPSettings.Highlight then
						espUI.Highlight.Adornee = pchar
						espUI.Highlight.FillColor = ESPColor
						espUI.Highlight.Enabled = true
					else espUI.Highlight.Enabled = false end

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
						espUI.BoxFrame.Visible = false; espUI.NameLbl.Visible = false; espUI.HPBarBg.Visible = false; espUI.StudsLbl.Visible = false
					end
				else
					espUI.Highlight.Enabled = false
					espUI.BoxFrame.Visible = false; espUI.NameLbl.Visible = false; espUI.HPBarBg.Visible = false; espUI.StudsLbl.Visible = false
				end
			else
				espUI.Highlight.Enabled = false
				espUI.BoxFrame.Visible = false; espUI.NameLbl.Visible = false; espUI.HPBarBg.Visible = false; espUI.StudsLbl.Visible = false
			end
		end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if InfJumpEnabled and LocalPlayer.Character then
		local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end) end
	end
end)
