-- ===================================================================
-- Network Library (Rewritten from Firelib ( https://github.com/InfernusScripts/Null-Fire/blob/main/Core/Libraries/Network/Main.lua ) )
-- ===================================================================
-- ========================================
-- GLOBAL TABLE SETUP
-- ========================================

local function getGlobalTable()
    return typeof(getfenv().getgenv) == "function" and typeof(getfenv().getgenv()) == "table" and getfenv().getgenv() or _G
end

-- Return existing instance if already loaded
if getGlobalTable()._NETWORK then
    return getGlobalTable()._NETWORK
end

-- ========================================
-- VARIABLES AND SERVICES
-- ========================================

local active = false
local cooldowns = {}

-- Environment functions
local setHiddenProperty = getfenv().sethiddenproperty or getfenv().sethiddenprop
local setSimulationRadius = getfenv().setsimulationradius
local fireTouchInterest = getfenv().firetouchinterest
local fireProximityPrompt = getfenv().fireproximityprompt

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================

local function setValue(object, index, value)
    object[index] = value
end

-- Render step timing function
local function renderStep(times)
    local times = math.max(math.round(tonumber(times) or 1), 1)
    local deltaTime = 0
    
    for i = 1, times do
        deltaTime = deltaTime + RunService.RenderStepped:Wait()
    end
    
    return deltaTime / times
end

-- Enhanced wait function for precise timing
local function renderWait(seconds)
    local startTime = tick()
    seconds = tonumber(seconds) or 0
    
    task.wait((seconds / 2) - renderStep())
    task.wait((seconds / 2) - (renderStep() * 2))
    renderStep()
    
    return tick() - startTime
end

-- ========================================
-- NETWORK OWNERSHIP MANAGEMENT
-- ========================================

-- Main network ownership loop
RunService.RenderStepped:Connect(function()
    if not active then return end
    
    -- Set other players' simulation radius to 0
    for _, player in Players:GetPlayers() do
        if player and player ~= localPlayer then
            pcall(setValue, player, "MaximumSimulationRadius", 0)
            if setHiddenProperty then 
                pcall(setHiddenProperty, player, 'MaxSimulationRadius', 0)
                pcall(setHiddenProperty, player, 'SimulationRadius', 0)
            end
        end
    end

    -- Disable physics sleep and set replication focus
    settings().Physics.AllowSleep = false
    localPlayer.ReplicationFocus = workspace

    -- Maximize local player's simulation radius
    if setHiddenProperty then
        pcall(setHiddenProperty, localPlayer, 'MaxSimulationRadius', math.huge)
        pcall(setHiddenProperty, localPlayer, 'SimulationRadius', math.huge)
    end
    
    if setSimulationRadius then 
        pcall(setSimulationRadius, 9e8, 9e9) 
    end

    pcall(setValue, localPlayer, "MaximumSimulationRadius", math.huge)
end)

-- ========================================
-- TOUCH INTEREST SYSTEM
-- ========================================

-- Test if firetouchinterest works properly
local touchInterestValid = false

task.spawn(pcall, function()
    if fireTouchInterest then
        local testPart = Instance.new("Part", workspace)
        testPart.Position = Vector3.new(0, 100, 0)
        testPart.Anchored = false -- important for physics
        testPart.CanCollide = false
        testPart.Transparency = 1
        
        testPart.Touched:Connect(function()
            testPart:Destroy()
            touchInterestValid = true
        end)
        
        task.wait(0.1)
        repeat task.wait() until localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and testPart and testPart.Parent
        
        fireTouchInterest(testPart, localPlayer.Character.HumanoidRootPart, 0)
        fireTouchInterest(localPlayer.Character.HumanoidRootPart, testPart, 0)
        task.wait()
        
        repeat task.wait() until localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and testPart and testPart.Parent
        
        fireTouchInterest(testPart, localPlayer.Character.HumanoidRootPart, 1)
        fireTouchInterest(localPlayer.Character.HumanoidRootPart, testPart, 1)
    end
end)

-- Custom touch interest function with fallback
local function customTouchInterest(partA, partB, touching)
    if touchInterestValid then
        return fireTouchInterest(partA, partB, touching)
    end

    -- Prevent multiple simultaneous operations on same parts
    if cooldowns[partA] or cooldowns[partB] then return end
    
    -- Don't touch parts within same character
    if partA:IsDescendantOf(localPlayer.Character) and partB:IsDescendantOf(localPlayer.Character) then return end
    
    -- Ensure partA is from player character
    if partB:IsDescendantOf(localPlayer.Character) then
        local temp = partA
        partA = partB
        partB = temp
    end

    -- Set cooldowns
    cooldowns[partA] = true
    cooldowns[partB] = true
    
    touching = touching == 0

    if not touching then
        -- Handle touch end
        local originalCanTouch = partB.CanTouch
        partB.CanTouch = false
        task.wait(0.015)
        partB.CanTouch = originalCanTouch
    else
        -- Handle touch begin
        local originalPivot = partB:GetPivot()
        local originalTransparency, originalCanCollide, originalAnchored = partB.Transparency, partB.CanCollide, partB.Anchored
        
        partB:PivotTo(partA:GetPivot())
        partB.Transparency = 1
        partB.CanCollide = false
        partB.Anchored = false
        partB.Velocity = partB.Velocity + Vector3.new(0, 1)
        
        partA.Touched:Wait()
        
        partB.Transparency = originalTransparency
        partB.CanCollide = originalCanCollide
        partB.Anchored = originalAnchored
        partB:PivotTo(originalPivot)
    end
    
    task.wait()

    -- Clear cooldowns
    cooldowns[partA] = false
    cooldowns[partB] = false
end

-- ========================================
-- PROXIMITY PROMPT SYSTEM
-- ========================================

-- Test if fireproximityprompt works properly
local proximityPromptValid = false

if fireProximityPrompt then
    task.spawn(pcall, function()
        local testPrompt = Instance.new("ProximityPrompt", localPlayer.Character)
        local connection
        
        connection = testPrompt.Triggered:Connect(function()
            connection:Disconnect()
            testPrompt:Destroy()
            proximityPromptValid = true
        end)
        
        task.wait(0.1)
        fireProximityPrompt(testPrompt)
        task.wait(1.5)
        
        if testPrompt and testPrompt.Parent then
            testPrompt:Destroy()
            connection:Disconnect()
        end	
    end)
end

-- Custom proximity prompt function with fallback
local function customProximityPromptFunction(proximityPrompt)
    if cooldowns[proximityPrompt] then return end
    
    cooldowns[proximityPrompt] = true
    
    -- Store original properties
    local originalMaxDistance = proximityPrompt.MaxActivationDistance
    local originalEnabled = proximityPrompt.Enabled
    local originalParent = proximityPrompt.Parent
    local originalHoldDuration = proximityPrompt.HoldDuration
    local originalRequiresLineOfSight = proximityPrompt.RequiresLineOfSight
    
    -- Create temporary object for prompt
    local tempObject = Instance.new("Part", workspace)
    tempObject.Transparency = 1
    tempObject.CanCollide = false
    tempObject.Size = Vector3.new(0.1, 0.1, 0.1)
    tempObject.Anchored = true
    
    -- Configure prompt for activation
    proximityPrompt.Parent = tempObject
    proximityPrompt.MaxActivationDistance = math.huge
    proximityPrompt.Enabled = true
    proximityPrompt.HoldDuration = 0
    proximityPrompt.RequiresLineOfSight = false
    
    if not proximityPrompt or not proximityPrompt.Parent then
        tempObject:Destroy()
        return
    end
    
    -- Position near camera
    local cameraPosition = workspace.CurrentCamera.CFrame + (workspace.CurrentCamera.CFrame.LookVector / 5)
    tempObject:PivotTo(cameraPosition)
    
    renderStep()
    tempObject:PivotTo(cameraPosition)
    renderStep()
    tempObject:PivotTo(cameraPosition)
    
    -- Simulate prompt interaction
    proximityPrompt:InputHoldBegin()
    renderStep()
    proximityPrompt:InputHoldEnd()
    renderStep()
    
    -- Restore original properties
    if proximityPrompt.Parent == tempObject then
        proximityPrompt.Parent = originalParent
        proximityPrompt.MaxActivationDistance = originalMaxDistance
        proximityPrompt.Enabled = originalEnabled
        proximityPrompt.HoldDuration = originalHoldDuration
        proximityPrompt.RequiresLineOfSight = originalRequiresLineOfSight
    end
    
    tempObject:Destroy()
    cooldowns[proximityPrompt] = false
end

-- ========================================
-- PIVOT HELPER FUNCTIONS
-- ========================================

local function canGetPivot(object)
    return object.GetPivot
end

local function getPivot(object)
    if not object or not object.Parent or object == workspace then 
        return CFrame.new() 
    end
    
    if object:IsA("BasePart") or object:IsA("Model") then
        return object:GetPivot()
    elseif object:IsA("Attachment") then
        return object.WorldCFrame
    end
    
    return getPivot(
        object:FindFirstAncestorWhichIsA("BasePart") or 
        object:FindFirstAncestorWhichIsA("Attachment") or 
        object:FindFirstAncestorWhichIsA("Model")
    )
end

-- ========================================
-- PUBLIC PROXIMITY PROMPT FUNCTION
-- ========================================

local function customFireProximityPrompt(proximityPrompt, distanceCheck)
    if distanceCheck == nil then
        distanceCheck = true
    end
    
    -- Validation checks
    if typeof(proximityPrompt) ~= "Instance" or 
       not proximityPrompt:IsA("ProximityPrompt") or 
       cooldowns[proximityPrompt] then
        return false
    end
    
    -- Distance check if enabled
    if distanceCheck then
        local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
        local rootPart = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
        if not rootPart then return false end

        local promptPosition = getPivot(proximityPrompt.Parent).Position
        local distance = (promptPosition - rootPart.Position).Magnitude
        
        if distance > proximityPrompt.MaxActivationDistance then
            return false
        end
    end
    
    -- Use native function if available, otherwise use custom
    if proximityPromptValid then
        task.spawn(fireProximityPrompt, proximityPrompt)
        return true
    end
    
    task.spawn(customProximityPromptFunction, proximityPrompt)
    return true
end

-- ========================================
-- MAIN MODULE TABLE
-- ========================================

local networkModule = setmetatable({
    Active = active,
    
    SetActive = function(self, state)
        return self(state)
    end,

    IsNetworkOwner = function(self, part, fullCustomCheck)
        if getfenv().isnetworkowner and not fullCustomCheck then
            return getfenv().isnetworkowner(part)
        end
        
        local currentNetworkOwner = getfenv().gethiddenproperty and getfenv().gethiddenproperty(part, "NetworkOwnerV3")
        return (typeof(currentNetworkOwner) == "number" and currentNetworkOwner > 2 or part.ReceiveAge == 0) and not part.Anchored
    end,
    
    Other = table.freeze({
        TouchInterest = function(self, ...)
            return customTouchInterest(...)
        end,
        
        TouchTransmitter = function(self, ...)
            return self:TouchInterest(...)
        end,
        
        FireTouchInterest = function(self, ...)
            return self:TouchInterest(...)
        end,
        
        FireTouchTransmitter = function(self, ...)
            return self:TouchInterest(...)
        end,
        
        ProximityPrompt = function(self, ...)
            return customFireProximityPrompt(...)
        end,
        
        FireProximityPrompt = function(self, ...)
            return self:ProximityPrompt(...)
        end,
        
        Touch = function(self, target, instant)
            if not localPlayer.Character or not target then return end
            
            local characterParts = {}
            
            for i, part in localPlayer.Character:GetChildren() do
                if part and part:IsA("BasePart") then
                    table.insert(characterParts, part)
                end
            end
            
            if #characterParts == 0 then return end
            
            local randomPart = characterParts[math.random(1, #characterParts)]
            
            self:TouchInterest(randomPart, target, 0)
            
            if not instant then
                renderWait()
            end
            
            self:TouchInterest(randomPart, target, 1)
        end,
        
        TouchPart = function(self, ...)
            return self:Touch(...)
        end,
        
        Sit = function(self, seatPart)
            if not seatPart or not localPlayer.Character then return end
            
            local humanoid = localPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                if seatPart.Occupant then return end
                
                local originalPosition = seatPart:GetPivot()
                
                seatPart:PivotTo(localPlayer.Character.HumanoidRootPart:GetPivot())
                self:Touch(seatPart, false)
                seatPart:PivotTo(originalPosition)
            end
        end,
    })
}, {
    __call = function(self, state)
        active = state
        self.Active = state

        settings().Physics.AllowSleep = not state
        localPlayer.ReplicationFocus = state and workspace or nil

        if not state then
            -- Reset all players' simulation radius to default when disabled
            for _, player in Players:GetPlayers() do
                if player then
                    pcall(setValue, player, "MaximumSimulationRadius", 20) -- default values
                    if setHiddenProperty then 
                        pcall(setHiddenProperty, player, 'MaxSimulationRadius', 20, 100)
                        pcall(setHiddenProperty, player, 'SimulationRadius', 40)
                    end
                end
            end
            if setSimulationRadius then 
                pcall(setSimulationRadius, 0, 30) 
            end
        end
    end
})

networkModule.__index = networkModule

-- Store in global table and return
getGlobalTable()._NETWORK = networkModule
return networkModule