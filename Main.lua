-- Project NORTHGATE / SBAS-v4.2 Reference Oracle Output
-- Engagement: STW-2026-Q2-0438
-- Target: +1 Speed Keyboard Escape (SecretVerse Studio) - 1:1 Parity Loop & Obstacle Eraser

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

-- Vollständiger Schutz vor jeglichen Shop- oder Kauf-Prompts
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
    LoadingSubtitle = "script made by maxizzzy",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ZylimatixsHub",
        FileName = "Config"
    },
    Discord = { Enabled = false, Invite = "noinvite", RememberJoins = true },
    KeySystem = false
})

local MainTab = Window:CreateTab("MAIN", 4483362458)
local MainSection = MainTab:CreateSection("Auto Farms Wins")

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

-- Aggressive Objektauslöschung, die wirklich alle Wellen, Kugeln, Laser und Kills-Teile im gesamten Spiel sofort vernichtet
local function wipeAllObstacles()
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local nameLower = obj.Name:lower()
            if nameLower:find("wave") or nameLower:find("welle") or nameLower:find("ball") or nameLower:find("kugel") or nameLower:find("sphere") 
               or nameLower:find("kill") or nameLower:find("laser") or nameLower:find("obstacle") or nameLower:find("trap") 
               or nameLower:find("fire") or nameLower:find("hazard") or nameLower:find("roller") or nameLower:find("moving") 
               or nameLower:find("damage") or nameLower:find("hurt") then
                pcall(function()
                    obj:Destroy()
                    count = count + 1
                end)
            end
        end
    end
    return count
end

-- Präzises Durchlaufen der tatsächlichen Stage-Plattformen von unten nach oben (wie im funktionierenden Skript)
local function executeExactPathLoop()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    -- Ständige Säuberung der Wellen/Kugeln während des Laufs
    wipeAllObstacles()

    local stages = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            -- Findet ausschließlich die echten Stage- und Checkpoint-Plattformen
            if (n:find("stage") or n:find("checkpoint") or n:find("platform")) 
               and not n:find("shop") and not n:find("buy") and not n:find("pass") and not n:find("ball") and not n:find("wave") then
                table.insert(stages, obj)
            end
        end
    end

    -- Von der untersten zur obersten Plattform sortieren
    table.sort(stages, function(a, b)
        return a.Position.Y < b.Position.Y
    end)

    if #stages > 0 then
        for _, stagePart in ipairs(stages) do
            if not _G.AutoWinFarmActive then break end
            
            -- Sauber auf die Plattform setzen
            hrp.CFrame = stagePart.CFrame + Vector3.new(0, 3, 0)
            pcall(function()
                firetouchinterest(hrp, stagePart, 0)
                firetouchinterest(hrp, stagePart, 1)
            end)
            
            -- Kurze, saubere Pause auf jeder Plattform, damit das Spiel sie registriert
            task.wait(0.2)
        end
    end

    -- Zum Schluss den finalen Win-Punkt oder das End-Portal ansteuern und auslösen
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("win") or n:find("end") or n:find("goal") then
                hrp.CFrame = obj.CFrame + Vector3.new(0, 3, 0)
                pcall(function()
                    firetouchinterest(hrp, obj, 0)
                    firetouchinterest(hrp, obj, 1)
                end)
            end
        end
    end

    -- Remote Event für den gewählten Win-Tier feuern
    pcall(function()
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                local rName = remote.Name:lower()
                if rName:find("win") or rName:find("stage") or rName:find("reward") then
                    remote:FireServer(_G.SelectedWinTier)
                end
            end
        end
    end)

    -- Sofortiger Respawn ohne störendes Delay, um den Loop nahtlos fortzusetzen
    pcall(function()
        humanoid.Health = 0
    end)

    LocalPlayer.CharacterAdded:Wait()
    task.wait(0.3)
end

MainTab:CreateToggle({
    Name = "Auto Farms Wins",
    CurrentValue = false,
    Flag = "AutoWinsToggleMain",
    Callback = function(Value)
        _G.AutoWinFarmActive = Value
        
        if Value then
            task.spawn(function()
                while _G.AutoWinFarmActive do
                    executeExactPathLoop()
                end
            end)
        end
    end,
})

-- Utilities Tab
local UtilTab = Window:CreateTab("Utilities", 4483362458)
UtilTab:CreateParagraph({ Title = "Author Attribution", Content = "script made by maxizzzy" })

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

-- Button zum sofortigen Löschen aller Wellen und Hindernisse
UtilTab:CreateButton({
    Name = "Remove All Obstacles & Waves",
    Callback = function()
        local count = wipeAllObstacles()
        Rayfield:Notify({
            Title = "Success",
            Content = "Cleared! " .. count .. " obstacles & waves deleted.",
            Duration = 5,
        })
    end
})

-- Visuals Tab (ESP)
local VisualTab = Window:CreateTab("Visuals", 4483362458)
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
