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
    Discord = {
        Enabled = false,
        Invite = "noinvite",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Zylimatixs Authentication",
        Subtitle = "Session Key Required",
        Note = "script made by maxizzzy",
        FileName = "ZylimatixsKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"maxizzzy"}
    }
})

local MainTab = Window:CreateTab("Execution", 4483362458)
local MainSection = MainTab:CreateSection("Core Utilities")

MainTab:CreateParagraph({
    Title = "Author Attribution",
    Content = "script made by maxizzzy"
})

MainTab:CreateButton({
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
        Rayfield:Notify({
            Title = "Execution Success",
            Content = "State bypass applied to local character instance.",
            Duration = 6.5,
            Image = 4483362458,
        })
    end
})

MainTab:CreateSlider({
    Name = "Velocity Multiplier",
    Range = {1, 5},
    Increment = 0.1,
    CurrentValue = 1,
    Flag = "VelocityMultiplier",
    Callback = function(Value)
        _G.VelocityMultiplier = Value
    end,
})

local BypassTab = Window:CreateTab("Obby Bypass", 4483362458)
local BypassSection = BypassTab:CreateSection("World 3 Direct Route Bypass")

_G.BypassActive = false
_G.TargetTrophiesFarm = 100
_G.FarmedCount = 0

BypassTab:CreateInput({
    Name = "World 3 Farm Amount",
    PlaceholderText = "e.g. 50",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        local val = tonumber(Text)
        if val then
            _G.TargetTrophiesFarm = val
        end
    end,
})

local function getTargetPart()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local nameLower = obj.Name:lower()
            if nameLower:find("win") or nameLower:find("end") or nameLower:find("finish") or nameLower:find("goal") or nameLower:find("world3") or nameLower:find("stage3") then
                return obj
            end
        end
    end
    return nil
end

BypassTab:CreateButton({
    Name = "Teleport to World 3 End / Win",
    Callback = function()
        local character = LocalPlayer.Character
        local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
        
        if root then
            local targetPart = getTargetPart()
            if targetPart then
                root.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                Rayfield:Notify({
                    Title = "Bypass Success",
                    Content = "Successfully teleported past the World 3 obby structure!",
                    Duration = 5,
                    Image = 4483362458,
                })
            else
                Rayfield:Notify({
                    Title = "Target Not Found",
                    Content = "Could not locate World 3 end goal automatically. Try moving closer.",
                    Duration = 5,
                    Image = 4483362458,
                })
            end
        end
    end
})

BypassTab:CreateToggle({
    Name = "Auto Farm World 3 Wins",
    CurrentValue = false,
    Flag = "AutoFarmBypass",
    Callback = function(Value)
        _G.BypassActive = Value
        _G.FarmedCount = 0
        
        if Value then
            task.spawn(function()
                while _G.BypassActive do
                    if _G.FarmedCount >= _G.TargetTrophiesFarm then
                        _G.BypassActive = false
                        Rayfield:Notify({
                            Title = "Farming Complete",
                            Content = "Reached target of " .. _G.FarmedCount .. " wins/trophies.",
                            Duration = 5,
                            Image = 4483362458,
                        })
                        break
                    end
                    
                    local character = LocalPlayer.Character
                    local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
                    local targetPart = getTargetPart()
                    
                    if root and targetPart then
                        root.CFrame = targetPart.CFrame + Vector3.new(0, 3, 0)
                        _G.FarmedCount = _G.FarmedCount + 1
                    end
                    
                    task.wait(1.2)
                end
            end)
        end
    end,
})

local VisualTab = Window:CreateTab("Visuals", 4483362458)
local VisualSection = VisualTab:CreateSection("ESP Configuration")

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
    highlight.OutlineTransparency = 0
    highlight.Enabled = _G.ESPEnabled
    highlight.Parent = character
end

VisualTab:CreateToggle({
    Name = "Enable Player ESP",
    CurrentValue = false,
    Flag = "ESPEnabled",
    Callback = function(Value)
        _G.ESPEnabled = Value
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hl = player.Character:FindFirstChild("NorthgateESP")
                if hl then
                    hl.Enabled = Value
                elseif Value then
                    createHighlight(player.Character)
                end
            end
        end
    end,
})

VisualTab:CreateColorPicker({
    Name = "ESP Color",
    Color = Color3.fromRGB(255, 0, 0),
    Flag = "ESPColorPicker",
    Callback = function(Value)
        _G.ESPColor = Value
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hl = player.Character:FindFirstChild("NorthgateESP")
                if hl then
                    hl.FillColor = Value
                end
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

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function(character)
            if _G.ESPEnabled then
                task.wait(1)
                createHighlight(character)
            end
        end)
    end
end

local DiagnosticTab = Window:CreateTab("Diagnostics", 4483362458)
DiagnosticTab:CreateParagraph({Title = "Protocol Version", Content = "SBAS v4.2 / STW-RFC-009 Reference Oracle Active"})

Rayfield:LoadConfiguration()
