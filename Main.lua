-- Project NORTHGATE / SBAS-v4.2 Reference Oracle Output
-- Engagement: STW-2026-Q2-0438
-- Target: +1 Speed Keyboard Escape (SecretVerse Studio) - Precision World 3 Farm

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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
local MainSection = MainTab:CreateSection("Auto Farms Wins (World 3)")

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

-- Gezielte Suche nach dem echten Welt 3 End-Trigger (verhindert das Teleportieren ins Nirgendwo)
local function getPreciseWorld3Goal()
    -- Suche zuerst nach spezifischen Welt 3 End-Ordnern oder Plattformen
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            -- Sagt das Teil explizit World 3 / Stage 3 End-Zone aus?
            if (n:find("world3") or n:find("stage3") or n:find("world_3") or n:find("stage_3")) and (n:find("end") or n:find("win") or n:find("goal") or n:find("portal")) then
                return obj
            end
        end
    end
    
    -- Fallback: Letztes Zielteil vor dem Übergang
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if (n:find("win") or n:find("finish")) and not n:find("shop") and not n:find("buy") and not n:find("pass") then
                return obj
            end
        end
    end
    return nil
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
                    -- 1. Versuche das Win-Event direkt über ReplicatedStorage anzusprechen (Sicherste Methode ohne Teleport-Chaos)
                    local fired = false
                    pcall(function()
                        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                            if remote:IsA("RemoteEvent") then
                                local rName = remote.Name:lower()
                                if rName:find("win") or rName:find("stage") or rName:find("escape") then
                                    remote:FireServer(_G.SelectedWinTier)
                                    fired = true
                                end
                            end
                        end
                    end)
                    
                    -- 2. Wenn kein Remote gefunden wurde, nutze den präzisen Workspace-Teleport zum echten Welt 3 Ziel
                    if not fired then
                        local char = LocalPlayer.Character
                        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
                        local target = getPreciseWorld3Goal()
                        
                        if hrp and target then
                            hrp.CFrame = target.CFrame + Vector3.new(0, 3, 0)
                            pcall(function()
                                firetouchinterest(hrp, target, 0)
                                firetouchinterest(hrp, target, 1)
                            end)
                        end
                    end
                    
                    task.wait(1.5)
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
