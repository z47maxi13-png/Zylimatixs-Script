-- Project NORTHGATE / SBAS-v4.2 Reference Oracle Output
-- Engagement: STW-2026-Q2-0438
-- Target: +1 Speed Keyboard Escape (SecretVerse Studio) - Fixed Underground Teleport & Clean Glide

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Ultimativer Schutz gegen Shop-Prompts (verhindert das "You already own this item"-Fenster komplett)
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
    LoadingSubtitle = "Anti-Underground Glide Edition",
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

-- Aggressive Objektauslöschung für alle Hindernisse, Wellen und Kugeln
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

-- Behobenes Gleit-System: Gleitet NUR oberhalb der Map und fällt niemals unter die Stage!
local function executeAboveMapGlide()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    wipeAllHazards()

    -- Sammelt nur echte, begehbare Platten oberhalb des Spielers ein und filtert Untergrund-Teile heraus
    local playerY = hrp.Position.Y
    local stages = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            -- Stellt sicher, dass das Zielteil oberhalb oder auf Höhe des Spielers ist (verhindert das Landen im Untergrund)
            if (n:find("stage") or n:find("checkpoint") or n:find("platform") o
