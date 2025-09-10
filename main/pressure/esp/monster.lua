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

    local AutoHideConfig = {
        Enabled = false, ActivationDistance = 200, SafeHeight = 500, TweenSpeed = 2,
        FlySpeed = 16, ReturnDelay = 3, AdaptiveHeight = true, SmoothReturn = true,
    }

    local AutoHideState = {
        isHiding = false, originalPosition = nil, flyConnection = nil,
        returnDelayCoroutine = nil, tweenConnection = nil, BodyGyro = nil, BodyPosition = nil,
        Humanoid = nil, isFlying = false
    }

    local function getRoot(character)
        return character:FindFirstChild('HumanoidRootPart') or character:FindFirstChild('Torso') or character:FindFirstChild('UpperTorso')
    end

    -- UPDATED: Function to disable fly
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

    -- UPDATED: Function to enable fly/hover (now simpler)
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

    -- UPDATED: Function to start hiding (tween CFrame first, then enable hover)
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
        
        -- After the tween is complete, enable hover to stay in the air
        tween.Completed:Wait()
        if AutoHideState.isHiding then -- Check if we didn't cancel during the tween
            enableFly()
        end
    end

    -- UPDATED: Function to return to ground (disable hover first, then tween CFrame)
    local function returnToGround()
        if not AutoHideState.isHiding then return end
        
        local char = LocalPlayer.Character
        local root = char and getRoot(char)
        if not root then return end

        disableFly() -- Disable hover first

        if AutoHideConfig.SmoothReturn then
            local tweenInfo = TweenInfo.new(AutoHideConfig.TweenSpeed, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
            local tween = TweenService:Create(root, tweenInfo, {CFrame = AutoHideState.originalPosition})
            tween:Play()
            tween.Completed:Wait()
        else
            root.CFrame = AutoHideState.originalPosition
        end

        AutoHideState.isHiding = false
        AutoHideState.originalPosition = nil
        
        if Alert and Alert.SendAlert then
            Alert:SendAlert({title = "All Clear", content = "Descending back to ground.", type = "info"})
        end
    end

    -- (The rest of your script: NPC_ESP_Config, State, GUI setup, detection logic...)
    -- ... (This part of your code is good and does not need changes)
    -- ...
    
    -- ---[[ AUTO HIDE FEATURE - RESPAWN SAFETY ]]---
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
        -- (Your ESP visual update logic here)
        -- ...
        
        ---[[ AUTO HIDE FEATURE - CORE LOGIC ]]---
        if AutoHideConfig.Enabled and LocalPlayer.Character and getRoot(LocalPlayer.Character) then
            local monsterIsNear = false
            local monsterCount = 0
            local playerRootPart = getRoot(LocalPlayer.Character)
            
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
                        task.wait(AutoHideConfig.ReturnDelay)
                        if AutoHideState.isHiding then
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

    -- (Your UI creation code here, which is correct)
    -- ...
end

return Module