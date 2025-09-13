local Module = {}

function Module.CreateTab(Window)
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local ObjectESP_Config = {
        Glow_Enabled = true,
        Name_Enabled = true,
        Distance_Enabled = true,
        Glow_Transparency = 0.6,
        Default_Color = Color3.fromRGB(0, 255, 255)
    }
    local ObjectESP_State = {
        TrackedItems = {},
        DiscoveredObjects = {}
    }

    local ObjectESP_ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    ObjectESP_ScreenGui.Name = "ObjectESP_Gui"
    ObjectESP_ScreenGui.ResetOnSpawn = false

    local function createVisualsForItem(item, itemName)
        if ObjectESP_State.TrackedItems[item] or not item:IsA("PVInstance") then
            return
        end
        local primaryPart = item:IsA("Model") and (item.PrimaryPart or item:FindFirstChildWhichIsA("BasePart")) or item
        if not primaryPart then
            return
        end

        local visuals = {
            PrimaryPart = primaryPart
        }

        visuals.Glow = Instance.new("Highlight", item)
        visuals.Glow.Name = "ItemESP_Glow";
        visuals.Glow.Adornee = item;
        visuals.Glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        visuals.Glow.FillTransparency = ObjectESP_Config.Glow_Transparency;
        visuals.Glow.OutlineTransparency = 1
        visuals.Glow.FillColor = ObjectESP_Config.Default_Color;
        visuals.Glow.Enabled = ObjectESP_Config.Glow_Enabled

        visuals.Billboard = Instance.new("BillboardGui", ObjectESP_ScreenGui)
        visuals.Billboard.Name = "ItemESP_Billboard";
        visuals.Billboard.AlwaysOnTop = true;
        visuals.Billboard.Size = UDim2.new(0, 200, 0, 50)
        visuals.Billboard.StudsOffset = Vector3.new(0, 2, 0);
        visuals.Billboard.Enabled = false

        local listLayout = Instance.new("UIListLayout", visuals.Billboard)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
        listLayout.Padding = UDim.new(0, 2)

        visuals.NameLabel = Instance.new("TextLabel", visuals.Billboard)
        visuals.NameLabel.Name = "NameLabel";
        visuals.NameLabel.Size = UDim2.new(1, 0, 0, 20);
        visuals.NameLabel.BackgroundTransparency = 1
        visuals.NameLabel.Font = Enum.Font.GothamBold;
        visuals.NameLabel.TextSize = 16;
        visuals.NameLabel.TextColor3 = ObjectESP_Config.Default_Color
        visuals.NameLabel.Text = itemName or item.Name

        visuals.DistanceLabel = Instance.new("TextLabel", visuals.Billboard)
        visuals.DistanceLabel.Name = "DistanceLabel";
        visuals.DistanceLabel.Size = UDim2.new(1, 0, 0, 15);
        visuals.DistanceLabel.BackgroundTransparency = 1
        visuals.DistanceLabel.Font = Enum.Font.Gotham;
        visuals.DistanceLabel.TextSize = 14;
        visuals.DistanceLabel.TextColor3 = Color3.new(1, 1, 1)

        ObjectESP_State.TrackedItems[item] = visuals
    end

    local function cleanupItemVisuals(item)
        if ObjectESP_State.TrackedItems[item] then
            if ObjectESP_State.TrackedItems[item].Glow then
                ObjectESP_State.TrackedItems[item].Glow:Destroy()
            end
            if ObjectESP_State.TrackedItems[item].Billboard then
                ObjectESP_State.TrackedItems[item].Billboard:Destroy()
            end
            ObjectESP_State.TrackedItems[item] = nil
        end
    end

    local function updateItemVisuals(item, data)
        local lpRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not lpRoot then
            if data.Billboard and data.Billboard.Enabled then
                data.Billboard.Enabled = false
            end
            return
        end

        data.Glow.Enabled = ObjectESP_Config.Glow_Enabled
        data.Glow.FillTransparency = ObjectESP_Config.Glow_Transparency

        if data.Billboard then
            data.Billboard.Enabled = ObjectESP_Config.Name_Enabled or ObjectESP_Config.Distance_Enabled
            data.Billboard.Adornee = data.PrimaryPart

            data.NameLabel.Visible = ObjectESP_Config.Name_Enabled

            local distance = (lpRoot.Position - data.PrimaryPart.Position).Magnitude
            data.DistanceLabel.Visible = ObjectESP_Config.Distance_Enabled
            data.DistanceLabel.Text = string.format("%dM", distance)
        end
    end

    RunService.RenderStepped:Connect(function()
        Camera = Workspace.CurrentCamera
        for item, data in pairs(ObjectESP_State.TrackedItems) do
            if not item or not item.Parent then
                cleanupItemVisuals(item)
            else
                pcall(updateItemVisuals, item, data)
            end
        end
    end)

    local ObjectESPTab = Window:CreateTab("Object ESP", "box")
    local objectListSection = nil
    local lastSearchText = ""

    local function refreshObjectListToggles()
        if objectListSection then
            objectListSection:Set('Scanned Object')
        else
            objectListSection = ObjectESPTab:CreateSection("Scanned Objects")
        end

        local sortedNames = {}
        for id, data in pairs(ObjectESP_State.DiscoveredObjects) do
            if lastSearchText == "" or (data.Name and data.Name:lower():find(lastSearchText)) then
                table.insert(sortedNames, {
                    name = data.Name,
                    id = id
                })
            end
        end

        for _, data in ipairs(sortedNames) do
            local assetId = data.id
            local name = data.name .. " (" .. #ObjectESP_State.DiscoveredObjects[assetId].Instances .. ")"
            local discoveryData = ObjectESP_State.DiscoveredObjects[assetId]

            ObjectESPTab:CreateToggle({
                Name = name,
                CurrentValue = discoveryData.IsEnabled,
                Flag = "ObjectESP_" .. assetId,
                Callback = function(Value)
                    discoveryData.IsEnabled = Value
                    for _, instance in ipairs(discoveryData.Instances) do
                        if Value and instance and instance.Parent then
                            createVisualsForItem(instance, discoveryData.Name)
                        else
                            cleanupItemVisuals(instance)
                        end
                    end
                end
            })
        end
    end

    ObjectESPTab:CreateButton({
        Name = "Scan for Objects",
        Callback = function()
            task.spawn(function()
                local previouslyEnabled = {}
                for id, data in pairs(ObjectESP_State.DiscoveredObjects) do
                    if data.IsEnabled then
                        previouslyEnabled[id] = true
                    end
                end

                ObjectESP_State.DiscoveredObjects = {}
                local charactersToIgnore = {}
                for _, player in ipairs(Players:GetPlayers()) do
                    if player.Character then
                        charactersToIgnore[player.Character] = true
                    end
                end

                local descendants = Workspace:GetDescendants()
                for i = 1, #descendants do
                    if i % 250 == 0 then
                        task.wait()
                    end
                    local descendant = descendants[i]
                    if descendant:IsA("MeshPart") and descendant.MeshId ~= "" then
                        local assetId = tonumber(string.match(descendant.MeshId, "%d+"))
                        if assetId then
                            local itemToTrack = descendant.Parent and descendant.Parent:IsA("Model") and
                                                    descendant.Parent.Name ~= "Workspace" and descendant.Parent or
                                                    descendant
                            if not charactersToIgnore[itemToTrack] then
                                if not ObjectESP_State.DiscoveredObjects[assetId] then
                                    ObjectESP_State.DiscoveredObjects[assetId] = {
                                        Name = itemToTrack.Name,
                                        IsEnabled = false,
                                        Instances = {}
                                    }
                                end
                                if not table.find(ObjectESP_State.DiscoveredObjects[assetId].Instances, itemToTrack) then
                                    table.insert(ObjectESP_State.DiscoveredObjects[assetId].Instances, itemToTrack)
                                end
                            end
                        end
                    end
                end

                for id, data in pairs(ObjectESP_State.DiscoveredObjects) do
                    if previouslyEnabled[id] then
                        data.IsEnabled = true
                        for _, instance in ipairs(data.Instances) do
                            createVisualsForItem(instance, data.Name)
                        end
                    end
                end

                refreshObjectListToggles()
            end)
        end
    })

    ObjectESPTab:CreateInput({
        Name = "Search",
        PlaceholderText = "Search for an object...",
        Callback = function(Value)
            lastSearchText = Value:lower()
            refreshObjectListToggles()
        end
    })

    ObjectESPTab:CreateSection("Settings")
    ObjectESPTab:CreateToggle({
        Name = "Enable Object Glow",
        CurrentValue = ObjectESP_Config.Glow_Enabled,
        Flag = "ObjGlow",
        Callback = function(v)
            ObjectESP_Config.Glow_Enabled = v
        end
    })
    ObjectESPTab:CreateToggle({
        Name = "Show Name",
        CurrentValue = ObjectESP_Config.Name_Enabled,
        Flag = "ObjName",
        Callback = function(v)
            ObjectESP_Config.Name_Enabled = v
        end
    })
    ObjectESPTab:CreateToggle({
        Name = "Show Distance",
        CurrentValue = ObjectESP_Config.Distance_Enabled,
        Flag = "ObjDist",
        Callback = function(v)
            ObjectESP_Config.Distance_Enabled = v
        end
    })
    ObjectESPTab:CreateSlider({
        Name = "Glow Transparency",
        Range = {0, 1},
        Increment = 0.05,
        Suffix = "%",
        CurrentValue = ObjectESP_Config.Glow_Transparency,
        Flag = "ObjGlowTrans",
        Callback = function(v)
            ObjectESP_Config.Glow_Transparency = v
        end
    })
end

return Module