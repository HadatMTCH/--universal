local Module = {}

function Module.CreateTab(Window)
    -- Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    -- Configuration for the ESP
    local Config = {
        Enabled = true,
        ShowName = true,
        ShowDistance = true,
        GlowColor = Color3.fromRGB(255, 220, 0) -- Gold color
    }

    local trackedCurrency = {}
    local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = "CurrencyESP_Gui"
    screenGui.ResetOnSpawn = false

    -- Function to remove visuals when an item is gone
    local function cleanupVisuals(item)
        if trackedCurrency[item] then
            trackedCurrency[item].Highlight:Destroy()
            trackedCurrency[item].Billboard:Destroy()
            trackedCurrency[item] = nil
        end
    end

    -- Function to create visuals for a new currency item
    local function createVisuals(item)
        if trackedCurrency[item] then return end

        local highlight = Instance.new("Highlight", item)
        highlight.FillColor = Config.GlowColor
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 1
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        
        local billboard = Instance.new("BillboardGui", screenGui)
        billboard.Adornee = item
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
        
        trackedCurrency[item] = { Highlight = highlight, Billboard = billboard, Text = textLabel }
    end

    -- Function to find currency items
    local function checkObject(object)
        if object:IsA("BasePart") and object.Name:match("^Currency") then
            createVisuals(object)
        end
    end

    -- Initial scan and listener for new items
    for _, item in ipairs(Workspace.GameplayFolder.Rooms:GetDescendants()) do checkObject(item) end
    Workspace.GameplayFolder.Rooms.DescendantAdded:Connect(checkObject)

    -- Update loop
    RunService.RenderStepped:Connect(function()
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
                
                local distance = (playerRoot.Position - item.Position).Magnitude
                local textParts = {}
                if Config.ShowName then table.insert(textParts, item.Name) end
                if Config.ShowDistance then table.insert(textParts, string.format("[%dM]", distance)) end
                
                visuals.Text.Text = table.concat(textParts, " ")
            end
        end
    end)

    -- UI Creation
    local ItemESPTab = Window:CreateTab("Item ESP", "box")
    local CurrencySection = ItemESPTab:CreateSection("Currency ESP")

    CurrencySection:CreateToggle({
        Name = "Enable Currency ESP", CurrentValue = Config.Enabled, Flag = "CurrencyESP_Enabled",
        Callback = function(v) Config.Enabled = v end
    })
    CurrencySection:CreateToggle({
        Name = "Show Name", CurrentValue = Config.ShowName, Flag = "CurrencyESP_ShowName",
        Callback = function(v) Config.ShowName = v end
    })
    CurrencySection:CreateToggle({
        Name = "Show Distance", CurrentValue = Config.ShowDistance, Flag = "CurrencyESP_ShowDistance",
        Callback = function(v) Config.ShowDistance = v end
    })
end

return Module