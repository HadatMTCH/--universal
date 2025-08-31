local Module = {}

function Module.CreateTab(Window)
    -- ALL THE UI LOGIC IS NOW INSIDE THIS FUNCTION
    local MainCheatsTab = Window:CreateTab("Universal Exploits", "bug")

    local customSpeed = 16
    local customJump = 50
    local customGravity = 196.2

    local SpeedSection = MainCheatsTab:CreateSection("Speed Hacks")

    local SpeedToggle = MainCheatsTab:CreateToggle({
        Name = "Enable Speed Hack",
        CurrentValue = false,
        Flag = "SpeedHackEnabled",
        Callback = function(Value)
            local humanoid = game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = Value and customSpeed or 16
            end
        end
    })

    MainCheatsTab:CreateInput({
        Name = "Set Speed",
        PlaceholderText = "Enter speed value",
        Flag = "SpeedValue",
        RemoveTextAfterFocusLost = true,
        Callback = function(Value)
            local speedValue = tonumber(Value)
            if speedValue then
                customSpeed = speedValue
                if SpeedToggle.CurrentValue then
                    local humanoid = game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.WalkSpeed = customSpeed
                    end
                end
            end
        end
    })

    local JumpSection = MainCheatsTab:CreateSection("JumpPower Hacks")

    local JumpToggle = MainCheatsTab:CreateToggle({
        Name = "Enable JumpPower Hack",
        CurrentValue = false,
        Flag = "JumpHackEnabled",
        Callback = function(Value)
            local humanoid = game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = Value and customJump or 50
            end
        end
    })

    MainCheatsTab:CreateInput({
        Name = "Set Jump Power",
        PlaceholderText = "Enter jump power value",
        Flag = "JumpValue",
        RemoveTextAfterFocusLost = true,
        Callback = function(Value)
            local jumpValue = tonumber(Value)
            if jumpValue then
                customJump = jumpValue
                if JumpToggle.CurrentValue then
                    local humanoid = game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid.JumpPower = customJump
                    end
                end
            end
        end
    })

    local GravitySection = MainCheatsTab:CreateSection("Gravity Modification")

    MainCheatsTab:CreateToggle({
        Name = "Enable Gravity Modification",
        CurrentValue = false,
        Flag = "GravityEnabled",
        Callback = function(Value)
            game:GetService("Workspace").Gravity = Value and customGravity or 196.2
        end
    })

    MainCheatsTab:CreateInput({
        Name = "Set Gravity",
        PlaceholderText = "Enter gravity value",
        Flag = "GravityValue",
        RemoveTextAfterFocusLost = true,
        Callback = function(Value)
            local gravValue = tonumber(Value)
            if gravValue then
                customGravity = gravValue
            end
        end
    })

    local MiscSection = MainCheatsTab:CreateSection("Misc Hacks")
    local jumpConnection
    MainCheatsTab:CreateToggle({
        Name = "Enable Infinite Jump",
        CurrentValue = false,
        Flag = "InfiniteJump",
        Callback = function(Value)
            if Value then
                if not jumpConnection then
                    jumpConnection = game:GetService("UserInputService").JumpRequest:Connect(function()
                        local humanoid = game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if humanoid then
                            humanoid:ChangeState("Jumping")
                        end
                    end)
                end
            else
                if jumpConnection then
                    jumpConnection:Disconnect()
                    jumpConnection = nil
                end
            end
        end
    })
end

return Module