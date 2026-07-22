-- Project NORTHGATE / SBAS-v4.2 Reference Oracle Output
-- Engagement: STW-2026-Q2-0438
-- Target: +1 Speed Keyboard Escape (SecretVerse Studio) - Stage Progression & Obstacle Removal

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

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
local MainSection = MainTab:CreateSection("Auto Farms Wins (Stage Progression)")

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

-- Funktion zum Finden und sequentiellen Durchlaufen der Stages (Stage 1 -> Stage 2 -> Stage 3 / End)
local function getStagesInOrder()
    local stages = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nameLower = obj.Name:lower()
            -- Sucht nach Stage-Teilen, Plattformen oder Checkpoints
            if nameLower:find("stage") or nameLower:find("checkpoint") or nameLower:find("platform") or nameLower:find("win") or nameLower:find("end") then
                if not nameLower:find("shop") and not nameLower:find("buy") and not nameLower:find("pass") then
                    table.insert(stages, obj)
                end
            end
        end
    end
    
    -- Sortiert die Stages nach ihrer Höhe (Y-Koordinate) oder Position, damit sie nacheinander abgelaufen werden
    table.sort(stages, function(a, b)
        return a.Position.Y < b.Position.Y
    end)
    
    return stages
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
                    local char = LocalPlayer.Character
                    local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
                    
                    if hrp then
                        local stages = getStagesInOrder()
                        if #stages > 0 then
                            -- Geht die Stages nacheinander kurz durch, damit das Spiel den Fortschritt registriert
                            for _, stagePart in ipairs(stages) do
                                if not _G.AutoWinFarmActive then break end
                                hrp.CFrame = stagePart.CFrame + Vector3.new(0, 3, 0)
                                pcall(function()
                                    firetouchinterest(hrp, stagePart, 0)
                                    firetouchinterest(hrp, stagePart, 1)
                                end)
                                task.wait(0.25) -- Kurze Pause auf jeder Plattform, damit das Spiel es "sieht"
                            end
                        end
                    end
                    
                    task.wait(1)
                end
            end)
        end
    end,
})

-- Neuer Tab für Utilities / Funktionen (Entfernen von Hindernissen)
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

-- Button zum Entfernen aller Hindernisse (Wellen, Kugeln etc.)
UtilTab:CreateButton({
    Name = "Remove Obstacles (Waves, Balls, etc.)",
    Callback = function()
        local removedCount = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local nameLower = obj.Name:lower()
                -- Filtert typische Hindernisse wie Wellen, Kugeln, Laser, Fallen, Killszteine
                if nameLower:find("wave") or nameLower:find("ball") or nameLower:find("kugel")  
                   or nameLower:find("kill") or nameLower:find("laser") or nameLower:find("obstacle") 
                   or nameLower:find("hazard") or nameLower:find("trap") or nameLower:find("fire") then
                    pcall(function()
                        obj:Destroy()
                        removedCount = removedCount + 1
                    end)
                end
            end
        end
        Rayfield:Notify({
            Title = "Obstacles Removed",
            Content = "Successfully deleted " .. removedCount .. " hazard objects from the map.",
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
