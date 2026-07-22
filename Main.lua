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
_G.AutoResetEnabled = false

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

local hazardWords = {"wave", "welle", "ball", "kugel", "sphere", "kill", "laser", "obstacle", "trap", "fire", "hazard", "roll", "moving", "boulder", "rock", "spike"}
local stageWords = {"stage", "checkpoint", "platform", "key", "win"}
local stageBlockWords = {"shop", "buy", "pass", "ball", "wave", "wall"}
local goalWords = {"win", "end", "goal"}

-- Glide tuning
local glideSpeed = 190      -- studs per second
local arriveRadius = 12     -- how close to a target still counts as reached
local stuckTimeout = 0.6    -- seconds without movement before a jump counts as stuck
local maxMisses = 3         -- failed stages in a row before the cycle restarts
local respawnTimeout = 8    -- seconds we wait for a new character after the reset
local searchDepth = 15      -- how far below the player a target may still sit
local flightHeight = 60     -- cruise height above the route, clears rolling boulders

-- Every toggle flip bumps this, so threads from an earlier run stop themselves
local farmGeneration = 0

local function matchesAny(name, words)
    for _, word in ipairs(words) do
        if name:find(word, 1, true) then
            return true
        end
    end
    return false
end

local function farmActive(generation)
    return _G.AutoWinFarmActive and generation == farmGeneration
end

-- Hazard and Obstacle Eraser (W Waves, Balls, Spheres, Lasers)
local function isHazard(obj)
    return (obj:IsA("BasePart") or obj:IsA("Model")) and matchesAny(obj.Name:lower(), hazardWords)
end

local function wipeAllHazards()
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isHazard(obj) then
            local removed = pcall(function()
                obj:Destroy()
            end)
            if removed then
                count = count + 1
            end
        end
    end
    return count
end

-- Pulls the trailing number out of names like "Stage12" or "Checkpoint 7"
local function stageNumber(name)
    local digits = name:match("(%d+)%s*$")
    return digits and tonumber(digits) or nil
end

-- One descendant pass clears hazards and collects the targets (three passes lagged big maps)
local function collectTargets(origin, clearHazards)
    local stages, goals = {}, {}
    local stageNamed, goalNamed = 0, 0

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isHazard(obj) then
            if clearHazards then
                pcall(function()
                    obj:Destroy()
                end)
            end
        elseif obj:IsA("BasePart") and obj.Parent then
            local n = obj.Name:lower()
            local isStage = matchesAny(n, stageWords) and not matchesAny(n, stageBlockWords)
            local isGoal = matchesAny(n, goalWords)

            if isStage then stageNamed = stageNamed + 1 end
            if isGoal then goalNamed = goalNamed + 1 end

            if obj.Position.Y >= origin.Y - searchDepth then
                if isStage then table.insert(stages, obj) end
                if isGoal then table.insert(goals, obj) end
            end
        end
    end

    -- Sorting by height only works on a tower. Flat race maps need the number in the
    -- name, so build one sort key per part: numbered stages first, the rest by distance.
    local keys = {}
    for _, part in ipairs(stages) do
        keys[part] = stageNumber(part.Name) or (1e6 + (part.Position - origin).Magnitude)
    end
    table.sort(stages, function(a, b)
        return keys[a] < keys[b]
    end)

    return stages, goals, stageNamed, goalNamed
end

-- Waits for a living character instead of yielding forever when the respawn never comes
local function getCharacterParts(generation, timeout)
    local deadline = tick() + timeout
    while farmActive(generation) and tick() < deadline do
        local char = LocalPlayer.Character
        if char and char.Parent then
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if hrp and humanoid and humanoid.Health > 0 then
                return char, hrp, humanoid
            end
        end
        task.wait(0.1)
    end
    return nil
end

