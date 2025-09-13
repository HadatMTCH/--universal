local Alert = loadstring(game:HttpGet('https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/utils/alert.lua'))()
local Module = {}

function Module.CreateTab(Window)
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local AutoHideConfig = {
        Enabled = false,

        SafeHeight = 1000, TweenSpeed = 0.5, FlySpeed = 16, AdaptiveHeight = true, SmoothReturn = true,
        
        MonsterSettings = {
            ["Defaults"] = { ActivationDistance = 200, ReturnDelay = 3 },
            ["Angler"] = { ActivationDistance = 150, ReturnDelay = 2 },
            ["Pinkie"] = { ActivationDistance = 180, ReturnDelay = 4 },
            ["Blitz"] = { ActivationDistance = 250, ReturnDelay = 3 },
            ["Pandemonium"] = { ActivationDistance = 300, ReturnDelay = 5 },    
            ["Chainsmoker"] = { ActivationDistance = 100, ReturnDelay = 3 },
            ["Froger"] = { ActivationDistance = 200, ReturnDelay = 4 },
            ["Mirage"] = { ActivationDistance = 250, ReturnDelay = 3 },
            ["RidgeAngler"] = { ActivationDistance = 150, ReturnDelay = 2 },
            ["RidgeBlitz"] = { ActivationDistance = 250, ReturnDelay = 3 },
            ["RidgePinkie"] = { ActivationDistance = 180, ReturnDelay = 4 },
            ["RidgeChainsmoker"] = { ActivationDistance = 100, ReturnDelay = 3 },
            ["RidgeFroger"] = { ActivationDistance = 200, ReturnDelay = 4 },
            ["RidgePandemonium"] = { ActivationDistance = 300, ReturnDelay = 5 },
            ["RidgeMirage"] = { ActivationDistance = 250, ReturnDelay = 3 },
            ["Pipsqueak"] = { ActivationDistance = 200, ReturnDelay = 6 },
            ["A60"] = { ActivationDistance = 300, ReturnDelay = 3 }
        }
    }

    local AutoHideState = {
        isHiding = false, originalPosition = nil, flyConnection = nil,
        returnDelayCoroutine = nil, BodyGyro = nil, BodyPosition = nil,
        isFlying = false
    }

    local function getRoot(character)
        return character:FindFirstChild('HumanoidRootPart') or character:FindFirstChild('Torso') or character:FindFirstChild('UpperTorso')
    end

    local function disableFly()
        if not AutoHideState.isFlying then return end
        AutoHideState.isFlying = false

        if AutoHideState.flyConnection then
            AutoHideState.flyConnection:Disconnect()
            AutoHideState.flyConnection = nil
        end
        if LocalPlayer.Character then
            local root = getRoot(LocalPlayer.Character)
            if root then
                if AutoHideState.BodyPosition and AutoHideState.BodyPosition.Parent == root then AutoHideState.BodyPosition:Destroy() end
                if AutoHideState.BodyGyro and AutoHideState.BodyGyro.Parent == root then AutoHideState.BodyGyro:Destroy() end
            end
            local humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then humanoid.PlatformStand = false end
        end
    end

    local function enableFly()
        if AutoHideState.isFlying then return end
        local char = LocalPlayer.Character
        if not char then return end
        local root = getRoot(char)
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid then return end

        AutoHideState.isFlying = true
        humanoid.PlatformStand = true

        AutoHideState.BodyPosition = Instance.new("BodyPosition")
        AutoHideState.BodyPosition.Position = root.Position
        AutoHideState.BodyPosition.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        AutoHideState.BodyPosition.P = 50000
        AutoHideState.BodyPosition.Parent = root

        AutoHideState.BodyGyro = Instance.new("BodyGyro")
        AutoHideState.BodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
        AutoHideState.BodyGyro.P = 50000
        AutoHideState.BodyGyro.CFrame = root.CFrame
        AutoHideState.BodyGyro.Parent = root

        AutoHideState.flyConnection = RunService.Stepped:Connect(function()
            if AutoHideState.isFlying and AutoHideState.BodyGyro and AutoHideState.BodyGyro.Parent then
                AutoHideState.BodyGyro.CFrame = Camera.CFrame
            else
                disableFly()
            end
        end)
    end

    local function startHiding(monsterCount)
        if AutoHideState.isHiding then return end
        AutoHideState.isHiding = true

        local char = LocalPlayer.Character
        local root = char and getRoot(char)
        if not root then return end

        AutoHideState.originalPosition = root.CFrame

        local safeHeight = AutoHideConfig.AdaptiveHeight and (AutoHideConfig.SafeHeight + (100 * (monsterCount - 1))) or AutoHideConfig.SafeHeight
        local targetCFrame = AutoHideState.originalPosition * CFrame.new(0, safeHeight, 0)

        local tweenInfo = TweenInfo.new(AutoHideConfig.TweenSpeed, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local tween = TweenService:Create(root, tweenInfo, {CFrame = targetCFrame})
        
        if Alert and Alert.SendAlert then
            Alert:SendAlert({title = "Auto Hide", content = "Monster detected! Ascending to safety.", type = "warn"})
        end
        
        tween:Play()
        
        task.spawn(function()
            tween.Completed:Wait()
            if AutoHideState.isHiding then
                enableFly()
            end
        end)
    end

    local function returnToGround()
        if not AutoHideState.isHiding then return end
        
        local char = LocalPlayer.Character
        local root = char and getRoot(char)
        if not root then
            AutoHideState.isHiding = false 
            return
        end

        disableFly() 

        if AutoHideConfig.SmoothReturn then
            local tweenInfo = TweenInfo.new(AutoHideConfig.TweenSpeed, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            local tween = TweenService:Create(root, tweenInfo, {CFrame = AutoHideState.originalPosition})
            tween:Play()
            
            task.spawn(function()
                tween.Completed:Wait()
                AutoHideState.isHiding = false
                AutoHideState.originalPosition = nil
            end)
        else
            root.CFrame = AutoHideState.originalPosition
            AutoHideState.isHiding = false
            AutoHideState.originalPosition = nil
        end
        
        if Alert and Alert.SendAlert then
            Alert:SendAlert({title = "All Clear", content = "Descending back to ground.", type = "info"})
        end
    end

    local NPC_ESP_Config = {
        Enabled = true,
        MonsterTypes = AutoHideConfig.MonsterSettings
    }

    local NPC_ESP_State = { TrackedNPCs = {} }
    
    local NPC_ESP_ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    NPC_ESP_ScreenGui.Name = "NPC_ESP_Gui"
    NPC_ESP_ScreenGui.ResetOnSpawn = false

    local function cleanupMonsterVisuals(monster)
        if NPC_ESP_State.TrackedNPCs[monster] then
            local data = NPC_ESP_State.TrackedNPCs[monster]
            if data.Visuals.Glow and data.Visuals.Glow.Parent then data.Visuals.Glow.Parent:Destroy() end
            if data.Visuals.Billboard and data.Visuals.Billboard.Parent then data.Visuals.Billboard:Destroy() end
            if data.DeathConnection then data.DeathConnection:Disconnect() end
            NPC_ESP_State.TrackedNPCs[monster] = nil
        end
    end

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
    
    local function updateMonsterVisuals(monster, data)
        local adornee = data.Visuals.Billboard.Adornee
        if not (adornee and adornee.Parent) then return end

        local color = Color3.fromRGB(255, 0, 0)
        
        data.Visuals.Glow.Enabled = NPC_ESP_Config.Glow_Enabled
        data.Visuals.Glow.FillColor = color
        data.Visuals.Glow.FillTransparency = NPC_ESP_Config.Glow_Transparency
        
        data.Visuals.Billboard.Enabled = NPC_ESP_Config.Name_Enabled or NPC_ESP_Config.Health_Enabled or NPC_ESP_Config.Distance_Enabled
        data.Visuals.NameLabel.Visible = NPC_ESP_Config.Name_Enabled
        data.Visuals.NameLabel.TextColor3 = color
        data.Visuals.HealthBar.Visible = NPC_ESP_Config.Health_Enabled

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

    local function checkAndTrackObject(object)
        if NPC_ESP_State.TrackedNPCs[object] then return end

        if object:IsA("Model") and object:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(object) then
            local humanoid = object:FindFirstChildOfClass("Humanoid")
            local hrp = object:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local visuals = createVisualsForMonster(object, hrp)
            local deathConnection = humanoid.Died:Connect(function() cleanupMonsterVisuals(object) end)
            NPC_ESP_State.TrackedNPCs[object] = { Visuals = visuals, Type = "Humanoid", DeathConnection = deathConnection }
            
            if NPC_ESP_Config.Spawn_Notifications then
                Alert:ConfigureAlerts({ position = "Center" })
                Alert:SendAlert({ title = "Monster Spawned!", content = string.format("A(n) %s has appeared.", object.Name), type = "danger", duration = 5 })
            end
        
        elseif object:IsA("BasePart") and NPC_ESP_Config.MonsterTypes[object.Name] then
            if object.Parent and NPC_ESP_State.TrackedNPCs[object.Parent] then return end

            local visuals = createVisualsForMonster(object, object)
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

    LocalPlayer.CharacterAdded:Connect(function(character)
        disableFly()
        AutoHideState.isHiding = false
        AutoHideState.originalPosition = nil
        if AutoHideState.returnDelayCoroutine then
            coroutine.close(AutoHideState.returnDelayCoroutine)
            AutoHideState.returnDelayCoroutine = nil
        end
    end)

    RunService.RenderStepped:Connect(function()
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

        if AutoHideConfig.Enabled and LocalPlayer.Character and getRoot(LocalPlayer.Character) then
            local monsterIsNear = false
            local monsterCount = 0
            local activeReturnDelay = AutoHideConfig.MonsterSettings.Defaults.ReturnDelay
            local playerRootPart = getRoot(LocalPlayer.Character)
            
            for monster, data in pairs(NPC_ESP_State.TrackedNPCs) do
                local monsterPart = data.Visuals.Billboard.Adornee
                if monsterPart and monsterPart.Parent then
                    
                    local monsterSettings = AutoHideConfig.MonsterSettings[monster.Name] or AutoHideConfig.MonsterSettings.Defaults
                    
                    local distance
                    if AutoHideState.isHiding then
                        local playerPosFlat = Vector3.new(playerRootPart.Position.X, 0, playerRootPart.Position.Z)
                        local monsterPosFlat = Vector3.new(monsterPart.Position.X, 0, monsterPart.Position.Z)
                        distance = (playerPosFlat - monsterPosFlat).Magnitude
                    else
                        distance = (playerRootPart.Position - monsterPart.Position).Magnitude
                    end
                    
                    if distance < monsterSettings.ActivationDistance then
                        monsterIsNear = true
                        activeReturnDelay = math.max(activeReturnDelay, monsterSettings.ReturnDelay)
                    end
                    monsterCount = monsterCount + 1
                end
            end

            if monsterIsNear then
                if AutoHideState.returnDelayCoroutine then
                    coroutine.close(AutoHideState.returnDelayCoroutine)
                    AutoHideState.returnDelayCoroutine = nil
                end
                if not AutoHideState.isHiding then
                    startHiding(monsterCount)
                end
            else
                if AutoHideState.isHiding and not AutoHideState.returnDelayCoroutine then
                    AutoHideState.returnDelayCoroutine = coroutine.create(function()
                        task.wait(activeReturnDelay)
                        if AutoHideState.isHiding then
                            returnToGround()
                        end
                        AutoHideState.returnDelayCoroutine = nil
                    end)
                    coroutine.resume(AutoHideState.returnDelayCoroutine)
                end
            end
        end
    end)
    
    local NPC_ESPTab = Window:CreateTab("NPC ESP", "ghost")
    NPC_ESPTab:CreateToggle({ Name = "Enable NPC ESP", CurrentValue = NPC_ESP_Config.Enabled, Flag = "NPC_ESP_Enabled", Callback = function(v) NPC_ESP_Config.Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Enable Glow (Chams)", CurrentValue = NPC_ESP_Config.Glow_Enabled, Flag = "NPC_ESP_Glow", Callback = function(v) NPC_ESP_Config.Glow_Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Show Name", CurrentValue = NPC_ESP_Config.Name_Enabled, Flag = "NPC_ESP_Name", Callback = function(v) NPC_ESP_Config.Name_Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Show Health", CurrentValue = NPC_ESP_Config.Health_Enabled, Flag = "NPC_ESP_Health", Callback = function(v) NPC_ESP_Config.Health_Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Show Distance", CurrentValue = NPC_ESP_Config.Distance_Enabled, Flag = "NPC_ESP_Distance", Callback = function(v) NPC_ESP_Config.Distance_Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Spawn Notifications", CurrentValue = NPC_ESP_Config.Spawn_Notifications, Flag = "NPC_ESP_Notifications", Callback = function(v) NPC_ESP_Config.Spawn_Notifications = v end })

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
end

return Module