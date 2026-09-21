-- =================================================================
-- CHRONO HUB (LinoriaLib UI) - PREMIUM EDITION
-- =================================================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local function getSvc(serviceName)
	local s = game:GetService(serviceName)
	return (cloneref and cloneref(s)) or s
end

local CoreGui = getSvc("CoreGui")
local Players = getSvc("Players")
local RunService = getSvc("RunService")
local UserInputService = getSvc("UserInputService")
local TeleportService = getSvc("TeleportService")
local HttpService = getSvc("HttpService")
local Lighting = getSvc("Lighting")
local ContentProvider = getSvc("ContentProvider")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local ExecCount = 1
pcall(function()
	if isfile and readfile and writefile then
		if isfile("ChronoHub_Execs.txt") then
			ExecCount = tonumber(readfile("ChronoHub_Execs.txt")) or 0
			ExecCount = ExecCount + 1
		end
		writefile("ChronoHub_Execs.txt", tostring(ExecCount))
	end
end)

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
if setfpscap then setfpscap(9999) end

-- ===================== ЗМІННІ СТАНУ =====================
local ESPSettings = { Master = false, Highlight = true, Box = false, Name = false, HP = false, Studs = false }
local ESPColor = Color3.fromRGB(255, 50, 50)
local HitboxEnabled, HitboxSize, KickStuffEnabled = false, 10, true
local SpeedEnabled, TargetSpeed, NoclipEnabled, InfJumpEnabled, FlyEnabled, FlySpeed = false, 16, false, false, false, 50
local AimbotEnabled, AimbotTarget, WallCheckEnabled, FOVEnabled, FOVRadius, Smoothness, RainbowFOVEnabled = false, "Head", true, false, 180, 0, false
local NoFogEnabled, FullbrightEnabled, FOVChangerEnabled, CustomFOV = false, false, false, 90
local NoCamShakeEnabled, NoCamBobbingEnabled = false, false
local EnableJumpToggle = false
local FPSUnlockerEnabled, CamUnlockerEnabled = true, false
local FreeCamEnabled, FreezeDuringEnabled, FC_Speed, fwdDown, bwdDown = false, false, 60, false, false
local SpectateEnabled, SpectateTargetPlayer = false, nil
local WhitelistedNames, OriginalSizes, OriginalNoclipStates = {}, {}, {}

-- Кеш для продуктивності та анімацій
local PerfSettings = { Textures = false, Particles = false, Animations = false }
local cacheMaterials, cacheDecals, cacheParticles = {}, {}, {}
local CustomAnims = {
    Run = { ID = "", Active = false, Path = {"run", "RunAnim"} },
    Jump = { ID = "", Active = false, Path = {"jump", "JumpAnim"} },
    Idle = { ID = "", Active = false, Path = {"idle", "Animation1"} }
}
local OriginalAnims = {}

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
btnFwd.Size = UDim2.new(1, 0, 0.45, 0); btnFwd.BackgroundColor3 = Color3.fromRGB(30,30,30); btnFwd.Text = "▲"; btnFwd.TextColor3 = Color3.fromRGB(255,255,255); btnFwd.TextScaled = true; btnFwd.BackgroundTransparency = 0.5; Instance.new("UICorner", btnFwd).CornerRadius = UDim.new(0.2,0)
local btnBwd = Instance.new("TextButton", FCMobileUI)
btnBwd.Size = UDim2.new(1, 0, 0.45, 0); btnBwd.Position = UDim2.new(0, 0, 0.55, 0); btnBwd.BackgroundColor3 = Color3.fromRGB(30,30,30); btnBwd.Text = "▼"; btnBwd.TextColor3 = Color3.fromRGB(255,255,255); btnBwd.TextScaled = true; btnBwd.BackgroundTransparency = 0.5; Instance.new("UICorner", btnBwd).CornerRadius = UDim.new(0.2,0)

btnFwd.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then fwdDown = true end end)
btnFwd.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then fwdDown = false end end)
btnBwd.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then bwdDown = true end end)
btnBwd.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then bwdDown = false end end)

-- ===================== ІНТЕРФЕЙС CHRONO HUB =====================
Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

