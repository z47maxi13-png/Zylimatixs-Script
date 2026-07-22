-- Zylimatixs Script | Made by Maxizzzy
-- Project NORTHGATE / SBAS-v4.2 Conformance Compliant
-- Target Environment: Roblox Luau Runtime (Delta / Rayfield Interface Suite)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Anti-Prompt Safety Filter (Prevents accidental product purchase prompts)
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
    LoadingSubtitle = "Clean Glide & Anti-Stuck Edition",
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

-- Hazard and Obstacle Eraser (W Waves, Balls, Spheres, Lasers)
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

-- Above-Map Glide Progression Engine (Prevents underground falling / clipping)
local function executeCleanGlide()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return end

    wipeAllHazards()

    local playerY = hrp.Position.Y
    local stages = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if (n:find("stage") or n:find("checkpoint") or n:find("platform") or n:find("key") or n:find("win")) 
               and not n:find("shop") and not n:find("buy") and not n:find("pass") and not n:find("ball") and not n:find("wave") and not n:find("wall") 
               and obj.Position.Y >= playerY - 15 then
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
            
            local distance = (hrp.Position - stagePart.Position).Magnitude
            local glideSpeed = 190
            local travelTime = distance / glideSpeed
            if travelTime < 0.05 then travelTime = 0.05 end

            local tween = TweenService:Create(hrp, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {CFrame = stagePart.CFrame + Vector3.new(0, 4, 0)})
            tween:Play()
            
            local completed = false
            tween.Completed:Connect(function() completed = true end)
            local timeout = tick() + 1.5
            while not completed and tick() < timeout and _G.AutoWinFarmActive do
                task.wait(0.05)
            end

            pcall(function()
                firetouchinterest(hrp, stagePart, 0)
                firetouchinterest(hrp, stagePart, 1)
            end)
        end
    end

    -- Trigger final goal/win portal safely
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if (n:find("win") or n:find("end") or n:find("goal")) and obj.Position.Y >= playerY - 15 then
                hrp.CFrame = obj.CFrame + Vector3.new(0, 4, 0)
                pcall(function()
                    firetouchinterest(hrp, obj, 0)
                    firetouchinterest(hrp, obj, 1)
                end)
            end
        end
    end

    -- Fire server-side win tier event
    pcall(function()
        for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
            if remote:IsA("RemoteEvent") then
                local name = remote.Name:lower()
                if (name:find("win") or name:find("stage") or name:find("reward")) and not name:find("product") and not name:find("purchase") then
                    remote:FireServer(_G.SelectedWinTier)
                end
            end
        end
    end)

    -- Force instant character reset to claim rewards and loop seamlessly
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
                    executeCleanGlide()
                end
            end)
        end
    end,
})

-- Utilities Tab
local UtilTab = Window:CreateTab("Utilities", 4483362458)
local UtilSection = UtilTab:CreateSection("Tools & Environment")

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
