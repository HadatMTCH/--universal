local Module = {}

function Module.CreateTab(Window)
    -- Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer

    -- Configuration for the ESP
    local Config = {
        Enabled = true,
        Doors_Enabled = true,
        Lockers_Enabled = true,
        ShowName = true,
        ShowDistance = true,
        DoorColor = Color3.fromRGB(0, 255, 127),   -- Spring Green
        LockerColor = Color3.fromRGB(255, 165, 0) -- Orange
    }

    local trackedObjects = {}
    local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = "RoomObjectESP_Gui"
    screenGui.ResetOnSpawn = false

    ---[[ NEW: Table to track which rooms have already been scanned ]]---
    local scannedRooms = {}

    -- Function to remove visuals when an object is gone
    local function cleanupVisuals(object)
        if trackedObjects[object] then
            trackedObjects[object].Highlight:Destroy()
            trackedObjects[object].Billboard:Destroy()
            trackedObjects[object] = nil
        end
    end

    -- Function to create visuals for a new object
    local function createVisuals(object, objectType)
        if trackedObjects[object] then return end

        local color = (objectType == "Door" and Config.DoorColor) or Config.LockerColor

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
        
        trackedObjects[object] = { Highlight = highlight, Billboard = billboard, Text = textLabel, Type = objectType }
    end

    -- Function to scan a parent (like a new room) for doors and lockers
    local function scanForObjects(parent)
        for _, descendant in ipairs(parent:GetDescendants()) do
            if descendant.Name == "Door" and descendant:IsA("BasePart") then
                createVisuals(descendant, "Door")
            elseif descendant.Name == "Locker" and descendant:IsA("Model") then
                local primaryPart = descendant.PrimaryPart or descendant:FindFirstChildWhichIsA("BasePart")
                if primaryPart then
                    createVisuals(primaryPart, "Locker")
                end
            end
        end
    end

    ---[[ NEW: Function to perform a full re-scan of all rooms ]]---
    local function rescanAllRooms()
        -- First, clear all existing visuals
        for object, _ in pairs(trackedObjects) do
            cleanupVisuals(object)
        end
        
        -- Get the current rooms folder and scan every room inside it
        local roomsFolder = Workspace:FindFirstChild("GameplayFolder") and Workspace.GameplayFolder:FindFirstChild("Rooms")
        if roomsFolder then
            for _, room in ipairs(roomsFolder:GetChildren()) do
                scanForObjects(room)
            end
        end
    end

    -- Perform an initial scan when the script starts
    task.wait(1) -- Wait a moment for the game to load
    rescanAllRooms()

    ---[[ NEW: Connect to the game's ZoneChange event (with debugging) ]]---
    print("Attempting to find remote events...")
    local eventsFolder = ReplicatedStorage:WaitForChild("Events", 10) -- Wait up to 10 seconds
    
    if eventsFolder then
        print("Found 'Events' folder. Looking for 'ZoneChange'...")
        local zoneChangeEvent = eventsFolder:FindFirstChild("ZoneChange")
        
        if zoneChangeEvent then
            print("SUCCESS: Found 'ZoneChange' event. Connecting listener.")
            zoneChangeEvent.OnClientEvent:Connect(function()
                print("LISTENER FIRED: 'ZoneChange' event was received!")
                task.wait(0.5)
                rescanAllRooms()
            end)
        else
            warn("ERROR: Could not find 'ZoneChange' inside ReplicatedStorage.Events.")
        end
    else
        warn("ERROR: Could not find 'Events' folder in ReplicatedStorage.")
    end

    -- Update loop
    RunService.RenderStepped:Connect(function()
        local camera = Workspace.CurrentCamera
        local roomsFolder = Workspace:FindFirstChild("GameplayFolder") and Workspace.GameplayFolder:FindFirstChild("Rooms")
        
        ---[[ REMOVED: The old room scanning logic is no longer needed here ]]---
        -- The ZoneChange event now handles this much more efficiently.

        if not Config.Enabled then
            for item, visuals in pairs(trackedObjects) do
                visuals.Highlight.Enabled = false
                visuals.Billboard.Enabled = false
            end
            return
        end

        local playerRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then return end

        for object, visuals in pairs(trackedObjects) do
            -- The cleanup logic remains to handle objects being removed individually
            if not object.Parent or not roomsFolder or not object:IsDescendantOf(roomsFolder) then
                cleanupVisuals(object)
            else
                -- (The rest of your visual update logic is the same)
                local shouldBeVisible = (visuals.Type == "Door" and Config.Doors_Enabled) or (visuals.Type == "Locker" and Config.Lockers_Enabled)
                visuals.Highlight.Enabled = shouldBeVisible
                visuals.Billboard.Enabled = shouldBeVisible and (Config.ShowName or Config.ShowDistance)
                
                if visuals.Billboard.Enabled then
                    local distance = (playerRoot.Position - object.Position).Magnitude
                    local textParts = {}
                    if Config.ShowName then table.insert(textParts, visuals.Type) end
                    if Config.ShowDistance then table.insert(textParts, string.format("[%dM]", distance)) end
                    visuals.Text.Text = table.concat(textParts, " ")
                end
            end
        end
    end)
    
    -- UI Creation
    local ItemESPTab = Window:CreateTab("Item ESP", "box")
    ItemESPTab:CreateSection("Room Object ESP")

    ItemESPTab:CreateToggle({
        Name = "Enable Room Object ESP", CurrentValue = Config.Enabled, Flag = "RoomObjectESP_Enabled",
        Callback = function(v) Config.Enabled = v end
    })
    ItemESPTab:CreateToggle({
        Name = "Show Doors", CurrentValue = Config.Doors_Enabled, Flag = "RoomObjectESP_Doors",
        Callback = function(v) Config.Doors_Enabled = v end
    })
    ItemESPTab:CreateToggle({
        Name = "Show Lockers", CurrentValue = Config.Lockers_Enabled, Flag = "RoomObjectESP_Lockers",
        Callback = function(v) Config.Lockers_Enabled = v end
    })
    ItemESPTab:CreateToggle({
        Name = "Show Name", CurrentValue = Config.ShowName, Flag = "RoomObjectESP_ShowName",
        Callback = function(v) Config.ShowName = v end
    })
    ItemESPTab:CreateToggle({
        Name = "Show Distance", CurrentValue = Config.ShowDistance, Flag = "RoomObjectESP_ShowDistance",
        Callback = function(v) Config.ShowDistance = v end
    })
end

return Module