local Window = Library:CreateWindow({ Title = "Chrono Hub", Footer = "Premium Edition", Icon = "clock", NotifySide = "Right", ShowCustomCursor = true })
local Tabs = {
	Info = Window:AddTab("Info", "info"),
	Main = Window:AddTab("Main", "house"),
	Visuals = Window:AddTab("Visuals", "eye"),
	Player = Window:AddTab("Player", "user"),
	Combat = Window:AddTab("Combat", "swords"),
	TeamCheck = Window:AddTab("Team Check", "users"),
	FreeCam = Window:AddTab("Free Camera", "camera"),
	UISettings = Window:AddTab("UI Settings", "settings"),
}

local function GetPlayerNames()
    local names = {"None"}
    for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(names, p.Name) end end
    return names
end

-- ===================== ВКЛАДКА: INFO =====================
local UserBox = Tabs.Info:AddLeftGroupbox("User Profile")
local AvatarContainer = Instance.new("Frame", UserBox.Container)
AvatarContainer.Size = UDim2.new(1, 0, 0, 200)
AvatarContainer.BackgroundTransparency = 1
local AvatarImage = Instance.new("ImageLabel", AvatarContainer)
AvatarImage.Size = UDim2.new(0, 180, 0, 180)
AvatarImage.Position = UDim2.new(0.5, -90, 0.5, -90)
AvatarImage.BackgroundTransparency = 1
Instance.new("UICorner", AvatarImage).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", AvatarImage).Color = Color3.fromRGB(50, 50, 50)

task.spawn(function()
	local ok, content = pcall(function() return Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420) end)
	if ok and content then
		AvatarImage.Image = content; pcall(function() ContentProvider:PreloadAsync({AvatarImage}) end)
	else
		AvatarImage.Image = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=420&h=420"
	end
end)

local InfoBox = Tabs.Info:AddRightGroupbox("Player Information")
InfoBox:AddLabel("Username: " .. LocalPlayer.Name)
InfoBox:AddLabel("Display Name: " .. LocalPlayer.DisplayName)
InfoBox:AddLabel("Player ID: " .. LocalPlayer.UserId)
InfoBox:AddLabel("Total Executions: " .. tostring(ExecCount))

local StatsBox = Tabs.Info:AddRightGroupbox("Game Stats")
local FPSLabel = StatsBox:AddLabel("FPS: Calculating...")
local PingLabel = StatsBox:AddLabel("Ping: Calculating...")

-- ===================== ВКЛАДКА: MAIN =====================
local ESPBox = Tabs.Main:AddLeftGroupbox("ESP Settings")
local ESPMasterTog = ESPBox:AddToggle("ESPMaster", { Text = "Enable ESP", Default = false, Tooltip = "Вмикає або вимикає головну систему ESP" })
ESPMasterTog:OnChanged(function(v) ESPSettings.Master = v end)
ESPMasterTog:AddColorPicker("ESPColor", { Default = Color3.fromRGB(255, 50, 50), Title = "ESP Color", Tooltip = "Колір для всіх елементів ESP" })
Library.Options.ESPColor:OnChanged(function() ESPColor = Library.Options.ESPColor.Value end)
ESPBox:AddToggle("ESPHighlight", { Text = "ESP Highlight", Default = true, Tooltip = "Підсвічує модель гравця крізь стіни" }):OnChanged(function(v) ESPSettings.Highlight = v end)
ESPBox:AddToggle("ESPBox", { Text = "ESP Box", Default = false, Tooltip = "Малює квадрат навколо гравця" }):OnChanged(function(v) ESPSettings.Box = v end)
ESPBox:AddToggle("ESPName", { Text = "ESP Name", Default = false, Tooltip = "Показує ім'я гравця" }):OnChanged(function(v) ESPSettings.Name = v end)
ESPBox:AddToggle("ESPHP", { Text = "ESP Health", Default = false, Tooltip = "Показує смугу здоров'я гравця" }):OnChanged(function(v) ESPSettings.HP = v end)
ESPBox:AddToggle("ESPStuds", { Text = "ESP Distance (Studs)", Default = false, Tooltip = "Показує відстань до гравця" }):OnChanged(function(v) ESPSettings.Studs = v end)

