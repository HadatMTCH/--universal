local Module = {}

function Module.CreateTab(Window)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    -- Configuration for the ESP
    local Config = {
        Enabled = true,
        ShowName = true,
        ShowDistance = true,
        GlowColor = Color3.fromRGB(255, 220, 0) 
    }

    local trackedCurrency = {}
    local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = "CurrencyESP_Gui"
    screenGui.ResetOnSpawn = false

    local function cleanupVisuals(item)
        if trackedCurrency[item] then
            trackedCurrency[item].Highlight:Destroy()
            trackedCurrency[item].Billboard:Destroy()
            trackedCurrency[item] = nil
        end
    end

    local function createVisuals(model)
        if trackedCurrency[model] then return end

        local adorneePart = model:FindFirstChildWhichIsA("BasePart")
        if not adorneePart then return end

        local highlight = Instance.new("Highlight", model)
        highlight.FillColor = Config.GlowColor
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        local billboard = Instance.new("BillboardGui", screenGui)
        billboard.Adornee = adorneePart 
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 150, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 1.5, 0)
        
        local textLabel = Instance.new("TextLabel", billboard)
        textLabel.Size = UDim2.fromScale(1, 1)
        textLabel.BackgroundTransparency = 1
        textLabel.Font = Enum.Font.GothamSemibold
        textLabel.TextSize = 16
        textLabel.TextColor3 = Config.GlowColor
        textLabel.TextStrokeTransparency = 0
        
        trackedCurrency[model] = { Highlight = highlight, Billboard = billboard, Text = textLabel, Adornee = adorneePart }
    end

    local function checkObject(object)
        -- Look for a Model whose name starts with "Currency"
        if object:IsA("Model") and object.Name:match("^Currency") then
            createVisuals(object)
        end
    end

    -- Initial scan and listener for new items
    local roomsFolder = Workspace:WaitForChild("GameplayFolder"):WaitForChild("Rooms")
    for _, item in ipairs(roomsFolder:GetDescendants()) do checkObject(item) end
    roomsFolder.DescendantAdded:Connect(checkObject)

    -- Update loop
    RunService.RenderStepped:Connect(function()
        local camera = Workspace.CurrentCamera
        if not Config.Enabled then
            for item, visuals in pairs(trackedCurrency) do
                visuals.Highlight.Enabled = false
                visuals.Billboard.Enabled = false
            end
            return
        end

        local playerRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        for item, visuals in pairs(trackedCurrency) do
            if not item.Parent then
                cleanupVisuals(item)
            else
                visuals.Highlight.Enabled = true
                visuals.Billboard.Enabled = Config.ShowName or Config.ShowDistance
                
                local distance = (playerRoot.Position - visuals.Adornee.Position).Magnitude
                local textParts = {}
                if Config.ShowName then table.insert(textParts, item.Name) end
                if Config.ShowDistance then table.insert(textParts, string.format("[%dM]", distance)) end
                
                visuals.Text.Text = table.concat(textParts, " ")
            end
        end
    end)

    local ItemESPTab = Window:CreateTab("Item ESP", "box")
    ItemESPTab:CreateSection("Currency ESP")

    ItemESPTab:CreateToggle({
        Name = "Enable Currency ESP", CurrentValue = Config.Enabled, Flag = "CurrencyESP_Enabled",
        Callback = function(v) Config.Enabled = v end
    })
    ItemESPTab:CreateToggle({
        Name = "Show Name", CurrentValue = Config.ShowName, Flag = "CurrencyESP_ShowName",
        Callback = function(v) Config.ShowName = v end
    })
    ItemESPTab:CreateToggle({
        Name = "Show Distance", CurrentValue = Config.ShowDistance, Flag = "CurrencyESP_ShowDistance",
        Callback = function(v) Config.ShowDistance = v end
    })
end

return Module