local Module = {}

function Module.CreateTab(Window, Rayfield)
    -- ===================================================================
    -- NPC/MONSTER ESP MODULE
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
        
        MonsterTypes = {
            -- Extended Monster List
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

    local NPC_ESP_State = { TrackedNPCs = {} }
    
    local NPC_ESP_ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    NPC_ESP_ScreenGui.Name = "NPC_ESP_Gui"
    NPC_ESP_ScreenGui.ResetOnSpawn = false

    local function createVisualsForMonster(monster)
        if NPC_ESP_State.TrackedNPCs[monster] then return end
        
        local visuals = {}
        local espFolder = Instance.new("Folder", monster); espFolder.Name = "NPC_ESP_Visuals"

        visuals.Glow = Instance.new("Highlight", espFolder); visuals.Glow.Name = "NPC_ESP_Glow"; visuals.Glow.Adornee = monster; visuals.Glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        visuals.Glow.FillTransparency = NPC_ESP_Config.Glow_Transparency; visuals.Glow.OutlineTransparency = 1; visuals.Glow.Enabled = false

        visuals.Billboard = Instance.new("BillboardGui", NPC_ESP_ScreenGui); visuals.Billboard.Name = "NPC_ESP_Billboard"; visuals.Billboard.AlwaysOnTop = true; visuals.Billboard.Size = UDim2.new(0, 200, 0, 80)
        visuals.Billboard.StudsOffset = Vector3.new(0, 3, 0); visuals.Billboard.Enabled = false
        
        local listLayout = Instance.new("UIListLayout", visuals.Billboard); listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0, 2)
        
        visuals.NameLabel = Instance.new("TextLabel", visuals.Billboard); visuals.NameLabel.Name = "NameLabel"; visuals.NameLabel.Size = UDim2.new(1, 0, 0, 20); visuals.NameLabel.LayoutOrder = 1
        visuals.NameLabel.BackgroundTransparency = 1; visuals.NameLabel.Font = Enum.Font.GothamBold; visuals.NameLabel.TextSize = 18; visuals.NameLabel.TextStrokeTransparency = 0; visuals.NameLabel.Text = monster.Name
        
        visuals.DistanceLabel = Instance.new("TextLabel", visuals.Billboard); visuals.DistanceLabel.Name = "DistanceLabel"; visuals.DistanceLabel.Size = UDim2.new(1, 0, 0, 15); visuals.DistanceLabel.LayoutOrder = 2
        visuals.DistanceLabel.BackgroundTransparency = 1; visuals.DistanceLabel.Font = Enum.Font.Gotham; visuals.DistanceLabel.TextSize = 14; visuals.DistanceLabel.TextColor3 = Color3.new(1, 1, 1)

        visuals.HealthBar = Instance.new("Frame", visuals.Billboard); visuals.HealthBar.Name = "HealthBar"; visuals.HealthBar.Size = UDim2.new(1, 0, 0, 8); visuals.HealthBar.LayoutOrder = 3
        visuals.HealthBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20); visuals.HealthBar.BorderSizePixel = 0
        
        visuals.HealthFill = Instance.new("Frame", visuals.HealthBar); visuals.HealthFill.Name = "HealthFill"; visuals.HealthFill.Size = UDim2.fromScale(1, 1); visuals.HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0); visuals.HealthFill.BorderSizePixel = 0
        
        NPC_ESP_State.TrackedNPCs[monster] = visuals
    end

    local function updateMonsterVisuals(monster, data)
        local hrp = monster:FindFirstChild("HumanoidRootPart"); local humanoid = monster:FindFirstChildOfClass("Humanoid")
        if not (hrp and humanoid and humanoid.Health > 0) then if data.Billboard.Enabled then data.Billboard.Enabled = false; data.Glow.Enabled = false end; return end
        
        local monsterTypeConfig = NPC_ESP_Config.MonsterTypes[monster.Name]
        local color = (monsterTypeConfig and monsterTypeConfig.Color) or NPC_ESP_Config.Default_Color
        
        data.Glow.Enabled = NPC_ESP_Config.Glow_Enabled; data.Glow.FillColor = color; data.Glow.FillTransparency = NPC_ESP_Config.Glow_Transparency
        
        data.Billboard.Enabled = NPC_ESP_Config.Name_Enabled or NPC_ESP_Config.Health_Enabled or NPC_ESP_Config.Distance_Enabled; data.Billboard.Adornee = hrp
        data.NameLabel.Visible = NPC_ESP_Config.Name_Enabled; data.NameLabel.TextColor3 = color
        data.HealthBar.Visible = NPC_ESP_Config.Health_Enabled
        
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        data.HealthFill.Size = UDim2.fromScale(healthPercent, 1); data.HealthFill.BackgroundColor3 = Color3.fromHSV(healthPercent * 0.33, 1, 1)
        
        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
        data.DistanceLabel.Visible = NPC_ESP_Config.Distance_Enabled; data.DistanceLabel.Text = string.format("%dM", distance)
    end

    local function cleanupMonsterVisuals(monster)
        if NPC_ESP_State.TrackedNPCs[monster] then
            local data = NPC_ESP_State.TrackedNPCs[monster]; if data.Glow.Parent then data.Glow.Parent:Destroy() end; data.Billboard:Destroy(); NPC_ESP_State.TrackedNPCs[monster] = nil
        end
    end

    local function checkAndTrackMonster(model)
        if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(model) then
            createVisualsForMonster(model)
            
            if NPC_ESP_Config.Spawn_Notifications then
                Rayfield:Notify({
                    Title = "Monster Spawned",
                    Content = string.format("A(n) %s has appeared.", model.Name),
                    Image = "info",
                    Duration = 5
                })
            end

            local humanoid = model:FindFirstChildOfClass("Humanoid")
            humanoid.Died:Connect(function()
                cleanupMonsterVisuals(model)
            end)
        end
    end

    Workspace.ChildAdded:Connect(checkAndTrackMonster)
    for _, child in ipairs(Workspace:GetChildren()) do
        checkAndTrackMonster(child)
    end

    RunService.RenderStepped:Connect(function()
        if not NPC_ESP_Config.Enabled then for _, d in pairs(NPC_ESP_State.TrackedNPCs) do if d.Glow.Enabled then d.Glow.Enabled=false end;if d.Billboard.Enabled then d.Billboard.Enabled=false end end; return end
        Camera = workspace.CurrentCamera; for m, d in pairs(NPC_ESP_State.TrackedNPCs) do pcall(updateMonsterVisuals, m, d) end
    end)
    
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