local MainControlsBox = Tabs.Main:AddRightGroupbox("Controls & Hitbox")
MainControlsBox:AddToggle("EnableJump", { Text = "Enable Jump", Default = false, Tooltip = "Розблоковує стрибок і показує кастомну кнопку JumpButton (якщо знайдено)" }):OnChanged(function(v) EnableJumpToggle = v end)
MainControlsBox:AddToggle("Hitbox", { Text = "Enable Hitbox", Default = false, Tooltip = "Збільшує розмір моделі гравців для легшого влучання" }):OnChanged(function(v) HitboxEnabled = v end)
MainControlsBox:AddSlider("HitboxSize", { Text = "Hitbox Size", Default = 10, Min = 1, Max = 30, Rounding = 0, Tooltip = "Розмір збільшеного хітбоксу" }):OnChanged(function(v) HitboxSize = v end)
MainControlsBox:AddToggle("KickSec", { Text = "Kick Security", Default = true, Tooltip = "Анти-кік захист для певних ігор" }):OnChanged(function(v) KickStuffEnabled = v end)

-- ===================== ВКЛАДКА: VISUALS =====================
local EnvBox = Tabs.Visuals:AddLeftGroupbox("Environment & Camera")
EnvBox:AddToggle("NoFog", { Text = "No Fog", Default = false, Tooltip = "Прибирає туман у грі" }):OnChanged(function(v) NoFogEnabled = v end)
EnvBox:AddToggle("Fullbright", { Text = "Fullbright", Default = false, Tooltip = "Робить гру максимально світлою" }):OnChanged(function(v) FullbrightEnabled = v end)
EnvBox:AddToggle("NoCamShake", { Text = "No Camera Shake", Default = false, Tooltip = "Вимикає трясіння камери (Camera Shake)" }):OnChanged(function(v) NoCamShakeEnabled = v end)
EnvBox:AddToggle("NoCamBobbing", { Text = "No Camera Bobbing", Default = false, Tooltip = "Вимикає покачування камери під час ходьби" }):OnChanged(function(v) NoCamBobbingEnabled = v end)
EnvBox:AddToggle("FOVChanger", { Text = "FOV Changer", Default = false, Tooltip = "Вмикає кастомне поле зору" }):OnChanged(function(v) FOVChangerEnabled = v; if not v then Camera.FieldOfView = 70 end end)
EnvBox:AddSlider("CustomFOV", { Text = "Custom FOV", Default = 90, Min = 10, Max = 120, Rounding = 0, Tooltip = "Значення поля зору" }):OnChanged(function(v) CustomFOV = v end)

-- PERFORMANCE SUB-TAB
local PerfBox = Tabs.Visuals:AddLeftGroupbox("Performance")
PerfBox:AddToggle("DisableTextures", { Text = "Disable Textures", Default = false, Tooltip = "Вимикає текстури та матеріали для підвищення FPS (змінює на SmoothPlastic)" }):OnChanged(function(v)
    PerfSettings.Textures = v
    for _, obj in pairs(workspace:GetDescendants()) do handleTexture(obj, v) end
end)
PerfBox:AddToggle("DisableParticles", { Text = "Disable Particles", Default = false, Tooltip = "Вимикає частинки, сліди та дим для підвищення FPS" }):OnChanged(function(v)
    PerfSettings.Particles = v
    for _, obj in pairs(workspace:GetDescendants()) do handleParticle(obj, v) end
end)
PerfBox:AddToggle("DisableAnimations", { Text = "Disable Animations", Default = false, Tooltip = "Зупиняє всі ігрові анімації для максимального бусту FPS" }):OnChanged(function(v)
    PerfSettings.Animations = v
    if not v then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character and p.Character:FindFirstChildOfClass("Humanoid") then
            local animator = p.Character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
            if animator then for _, t in pairs(animator:GetPlayingAnimationTracks()) do t:Stop() end end
        end
    end
end)

-- ANIMATIONS SUB-TAB
local AnimBox = Tabs.Visuals:AddLeftGroupbox("Animations")

