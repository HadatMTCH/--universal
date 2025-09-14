local Module = {}

function Module.CreateTab(Window, Network)
    -- Services & Player
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    -- UPDATED: Configuration table
    local Config = {
        EnableCurrencyESP = true,
        EnableItemESP = true,
        EnableAmmoESP = true,
        EnableAutoGrab = false, -- Unified toggle
        ExtraRadiusPercent = 50
    }

    -- State tables
    local trackedObjects = {}
    local promptsToGrab = {} -- Unified list for all collectibles
    local originalPromptDistances = {}
    local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = "AutofarmESP_Gui"
    screenGui.ResetOnSpawn = false
    
    -- UPDATED: createVisuals now finds a valid BasePart to attach the billboard to
    local function createVisuals(object, objectType, color, text)
        if trackedObjects[object] then return end
        
        local adorneePart = object:IsA("BasePart") and object or object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart")
        if not adorneePart then return end -- Cannot create ESP without a part

        local highlight = Instance.new("Highlight", object)
        highlight.FillColor = color; highlight.FillTransparency = 0.6; highlight.OutlineTransparency = 1; highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        local billboard = Instance.new("BillboardGui", screenGui)
        billboard.Adornee = adorneePart -- Attach to the found part
        billboard.AlwaysOnTop = true; billboard.Size = UDim2.new(0, 150, 0, 40); billboard.StudsOffset = Vector3.new(0, 1.5, 0)
        
        local textLabel = Instance.new("TextLabel", billboard)
        textLabel.Size = UDim2.fromScale(1, 1); textLabel.BackgroundTransparency = 1; textLabel.Font = Enum.Font.GothamSemibold; textLabel.TextSize = 16; textLabel.TextColor3 = color; textLabel.TextStrokeTransparency = 0
        
        trackedObjects[object] = { Highlight = highlight, Billboard = billboard, Text = textLabel, Type = objectType, BaseText = text, Adornee = adorneePart }
    end

    local function cleanupVisuals(object)
        if trackedObjects[object] then
            if trackedObjects[object].Highlight then trackedObjects[object].Highlight:Destroy() end
            if trackedObjects[object].Billboard then trackedObjects[object].Billboard:Destroy() end
            trackedObjects[object] = nil
        end
    end

    local triggerCooldowns = {}
    local function forceTriggerPrompt(prompt)
        if not prompt or not prompt.Parent or triggerCooldowns[prompt] then return end

        triggerCooldowns[prompt] = true
        
        -- 1. Save the prompt's original properties
        local originalParent = prompt.Parent
        local originalMaxDistance = prompt.MaxActivationDistance
        local originalLineOfSight = prompt.RequiresLineOfSight
        local originalEnabled = prompt.Enabled

        -- 2. Create a temporary part to hold the prompt and modify it
        local tempPart = Instance.new("Part", workspace.CurrentCamera)
        tempPart.Transparency = 1
        tempPart.CanCollide = false
        tempPart.Anchored = true
        
        prompt.Parent = tempPart
        prompt.MaxActivationDistance = math.huge
        prompt.RequiresLineOfSight = false
        prompt.Enabled = true
        
        -- 3. Fire the unrestricted prompt using the network library
        Network.Other:FireProximityPrompt(prompt)
        
        -- A brief wait is crucial for the game to process the event
        RunService.Heartbeat:Wait()

        -- 4. Restore all original properties and clean up
        if prompt.Parent == tempPart then
            prompt.Parent = originalParent
            prompt.MaxActivationDistance = originalMaxDistance
            prompt.RequiresLineOfSight = originalLineOfSight
            prompt.Enabled = originalEnabled
        end
        tempPart:Destroy()
        
        -- Add a small cooldown before this prompt can be triggered again
        task.delay(0.2, function()
            triggerCooldowns[prompt] = nil
        end)
    end


    -- Central function to identify all collectible objects
    local function processObject(object)
        if object:IsA("ProximityPrompt") then
            if originalPromptDistances[object] then return end
            local parentModel = object.Parent and object.Parent.Parent
            if not (parentModel and parentModel:IsA("Model")) then return end

            originalPromptDistances[object] = object.MaxActivationDistance

            if parentModel:GetAttribute("Amount") then
                local amount = parentModel:GetAttribute("Amount")
                createVisuals(parentModel, "Currency", Color3.fromRGB(255, 220, 0), "Currency ("..amount..")")
                table.insert(promptsToGrab, object) -- Add to unified list
            elseif not parentModel:FindFirstChild("Enter", true) then
                 createVisuals(parentModel, "Item", Color3.fromRGB(0, 180, 255), "Item")
            end
        elseif object:IsA("Model") and (object.Name == "SmallAmmoBox" or object.Name:match("^%d+Shells?%d+$")) then
            local prompt = object:FindFirstChildOfClass("ProximityPrompt", true)
            if prompt and not originalPromptDistances[prompt] then
                originalPromptDistances[prompt] = prompt.MaxActivationDistance
                createVisuals(object, "Ammo", Color3.fromRGB(0, 255, 100), "Ammo")
                table.insert(promptsToGrab, object) -- Add to unified list
            end
        end
    end
    
    -- Initial scan and listener for new items
    for _, v in ipairs(Workspace:GetDescendants()) do task.spawn(processObject, v) end
    Workspace.DescendantAdded:Connect(processObject)

    -- Main update loop
    RunService.RenderStepped:Connect(function()
        local playerRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        -- UPDATED: Auto Grab logic with your requested distance check
        if Config.EnableAutoGrab then
            for i = #promptsToGrab, 1, -1 do
                local prompt = promptsToGrab[i]
                if prompt and prompt.Parent and prompt.Parent.Parent then
                    local itemModel = prompt.Parent.Parent
                    local itemPosition = prompt.Parent.Position
                    
                    local originalRange = originalPromptDistances[prompt] or prompt.MaxActivationDistance
                    local totalRange = originalRange * (1 + (Config.ExtraRadiusPercent / 100))
                    local distance = (itemPosition - playerRoot.Position).Magnitude
                    
                    if distance <= totalRange then
                        forceTriggerPrompt(prompt)
                    end
                else
                    table.remove(promptsToGrab, i)
                end
            end
        end

        -- ESP Visual Update Logic
        for object, visuals in pairs(trackedObjects) do
            local shouldBeCleaned = false
            if not object or not object.Parent then
                shouldBeCleaned = true
            elseif visuals.Type == "Currency" or visuals.Type == "Ammo" or visuals.Type == "Item" then
                if not object:FindFirstChildOfClass("ProximityPrompt", true) then
                    shouldBeCleaned = true
                end
            end

            if shouldBeCleaned then
                cleanupVisuals(object)
            else
                local shouldBeVisible = (visuals.Type == "Currency" and Config.EnableCurrencyESP) or (visuals.Type == "Item" and Config.EnableItemESP) or (visuals.Type == "Ammo" and Config.EnableAmmoESP)
                visuals.Highlight.Enabled = shouldBeVisible
                visuals.Billboard.Enabled = shouldBeVisible

                if shouldBeVisible then
                    local distance = (playerRoot.Position - visuals.Adornee.Position).Magnitude
                    visuals.Text.Text = visuals.BaseText .. string.format(" [%dM]", distance)
                end
            end
        end
    end)

    -- UI Creation
    local FarmTab = Window:CreateTab("Pressure Farm", "badge-dollar-sign")
    FarmTab:CreateSection("ESP Settings")
    FarmTab:CreateToggle({ Name = "Currency ESP", CurrentValue = Config.EnableCurrencyESP, Callback = function(v) Config.EnableCurrencyESP = v end })
    FarmTab:CreateToggle({ Name = "Item ESP", CurrentValue = Config.EnableItemESP, Callback = function(v) Config.EnableItemESP = v end })
    FarmTab:CreateToggle({ Name = "Ammo ESP", CurrentValue = Config.EnableAmmoESP, Callback = function(v) Config.EnableAmmoESP = v end })

    FarmTab:CreateSection("Auto-Farm Settings")
    FarmTab:CreateToggle({ Name = "Auto Grab All Collectibles", CurrentValue = Config.EnableAutoGrab, Callback = function(v) Config.EnableAutoGrab = v end })
    
    FarmTab:CreateSlider({ 
        Name = "Extra Grab Radius", 
        Range = {0, 100}, 
        Increment = 5, 
        Suffix = "%", 
        CurrentValue = Config.ExtraRadiusPercent, 
        Flag = "Pressure_ExtraGrabPercent",
        Callback = function(v) Config.ExtraRadiusPercent = v end 
    })
end

return Module