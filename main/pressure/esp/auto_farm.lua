local Module = {}

function Module.CreateTab(Window, Network)
    -- Services & Player
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    -- UPDATED: Configuration table now includes Ammo
    local Config = {
        EnableCurrencyESP = true,
        EnableItemESP = true,
        EnableAmmoESP = true, -- NEW
        EnableAutoGrabCurrency = false,
        EnableAutoGrabAmmo = false, -- NEW
        ExtraRadiusPercent = 50
    }

    -- State tables
    local trackedObjects = {}
    local promptsToGrabCurrency = {}
    local promptsToGrabAmmo = {} -- NEW
    local originalPromptDistances = {}
    local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = "AutofarmESP_Gui"
    screenGui.ResetOnSpawn = false
    
    local function createVisuals(object, objectType, color, text)
        if trackedObjects[object] then return end

        local highlight = Instance.new("Highlight", object)
        highlight.FillColor = color
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        local billboard = Instance.new("BillboardGui", screenGui)
        billboard.Adornee = object
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 150, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 1.5, 0)
        
        local textLabel = Instance.new("TextLabel", billboard)
        textLabel.Size = UDim2.fromScale(1, 1)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.GothamSemibold
        textLabel.TextSize = 16
        textLabel.TextColor3 = color
        textLabel.TextStrokeTransparency = 0
        
        trackedObjects[object] = { Highlight = highlight, Billboard = billboard, Text = textLabel, Type = objectType, BaseText = text }
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
        -- Check for ProximityPrompt first, as it's common to all our targets
        if object:IsA("ProximityPrompt") then
            if originalPromptDistances[object] then return end -- Already processed this prompt

            local parentModel = object.Parent and object.Parent.Parent
            if not (parentModel and parentModel:IsA("Model")) then return end

            originalPromptDistances[object] = object.MaxActivationDistance

            -- Check if it's a Currency item
            if parentModel:GetAttribute("Amount") then
                local amount = parentModel:GetAttribute("Amount")
                createVisuals(parentModel, "Currency", Color3.fromRGB(255, 220, 0), "Currency ("..amount..")")
                table.insert(promptsToGrabCurrency, object)
            -- Check if it's a generic Item
            elseif not parentModel:FindFirstChild("Enter", true) then
                 createVisuals(parentModel, "Item", Color3.fromRGB(0, 180, 255), "Item")
            end
        
        -- NEW: Check for Ammo models by name, based on your ammo.lua logic
        elseif object:IsA("Model") and (object.Name == "SmallAmmoBox" or object.Name:match("^%d+Shells?%d+$")) then
            local prompt = object:FindFirstChildOfClass("ProximityPrompt", true)
            if prompt and not originalPromptDistances[prompt] then -- Make sure it has a prompt we haven't seen
                originalPromptDistances[prompt] = prompt.MaxActivationDistance
                createVisuals(object, "Ammo", Color3.fromRGB(0, 255, 100), "Ammo")
                table.insert(promptsToGrabAmmo, prompt)
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

        -- Auto Grab Logic (This part is correct and remains the same)
        if Config.EnableAutoGrab then
            for i = #promptsToGrabCurrency, 1, -1 do
                local prompt = promptsToGrabCurrency[i]
                if prompt and prompt.Parent then
                    forceTriggerPrompt(prompt)
                else
                    table.remove(promptsToGrabCurrency, i)
                end
            end
        end
        if Config.EnableAutoGrabAmmo then
            for i = #promptsToGrabAmmo, 1, -1 do
                local prompt = promptsToGrabAmmo[i]
                if prompt and prompt.Parent then
                    forceTriggerPrompt(prompt)
                else
                    table.remove(promptsToGrabAmmo, i)
                end
            end
        end

        -- ESP Visual Update Logic
        for object, visuals in pairs(trackedObjects) do
            
            ---[[ UPDATED: Logic to remove 'goto' ]]---
            -- First, we determine if the ESP for this object should be removed.
            local shouldBeCleaned = false
            if not object or not object.Parent then
                shouldBeCleaned = true
            elseif visuals.Type == "Currency" or visuals.Type == "Ammo" or visuals.Type == "Item" then
                if not object:FindFirstChildOfClass("ProximityPrompt", true) then
                    shouldBeCleaned = true -- Mark for cleanup if the prompt is gone
                end
            end

            -- Now, we either clean it up OR update it.
            if shouldBeCleaned then
                cleanupVisuals(object)
            else
                -- If it's still valid, update its visuals. All update logic now goes in this else block.
                local shouldBeVisible = 
                    (visuals.Type == "Currency" and Config.EnableCurrencyESP) or 
                    (visuals.Type == "Item" and Config.EnableItemESP) or
                    (visuals.Type == "Ammo" and Config.EnableAmmoESP)
                
                visuals.Highlight.Enabled = shouldBeVisible
                visuals.Billboard.Enabled = shouldBeVisible

                if shouldBeVisible then
                    local distance = (playerRoot.Position - visuals.Adornee.Position).Magnitude
                    visuals.Text.Text = visuals.BaseText .. string.format(" [%dM]", distance)
                end
            end
            ---------------------------------------------
        end
    end)

    -- UI Creation
    local FarmTab = Window:CreateTab("Pressure Farm", "badge-dollar-sign")
    FarmTab:CreateSection("ESP Settings")
    FarmTab:CreateToggle({ Name = "Currency ESP", CurrentValue = Config.EnableCurrencyESP, Callback = function(v) Config.EnableCurrencyESP = v end })
    FarmTab:CreateToggle({ Name = "Item ESP", CurrentValue = Config.EnableItemESP, Callback = function(v) Config.EnableItemESP = v end })
    FarmTab:CreateToggle({ Name = "Ammo ESP", CurrentValue = Config.EnableAmmoESP, Callback = function(v) Config.EnableAmmoESP = v end }) -- NEW

    FarmTab:CreateSection("Auto-Farm Settings")
    FarmTab:CreateToggle({ Name = "Auto Grab Currency", CurrentValue = Config.EnableAutoGrabCurrency, Callback = function(v) Config.EnableAutoGrabCurrency = v end })
    FarmTab:CreateToggle({ Name = "Auto Grab Ammo", CurrentValue = Config.EnableAutoGrabAmmo, Callback = function(v) Config.EnableAutoGrabAmmo = v end }) -- NEW
end

return Module