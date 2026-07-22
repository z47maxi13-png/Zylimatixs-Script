-- Project NORTHGATE / SBAS-v4.2 Reference Oracle Output
-- Engagement: STW-2026-Q2-0438
-- Target: +1 Speed Keyboard Escape (SecretVerse Studio) - Pathfinding & Complete Hazard Eradication

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Anti-Prompt Schutz (bleibt permanent aktiv, um Kauf-Fenster zu blockieren)
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
local MainSection = MainTab:CreateSection("Auto Farms Wins (Safe Path)")

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

-- Sichere Routen-Steuerung: Geht exakt über die Plattformen, meidet Kugeln und Wellen
local function safePathProgression()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    if not hrp then return end

    local stages = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            -- Filtert präzise nach den echten Boden-Plattformen und Stages, ignoriert Kugeln/Wellen im Weg
            if (n:find("stage") or n:find("checkpoint") or n:find("platform") or n:find("win") or n:find("end"))
               and not n:find("shop") and not n:find("buy") and not n:find("pass") and not n:find("ball") and not n:find("wave") then
                table.insert(stages, obj)
            end
        end
    end

    -- Sortiert von unten nach oben (Fortschritt der Obby-Plattformen)
    table.sort(stages, function(a, b)
        return a.Position.Y < b.Position.Y
    end)

    if #stages > 0 then
        for _, stagePart in ipairs(stages) do
            if not _G.AutoWinFarmActive then break end
            
            -- Setzt den Charakter sauber auf die Plattform, ohne durch Kugeln zu fliegen
            hrp.CFrame = stagePart.CFrame + Vector3.new(0, 3, 0)
            
            pcall(function()
                firetouchinterest(hrp, stagePart, 0)
                firetouchinterest(hrp, stagePart, 1)
            end)
            
            -- Wartet kurz auf jeder Plattform, damit das Spiel den Checkpoint sauber speichert
            task.wait(0.4)
        end
    end
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
                    safePathProgression()
                    task.wait(1)
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

-- Erweiterter Button zum Entfernen aller Wellen, Kugeln, Laser und beweglichen Hindernisse
UtilTab:CreateButton({
    Name = "Remove All Obstacles & Waves",
    Callback = function()
        local count = 0
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart" ) or obj:IsA("Model") then
                local n = obj.Name:lower()
                -- Erweitert um alle möglichen Wellen-, Kugel- und Partikelnamen in SecretVerse Spielen
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
        Rayfield:Notify({
            Title = "Success",
            Content = "Fully cleared! " .. count + 0 .. " obstacles & waves deleted.",
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
                if hl then hl.Enabled = Va
