local Module = {}

function Module.CreateTab(Window, Rayfield)
    -- ===================================================================
    -- DUAL-SYSTEM NPC/MONSTER ESP MODULE
    -- Handles both Humanoid-based models and custom Part-based monsters.
    -- ===================================================================
    local Workspace = game:GetService("Workspace")
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = Workspace.CurrentCamera

    local NPC_ESP_Config = {
        Enabled = true,
        Glow_Enabled = true,
        Name_Enabled = true,
        Health_Enabled = true,
        Distance_Enabled = true,
        Spawn_Notifications = true,
        Default_Color = Color3.fromRGB(255, 80, 80),
        Glow_Transparency = 0.7,
        
        -- Your collected list of all monster names
        MonsterTypes = {
            ["Angler"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["Pinkie"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["Blitz"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["Pandemonium"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["Chainsmoker"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["Froger"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["RidgeAngler"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["RidgeBlitz"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["RidgePinkie"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["RidgeChainsmoker"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["RidgeFroger"] = { Color = Color3.fromRGB(240, 240, 240) },
            ["RidgePandemonium"] = { Color = Color3.fromRGB(240, 240, 240) }
        }
    }

    -- Redesigned state to handle different monster types and their data
    local NPC_ESP_State = { TrackedNPCs = {} }
    
    local NPC_ESP_ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    NPC_ESP_ScreenGui.Name = "NPC_ESP_Gui"
    NPC_ESP_ScreenGui.ResetOnSpawn = false

    -- Universal cleanup function
    local function cleanupMonsterVisuals(monster)
        if NPC_ESP_State.TrackedNPCs[monster] then
            local data = NPC_ESP_State.TrackedNPCs[monster]
            if data.Visuals.Glow and data.Visuals.Glow.Parent then data.Visuals.Glow.Parent:Destroy() end
            if data.Visuals.Billboard and data.Visuals.Billboard.Parent then data.Visuals.Billboard:Destroy() end
            if data.DeathConnection then data.DeathConnection:Disconnect() end
            NPC_ESP_State.TrackedNPCs[monster] = nil
        end
    end

    -- Universal function to create visuals for any monster type
    local function createVisualsForMonster(monster, adornee)
        if NPC_ESP_State.TrackedNPCs[monster] then return end
        
        local visuals = {}
        local espFolder = Instance.new("Folder", monster); espFolder.Name = "NPC_ESP_Visuals"

        visuals.Glow = Instance.new("Highlight", espFolder)
        visuals.Glow.Adornee = monster
        visuals.Glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        visuals.Glow.FillTransparency = NPC_ESP_Config.Glow_Transparency
        visuals.Glow.OutlineTransparency = 1
        visuals.Glow.Enabled = false

        visuals.Billboard = Instance.new("BillboardGui", NPC_ESP_ScreenGui)
        visuals.Billboard.Adornee = adornee
        visuals.Billboard.AlwaysOnTop = true
        visuals.Billboard.Size = UDim2.new(0, 200, 0, 80)
        visuals.Billboard.StudsOffset = Vector3.new(0, 3, 0)
        visuals.Billboard.Enabled = false
        
        local listLayout = Instance.new("UIListLayout", visuals.Billboard)
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 2)
        
        visuals.NameLabel = Instance.new("TextLabel", visuals.Billboard)
        visuals.NameLabel.Size = UDim2.new(1, 0, 0, 20)
        visuals.NameLabel.LayoutOrder = 1
        visuals.NameLabel.BackgroundTransparency = 1
        visuals.NameLabel.Font = Enum.Font.GothamBold
        visuals.NameLabel.TextSize = 18
        visuals.NameLabel.TextStrokeTransparency = 0
        visuals.NameLabel.Text = monster.Name
        
        visuals.DistanceLabel = Instance.new("TextLabel", visuals.Billboard)
        visuals.DistanceLabel.Size = UDim2.new(1, 0, 0, 15)
        visuals.DistanceLabel.LayoutOrder = 2
        visuals.DistanceLabel.BackgroundTransparency = 1
        visuals.DistanceLabel.Font = Enum.Font.Gotham
        visuals.DistanceLabel.TextSize = 14
        visuals.DistanceLabel.TextColor3 = Color3.new(1, 1, 1)

        visuals.HealthBar = Instance.new("Frame", visuals.Billboard)
        visuals.HealthBar.Size = UDim2.new(1, 0, 0, 8)
        visuals.HealthBar.LayoutOrder = 3
        visuals.HealthBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        visuals.HealthBar.BorderSizePixel = 0
        
        visuals.HealthFill = Instance.new("Frame", visuals.HealthBar)
        visuals.HealthFill.Size = UDim2.fromScale(1, 1)
        visuals.HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        visuals.HealthFill.BorderSizePixel = 0
        
        return visuals
    end
    
    -- NEW: Universal update function for all monster types
    local function updateMonsterVisuals(monster, data)
        -- Get position from the adornee we set earlier
        local adornee = data.Visuals.Billboard.Adornee
        if not (adornee and adornee.Parent) then return end

        local monsterTypeConfig = NPC_ESP_Config.MonsterTypes[monster.Name]
        local color = (monsterTypeConfig and monsterTypeConfig.Color) or NPC_ESP_Config.Default_Color
        
        data.Visuals.Glow.Enabled = NPC_ESP_Config.Glow_Enabled
        data.Visuals.Glow.FillColor = color
        data.Visuals.Glow.FillTransparency = NPC_ESP_Config.Glow_Transparency
        
        data.Visuals.Billboard.Enabled = NPC_ESP_Config.Name_Enabled or NPC_ESP_Config.Health_Enabled or NPC_ESP_Config.Distance_Enabled
        data.Visuals.NameLabel.Visible = NPC_ESP_Config.Name_Enabled
        data.Visuals.NameLabel.TextColor3 = color
        data.Visuals.HealthBar.Visible = NPC_ESP_Config.Health_Enabled

        -- Health calculation depends on the monster's type
        local health, maxHealth = 1, 1
        if data.Type == "Humanoid" then
            local humanoid = monster:FindFirstChildOfClass("Humanoid")
            if humanoid then
                health, maxHealth = humanoid.Health, humanoid.MaxHealth
            end
        elseif data.Type == "Custom" then
            health = monster:GetAttribute("Health") or 0
            maxHealth = monster:GetAttribute("MaxHealth") or 1
        end

        if maxHealth == 0 then maxHealth = 1 end -- Avoid division by zero
        local healthPercent = math.clamp(health / maxHealth, 0, 1)
        data.Visuals.HealthFill.Size = UDim2.fromScale(healthPercent, 1)
        data.Visuals.HealthFill.BackgroundColor3 = Color3.fromHSV(healthPercent * 0.33, 1, 1)
        
        local distance = (Camera.CFrame.Position - adornee.Position).Magnitude
        data.Visuals.DistanceLabel.Visible = NPC_ESP_Config.Distance_Enabled
        data.Visuals.DistanceLabel.Text = string.format("%dM", distance)
    end

    -- NEW: Main detection function that checks for any monster type
    local function checkAndTrackObject(object)
        if NPC_ESP_State.TrackedNPCs[object] then return end -- Already tracking

        -- TYPE 1: Humanoid-based Monster
        if object:IsA("Model") and object:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(object) then
            local humanoid = object:FindFirstChildOfClass("Humanoid")
            local hrp = object:FindFirstChild("HumanoidRootPart")
            if not hrp then return end -- Needs a root part to attach visuals to

            local visuals = createVisualsForMonster(object, hrp)
            local deathConnection = humanoid.Died:Connect(function() cleanupMonsterVisuals(object) end)
            NPC_ESP_State.TrackedNPCs[object] = { Visuals = visuals, Type = "Humanoid", DeathConnection = deathConnection }
            
            if NPC_ESP_Config.Spawn_Notifications then
                Rayfield:Notify({ Title = "Monster Spawned", Content = string.format("A(n) %s has appeared.", object.Name), Image = "info", Duration = 5 })
            end
        
        -- TYPE 2: Custom Part-based Monster
        elseif object:IsA("BasePart") and NPC_ESP_Config.MonsterTypes[object.Name] then
             -- Prevent tracking a part of an already tracked Humanoid monster
            if object.Parent and NPC_ESP_State.TrackedNPCs[object.Parent] then return end

            local visuals = createVisualsForMonster(object, object)
            -- For custom parts, we detect death by listening to attribute changes or ancestry changes
            local deathConnection = object.AncestryChanged:Connect(function(_, parent)
                if not parent then cleanupMonsterVisuals(object) end
            end)
            
            NPC_ESP_State.TrackedNPCs[object] = { Visuals = visuals, Type = "Custom", DeathConnection = deathConnection }

            if NPC_ESP_Config.Spawn_Notifications then
                Rayfield:Notify({ Title = "Monster Spawned", Content = string.format("A(n) %s has appeared.", object.Name), Image = "info", Duration = 5 })
            end
        end
    end

    Workspace.ChildAdded:Connect(checkAndTrackObject)
    for _, child in ipairs(Workspace:GetChildren()) do
        checkAndTrackObject(child)
    end

    RunService.RenderStepped:Connect(function()
        if not NPC_ESP_Config.Enabled then
            for _, data in pairs(NPC_ESP_State.TrackedNPCs) do
                if data.Visuals.Glow.Enabled then data.Visuals.Glow.Enabled = false end
                if data.Visuals.Billboard.Enabled then data.Visuals.Billboard.Enabled = false end
            end
            return
        end

        Camera = workspace.CurrentCamera
        for monster, data in pairs(NPC_ESP_State.TrackedNPCs) do
            -- Cleanup if monster is destroyed but not caught by death event
            if not monster or not monster.Parent then
                cleanupMonsterVisuals(monster)
            else
                pcall(updateMonsterVisuals, monster, data)
            end
        end
    end)
    
    -- UI Section (Unchanged)
    local NPC_ESPTab = Window:CreateTab("NPC ESP", "ghost")
    NPC_ESPTab:CreateToggle({ Name = "Enable NPC ESP", CurrentValue = NPC_ESP_Config.Enabled, Flag = "NPC_ESP_Enabled", Callback = function(v) NPC_ESP_Config.Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Enable Glow (Chams)", CurrentValue = NPC_ESP_Config.Glow_Enabled, Flag = "NPC_ESP_Glow", Callback = function(v) NPC_ESP_Config.Glow_Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Show Name", CurrentValue = NPC_ESP_Config.Name_Enabled, Flag = "NPC_ESP_Name", Callback = function(v) NPC_ESP_Config.Name_Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Show Health", CurrentValue = NPC_ESP_Config.Health_Enabled, Flag = "NPC_ESP_Health", Callback = function(v) NPC_ESP_Config.Health_Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Show Distance", CurrentValue = NPC_ESP_Config.Distance_Enabled, Flag = "NPC_ESP_Distance", Callback = function(v) NPC_ESP_Config.Distance_Enabled = v end })
    NPC_ESPTab:CreateToggle({ Name = "Spawn Notifications", CurrentValue = NPC_ESP_Config.Spawn_Notifications, Flag = "NPC_ESP_Notifications", Callback = function(v) NPC_ESP_Config.Spawn_Notifications = v end })
    NPC_ESPTab:CreateSlider({ Name = "Glow Transparency", Range = {0, 1}, Increment = 0.05, Suffix = "%", CurrentValue = NPC_ESP_Config.Glow_Transparency, Flag = "NPC_ESP_GlowTrans", Callback = function(v) NPC_ESP_Config.Glow_Transparency = v end })
end

return Module