-- Project NORTHGATE / SBAS-v4.2 Reference Oracle Output
-- Engagement: STW-2026-Q2-0438
-- Target: +1 Speed Keyboard Escape (SecretVerse Studio)

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

-- Intelligenter Remote & Trigger-Finder für SecretVerse Spiele
local function triggerWinRemote()
    local success = false
    
    -- Methode 1: Suche nach RemoteEvents im ReplicatedStorage (Standard für Simulator/Escape Games)
    for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local name = v.Name:lower()
            if name:find("win") or name:find("finish") or name:find("claim") or name:find("stage") or name:find("reward") then
                pcall(function()
                    v:FireServer(_G.SelectedWinTier)
                    success = true
                end)
            end
        end
    end
    
    -- Methode 2: Physisches Antippen des End-Portals oder der World 3 Win-Zone im Workspace
    if not success then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local nameLower = obj.Name:lower()
                if nameLower:find("win") or nameLower:find("end") or nameLower:find("goal") or nameLower:find("portal") then
                    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if root then
                        pcall(function()
                            firetouchinterest(root, obj, 0)
                            firetouchinterest(root, obj, 1)
                            success = true
                        end)
                    end
                end
            end
        end
    end
    
    return success
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
                    triggerWinRemote()
                    task.wait(0.5) -- Schneller Intervall für den Win-Loop
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
}

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
