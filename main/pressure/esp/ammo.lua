-- File: ammo.lua (Updated with Room Listener)
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
        GlowColor = Color3.fromRGB(0, 255, 100) -- A green color for ammo
    }

    local trackedAmmo = {}
    local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = "AmmoESP_Gui"
    screenGui.ResetOnSpawn = false

    -- Function to remove visuals when an item is gone
    local function cleanupVisuals(item)
        if trackedAmmo[item] then
            if trackedAmmo[item].Highlight then trackedAmmo[item].Highlight:Destroy() end
            if trackedAmmo[item].Billboard then trackedAmmo[item].Billboard:Destroy() end
            trackedAmmo[item] = nil
        end
    end

    -- Function to create visuals for a new ammo item
    local function createVisuals(model)
        if trackedAmmo[model] then return end

        -- Prioritize 'ProxyPart' as seen in your structure, otherwise find any BasePart.
        local adorneePart = model:FindFirstChild("ProxyPart") or model:FindFirstChildWhichIsA("BasePart")
        if not adorneePart then return end -- Can't create ESP without a part to attach to

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
        
        -- Handle item being destroyed
        model.AncestryChanged:Connect(function(_, parent)
            if not parent then
                cleanupVisuals(model)
            end
        end)
    end

    -- Function to find Ammo items based on your game's structure
    local function checkObject(object)
        if object:IsA("Model") then
            -- Check for 'SmallAmmoBox' or models containing "Shells" like '2Shells3'
            if object.Name == "SmallAmmoBox" or object.Name:find("Shells") then
                createVisuals(object)
            end
        end
    end

    -----------------------------------------------------------------------------------
    -- ## Scanning and Listening Logic (UPDATED SECTION) ## --
    -----------------------------------------------------------------------------------
    local roomsFolder = Workspace:WaitForChild("GameplayFolder"):WaitForChild("Rooms")

    -- This function scans a room model and then listens for new items spawning within it
    local function scanAndListenToRoom(room)
        if not (room:IsA("Model") or room:IsA("Folder")) then return end

        -- 1. Scan the entire room for any items that already exist inside
        for _, descendant in ipairs(room:GetDescendants()) do
            checkObject(descendant)
        end
        
        -- 2. Listen for any NEW items that get added to this specific room later
        room.DescendantAdded:Connect(checkObject)
    end

    -- Scan all rooms that already exist when the script first runs
    for _, existingRoom in ipairs(roomsFolder:GetChildren()) do
        scanAndListenToRoom(existingRoom)
    end
    
    -- Listen for completely NEW rooms being added to the RoomsFolder
    roomsFolder.ChildAdded:Connect(scanAndListenToRoom)
    -----------------------------------------------------------------------------------
    
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
    local ItemESPTab = Window:CreateTab("Ammo ESP", "box")
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