AnimBox:AddInput("RunAnimID", { Default = "", Numeric = true, Finished = false, Text = "Run Animation ID", Tooltip = "Введіть ID для кастомної анімації бігу" }):OnChanged(function(v) CustomAnims.Run.ID = v end)
AnimBox:AddToggle("PlayRunAnim", { Text = "Play Run Animation", Default = false, Tooltip = "Вмикає або вимикає кастомну анімацію бігу" }):OnChanged(function(v) CustomAnims.Run.Active = v; updateLocalAnim("Run") end)

AnimBox:AddInput("JumpAnimID", { Default = "", Numeric = true, Finished = false, Text = "Jump Animation ID", Tooltip = "Введіть ID для кастомної анімації стрибка" }):OnChanged(function(v) CustomAnims.Jump.ID = v end)
AnimBox:AddToggle("PlayJumpAnim", { Text = "Play Jump Animation", Default = false, Tooltip = "Вмикає або вимикає кастомну анімацію стрибка" }):OnChanged(function(v) CustomAnims.Jump.Active = v; updateLocalAnim("Jump") end)

AnimBox:AddInput("IdleAnimID", { Default = "", Numeric = true, Finished = false, Text = "Idle Animation ID", Tooltip = "Введіть ID для кастомної анімації стояння (Idle)" }):OnChanged(function(v) CustomAnims.Idle.ID = v end)
AnimBox:AddToggle("PlayIdleAnim", { Text = "Play Idle Animation", Default = false, Tooltip = "Вмикає або вимикає кастомну анімацію стояння" }):OnChanged(function(v) CustomAnims.Idle.Active = v; updateLocalAnim("Idle") end)

local SpecBox = Tabs.Visuals:AddRightGroupbox("Spectate")
SpecBox:AddToggle("SpectateToggle", { Text = "Enable Spectate", Default = false, Tooltip = "Вмикає спостереження за іншим гравцем" }):OnChanged(function(v)
	SpectateEnabled = v
	if not v then
		SpectateTargetPlayer = nil
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then Camera.CameraSubject = LocalPlayer.Character.Humanoid end
	end
end)
local SpectateDropdown = SpecBox:AddDropdown("SpectateTarget", { Values = GetPlayerNames(), Default = 1, Multi = false, Text = "Target Player", Tooltip = "Оберіть гравця для спостереження" })
SpectateDropdown:OnChanged(function(v)
    if v and v ~= "None" then SpectateTargetPlayer = Players:FindFirstChild(v) else SpectateTargetPlayer = nil end
end)

local MiscBox = Tabs.Visuals:AddRightGroupbox("Misc Settings")
MiscBox:AddToggle("FPSUnlock", { Text = "FPS Unlocker", Default = true, Tooltip = "Знімає ліміт FPS" }):OnChanged(function(v) 
    FPSUnlockerEnabled = v; if setfpscap then pcall(function() setfpscap(v and 9999 or 60) end) end 
end)
MiscBox:AddToggle("CamUnlock", { Text = "Camera Unlocker", Default = false, Tooltip = "Дозволяє віддаляти камеру нескінченно" }):OnChanged(function(v) 
    CamUnlockerEnabled = v; LocalPlayer.CameraMaxZoomDistance = v and 100000 or 128 
end)

