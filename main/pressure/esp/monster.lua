local Alert = loadstring(game:HttpGet('https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/utils/alert.lua'))()
local Module = {}

function Module.CreateTab(Window)
    -- services
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    ---[[ AUTO HIDE FEATURE - ENHANCED CONFIGURATION ]]---
    local AutoHideConfig = {
        Enabled = false,
        ActivationDistance = 200, -- Updated to 200m as requested
        SafeHeight = 500,         -- Base safe height (+500 to current Y as requested)
        TweenSpeed = 2,           -- Duration in seconds for tween (smooth teleport up/down)
        FlySpeed = 16,            -- Not used in auto mode, but kept for potential manual control
        ReturnDelay = 3,          -- Seconds to wait after monsters gone before returning
        AdaptiveHeight = true,    -- Adjust height based on monster count (optional, can toggle)
        SmoothReturn = true,      -- Use tween for smooth return to ground
    }

    local AutoHideState = {
        isHiding = false,
        originalPosition = nil,
        flyConnection = nil,
        returnDelayCoroutine = nil,
        tweenConnection = nil,
        lastMonsterDetectedTime = 0,
        currentSafeHeight = 500,
        
        -- IY-inspired Flight variables
        BodyGyro = nil,
        BodyPosition = nil,
        Humanoid = nil,
        isFlying = false,
        isTweening = false,
    }

    -- Helper function to get root part
    local function getRoot(character)
        return character:FindFirstChild('HumanoidRootPart') or character:FindFirstChild('Torso') or character:FindFirstChild('UpperTorso')
    end

    -- Function to enable fly/hover (inspired by Infinite Yield's fly method, adapted for auto-hover)
    local function enableFly()
        if AutoHideState.isFlying then return end
        AutoHideState.isFlying = true

        local char = LocalPlayer.Character
        if not char then return end

        AutoHideState.Humanoid = char:FindFirstChildOfClass("Humanoid")
        local root = getRoot(char)
        if not root or not AutoHideState.Humanoid then return end

        -- Set humanoid state to prevent falling
        AutoHideState.Humanoid.PlatformStand = true

        -- BodyPosition for maintaining position (hover)
        AutoHideState.BodyPosition = Instance.new("BodyPosition")
        AutoHideState.BodyPosition.Position = root.Position
        AutoHideState.BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        AutoHideState.BodyPosition.P = 10000
        AutoHideState.BodyPosition.Parent = root

        -- BodyGyro for orientation (face camera direction)
        AutoHideState.BodyGyro = Instance.new("BodyGyro")
        AutoHideState.BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        AutoHideState.BodyGyro.P = 9000
        AutoHideState.BodyGyro.CFrame = root.CFrame
        AutoHideState.BodyGyro.Parent = root

        -- Connection to maintain hover and orientation
        AutoHideState.flyConnection = RunService.Stepped:Connect(function()
            if AutoHideState.Humanoid then
                AutoHideState.Humanoid.PlatformStand = true
            end
            -- Maintain current position (hover, no ascent here - ascent handled by tween)
            AutoHideState.BodyPosition.Position = root.Position
            -- Orient to camera
            AutoHideState.BodyGyro.CFrame = Camera.CFrame
        end)
    end

    -- Function to disable fly
    local function disableFly()
        if not AutoHideState.isFlying then return end
        AutoHideState.isFlying = false

        if AutoHideState.flyConnection then
            AutoHideState.flyConnection:Disconnect()
            AutoHideState.flyConnection = nil
        end
        if AutoHideState.BodyPosition then
            AutoHideState.BodyPosition:Destroy()
            AutoHideState.BodyPosition = nil
        end
        if AutoHideState.BodyGyro then
            AutoHideState.BodyGyro:Destroy()
            AutoHideState.BodyGyro = nil
        end
        if AutoHideState.Humanoid then
            AutoHideState.Humanoid.PlatformStand = false
        end
    end

    -- Function to start hiding (tween up + enable fly for hover)
    local function startHiding(monsterCount)
        if AutoHideState.isHiding then return end
        AutoHideState.isHiding = true

        local char = LocalPlayer.Character
        if not char then return end

        local root = getRoot(char)
        if not root then return end

        AutoHideState.originalPosition = root.CFrame

        -- Calculate adaptive height if enabled
        if AutoHideConfig.AdaptiveHeight then
            AutoHideState.currentSafeHeight = AutoHideConfig.SafeHeight + (100 * (monsterCount - 1)) -- +100 per extra monster
        else
            AutoHideState.currentSafeHeight = AutoHideConfig.SafeHeight
        end

        -- Enable fly first to prevent falling during tween
        enableFly()

        -- Target position: current Y + safe height (preserves X/Z)
        local targetPos = AutoHideState.originalPosition.Position + Vector3.new(0, AutoHideState.currentSafeHeight, 0)

        -- Tween the BodyPosition for smooth ascent (inspired by IY tween tp)
        local tweenInfo = TweenInfo.new(AutoHideConfig.TweenSpeed, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local tween = TweenService:Create(AutoHideState.BodyPosition, tweenInfo, {Position = targetPos})
        tween:Play()

        AutoHideState.isTweening = true
        AutoHideState.tweenConnection = tween.Completed:Connect(function()
            AutoHideState.isTweening = false
            -- Now hovering at target height until monster gone
        end)

        if Alert and Alert.SendAlert then
            Alert:SendAlert({title = "Auto Hide", content = "Monster detected! Ascending to safety.", type = "warn"})
        end
    end

    -- Function to return to ground (tween down + disable fly)
    local function returnToGround()
        if not AutoHideState.isHiding then return end

        local char = LocalPlayer.Character
        if not char then return end

        local root = getRoot(char)
        if not root then return end

        local targetPos = AutoHideState.originalPosition.Position
        local targetCFrame = AutoHideState.originalPosition -- Full original CFrame for orientation

        if AutoHideConfig.SmoothReturn then
            -- Tween down using BodyPosition
            local tweenInfo = TweenInfo.new(AutoHideConfig.TweenSpeed, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            local tween = TweenService:Create(AutoHideState.BodyPosition, tweenInfo, {Position = targetPos})
            tween:Play()
            tween.Completed:Wait()
            root.CFrame = targetCFrame -- Ensure exact orientation after tween
        else
            root.CFrame = targetCFrame
        end

        disableFly()
        AutoHideState.isHiding = false
        AutoHideState.originalPosition = nil

        if Alert and Alert.SendAlert then
            Alert:SendAlert({title = "All Clear", content = "Descending back to ground.", type = "info"})
        end
    end

    local NPC_ESP_Config = {
        Enabled = true,
        Glow_Enabled = true,
        Name_Enabled = true,
        Health_Enabled = true,
        Distance_Enabled = true,
        Spawn_Notifications = true,
        Default_Color = Color3.fromRGB(255, 80, 80),
        Glow_Transparency = 0.7,
        MonsterTypes = {
            ["Angler"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["Pinkie"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["Blitz"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["Pandemonium"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["Chainsmoker"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["Froger"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["RidgeAngler"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["RidgeBlitz"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["RidgePinkie"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["RidgeChainsmoker"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["RidgeFroger"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["RidgePandemonium"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["Pipsqueak"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["A60"] = { Color = Color3.fromRGB(240, 240, 240) }
        }
    }

    local NPC_ESP_State = { TrackedNPCs = {} }
    
    local NPC_ESP_ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    NPC_ESP_ScreenGui.Name = "NPC_ESP_Gui"
    NPC_ESP_ScreenGui.ResetOnSpawn = false

    -- Universal cleanup function
    local function cleanupMonsterVisuals(monster)
        if NPC_ESP_State.TrackedNPCs[monster] then
            local data = NPC_ESP_State.TrackedNPCs[monster]
            if data.Visuals.Glow and data.Visuals.Glow.Parent then data.Visuals.Glow.Parent:Destroy() end
            if data.Visuals.Billboard and data.Visuals.Billboard.Parent then data.Visuals.Billboard:Destroy() end
            if data.DeathConnection then data.DeathConnection:Disconnect() end
            NPC_ESP_State.TrackedNPCs[monster] = nil
        end
    end

    -- Universal function to create visuals for any monster type
    local function createVisualsForMonster(monster, adornee)
        if NPC_ESP_State.TrackedNPCs[monster] then return end
        
        local visuals = {}
        local espFolder = Instance.new("Folder", monster); espFolder.Name = "NPC_ESP_Visuals"

        visuals.Glow = Instance.new("Highlight", espFolder)
        visuals.Glow.Adornee = monster
        visuals.Glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        visuals.Glow.FillTransparency = NPC_ESP_Config.Glow_Transparency
        visuals.Glow.OutlineTransparency = 1
        visuals.Glow.Enabled = false

        visuals.Billboard = Instance.new("BillboardGui", NPC_ESP_ScreenGui)
        visuals.Billboard.Adornee = adornee
        visuals.Billboard.AlwaysOnTop = true
        visuals.Billboard.Size = UDim2.new(0, 200, 0, 80)
        visuals.Billboard.StudsOffset = Vector3.new(0, 3, 0)
        visuals.Billboard.Enabled = false
        
        local listLayout = Instance.new("UIListLayout", visuals.Billboard)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 2)
        
        visuals.NameLabel = Instance.new("TextLabel", visuals.Billboard)
        visuals.NameLabel.Size = UDim2.new(1, 0, 0, 20)
        visuals.NameLabel.LayoutOrder = 1
        visuals.NameLabel.BackgroundTransparency = 1
        visuals.NameLabel.Font = Enum.Font.GothamBold
        visuals.NameLabel.TextSize = 18
        visuals.NameLabel.TextStrokeTransparency = 0
        visuals.NameLabel.Text = monster.Name
        
        visuals.DistanceLabel = Instance.new("TextLabel", visuals.Billboard)
        visuals.DistanceLabel.Size = UDim2.new(1, 0, 0, 15)
        visuals.DistanceLabel.LayoutOrder = 2
        visuals.DistanceLabel.BackgroundTransparency = 1
        visuals.DistanceLabel.Font = Enum.Font.Gotham
        visuals.DistanceLabel.TextSize = 14
        visuals.DistanceLabel.TextColor3 = Color3.new(1, 1, 1)

        visuals.HealthBar = Instance.new("Frame", visuals.Billboard)
        visuals.HealthBar.Size = UDim2.new(1, 0, 0, 8)
        visuals.HealthBar.LayoutOrder = 3
        visuals.HealthBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        visuals.HealthBar.BorderSizePixel = 0
        
        visuals.HealthFill = Instance.new("Frame", visuals.HealthBar)
        visuals.HealthFill.Size = UDim2.fromScale(1, 1)
        visuals.HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        visuals.HealthFill.BorderSizePixel = 0
        
        return visuals
    end
    
    -- NEW: Universal update function for all monster types
    local function updateMonsterVisuals(monster, data)
        -- Get position from the adornee we set earlier
        local adornee = data.Visuals.Billboard.Adornee
        if not (adornee and adornee.Parent) then return end

        local monsterTypeConfig = NPC_ESP_Config.MonsterTypes[monster.Name]
        local color = (monsterTypeConfig and monsterTypeConfig.Color) or NPC_ESP_Config.Default_Color
        
        data.Visuals.Glow.Enabled = NPC_ESP_Config.Glow_Enabled
        data.Visuals.Glow.FillColor = color
        data.Visuals.Glow.FillTransparency = NPC_ESP_Config.Glow_Transparency
        
        data.Visuals.Billboard.Enabled = NPC_ESP_Config.Name_Enabled or NPC_ESP_Config.Health_Enabled or NPC_ESP_Config.Distance_Enabled
        data.Visuals.NameLabel.Visible = NPC_ESP_Config.Name_Enabled
        data.Visuals.NameLabel.TextColor3 = color
        data.Visuals.HealthBar.Visible = NPC_ESP_Config.Health_Enabled

        -- Health calculation depends on the monster's type
        local health, maxHealth = 1, 1
        if data.Type == "Humanoid" then
            local humanoid = monster:FindFirstChildOfClass("Humanoid")
            if humanoid then
                health, maxHealth = humanoid.Health, humanoid.MaxHealth
            end
        elseif data.Type == "Custom" then
            health = monster:GetAttribute("Health") or 0
            maxHealth = monster:GetAttribute("MaxHealth") or 1
        end

        if maxHealth == 0 then maxHealth = 1 end -- Avoid division by zero
        local healthPercent = math.clamp(health / maxHealth, 0, 1)
        data.Visuals.HealthFill.Size = UDim2.fromScale(healthPercent, 1)
        data.Visuals.HealthFill.BackgroundColor3 = Color3.fromHSV(healthPercent * 0.33, 1, 1)
        
        local distance = (Camera.CFrame.Position - adornee.Position).Magnitude
        data.Visuals.DistanceLabel.Visible = NPC_ESP_Config.Distance_Enabled
        data.Visuals.DistanceLabel.Text = string.format("%dM", distance)
    end

    -- NEW: Main detection function that checks for any monster type
    local function checkAndTrackObject(object)
        if NPC_ESP_State.TrackedNPCs[object] then return end -- Already tracking

        -- TYPE 1: Humanoid-based Monster
        if object:IsA("Model") and object:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(object) then
            local humanoid = object:FindFirstChildOfClass("Humanoid")
            local hrp = object:FindFirstChild("HumanoidRootPart")
            if not hrp then return end -- Needs a root part to attach visuals to

            local visuals = createVisualsForMonster(object, hrp)
            local deathConnection = humanoid.Died:Connect(function() cleanupMonsterVisuals(object) end)
            NPC_ESP_State.TrackedNPCs[object] = { Visuals = visuals, Type = "Humanoid", DeathConnection = deathConnection }
            
            if NPC_ESP_Config.Spawn_Notifications then
                Alert:ConfigureAlerts({ position = "Center" })
                Alert:SendAlert({ title = "Monster Spawned!", content = string.format("A(n) %s has appeared.", object.Name), type = "danger", duration = 5 })
            end
        
        -- TYPE 2: Custom Part-based Monster
        elseif object:IsA("BasePart") and NPC_ESP_Config.MonsterTypes[object.Name] then
             -- Prevent tracking a part of an already tracked Humanoid monster
            if object.Parent and NPC_ESP_State.TrackedNPCs[object.Parent] then return end

            local visuals = createVisualsForMonster(object, object)
            -- For custom parts, we detect death by listening to attribute changes or ancestry changes
            local deathConnection = object.AncestryChanged:Connect(function(_, parent)
                if not parent then cleanupMonsterVisuals(object) end
            end)
            
            NPC_ESP_State.TrackedNPCs[object] = { Visuals = visuals, Type = "Custom", DeathConnection = deathConnection }

            if NPC_ESP_Config.Spawn_Notifications then
                Alert:ConfigureAlerts({ position = "Center" })
                Alert:SendAlert({ title = "Monster Spawned!", content = string.format("A(n) %s has appeared.", object.Name), type = "danger", duration = 5 })
            end
        end
    end

    Workspace.ChildAdded:Connect(checkAndTrackObject)
    for _, child in ipairs(Workspace:GetChildren()) do
        checkAndTrackObject(child)
    end

    ---[[ AUTO HIDE FEATURE - RESPAWN SAFETY ]]---
    LocalPlayer.CharacterAdded:Connect(function(character)
        disableFly()
        AutoHideState.isHiding = false
        AutoHideState.originalPosition = nil
        if AutoHideState.returnDelayCoroutine then
            coroutine.close(AutoHideState.returnDelayCoroutine)
            AutoHideState.returnDelayCoroutine = nil
        end
    end)
    ---------------------------------------------

    RunService.RenderStepped:Connect(function()
        -- ESP Logic
        if not NPC_ESP_Config.Enabled then
            for _, data in pairs(NPC_ESP_State.TrackedNPCs) do
                if data.Visuals.Glow.Enabled then data.Visuals.Glow.Enabled = false end
                if data.Visuals.Billboard.Enabled then data.Visuals.Billboard.Enabled = false end
            end
        else
            Camera = workspace.CurrentCamera
            for monster, data in pairs(NPC_ESP_State.TrackedNPCs) do
                if not monster or not monster.Parent then
                    cleanupMonsterVisuals(monster)
                else
                    pcall(updateMonsterVisuals, monster, data)
                end
            end
        end

        ---[[ AUTO HIDE FEATURE - CORE LOGIC ]]---
        if AutoHideConfig.Enabled and LocalPlayer.Character and getRoot(LocalPlayer.Character) then
            local monsterIsNear = false
            local monsterCount = 0
            local playerRootPart = getRoot(LocalPlayer.Character)
            
            -- Check distance to all tracked monsters and count them
            for monster, data in pairs(NPC_ESP_State.TrackedNPCs) do
                local monsterPart = data.Visuals.Billboard.Adornee
                if monsterPart and monsterPart.Parent then
                    local distance = (playerRootPart.Position - monsterPart.Position).Magnitude
                    if distance < AutoHideConfig.ActivationDistance then
                        monsterIsNear = true
                    end
                    monsterCount = monsterCount + 1
                end
            end

            if monsterIsNear then
                -- Cancel any pending return if monster reappears
                if AutoHideState.returnDelayCoroutine then
                    coroutine.close(AutoHideState.returnDelayCoroutine)
                    AutoHideState.returnDelayCoroutine = nil
                end
                if not AutoHideState.isHiding then
                    startHiding(monsterCount)
                end
            else
                -- Start return delay if hiding and no delay active
                if AutoHideState.isHiding and not AutoHideState.returnDelayCoroutine then
                    AutoHideState.returnDelayCoroutine = coroutine.create(function()
                        wait(AutoHideConfig.ReturnDelay)
                        if not monsterIsNear then -- Double-check after delay
                            returnToGround()
                        end
                        AutoHideState.returnDelayCoroutine = nil
                    end)
                    coroutine.resume(AutoHideState.returnDelayCoroutine)
                end
            end
        end
        ---------------------------------------------
    end)
    
    local NPC_ESPTab = Window:CreateTab("NPC ESP", "ghost")
    NPC_ESPTab:CreateToggle({ Name = "Enable NPC ESP", CurrentValue = NPC_ESP_Config.Enabled, Flag = "NPC_ESP_Enabled", Callback = function(v) NPC_ESP_Config.Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Enable Glow (Chams)", CurrentValue = NPC_ESP_Config.Glow_Enabled, Flag = "NPC_ESP_Glow", Callback = function(v) NPC_ESP_Config.Glow_Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Show Name", CurrentValue = NPC_ESP_Config.Name_Enabled, Flag = "NPC_ESP_Name", Callback = function(v) NPC_ESP_Config.Name_Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Show Health", CurrentValue = NPC_ESP_Config.Health_Enabled, Flag = "NPC_ESP_Health", Callback = function(v) NPC_ESP_Config.Health_Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Show Distance", CurrentValue = NPC_ESP_Config.Distance_Enabled, Flag = "NPC_ESP_Distance", Callback = function(v) NPC_ESP_Config.Distance_Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Spawn Notifications", CurrentValue = NPC_ESP_Config.Spawn_Notifications, Flag = "NPC_ESP_Notifications", Callback = function(v) NPC_ESP_Config.Spawn_Notifications = v end })
    NPC_ESPTab:CreateSlider({ Name = "Glow Transparency", Range = {0, 1}, Increment = 0.05, Suffix = "%", CurrentValue = NPC_ESP_Config.Glow_Transparency, Flag = "NPC_ESP_GlowTrans", Callback = function(v) NPC_ESP_Config.Glow_Transparency = v end })

    ---[[ AUTO HIDE FEATURE - UI CONTROLS ]]---
    NPC_ESPTab:CreateSection("Auto Hide Settings")

    NPC_ESPTab:CreateToggle({
        Name = "Enable Auto Hide (Teleport + Fly)",
        CurrentValue = AutoHideConfig.Enabled,
        Flag = "AutoHide_Teleport_Enabled",
        Callback = function(value)
            AutoHideConfig.Enabled = value
            if not value and AutoHideState.isHiding then
                returnToGround()
            end
        end
    })

    NPC_ESPTab:CreateToggle({
        Name = "Adaptive Height (Based on Monster Count)",
        CurrentValue = AutoHideConfig.AdaptiveHeight,
        Flag = "AutoHide_Adaptive",
        Callback = function(value) AutoHideConfig.AdaptiveHeight = value end
    })

    NPC_ESPTab:CreateSlider({
        Name = "Activation Distance",
        Range = {50, 500},
        Increment = 10,
        Suffix = "m",
        CurrentValue = AutoHideConfig.ActivationDistance,
        Flag = "AutoHide_Distance",
        Callback = function(value) AutoHideConfig.ActivationDistance = value end
    })

    NPC_ESPTab:CreateSlider({
        Name = "Safe Height Offset",
        Range = {100, 1000},
        Increment = 50,
        Suffix = "studs",
        CurrentValue = AutoHideConfig.SafeHeight,
        Flag = "AutoHide_Height",
        Callback = function(value) AutoHideConfig.SafeHeight = value end
    })

    NPC_ESPTab:CreateSlider({
        Name = "Tween Duration",
        Range = {0.5, 5},
        Increment = 0.5,
        Suffix = "s",
        CurrentValue = AutoHideConfig.TweenSpeed,
        Flag = "AutoHide_TweenSpeed",
        Callback = function(value) AutoHideConfig.TweenSpeed = value end
    })

    NPC_ESPTab:CreateSlider({
        Name = "Return Delay",
        Range = {1, 10},
        Increment = 1,
        Suffix = "s",
        CurrentValue = AutoHideConfig.ReturnDelay,
        Flag = "AutoHide_ReturnDelay",
        Callback = function(value) AutoHideConfig.ReturnDelay = value end
    })

    NPC_ESPTab:CreateToggle({
        Name = "Smooth Return",
        CurrentValue = AutoHideConfig.SmoothReturn,
        Flag = "AutoHide_SmoothReturn",
        Callback = function(value) AutoHideConfig.SmoothReturn = value end
    })
    ---------------------------------------------
end

return Module