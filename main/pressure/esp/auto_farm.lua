local Module = {}

function Module.CreateTab(Window, Network)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    -- Configuration table
    local Config = {
        EnableCurrencyESP = true,
        EnableItemESP = false,
        EnableAutoGrab = false,
        Radius = 40
    }

    -- State tables
    local trackedObjects = {}
    local promptsToGrab = {}
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

    -- Central function to identify all collectible objects
    local function processObject(object)
        if not object or not object.Parent or not object:IsA("ProximityPrompt") then return end

        local parentModel = object.Parent and object.Parent.Parent
        if not (parentModel and parentModel:IsA("Model")) then return end

        -- Check if it's a Currency item
        if parentModel:GetAttribute("Amount") then
            local amount = parentModel:GetAttribute("Amount")
            createVisuals(parentModel, "Currency", Color3.fromRGB(255, 220, 0), "Currency ("..amount..")")
            table.insert(promptsToGrab, object)

        -- Check if it's a generic Item (and not a Locker)
        elseif not parentModel:FindFirstChild("Enter", true) then
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
            for i, prompt in ipairs(promptsToGrab) do
                if prompt and prompt.Parent then
                    local itemModel = prompt.Parent.Parent
                    if (itemModel:GetPivot().Position - playerRoot.Position).Magnitude <= Config.Radius then
                        Network:FireProximityPrompt(prompt, false) -- Use the Network library
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
    local FarmTab = Window:CreateTab("Pressure Farm", "dollar")
    FarmTab:CreateSection("ESP Settings")
    FarmTab:CreateToggle({ Name = "Currency ESP", CurrentValue = Config.EnableCurrencyESP, Callback = function(v) Config.EnableCurrencyESP = v end })
    FarmTab:CreateToggle({ Name = "Item ESP", CurrentValue = Config.EnableItemESP, Callback = function(v) Config.EnableItemESP = v end })

    FarmTab:CreateSection("Auto-Farm Settings")
    FarmTab:CreateToggle({ Name = "Auto Grab Currency", CurrentValue = Config.EnableAutoGrab, Callback = function(v) Config.EnableAutoGrab = v end })
    FarmTab:CreateSlider({ Name = "Grab Radius", Range = {10, 100}, Increment = 5, Suffix = "m", CurrentValue = Config.Radius, Callback = function(v) Config.Radius = v end })
end

return Module