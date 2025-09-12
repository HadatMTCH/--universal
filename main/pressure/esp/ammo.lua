-- File: ammo.lua (Final Version)
local Module = {}

function Module.CreateTab(Window)
    -- Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    -- Configuration for the Ammo ESP
    local Config = {
        Enabled = true,
        ShowName = true,
        ShowDistance = true,
        GlowColor = Color3.fromRGB(0, 255, 100)
    }

    local trackedAmmo = {}
    local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = "AmmoESP_Gui"
    screenGui.ResetOnSpawn = false

    local function cleanupVisuals(item)
        if trackedAmmo[item] then
            if trackedAmmo[item].Highlight then trackedAmmo[item].Highlight:Destroy() end
            if trackedAmmo[item].Billboard then trackedAmmo[item].Billboard:Destroy() end
            trackedAmmo[item] = nil
        end
    end

    local function createVisuals(model)
        if trackedAmmo[model] then return end
        local adorneePart = model:FindFirstChild("ProxyPart") or model:FindFirstChildWhichIsA("BasePart")
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
        
        trackedAmmo[model] = { Highlight = highlight, Billboard = billboard, Text = textLabel, Adornee = adorneePart }
        
        model.AncestryChanged:Connect(function(_, parent)
            if not parent then
                cleanupVisuals(model)
            end
        end)
    end

    -----------------------------------------------------------------------------------
    -- ## Item Detection Logic (FINAL UPDATE) ## --
    -----------------------------------------------------------------------------------
    local function checkObject(object)
        if not object:IsA("Model") then return end

        -- Condition 1: Check for SmallAmmoBox by its exact name
        if object.Name == "SmallAmmoBox" then
            createVisuals(object)
            return
        end

        -- Condition 2: NEW - Check for shell models whose OWN name matches the pattern (e.g., "1Shell3")
        if object.Name:match("^%d+Shell%d+$") then
            createVisuals(object)
            return
        end
        
        -- Condition 3: Check for shells based on their PARENT folder's name (e.g., inside a "2Shells" folder)
        local parent = object.Parent
        if parent then
            if parent.Name:match("^%d+Shells?$") then
                createVisuals(object)
            end
        end
    end
    -----------------------------------------------------------------------------------

    -- Scanning and Listening Logic
    local function setupScannerForFolder(folder)
        if not folder then return end
        for _, descendant in ipairs(folder:GetDescendants()) do
            checkObject(descendant)
        end
        folder.DescendantAdded:Connect(checkObject)
    end

    local gameplayRoomsFolder = Workspace:WaitForChild("GameplayFolder"):WaitForChild("Rooms")
    local workspaceRoomsFolder = Workspace:WaitForChild("RoomsFolder")

    setupScannerForFolder(gameplayRoomsFolder)
    setupScannerForFolder(workspaceRoomsFolder)
    
    -- Update loop
    RunService.RenderStepped:Connect(function()
        if not Config.Enabled then
            for _, visuals in pairs(trackedAmmo) do
                visuals.Highlight.Enabled = false
                visuals.Billboard.Enabled = false
            end
            return
        end

        local playerCharacter = LocalPlayer.Character
        if not playerCharacter then return end
        local playerRoot = playerCharacter:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end
        
        for item, visuals in pairs(trackedAmmo) do
            visuals.Highlight.Enabled = true
            visuals.Billboard.Enabled = Config.ShowName or Config.ShowDistance
            
            local distance = (playerRoot.Position - visuals.Adornee.Position).Magnitude
            local textParts = {}
            if Config.ShowName then table.insert(textParts, item.Name) end
            if Config.ShowDistance then table.insert(textParts, string.format("[%dM]", distance)) end
            
            visuals.Text.Text = table.concat(textParts, " ")
        end
    end)

    -- UI Creation
    local ItemESPTab = Window:CreateTab("Item ESP", "box")
    ItemESPTab:CreateSection("Ammo ESP")

    ItemESPTab:CreateToggle({
        Name = "Enable Ammo ESP", CurrentValue = Config.Enabled, Flag = "AmmoESP_Enabled",
        Callback = function(v) Config.Enabled = v end
    })
    ItemESPTab:CreateToggle({
        Name = "Show Name", CurrentValue = Config.ShowName, Flag = "AmmoESP_ShowName",
        Callback = function(v) Config.ShowName = v end
    })
    ItemESPTab:CreateToggle({
        Name = "Show Distance", CurrentValue = Config.ShowDistance, Flag = "AmmoESP_ShowDistance",
        Callback = function(v) Config.ShowDistance = v end
    })
end

return Module