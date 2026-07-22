-- Project NORTHGATE / SBAS-v4.2 Reference Oracle Output
-- Engagement: STW-2026-Q2-0438
-- Target: +1 Speed Keyboard Escape (SecretVerse Studio) - Smooth Glide / Tween Movement System

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Dauerhafter Anti-Prompt Schutz (verhindert das Kaufen-Fenster)
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
    LoadingSubtitle = "Glide Progression Edition",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ZylimatixsHub",
        FileName = "Config"
    },
    Discord = { Enabled = false, Invite = "noinvite", RememberJoins = true },
    KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local MainSection = MainTab:CreateSection("Auto Win (Glide System)")

_G.SelectedWinTier = "300M Wins"
_G.AutoWinFarmActive = false

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

-- Aggressive Objektauslöschung für Wellen und Kugeln
local function wipeAllHazards()
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local n = obj.Name:lower()
            if n:find("wave") or n:find("welle") or n:find("ball") or n:find("kugel") or n:find("sphere") 
               or n:find("kill") or n:find("laser") or n:find("obstacle") or n:find("trap") 
               or n:find("fire") or n:find("hazard") or n:find("roller") or n:find("moving") then
                pcall(function()
                    obj:Destroy()
                    count = count + 1
                end)
            end
        end
    end
    return count
end

-- Das exakte Glide-System aus dem Video: Gleitet fließend von Stufe zu Stufe an den Tasten entlang
local function executeGlideProgression()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    -- Wellen und Kugeln im Hintergrund wegräumen
    wipeAllHazards()

    -- Sammelt alle Tasten/Plattformen im Obby sequentiell ein
    local stages = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if (n:find("stage") or n:find("checkpoint") or n:find("platform") or n:find("key") or n:find("win")) 
               and not n:find("shop") and not n:find("buy") and not n:find("pass") and not n:find("ball") and not n:find("wave") then
                table.insert(stages, obj)
            end
        end
    end

    table.sort(stages, function(a, b)
        return a.Position.Y < b.Position.Y
    end)

    if #stages > 0 then
        for _, stagePart in ipairs(stages) do
            if not _G.AutoWinFarmActive then break end
            
            -- Berechnet die Distanz für ein flüssiges Gleiten (Glide) an den Tasten entlang
            local distance = (hrp.Position - stagePart.Position).Magnitude
            local glideSpeed = 160 -- Gleit-Geschwindigkeit
            local travelTime = distance / glideSpeed
            if travelTime < 0.08 then travelTime = 0.08 end

            local tweenInfo = TweenInfo.new(travelTime, Enum.EasingStyle.Linear)
            local tween = TweenService:Create(hrp, tweenInfo, {CFrame = stagePart.CFrame + Vector3.new(0, 3, 0)})
            
            tween:Play()
            tween.Completed:Wait()

            pcall(function()
                firetouchinterest(hrp, stagePart, 0)
                firetouchinterest(hrp, stagePart, 1)
            end)
            
            task.wait(0.05)
        end
    end

    -- Endpunkt / Win-Zone berühren
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("win") or n:find("end") or n:find("goal") then
                local distance = (hrp.Position - obj.Position).Magnitude
                local travelTime = distance / 160
                local tween = TweenService:Create(hrp, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {CFrame = obj.CFrame + Vector3.new(0, 3, 0)})
                tween:Play()
                tween.Completed:Wait()
                
                pcall(function()
                    firetouchinterest(hrp, obj, 0)
                    firetouchinterest(hrp, obj, 1)
                end)
            end
        end
    end

    -- Event für den ausgewählten Win-Tier senden
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

    -- Sofortiger Respawn, um die Trophäen gutzuschreiben und neu zu starten
    pcall(function()
        humanoid.Health = 0
    end)

    LocalPlayer.CharacterAdded:Wait()
    task.wait(0.2)
end

MainTab:CreateToggle({
    Name = "Enable Auto Win (Selected Tier)",
    CurrentValue = false,
    Flag = "AutoWinGlideToggle",
    Callback = function(Value)
        _G.AutoWinFarmActive = Value
        
        if Value then
            task.spawn(function()
                while _G.AutoWinFarmActive do
                    executeGlideProgression()
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
    Name = "Remove All Obstacles",
    Callback = function()
        local count = wipeAllHazards()
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
