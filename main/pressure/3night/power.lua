local Module = {}

function Module.CreateTab(Window)
    -- Services
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    -- Configuration for our feature
    local Config = {
        UnlimitedPower = false
    }

    -- Find the OfficeBattery ValueObject
    local officeBattery = ReplicatedStorage:WaitForChild("OfficeBattery")
    if not officeBattery then
        warn("Unlimited Power: Could not find 'OfficeBattery' in ReplicatedStorage.")
        return
    end

    -- Create a loop that runs in the background
    task.spawn(function()
        while task.wait(0.1) do -- Check every tenth of a second
            if Config.UnlimitedPower then
                -- If unlimited power is on, force the battery value to 100
                if officeBattery.Value < 100 then
                    officeBattery.Value = 100
                end
            end
        end
    end)

    -- Add the toggle to your UI
    local GameCheatsTab = Window:CreateTab("Game Cheats", "bolt")
    GameCheatsTab:CreateSection("Power Management")

    GameCheatsTab:CreateToggle({
        Name = "Unlimited Power",
        CurrentValue = Config.UnlimitedPower,
        Flag = "UnlimitedPower_Enabled",
        Callback = function(value)
            Config.UnlimitedPower = value
        end
    })

    print("Unlimited Power script loaded successfully.")
end

return Module