-- Tweens the root part to one waypoint and reports whether we really arrived
local function tweenTo(hrp, targetCFrame, generation)
    local distance = (targetCFrame.Position - hrp.Position).Magnitude
    local travelTime = math.max(distance / glideSpeed, 0.05)

    local tween = TweenService:Create(hrp, TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {CFrame = targetCFrame})
    tween:Play()

    -- Deadline follows the distance, a flat timeout cut off every long jump
    local deadline = tick() + travelTime + 1.5
    local lastPos = hrp.Position
    local stalled = 0

    while true do
        task.wait(0.05)

        if not farmActive(generation) or not hrp.Parent then
            tween:Cancel()
            return false
        end

        local state = tween.PlaybackState
        if state == Enum.PlaybackState.Completed then
            break
        end
        if state == Enum.PlaybackState.Cancelled then
            return false
        end

        -- Anti-stuck: an anti-cheat pulling us back looks like "tween runs but we stay put"
        if (hrp.Position - lastPos).Magnitude < 0.5 then
            stalled = stalled + 0.05
            if stalled >= stuckTimeout then
                tween:Cancel()
                return false
            end
        else
            stalled = 0
        end
        lastPos = hrp.Position

        if tick() > deadline then
            tween:Cancel()
            break
        end
    end

    return (hrp.Position - targetCFrame.Position).Magnitude <= arriveRadius
end

-- Lifts the character over the map, crosses at cruise height, then drops onto the target.
-- Flying straight at a stage ran right through the boulders rolling down the track.
local function glideAbove(hrp, targetCFrame, generation)
    local cruiseY = math.max(hrp.Position.Y, targetCFrame.Position.Y) + flightHeight
    local liftPoint = CFrame.new(hrp.Position.X, cruiseY, hrp.Position.Z)
    local crossPoint = CFrame.new(targetCFrame.Position.X, cruiseY, targetCFrame.Position.Z)

    if not tweenTo(hrp, liftPoint, generation) then return false end
    if not tweenTo(hrp, crossPoint, generation) then return false end
    return tweenTo(hrp, targetCFrame, generation)
end

-- Remembers the original collision state per part, restoring everything to true would
-- make the root part and the accessories solid, which they never were
local collisionMemory = setmetatable({}, {__mode = "k"})

-- Intangible and physics-free while in the air, a rolling boulder used to shove the
-- tweened root part right off the route
local function setFlightMode(char, humanoid, enabled)
    pcall(function()
        humanoid.PlatformStand = enabled
    end)

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if enabled then
                collisionMemory[part] = part.CanCollide
                part.CanCollide = false
            elseif collisionMemory[part] ~= nil then
                part.CanCollide = collisionMemory[part]
                collisionMemory[part] = nil
            end
        end
    end
end

local function touchPart(hrp, part)
    pcall(function()
        firetouchinterest(hrp, part, 0)
        firetouchinterest(hrp, part, 1)
    end)
end

-- Walks the stage list, then the goal parts. Runs with flight mode on.
local function traverse(hrp, stages, goals, generation)
    local misses = 0
    for _, stagePart in ipairs(stages) do
        if not farmActive(generation) or not hrp.Parent then return end

        -- The stage can be gone by now, the scan happened a few seconds ago
        if stagePart.Parent then
            if glideAbove(hrp, stagePart.CFrame + Vector3.new(0, 4, 0), generation) then
                misses = 0
                touchPart(hrp, stagePart)
            else
                misses = misses + 1
                -- Blocked or pulled back too often, restart the whole cycle instead of grinding
                if misses >= maxMisses then return end
            end
        end
    end

    -- Trigger final goal/win portal safely
    for _, goalPart in ipairs(goals) do
        if not farmActive(generation) or not hrp.Parent then return end

        if goalPart.Parent then
            hrp.CFrame = goalPart.CFrame + Vector3.new(0, 4, 0)
            task.wait(0.05)
            touchPart(hrp, goalPart)
        end
    end
end

