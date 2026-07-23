-- Zylimatixs Script | Made by Maxizzzy
-- Project NORTHGATE / SBAS-v4.2 Conformance Compliant
-- Target Environment: Roblox Luau Runtime (Delta / Rayfield Interface Suite)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Anti-Prompt Safety Filter (Prevents accidental product purchase prompts).
-- Every Prompt* method MarketplaceService exposes, not just the three obvious ones.
local blockedPrompts = {
    PromptProductPurchase = true,
    PromptGamePassPurchase = true,
    PromptBundlePurchase = true,
    PromptPurchase = true,
    PromptPremiumPurchase = true,
    PromptSubscriptionPurchase = true,
    PromptThirdPartyPurchase = true,
    PromptRobloxPurchase = true,
}

pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldNamecall = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        if blockedPrompts[getnamecallmethod()] then
            return nil
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end)

local Window = Rayfield:CreateWindow({
    Name = "Zylimatixs Script | Made by Maxizzzy",
    LoadingTitle = "Zylimatixs Hub",
    LoadingSubtitle = "World 3 | +1 Speed Keyboard Escape",
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
_G.GlideHeight = 15         -- studs above the route, low and flat like a real glide
_G.GlideSpeed = 190         -- studs per second
_G.FireWinRemotes = false   -- off: firing unknown remotes is how shop handlers get hit

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

-- Target: World 3 of "+1 Speed Keyboard Escape | Candy & Chocolate" by SecretVerse
-- Studio. World 3 is the endgame Wins zone, unlocked at level 400.
local targetPlaceId = 95082159892680
local worldPattern = "world%s*_?3"
local anyWorldPattern = "world%s*_?%d"

local hazardWords = {"wave", "welle", "ball", "kugel", "sphere", "kill", "laser", "obstacle", "trap", "fire", "hazard", "roll", "moving", "boulder", "rock", "spike"}
local stageWords = {"stage", "checkpoint", "platform", "key", "win"}
-- Never touched, never fired. The goal list had no blocker at all, so a pad called
-- something like "BuyWins" counted as a goal, got touched, and popped the Roblox
-- purchase dialog. Anything that can cost Robux belongs in here.
local blockWords = {"shop", "buy", "pass", "gamepass", "robux", "purchase", "product",
    "premium", "donate", "dev", "gift", "sign", "npc", "ball", "wave", "wall"}
local goalWords = {"win", "end", "goal"}

-- Glide tuning (height and speed are sliders in the MAIN tab)
local arriveRadius = 12     -- how close to a target still counts as reached
local stuckTimeout = 0.6    -- seconds without movement before a jump counts as stuck
local maxMisses = 3         -- failed stages in a row before the cycle restarts
local respawnTimeout = 8    -- seconds we wait for a new character after the reset
local searchDepth = 15      -- how far below the player a target may still sit

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

-- World 3 is the endgame Wins zone of "+1 Speed Keyboard Escape". Everything below
-- stays inside it, so stages from World 1 and 2 can never pull the glide off course.
local worldRootCache = nil

local function findWorldRoot()
    local best, bestDepth = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if (obj:IsA("Folder") or obj:IsA("Model")) and obj.Name:lower():match(worldPattern) then
            -- The shallowest match is the container, deeper ones are parts inside it
            local depth, node = 0, obj
            while node and node ~= Workspace do
                depth = depth + 1
                node = node.Parent
            end
            if depth < bestDepth then
                best, bestDepth = obj, depth
            end
        end
    end
    return best
end

local function getWorldRoot()
    if worldRootCache and worldRootCache.Parent then
        return worldRootCache
    end
    worldRootCache = findWorldRoot()
    return worldRootCache
end

-- True when this place splits its worlds into containers at all. If it does not, the
-- whole map already is one world and filtering by name would throw away everything,
-- which is exactly what turned up 0 stages and 0 goals.
local function mapHasWorldFolders()
    for _, obj in ipairs(Workspace:GetChildren()) do
        if (obj:IsA("Folder") or obj:IsA("Model")) and obj.Name:lower():match(anyWorldPattern) then
            return true
        end
    end
    return false
end

-- Only called for objects that already matched a keyword, GetFullName on every
-- descendant of the map would be far too slow
local function inWorld3(obj, root)
    if root then
        return true -- the search already started inside the container
    end
    if not mapHasWorldFolders() then
        return true -- single world place, nothing to separate
    end
    return obj:GetFullName():lower():match(worldPattern) ~= nil
end

-- Hazard and Obstacle Eraser (W Waves, Balls, Spheres, Lasers)
local function isHazard(obj)
    return (obj:IsA("BasePart") or obj:IsA("Model")) and matchesAny(obj.Name:lower(), hazardWords)
end

local function wipeAllHazards()
    local root = getWorldRoot()
    local count = 0
    for _, obj in ipairs((root or Workspace):GetDescendants()) do
        if isHazard(obj) and inWorld3(obj, root) then
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
    local root = getWorldRoot()

    for _, obj in ipairs((root or Workspace):GetDescendants()) do
        if isHazard(obj) then
            if clearHazards and inWorld3(obj, root) then
                pcall(function()
                    obj:Destroy()
                end)
            end
        elseif obj:IsA("BasePart") and obj.Parent then
            local n = obj.Name:lower()
            local isStage = matchesAny(n, stageWords) and not matchesAny(n, blockWords)
            local isGoal = matchesAny(n, goalWords) and not matchesAny(n, blockWords)

            if (isStage or isGoal) and not inWorld3(obj, root) then
                isStage, isGoal = false, false
            end

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
    local travelTime = math.max(distance / math.max(_G.GlideSpeed, 10), 0.05)

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

-- CFrame.new(position, lookAt) throws when both points are identical
local function facing(position, lookAt)
    if (lookAt - position).Magnitude < 0.1 then
        return CFrame.new(position)
    end
    return CFrame.new(position, lookAt)
end

-- Rises just far enough to clear the walls in between, crosses at a steady speed facing
-- the direction of travel, then settles onto the stage. A low flat glide, not a tall arc.
local function glideRoute(hrp, targetCFrame, generation)
    local startPos = hrp.Position
    local targetPos = targetCFrame.Position
    local cruiseY = math.max(startPos.Y, targetPos.Y) + math.max(_G.GlideHeight, 0)

    local liftPos = Vector3.new(startPos.X, cruiseY, startPos.Z)
    local crossPos = Vector3.new(targetPos.X, cruiseY, targetPos.Z)

    if not tweenTo(hrp, facing(liftPos, crossPos), generation) then return false end
    if not tweenTo(hrp, facing(crossPos, targetPos), generation) then return false end
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
            if glideRoute(hrp, stagePart.CFrame + Vector3.new(0, 4, 0), generation) then
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

    -- Fire server-side win tier event. Off by default: this sprays an argument at every
    -- remote whose name looks right, and one of those can be a shop handler.
    if _G.FireWinRemotes then
        pcall(function()
            for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") then
                    local name = remote.Name:lower()
                    if (name:find("win") or name:find("stage") or name:find("reward")) and not matchesAny(name, blockWords) then
                        remote:FireServer(_G.SelectedWinTier)
                    end
                end
            end
        end)
    end

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

MainTab:CreateToggle({
    Name = "Fire Win Remotes (risky, can hit shop handlers)",
    CurrentValue = false,
    Flag = "FireWinRemotesToggle",
    Callback = function(Value)
        _G.FireWinRemotes = Value
    end,
})

local TuningSection = MainTab:CreateSection("Glide Tuning")

MainTab:CreateSlider({
    Name = "Glide Height",
    Range = {0, 150},
    Increment = 5,
    Suffix = " studs",
    CurrentValue = 15,
    Flag = "GlideHeightSlider",
    Callback = function(Value)
        _G.GlideHeight = Value
    end,
})

MainTab:CreateSlider({
    Name = "Glide Speed",
    Range = {50, 600},
    Increment = 10,
    Suffix = " studs/s",
    CurrentValue = 190,
    Flag = "GlideSpeedSlider",
    Callback = function(Value)
        _G.GlideSpeed = Value
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

-- Reports what the scanner really sees, so tuning stops being guesswork. The report
-- goes to the clipboard as well, reading a mobile executor console is painful.
UtilTab:CreateButton({
    Name = "Debug Scan (copies report to clipboard)",
    Callback = function()
        local char = LocalPlayer.Character
        local hrp = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
        if not hrp then
            Rayfield:Notify({ Title = "Debug Scan", Content = "No character found.", Duration = 4 })
            return
        end

        local lines = {}
        local function add(text)
            table.insert(lines, text)
        end

        local pos = hrp.Position
        local stages, goals, stageNamed, goalNamed = collectTargets(pos, false)
        local root = getWorldRoot()

        add("=== Zylimatixs Debug Scan ===")
        add(string.format("PlaceId %d (expected %d)", game.PlaceId, targetPlaceId))
        add(string.format("Player at X=%.0f Y=%.0f Z=%.0f", pos.X, pos.Y, pos.Z))
        add("World folders in this map: " .. tostring(mapHasWorldFolders()))
        add("World 3 container: " .. (root and root:GetFullName() or "NOT FOUND"))
        add(string.format("Stages: %d usable of %d named", #stages, stageNamed))
        add(string.format("Goals:  %d usable of %d named", #goals, goalNamed))

        add("-- Workspace top level --")
        for i, child in ipairs(Workspace:GetChildren()) do
            if i > 30 then
                add("   ...")
                break
            end
            add(string.format("  %s [%s]", child.Name, child.ClassName))
        end

        add("-- first stages in glide order --")
        for i, part in ipairs(stages) do
            if i > 20 then
                add(string.format("   ... and %d more", #stages - 20))
                break
            end
            add(string.format("  [%02d] %s | %.0f studs | Y=%.0f", i, part:GetFullName(), (part.Position - pos).Magnitude, part.Position.Y))
        end

        add("-- first goals --")
        for i, part in ipairs(goals) do
            if i > 10 then
                add(string.format("   ... and %d more", #goals - 10))
                break
            end
            add(string.format("  [%02d] %s | %.0f studs", i, part:GetFullName(), (part.Position - pos).Magnitude))
        end

        -- Nothing matched, so the keyword lists are wrong for this map. Dump the real
        -- names around the player instead of leaving us to guess again.
        if #stages == 0 and #goals == 0 then
            local near = {}
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Parent then
                    local distance = (obj.Position - pos).Magnitude
                    if distance <= 300 then
                        table.insert(near, {part = obj, distance = distance})
                    end
                end
            end
            table.sort(near, function(a, b)
                return a.distance < b.distance
            end)

            add(string.format("-- nothing matched, %d parts within 300 studs, nearest 40 --", #near))
            for i = 1, math.min(#near, 40) do
                add(string.format("  %5.0f  %s", near[i].distance, near[i].part:GetFullName()))
            end
        end

        add("-- remote events matching win/stage/reward --")
        local remoteCount = 0
        pcall(function()
            for _, remote in ipairs(ReplicatedStorage:GetDescendants()) do
                if remote:IsA("RemoteEvent") then
                    local name = remote.Name:lower()
                    if (name:find("win") or name:find("stage") or name:find("reward")) and not matchesAny(name, blockWords) then
                        remoteCount = remoteCount + 1
                        if remoteCount <= 15 then
                            add("  " .. remote:GetFullName())
                        end
                    end
                end
            end
        end)
        add(string.format("Remote events matched: %d", remoteCount))
        add("=== end of scan ===")

        local report = table.concat(lines, "\n")
        print(report)

        local copied = pcall(function()
            setclipboard(report)
        end)

        Rayfield:Notify({
            Title = "Debug Scan",
            Content = copied
                and string.format("%d stages, %d goals. Report copied, paste it to Claude.", #stages, #goals)
                or string.format("%d stages, %d goals. Clipboard failed, check the console.", #stages, #goals),
            Duration = 8
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

-- Wrong game or wrong world means every scan below runs against a map this script was
-- never built for, so say it out loud instead of failing quietly
task.spawn(function()
    if game.PlaceId ~= targetPlaceId then
        Rayfield:Notify({
            Title = "Wrong Game",
            Content = "This build only targets +1 Speed Keyboard Escape (World 3). Nothing here is tuned for this place.",
            Duration = 10
        })
        return
    end

    if not getWorldRoot() then
        Rayfield:Notify({
            Title = "World 3 Not Found",
            Content = "No World 3 container in this map. Run Debug Scan in Utilities and send the output.",
            Duration = 10
        })
    end
end)
