local Module = {}

function Module.CreateTab(Window)
    -- ===================================================================
    -- INTEGRATED PLAYER ESP MODULE
    -- ===================================================================
    local ESP_Config = {
        ESP_Enabled = true,
        Glow_Enabled = true,
        Names_Enabled = true,
        Health_Enabled = true,
        Distance_Enabled = true,
        Show_Enemies = true,
        Show_Teammates = true,
        Default_Color = Color3.fromRGB(255, 170, 0),
        Glow_Transparency = 0.7
    }
    local Players, RunService = game:GetService("Players"), game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer
    local Camera = workspace.CurrentCamera
    local PlayerESP_ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
    PlayerESP_ScreenGui.Name = "PlayerESP_Gui";
    PlayerESP_ScreenGui.ResetOnSpawn = false;
    PlayerESP_ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local ESP_State = {
        TrackedCharacters = {}
    }

    local function createVisualsForCharacter(character)
        if ESP_State.TrackedCharacters[character] then
            return
        end
        local player = Players:GetPlayerFromCharacter(character)
        if not player then
            return
        end
        local visuals = {
            Player = player
        }
        local espFolder = Instance.new("Folder", character);
        espFolder.Name = "ESP_Visuals"
        visuals.Glow = Instance.new("Highlight", espFolder);
        visuals.Glow.Name = "ESP_Glow";
        visuals.Glow.Adornee = character;
        visuals.Glow.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        visuals.Glow.FillTransparency = ESP_Config.Glow_Transparency;
        visuals.Glow.OutlineTransparency = 1;
        visuals.Glow.Enabled = false
        visuals.Billboard = Instance.new("BillboardGui", PlayerESP_ScreenGui);
        visuals.Billboard.Name = "ESP_Billboard";
        visuals.Billboard.AlwaysOnTop = true;
        visuals.Billboard.Size = UDim2.new(0, 200, 0, 80)
        visuals.Billboard.StudsOffset = Vector3.new(0, 3, 0);
        visuals.Billboard.Enabled = false
        local listLayout = Instance.new("UIListLayout", visuals.Billboard);
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center;
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder;
        listLayout.Padding = UDim.new(0, 2)
        visuals.NameLabel = Instance.new("TextLabel", visuals.Billboard);
        visuals.NameLabel.Name = "NameLabel";
        visuals.NameLabel.Size = UDim2.new(1, 0, 0, 20);
        visuals.NameLabel.LayoutOrder = 1
        visuals.NameLabel.BackgroundTransparency = 1;
        visuals.NameLabel.Font = Enum.Font.GothamBold;
        visuals.NameLabel.TextSize = 18;
        visuals.NameLabel.TextStrokeTransparency = 0;
        visuals.NameLabel.Text = player.Name
        visuals.DistanceLabel = Instance.new("TextLabel", visuals.Billboard);
        visuals.DistanceLabel.Name = "DistanceLabel";
        visuals.DistanceLabel.Size = UDim2.new(1, 0, 0, 15);
        visuals.DistanceLabel.LayoutOrder = 2
        visuals.DistanceLabel.BackgroundTransparency = 1;
        visuals.DistanceLabel.Font = Enum.Font.Gotham;
        visuals.DistanceLabel.TextSize = 14;
        visuals.DistanceLabel.TextColor3 = Color3.new(1, 1, 1)
        visuals.HealthBar = Instance.new("Frame", visuals.Billboard);
        visuals.HealthBar.Name = "HealthBar";
        visuals.HealthBar.Size = UDim2.new(1, 0, 0, 8);
        visuals.HealthBar.LayoutOrder = 3
        visuals.HealthBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20);
        visuals.HealthBar.BorderSizePixel = 0
        visuals.HealthFill = Instance.new("Frame", visuals.HealthBar);
        visuals.HealthFill.Name = "HealthFill";
        visuals.HealthFill.Size = UDim2.fromScale(1, 1);
        visuals.HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0);
        visuals.HealthFill.BorderSizePixel = 0
        ESP_State.TrackedCharacters[character] = visuals
    end
    local function updateVisuals(character, data)
        local hrp = character:FindFirstChild("HumanoidRootPart");
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not (hrp and humanoid and humanoid.Health > 0) then
            if data.Billboard.Enabled then
                data.Billboard.Enabled = false;
                data.Glow.Enabled = false
            end
            return
        end
        local player = data.Player;
        local isTeammate = (player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team)
        local shouldShow = (isTeammate and ESP_Config.Show_Teammates) or (not isTeammate and ESP_Config.Show_Enemies)
        if not shouldShow then
            if data.Glow.Enabled then
                data.Glow.Enabled = false
            end
            if data.Billboard.Enabled then
                data.Billboard.Enabled = false
            end
            return
        end
        local color = (isTeammate and player.Team) and player.Team.TeamColor.Color or ESP_Config.Default_Color
        data.Glow.Enabled = ESP_Config.Glow_Enabled;
        data.Glow.FillColor = color;
        data.Glow.FillTransparency = ESP_Config.Glow_Transparency
        data.Billboard.Enabled = ESP_Config.Names_Enabled or ESP_Config.Health_Enabled or ESP_Config.Distance_Enabled;
        data.Billboard.Adornee = hrp
        data.NameLabel.Visible = ESP_Config.Names_Enabled;
        data.NameLabel.TextColor3 = color;
        data.HealthBar.Visible = ESP_Config.Health_Enabled
        local healthPercent = humanoid.Health / humanoid.MaxHealth;
        data.HealthFill.Size = UDim2.fromScale(healthPercent, 1);
        data.HealthFill.BackgroundColor3 = Color3.fromHSV(healthPercent * 0.33, 1, 1)
        local distance = (Camera.CFrame.Position - hrp.Position).Magnitude;
        data.DistanceLabel.Visible = ESP_Config.Distance_Enabled;
        data.DistanceLabel.Text = string.format("%dM", distance)
    end
    local function cleanupVisuals(character)
        if ESP_State.TrackedCharacters[character] then
            local data = ESP_State.TrackedCharacters[character];
            if data.Glow.Parent then
                data.Glow.Parent:Destroy()
            end
            data.Billboard:Destroy();
            ESP_State.TrackedCharacters[character] = nil
        end
    end
    local function onCharacterAdded(character)
        local player = Players:GetPlayerFromCharacter(character);
        if not player or player == LocalPlayer then
            return
        end
        if not character:FindFirstChild("HumanoidRootPart") then
            local c;
            c = character.ChildAdded:Connect(function(child)
                if child.Name == "HumanoidRootPart" then
                    c:Disconnect();
                    createVisualsForCharacter(character)
                end
            end)
        else
            createVisualsForCharacter(character)
        end
    end
    local function onCharacterRemoving(character)
        cleanupVisuals(character)
    end
    local function setupPlayer(player)
        player.CharacterAdded:Connect(onCharacterAdded);
        player.CharacterRemoving:Connect(onCharacterRemoving);
        if player.Character then
            onCharacterAdded(player.Character)
        end
    end
    Players.PlayerAdded:Connect(setupPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            setupPlayer(player)
        end
    end
    RunService.RenderStepped:Connect(function()
        if not ESP_Config.ESP_Enabled then
            for _, d in pairs(ESP_State.TrackedCharacters) do
                if d.Glow.Enabled then
                    d.Glow.Enabled = false
                end
                if d.Billboard.Enabled then
                    d.Billboard.Enabled = false
                end
            end
            return
        end
        Camera = workspace.CurrentCamera;
        for c, d in pairs(ESP_State.TrackedCharacters) do
            pcall(updateVisuals, c, d)
        end
    end)
    local PlayerESPTab = Window:CreateTab("Player ESP", "eye")
    PlayerESPTab:CreateSection("Main ESP Settings");
    PlayerESPTab:CreateToggle({
        Name = "Enable ESP",
        CurrentValue = ESP_Config.ESP_Enabled,
        Flag = "PlayerESP_Enabled",
        Callback = function(v)
            ESP_Config.ESP_Enabled = v
        end
    })
    PlayerESPTab:CreateToggle({
        Name = "Enable Glow (Chams)",
        CurrentValue = ESP_Config.Glow_Enabled,
        Flag = "PlayerESP_Glow",
        Callback = function(v)
            ESP_Config.Glow_Enabled = v
        end
    })
    PlayerESPTab:CreateToggle({
        Name = "Show Names",
        CurrentValue = ESP_Config.Names_Enabled,
        Flag = "PlayerESP_Names",
        Callback = function(v)
            ESP_Config.Names_Enabled = v
        end
    })
    PlayerESPTab:CreateToggle({
        Name = "Show Health Bar",
        CurrentValue = ESP_Config.Health_Enabled,
        Flag = "PlayerESP_Health",
        Callback = function(v)
            ESP_Config.Health_Enabled = v
        end
    })
    PlayerESPTab:CreateToggle({
        Name = "Show Distance",
        CurrentValue = ESP_Config.Distance_Enabled,
        Flag = "PlayerESP_Distance",
        Callback = function(v)
            ESP_Config.Distance_Enabled = v
        end
    })
    PlayerESPTab:CreateSection("Team Filters");
    PlayerESPTab:CreateToggle({
        Name = "Show Teammates",
        CurrentValue = ESP_Config.Show_Teammates,
        Flag = "PlayerESP_ShowTeam",
        Callback = function(v)
            ESP_Config.Show_Teammates = v
        end
    })
    PlayerESPTab:CreateToggle({
        Name = "Show Enemies",
        CurrentValue = ESP_Config.Show_Enemies,
        Flag = "PlayerESP_ShowEnemies",
        Callback = function(v)
            ESP_Config.Show_Enemies = v
        end
    })
    PlayerESPTab:CreateSection("Style Settings");
    PlayerESPTab:CreateSlider({
        Name = "Glow Transparency",
        Range = {0, 1},
        Increment = 0.05,
        Suffix = "%",
        CurrentValue = ESP_Config.Glow_Transparency,
        Flag = "PlayerESP_GlowTrans",
        Callback = function(v)
            ESP_Config.Glow_Transparency = v
        end
    })
end

return Module