-- Double Click Buttons
MiscBox:AddButton({
    Text = "Serverhop",
    DoubleClick = true,
    Tooltip = "Натисніть двічі, щоб перейти на інший сервер",
    Func = function()
        local servers = {}
        local req = (syn and syn.request) or request or http_request or (fluxus and fluxus.request)
        if req then
            pcall(function()
                local response = req({Url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100", Method = "GET"})
                if response and response.Body then
                    local body = HttpService:JSONDecode(response.Body)
                    for _, v in ipairs(body.data) do
                        if v.playing and v.maxPlayers and v.playing < v.maxPlayers and v.id ~= game.JobId then table.insert(servers, v.id) end
                    end
                end
            end)
            if #servers > 0 then TeleportService:TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], LocalPlayer); return end
        end
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

MiscBox:AddButton({
    Text = "Rejoin Server",
    DoubleClick = true,
    Tooltip = "Натисніть двічі, щоб перепідключитися до цього ж сервера",
    Func = function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) 
    end
})

-- ===================== ВКЛАДКА: PLAYER =====================
local MoveBox = Tabs.Player:AddLeftGroupbox("Movement")
MoveBox:AddToggle("WalkSpeedTog", { Text = "Custom WalkSpeed", Default = false, Tooltip = "Вмикає зміну швидкості бігу" }):OnChanged(function(v)
	SpeedEnabled = v 
	if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = 16 end
end)
MoveBox:AddSlider("WalkSpeedVal", { Text = "WalkSpeed Value", Default = 16, Min = 1, Max = 100, Rounding = 0, Tooltip = "Значення швидкості" }):OnChanged(function(v) TargetSpeed = v end)

MoveBox:AddToggle("Noclip", { Text = "Noclip", Default = false, Tooltip = "Дозволяє проходити крізь стіни" }):OnChanged(function(v)
	NoclipEnabled = v 
	if v and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then OriginalNoclipStates[part] = part.CanCollide end end
	elseif not v and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
			if part:IsA("BasePart") and OriginalNoclipStates[part] ~= nil then part.CanCollide = OriginalNoclipStates[part] end
		end
		table.clear(OriginalNoclipStates)
	end
end)
MoveBox:AddToggle("InfJump", { Text = "Infinite Jump", Default = false, Tooltip = "Дозволяє стрибати у повітрі" }):OnChanged(function(v) InfJumpEnabled = v end)

local FlyBox = Tabs.Player:AddRightGroupbox("Fly Settings")
FlyBox:AddToggle("FlyTog", { Text = "Fly", Default = false, Tooltip = "Вмикає політ" }):OnChanged(function(v) FlyEnabled = v end)
FlyBox:AddSlider("FlySpeed", { Text = "Fly Speed", Default = 50, Min = 1, Max = 200, Rounding = 0, Tooltip = "Швидкість польоту" }):OnChanged(function(v) FlySpeed = v end)

-- ===================== ВКЛАДКА: COMBAT =====================
local AimbotBox = Tabs.Combat:AddLeftGroupbox("Aimbot")
AimbotBox:AddToggle("Aimbot", { Text = "Enable Aimbot", Default = false, Tooltip = "Автоматично наводить камеру на ворога" }):OnChanged(function(v) AimbotEnabled = v end)
AimbotBox:AddDropdown("AimTarget", { Values = {"Head", "Torso"}, Default = 1, Multi = false, Text = "Target Part", Tooltip = "Частина тіла для націлювання" }):OnChanged(function(v) AimbotTarget = v end)
AimbotBox:AddToggle("WallCheck", { Text = "Wall Check", Default = true, Tooltip = "Перевіряє чи є стіна між вами та ворогом" }):OnChanged(function(v) WallCheckEnabled = v end)
AimbotBox:AddSlider("AimSmooth", { Text = "Aimbot Smoothness", Default = 0, Min = 0, Max = 100, Rounding = 0, Tooltip = "Плавність наведення Aimbot" }):OnChanged(function(v) Smoothness = v end)

local FOVBox = Tabs.Combat:AddRightGroupbox("FOV")
FOVBox:AddToggle("FOVCircle", { Text = "Show FOV Circle", Default = false, Tooltip = "Показує радіус дії Aimbot" }):OnChanged(function(v) FOVEnabled = v; FOVCircleUI.Visible = v end)
FOVBox:AddToggle("RainbowFOV", { Text = "Rainbow FOV", Default = false, Tooltip = "Робить коло FOV переливчастим" }):OnChanged(function(v)
	RainbowFOVEnabled = v; if not v and UIStroke then UIStroke.Color = Color3.fromRGB(255, 255, 255) end
end)
FOVBox:AddSlider("FOVCircleSize", { Text = "FOV Size", Default = 180, Min = 20, Max = 400, Rounding = 0, Tooltip = "Розмір радіуса Aimbot" }):OnChanged(function(v)
	FOVRadius = v
	if FOVCircleUI then
		FOVCircleUI.Size = UDim2.new(0, FOVRadius * 2, 0, FOVRadius * 2)
		FOVCircleUI.Position = UDim2.new(0.5, -FOVRadius, 0.5, -FOVRadius)
	end
end)

-- ===================== ВКЛАДКА: TEAM CHECK =====================
local TeamBox = Tabs.TeamCheck:AddLeftGroupbox("Whitelist")
local WhitelistDropdown = TeamBox:AddDropdown("WhitelistPlayers", {
	Values = GetPlayerNames(), Multi = true, Text = "Whitelisted Players", Tooltip = "Гравці, яких не буде цілити Aimbot"
})
WhitelistDropdown:OnChanged(function(selected) WhitelistedNames = selected end)

Players.PlayerAdded:Connect(function() SpectateDropdown:SetValues(GetPlayerNames()); WhitelistDropdown:SetValues(GetPlayerNames()) end)
Players.PlayerRemoving:Connect(function() SpectateDropdown:SetValues(GetPlayerNames()); WhitelistDropdown:SetValues(GetPlayerNames()) end)

-- ===================== ВКЛАДКА: FREE CAM =====================
local FCBox = Tabs.FreeCam:AddLeftGroupbox("Camera Controls")
FCBox:AddToggle("FCToggle", { Text = "Enable Free Camera", Default = false, Tooltip = "Вільна камера для польоту по карті" }):OnChanged(function(s)
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
FCBox:AddToggle("FCFreeze", { Text = "Freeze Character During Freecam", Default = false, Tooltip = "Заморожує вашого персонажа, поки включена Free Cam" }):OnChanged(function(s)
	FreezeDuringEnabled = s
	if not s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.Character.HumanoidRootPart.Anchored = false end
end)
FCBox:AddSlider("FCSpeed", { Text = "Free Cam Speed", Default = 60, Min = 10, Max = 300, Rounding = 0, Tooltip = "Швидкість польоту камери" }):OnChanged(function(v) FC_Speed = v end)

-- ===================== UI SETTINGS =====================
ThemeManager:SetLibrary(Library); SaveManager:SetLibrary(Library); SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({'WhitelistPlayers', 'SpectateTarget'})
ThemeManager:SetFolder('ChronoHub'); SaveManager:SetFolder('ChronoHub/Configs')
SaveManager:BuildConfigSection(Tabs.UISettings); ThemeManager:ApplyToTab(Tabs.UISettings)
SaveManager:LoadAutoloadConfig()

-- ===================== ДОПОМІЖНІ ФУНКЦІЇ =====================
function handleTexture(v, disable)
    if disable then
        if v:IsA("BasePart") and not cacheMaterials[v] then
            cacheMaterials[v] = v.Material; v.Material = Enum.Material.SmoothPlastic
        elseif (v:IsA("Decal") or v:IsA("Texture")) and not cacheDecals[v] then
            cacheDecals[v] = v.Transparency; v.Transparency = 1
        end
    else
        if v:IsA("BasePart") and cacheMaterials[v] then v.Material = cacheMaterials[v]; cacheMaterials[v] = nil
        elseif (v:IsA("Decal") or v:IsA("Texture")) and cacheDecals[v] then v.Transparency = cacheDecals[v]; cacheDecals[v] = nil end
    end
end

function handleParticle(v, disable)
    if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
        if disable then
            if cacheParticles[v] == nil then cacheParticles[v] = v.Enabled end; v.Enabled = false
        else
            if cacheParticles[v] ~= nil then v.Enabled = cacheParticles[v]; cacheParticles[v] = nil end
        end
    end
end

workspace.DescendantAdded:Connect(function(v)
    if PerfSettings.Textures then handleTexture(v, true) end
    if PerfSettings.Particles then handleParticle(v, true) end
end)

function updateLocalAnim(animType)
    local char = LocalPlayer.Character
    if not char then return end
    local animate = char:FindFirstChild("Animate")
    if not animate then return end
    
    local cfg = CustomAnims[animType]
    if cfg then
        local folder = animate:FindFirstChild(cfg.Path[1])
        local animObj = folder and folder:FindFirstChild(cfg.Path[2])
        if animObj then
            if not OriginalAnims[animType] then OriginalAnims[animType] = animObj.AnimationId end
            if cfg.Active and cfg.ID ~= "" then
                animObj.AnimationId = "rbxassetid://" .. cfg.ID
            else
                if OriginalAnims[animType] then animObj.AnimationId = OriginalAnims[animType] end
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    updateLocalAnim("Run")
    updateLocalAnim("Jump")
    updateLocalAnim("Idle")
end)

local function getTargetPart(char) return AimbotTarget == "Head" and char:FindFirstChild("Head") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart") end
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
	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and not WhitelistedNames[player.Name] then
			local char = player.Character
			if char and char:FindFirstChildOfClass("Humanoid") and char:FindFirstChildOfClass("Humanoid").Health > 0 then
				local targetPart = getTargetPart(char)
				if targetPart and isVisible(targetPart) then
					local dir = (targetPart.Position - Camera.CFrame.Position).Unit
					if Camera.CFrame.LookVector:Dot(dir) > 0 then
						local pos = Camera:WorldToViewportPoint(targetPart.Position)
						local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
						if (not FOVEnabled or dist <= FOVRadius) and dist < shortestDist then shortestDist, closestPlayer = dist, targetPart end
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
	t.Highlight = Instance.new("Highlight", ESP_Folder); t.Highlight.OutlineColor = Color3.fromRGB(255, 255, 255); t.Highlight.FillTransparency = 0.5; t.Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; t.Highlight.Enabled = false
	t.BoxFrame = Instance.new("Frame", ESP_Folder); t.BoxFrame.BackgroundTransparency = 1; t.BoxStroke = Instance.new("UIStroke", t.BoxFrame); t.BoxStroke.Thickness = 1
	t.NameLbl = Instance.new("TextLabel", ESP_Folder); t.NameLbl.BackgroundTransparency = 1; t.NameLbl.Font = Enum.Font.GothamBold; t.NameLbl.TextSize = 12
	t.HPBarBg = Instance.new("Frame", ESP_Folder); t.HPBarBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0); t.HPBarBg.BorderSizePixel = 0
	t.HPBar = Instance.new("Frame", t.HPBarBg); t.HPBar.BackgroundColor3 = Color3.fromRGB(50, 255, 50); t.HPBar.BorderSizePixel = 0
	t.StudsLbl = Instance.new("TextLabel", ESP_Folder); t.StudsLbl.BackgroundTransparency = 1; t.StudsLbl.TextColor3 = Color3.fromRGB(255, 255, 255); t.StudsLbl.Font = Enum.Font.GothamBold; t.StudsLbl.TextSize = 12
	local StudsStroke = Instance.new("UIStroke", t.StudsLbl); StudsStroke.Thickness = 1.5; StudsStroke.Color = Color3.fromRGB(0, 0, 0)
	t.BoxFrame.Visible = false; t.NameLbl.Visible = false; t.HPBarBg.Visible = false; t.StudsLbl.Visible = false
	ESP_Elements[player] = t
	return t
end

Players.PlayerRemoving:Connect(function(player)
	if ESP_Elements[player] then
		for _, v in pairs(ESP_Elements[player]) do if typeof(v) == "Instance" then pcall(function() v:Destroy() end) end end
		ESP_Elements[player] = nil
	end
end)

RunService.Stepped:Connect(function()
	if NoclipEnabled and LocalPlayer.Character then
		for _, part in pairs(LocalPlayer.Character:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end
	end
end)

local lastFpsTick = tick()
local origAmbient, origFogEnd = Lighting.Ambient, Lighting.FogEnd

RunService.RenderStepped:Connect(function(dt)
	if tick() - lastFpsTick >= 0.5 then
		pcall(function() FPSLabel:SetText("FPS: " .. math.round(1 / dt)); PingLabel:SetText("Ping: " .. math.floor(LocalPlayer:GetNetworkPing() * 1000) .. " ms") end)
		lastFpsTick = tick()
	end
	
	if FOVEnabled and RainbowFOVEnabled and UIStroke then UIStroke.Color = Color3.fromHSV((tick() % 3) / 3, 1, 1) end
	if FOVChangerEnabled then Camera.FieldOfView = CustomFOV end
	if FullbrightEnabled then Lighting.Ambient = Color3.new(1,1,1) else Lighting.Ambient = origAmbient end
	if NoFogEnabled then Lighting.FogEnd = 100000 else Lighting.FogEnd = origFogEnd end

    if PerfSettings.Animations then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChildOfClass("Humanoid") then
                local animator = p.Character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
                if animator then for _, t in pairs(animator:GetPlayingAnimationTracks()) do t:Stop() end end
            end
        end
    end

	local pGui = LocalPlayer:FindFirstChild("PlayerGui")
	local customJumpBtn = pGui and pGui:FindFirstChild("MainGui") and pGui.MainGui:FindFirstChild("MainFrame") and pGui.MainGui.MainFrame:FindFirstChild("MobileButtons") and pGui.MainGui.MainFrame.MobileButtons:FindFirstChild("JumpButton")
	if customJumpBtn then customJumpBtn.Visible = EnableJumpToggle end

	if EnableJumpToggle and LocalPlayer.Character then
		local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true); if hum.JumpPower == 0 then hum.JumpPower = 50 end end
	end

	if LocalPlayer.Character then
		local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if hum and (NoCamBobbingEnabled or NoCamShakeEnabled) then hum.CameraOffset = Vector3.zero end
	end

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
		local hrp, hum = char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
		if hrp and hum then
			if SpeedEnabled and not FlyEnabled then
				if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
				local moveDir = hum.MoveDirection
				if moveDir.Magnitude > 0.01 then hrp.AssemblyLinearVelocity = Vector3.new((moveDir * TargetSpeed).X, hrp.AssemblyLinearVelocity.Y, (moveDir * TargetSpeed).Z) end
			end
			
			if FlyEnabled then
				hum.PlatformStand = false
				local moveDir, camCFrame, vel = hum.MoveDirection, Camera.CFrame, Vector3.zero
				if moveDir.Magnitude > 0.01 then
					local flyDir = (camCFrame.LookVector * Vector3.new(camCFrame.LookVector.X, 0, camCFrame.LookVector.Z).Unit:Dot(moveDir)) + (camCFrame.RightVector * Vector3.new(camCFrame.RightVector.X, 0, camCFrame.RightVector.Z).Unit:Dot(moveDir))
					if flyDir.Magnitude > 0 then vel = flyDir.Unit * FlySpeed end
				end
				local verticalVel = 0
				if UserInputService:IsKeyDown(Enum.KeyCode.Space) then verticalVel = FlySpeed elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then verticalVel = -FlySpeed end
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
				else
					if OriginalSizes[rootPart] then pcall(function() rootPart.Size = OriginalSizes[rootPart]; rootPart.Transparency = 1; rootPart.CanCollide = false end) end
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
						if ESPSettings.Studs then espUI.StudsLbl.Text = tostring(math.floor((Camera.CFrame.Position - rootPart.Position).Magnitude)) .. "s"; espUI.StudsLbl.Size = UDim2.new(0, w, 0, 15); espUI.StudsLbl.Position = UDim2.new(0, x, 0, y + h + 2); espUI.StudsLbl.Visible = true else espUI.StudsLbl.Visible = false end
					else espUI.BoxFrame.Visible = false; espUI.NameLbl.Visible = false; espUI.HPBarBg.Visible = false; espUI.StudsLbl.Visible = false end
				else espUI.Highlight.Enabled = false; espUI.BoxFrame.Visible = false; espUI.NameLbl.Visible = false; espUI.HPBarBg.Visible = false; espUI.StudsLbl.Visible = false end
			else espUI.Highlight.Enabled = false; espUI.BoxFrame.Visible = false; espUI.NameLbl.Visible = false; espUI.HPBarBg.Visible = false; espUI.StudsLbl.Visible = false end
		end
	end
end)

UserInputService.JumpRequest:Connect(function()
	if (InfJumpEnabled or EnableJumpToggle) and LocalPlayer.Character then
		local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end) end
	end
end)