-- Above-Map Glide Progression Engine (Prevents underground falling / clipping)
local function executeCleanGlide(generation)
    local char, hrp, humanoid = getCharacterParts(generation, respawnTimeout)
    if not char then return end

    local stages, goals = collectTargets(hrp.Position, true)

    -- Flight mode has to come back off even when the run errors out mid-air
    setFlightMode(char, humanoid, true)
    local ok, err = pcall(traverse, hrp, stages, goals, generation)
    pcall(setFlightMode, char, humanoid, false)

    if not ok then
        warn("[Zylimatixs] Traverse failed: " .. tostring(err))
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

    -- Optional reset. Obby maps hand out the reward on death, race maps just send you
    -- back to the start, so this stays off unless the game actually rewards it.
    if _G.AutoResetEnabled then
        pcall(function()
            humanoid.Health = 0
        end)

        -- Wait for the respawn with a deadline, a blocked reset used to freeze the loop forever
        local deadline = tick() + respawnTimeout
        while farmActive(generation) and tick() < deadline do
            local newChar = LocalPlayer.Character
            if newChar and newChar ~= char then break end
            task.wait(0.2)
        end
    end

    task.wait(0.2)
end

MainTab:CreateToggle({
    Name = "Enable Auto Win (Selected Tier)",
    CurrentValue = false,
    Flag = "AutoWinGlideToggle",
    Callback = function(Value)
        _G.AutoWinFarmActive = Value
        -- Any thread from an earlier toggle sees a new generation and stops itself
        farmGeneration = farmGeneration + 1

        if Value then
            local generation = farmGeneration
            task.spawn(function()
                while farmActive(generation) do
                    local ok, err = pcall(executeCleanGlide, generation)
                    if not ok then
                        warn("[Zylimatixs] Glide cycle failed: " .. tostring(err))
                    end
                    -- Guaranteed yield, an early return can no longer freeze the client
                    task.wait(0.25)
                end
            end)
        end
    end,
})

MainTab:CreateToggle({
    Name = "Reset After Each Round (Obby maps only)",
    CurrentValue = false,
    Flag = "AutoResetToggle",
    Callback = function(Value)
        _G.AutoResetEnabled = Value
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

-- Prints what the scanner really sees, so tuning stops being guesswork
UtilTab:CreateButton({
    Name = "Debug Scan (prints to console)",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if not hrp then
            Rayfield:Notify({ Title = "Debug Scan", Content = "No character found.", Duration = 4 })
            return
        end

        local stages, goals, stageNamed, goalNamed = collectTargets(hrp.Position, false)
        local pos = hrp.Position

        print("=== Zylimatixs Debug Scan ===")
        print(string.format("Player at X=%.0f Y=%.0f Z=%.0f", pos.X, pos.Y, pos.Z))
        print(string.format("Stages: %d usable of %d named (%d dropped by the height filter)", #stages, stageNamed, stageNamed - #stages))
        print(string.format("Goals:  %d usable of %d named (%d dropped by the height filter)", #goals, goalNamed, goalNamed - #goals))

        print("-- first stages in glide order --")
        for i, part in ipairs(stages) do
            if i > 25 then
                print(string.format("   ... and %d more", #stages - 25))
                break
            end
            print(string.format("  [%02d] %-40s %5.0f studs away, Y=%.0f", i, part:GetFullName(), (part.Position - pos).Magnitude, part.Position.Y))
        end

        print("-- first goals --")
        for i, part in ipairs(goals) do
            if i > 10 then
                print(string.format("   ... and %d more", #goals - 10))
                break
            end
            print(string.format("  [%02d] %-40s %5.0f studs away", i, part:GetFullName(), (part.Position - pos).Magnitude))
        end

        print("-- remote events the script would fire --")
        local remoteCount = 0
        pcall(function()
            for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") then
                    local name = remote.Name:lower()
                    if (name:find("win") or name:find("stage") or name:find("reward")) and not name:find("product") and not name:find("purchase") then
                        remoteCount = remoteCount + 1
                        if remoteCount <= 15 then
                            print("  " .. remote:GetFullName())
                        end
                    end
                end
            end
        end)
        print(string.format("Remote events matched: %d", remoteCount))
        print("=== end of scan ===")

        Rayfield:Notify({
            Title = "Debug Scan",
            Content = string.format("%d stages, %d goals, %d remotes. Details in the console.", #stages, #goals, remoteCount),
            Duration = 6
        })
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
