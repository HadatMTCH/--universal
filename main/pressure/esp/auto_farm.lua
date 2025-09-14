local Module = {}

function Module.CreateTab(Window, Network)
    -- Services & Player
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    local Config = {
        EnableCurrencyESP = true,
        EnableItemESP = true,
        EnableAutoGrab = false,
        RadiusPercent = 0
    }

    -- State tables
    local trackedObjects = {}
    local promptsToGrab = {}
    local originalPromptDistances = {} -- NEW: Table to store original distances
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
        if not object or not object.Parent or not object:IsA("ProximityPrompt") then return end
        if originalPromptDistances[object] then return end -- Already processed

        local parentModel = object.Parent and object.Parent.Parent
        if not (parentModel and parentModel:IsA("Model")) then return end

        originalPromptDistances[object] = object.MaxActivationDistance
        if parentModel:GetAttribute("Amount") then
            local amount = parentModel:GetAttribute("Amount")
            createVisuals(parentModel, "Currency", Color3.fromRGB(255, 220, 0), "Currency ("..amount..")")
            table.insert(promptsToGrab, object)
        elseif not parentModel:FindFirstChild("Enter", true) then
            print("Item section Parent Name")
            print(parentModel.Name)
            print("Item section Object Name")
            print(object.Name)
             createVisuals(parentModel, "Item", Color3.fromRGB(0, 180, 255), "Item")
        end
    end
    
    -- Initial scan and listener for new items
    for _, v in ipairs(Workspace:GetDescendants()) do task.spawn(processObject, v) end
    Workspace.DescendantAdded:Connect(processObject)

    -- Main update loop
    RunService.RenderStepped:Connect(function()
        local playerRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        -- Auto Grab Logic
        if Config.EnableAutoGrab then
            for i = #promptsToGrab, 1, -1 do
                local prompt = promptsToGrab[i]
                if prompt and prompt.Parent and prompt.Parent.Parent then
                    
                    ---[[ THE ONLY CHANGE IS ON THIS LINE ]]---
                    -- Instead of getting the position from the model, get it from the prompt's direct parent part.
                    local itemPosition = prompt.Parent.Position
                    
                    local originalRange = originalPromptDistances[prompt] or prompt.MaxActivationDistance
                    local totalRange = originalRange * (1 + (Config.RadiusPercent / 100))
                    local distance = (itemPosition - playerRoot.Position).Magnitude -- Use the new itemPosition variable
                    
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
            if not object or not object.Parent then
                cleanupVisuals(object)
            else
                local shouldBeVisible = (visuals.Type == "Currency" and Config.EnableCurrencyESP) or (visuals.Type == "Item" and Config.EnableItemESP)
                visuals.Highlight.Enabled = shouldBeVisible
                visuals.Billboard.Enabled = shouldBeVisible

                if shouldBeVisible then
                    local distance = (playerRoot.Position - object:GetPivot().Position).Magnitude
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

    FarmTab:CreateSection("Auto-Farm Settings")
    FarmTab:CreateToggle({ Name = "Auto Grab Currency", CurrentValue = Config.EnableAutoGrab, Callback = function(v) Config.EnableAutoGrab = v end })
    
    FarmTab:CreateSlider({ 
        Name = "Grab Radius Multiplier", 
        Range = {0, 100}, -- Slider from 0% to 100%
        Increment = 5, 
        Suffix = "% Extra", 
        CurrentValue = Config.RadiusPercent, 
        Flag = "Pressure_GrabRadiusPercent",
        Callback = function(v) Config.RadiusPercent = v end 
    })
end

return Module