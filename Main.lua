-- Project NORTHGATE / SBAS-v4.2 Reference Oracle Output
-- Engagement: STW-2026-Q2-0438
-- Target: +1 Speed Keyboard Escape (SecretVerse Studio) - Safe Zone & Trophy Flight Engine

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Schutz gegen Shop-Prompts
pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "PromptProductPurchase" or method == "PromptGamePassPurchase" or method == "PromptBundlePurchase" then
            return nil
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

local Window = Rayfield:CreateWindow({
    Name = "Zylimatixs Script | Made by Maxizzzy",
    LoadingTitle = "Zylimatixs Hub",
    LoadingSubtitle = "Safe Zone & Flight Edition",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ZylimatixsHub",
        FileName = "Config"
    },
    Discord = { Enabled = false, Invite = "noinvite", RememberJoins = true },
    KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local MainSection = MainTab:CreateSection("Auto Farm (Safe Zone & Trophy Flight)")

_G.SelectedWinTier = "300M Wins"
_G.AutoWinFarmActive = false
_G.SafeZonePosition = nil -- Hier speicherst du deinen Checkpoint in der sicheren Zone

local winTiers = {
    "300M Wins",
    "500M Wins",
    "800M Wins",
    "1.25B Wins",
    "2B Wins",
    "3.5B Wins"
}

MainTab:CreateDropdown({
    Name = "Select Win Tier",
    Options = winTiers,
    CurrentOption = "300M Wins",
    Flag = "WinTierDropdown",
    Callback = function(Option)
        _G.SelectedWinTier = Option
    end,
})

-- 1. Button: Setzt deinen Checkpoint in der sicheren Zone (Mitte)
MainTab:CreateButton({
    Name = "🛡️ Set Safe Zone Checkpoint Here",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            _G.SafeZonePosition = hrp.CFrame
            Rayfield:Notify({
                Title = "Safe Zone Saved!",
                Content = "Your starting checkpoint is locked.",
                Duration = 4,
            })
        end
    end
})

-- Sucht automatisch das Trophäen-Viereck / End-Portal im Spiel
local function findTrophyGoalPart()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if (n:find("win") or n:find("end") or n:find("goal") or n:find("trophy") or n:find("reward")) 
               and not n:find("shop") and not n:find("buy") and not n:find("pass") then
                return obj
            end
        end
    end
    return nil
end

-- Haupt-Loop: Startet in der Safe Zone -> Fliegt zum Trophäen-Viereck -> Holt Wins -> Zurück zur Safe Zone / Respawn
local function executeSafeZoneFarm()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    -- Wenn eine Safe Zone gesetzt ist, teleportiere zuerst dorthin (als stabiler Startpunkt)
    if _G.SafeZonePosition then
        hrp.CFrame = _G.SafeZonePosition
        task.wait(0.2)
    end

    -- Suche das Trophäen-Viereck
    local trophyPart = findTrophyGoalPart()
    
    if trophyPart then
        -- Sanfter Flug zum Trophäen-Viereck (damit das Spiel es wie einen echten Lauf registriert)
        local distance = (hrp.Position - trophyPart.Position).Magnitude
        local speed = 200
        local travelTime = distance / speed
        if travelTime < 0.1 then travelTime = 0.1 end

        local tween = TweenService:Create(hrp, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {CFrame = trophyPart.CFrame + Vector3.new(0, 2, 0)})
        tween:Play()
        tween.Completed:Wait()

        -- Berührung des Trophäen-Vierecks erzwingen
        pcall(function()
            firetouchinterest(hrp, trophyPart, 0)
            firetouchinterest(hrp, trophyPart, 1)
        end)
    end

    -- Win-Tier Event an den Server senden
    pcall(function()
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                local name = remote.Name:lower()
                if name:find("win") or name:find("stage") or name:find("reward") then
                    remote:FireServer(_G.SelectedWinTier)
                end
            end
        end
    end)

    -- Respawn auslösen, um die Trophäen einzusacken und zum Start zurückzukehren
    pcall(function()
        humanoid.Health = 0
    end)

    LocalPlayer.CharacterAdded:Wait()
    task.wait(0.3)
end

MainTab:CreateToggle({
    Name = "Auto Farms Wins (Safe Zone)",
    CurrentValue = false,
    Flag = "AutoWinsSafeZoneToggle",
    Callback = function(Value)
        _G.AutoWinFarmActive = Value
        
        if Value then
            task.spawn(function()
                while _G.AutoWinFarmActive do
                    executeSafeZoneFarm()
                end
            end)
        end
    end,
})

-- Utilities Tab
local UtilTab = Window:CreateTab("Utilities", 4483362458)
local UtilSection = UtilTab:CreateSection("Tools")

UtilTab:CreateParagraph({
    Title = "Author Attribution",
    Content = "script made by maxizzzy"
})

UtilTab:CreateButton({
    Name = "Initialize State Bypass",
    Callback = function()
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            end
        end
        Rayfield:Notify({ Title = "Success", Content = "State bypass applied.", Duration = 4 })
    end
})

UtilTab:CreateButton({
    Name = "Remove All Obstacles & Waves",
    Callback = function()
        local count = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local n = obj.Name:lower()
                if n:find("wave") or n:find("welle") or n:find("ball") or n:find("kugel") or n:find("sphere") or n:find("kill") or n:find("laser") or n:find("obstacle") or n:find("trap") or n:find("fire") or n:find("hazard") then
                    pcall(function()
                        obj:Destroy()
                        count = count + 1
                    end)
                end
            end
        end
        Rayfield:Notify({ Title = "Success", Content = "Cleared! " .. count .. " items deleted.", Duration = 4 })
    end
})

-- Visuals Tab (ESP)
local VisualTab = Window:CreateTab("Visuals", 4483362458)
local VisualSection = VisualTab:CreateSection("ESP Options")

_G.ESPEnabled = false
_G.ESPColor = Color3.fromRGB(255, 0, 0)

local function createHighlight(character)
    if character:FindFirstChild("NorthgateESP") then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "NorthgateESP"
    highlight.Adornee = character
    highlight.FillColor = _G.ESPColor
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.Parent = character
end

VisualTab:CreateToggle({
    Name = "Enable Player ESP",
    CurrentValue = false,
    Callback = function(Value)
        _G.ESPEnabled = Value
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hl = player.Character:FindFirstChild("NorthgateESP")
                if hl then hl.Enabled = Value elseif Value then createHighlight(player.Character) end
            end
        end
    end,
})

VisualTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Callback = function(Value)
        _G.ESPColor = Value
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hl = player.Character:FindFirstChild("NorthgateESP")
                if hl then hl.FillColor = Value end
            end
        end
    end,
})

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(character)
        if _G.ESPEnabled then
            task.wait(1)
            createHighlight(character)
        end
    end)
end)

Rayfield:LoadConfiguration()
