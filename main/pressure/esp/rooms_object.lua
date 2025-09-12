local Module = {}

function Module.CreateTab(Window)
    -- Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    -- Config table
    local Config = {
        Enabled = true,
        Doors_Enabled = true,
        Lockers_Enabled = true,
        ShowName = true,
        ShowDistance = true,
        DoorColor = Color3.fromRGB(0, 255, 127),
        LockerColor = Color3.fromRGB(255, 165, 0)
    }

    local trackedObjects = {}
    local screenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    screenGui.Name = "RoomObjectESP_Gui"
    screenGui.ResetOnSpawn = false

    -- [REMOVED] Unused variables from the old "Folder Watcher" method.

    -- Function to remove visuals when an object is gone
    local function cleanupVisuals(object)
        if trackedObjects[object] then
            if trackedObjects[object].Highlight then
                trackedObjects[object].Highlight:Destroy()
            end
            if trackedObjects[object].Billboard then
                trackedObjects[object].Billboard:Destroy()
            end
            trackedObjects[object] = nil
        end
    end

    -- Function to create visuals for a new object
    local function createVisuals(object, objectType)
        if trackedObjects[object] then
            return
        end

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

        trackedObjects[object] = {
            Highlight = highlight,
            Billboard = billboard,
            Text = textLabel,
            Type = objectType
        }
    end

    ---[[ UPDATED: Function to scan for doors and lockers ]]---
    local function scanForObjects(parent)
        for _, descendant in ipairs(parent:GetDescendants()) do
            -- UPDATED: This now finds any part named "Door", making it work for NormalDoor, BigDoor, etc.
            if descendant.Name == "Door" and descendant:IsA("BasePart") then
                createVisuals(descendant, "Door")
            -- Locker logic is correct and unchanged
            elseif descendant.Name == "Locker" and descendant:IsA("Model") then
                local primaryPart = descendant.PrimaryPart or descendant:FindFirstChildWhichIsA("BasePart")
                if primaryPart then
                    createVisuals(primaryPart, "Locker")
                end
            end
        end
    end

    -- Path to the Rooms folder
    local roomsFolder = Workspace:WaitForChild("GameplayFolder"):WaitForChild("Rooms")

    -- Initial scan of existing rooms (correct)
    for _, room in ipairs(roomsFolder:GetChildren()) do
        scanForObjects(room)
    end

    ---[[ UPDATED: Made the listener more efficient ]]---
    -- Now it only scans the new room, not all of them every time.
    roomsFolder.ChildAdded:Connect(function(newRoom)
        task.wait(1) -- Wait for room to fully load
        scanForObjects(newRoom)
    end)

    -- [REMOVED] The redundant rescanAllRooms() function and its call.

    -- Update loop
    RunService.RenderStepped:Connect(function()
        local camera = Workspace.CurrentCamera

        -- [IMPROVED] Get a fresh reference to the rooms folder to make cleanup more reliable
        local currentRoomsFolder = Workspace:FindFirstChild("GameplayFolder") and
                                       Workspace.GameplayFolder:FindFirstChild("Rooms")

        if not Config.Enabled or not currentRoomsFolder then
            for item, visuals in pairs(trackedObjects) do
                if visuals.Highlight then
                    visuals.Highlight.Enabled = false
                end
                if visuals.Billboard then
                    visuals.Billboard.Enabled = false
                end
            end
            return
        end

        local playerRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not playerRoot then
            return
        end

        for object, visuals in pairs(trackedObjects) do
            if not object.Parent or not object:IsDescendantOf(currentRoomsFolder) then
                cleanupVisuals(object)
            else
                -- (Visual update logic)
                local shouldBeVisible = (visuals.Type == "Door" and Config.Doors_Enabled) or
                                            (visuals.Type == "Locker" and Config.Lockers_Enabled)
                visuals.Highlight.Enabled = shouldBeVisible
                visuals.Billboard.Enabled = shouldBeVisible and (Config.ShowName or Config.ShowDistance)

                if visuals.Billboard.Enabled then
                    local distance = (playerRoot.Position - object.Position).Magnitude
                    local textParts = {}
                    if Config.ShowName then
                        table.insert(textParts, visuals.Type)
                    end
                    if Config.ShowDistance then
                        table.insert(textParts, string.format("[%dM]", distance))
                    end
                    visuals.Text.Text = table.concat(textParts, " ")
                end
            end
        end
    end)

    -- UI Creation
    local ItemESPTab = Window:CreateTab("Item ESP", "box")
    ItemESPTab:CreateSection("Room Object ESP")

    ItemESPTab:CreateToggle({
        Name = "Enable Room Object ESP",
        CurrentValue = Config.Enabled,
        Flag = "RoomObjectESP_Enabled",
        Callback = function(v)
            Config.Enabled = v
        end
    })
    ItemESPTab:CreateToggle({
        Name = "Show Doors",
        CurrentValue = Config.Doors_Enabled,
        Flag = "RoomObjectESP_Doors",
        Callback = function(v)
            Config.Doors_Enabled = v
        end
    })
    ItemESPTab:CreateToggle({
        Name = "Show Lockers",
        CurrentValue = Config.Lockers_Enabled,
        Flag = "RoomObjectESP_Lockers",
        Callback = function(v)
            Config.Lockers_Enabled = v
        end
    })
    ItemESPTab:CreateToggle({
        Name = "Show Name",
        CurrentValue = Config.ShowName,
        Flag = "RoomObjectESP_ShowName",
        Callback = function(v)
            Config.ShowName = v
        end
    })
    ItemESPTab:CreateToggle({
        Name = "Show Distance",
        CurrentValue = Config.ShowDistance,
        Flag = "RoomObjectESP_ShowDistance",
        Callback = function(v)
            Config.ShowDistance = v
        end
    })
end

return Module
