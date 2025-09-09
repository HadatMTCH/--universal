local Module = {}

-- NEW: A palette of predefined colors for the dropdown menus
local ColorPalette = {
    ["Red"] = Color3.fromRGB(255, 60, 60),
    ["Green"] = Color3.fromRGB(60, 255, 60),
    ["Blue"] = Color3.fromRGB(60, 150, 255),
    ["Yellow"] = Color3.fromRGB(255, 255, 60),
    ["Cyan"] = Color3.fromRGB(60, 255, 255),
    ["Magenta"] = Color3.fromRGB(255, 60, 255),
    ["White"] = Color3.fromRGB(255, 255, 255),
    ["Team Color"] = "Team Color" -- This is a special string that the Sense library understands
}
local ColorNames = {"Red", "Green", "Blue", "Yellow", "Cyan", "Magenta", "White", "Team Color"}


local function CreateTeamSettings(tab, settingsTable)
    tab:CreateToggle({
        Name = "Enabled",
        CurrentValue = settingsTable.enabled,
        Callback = function(v) settingsTable.enabled = v end
    })

    tab:CreateToggle({
        Name = "Box ESP",
        CurrentValue = settingsTable.box,
        Callback = function(v) settingsTable.box = v end
    })
    -- UPDATED: Replaced Colorpicker with a Dropdown
    tab:CreateDropdown({
        Name = "Box Color",
        Options = ColorNames,
        CurrentValue = "Red",
        Callback = function(c) settingsTable.boxColor[1] = ColorPalette[c] end
    })

    tab:CreateToggle({
        Name = "Name ESP",
        CurrentValue = settingsTable.name,
        Callback = function(v) settingsTable.name = v end
    })
    -- UPDATED: Replaced Colorpicker with a Dropdown
    tab:CreateDropdown({
        Name = "Name Color",
        Options = ColorNames,
        CurrentValue = "White",
        Callback = function(c) settingsTable.nameColor[1] = ColorPalette[c] end
    })

    tab:CreateToggle({
        Name = "Health Bar",
        CurrentValue = settingsTable.healthBar,
        Callback = function(v) settingsTable.healthBar = v end
    })
    
    tab:CreateDropdown({
        Name = "Healthy Color",
        Options = ColorNames,
        CurrentValue = "Green",
        Callback = function(c) settingsTable.healthyColor = ColorPalette[c] end
    })

    tab:CreateDropdown({
        Name = "Dying Color",
        Options = ColorNames,
        CurrentValue = "Red",
        Callback = function(c) settingsTable.dyingColor = ColorPalette[c] end
    })

    tab:CreateToggle({
        Name = "Tracer",
        CurrentValue = settingsTable.tracer,
        Callback = function(v) settingsTable.tracer = v end
    })
    -- UPDATED: Replaced Colorpicker with a Dropdown
    tab:CreateDropdown({
        Name = "Tracer Color",
        Options = ColorNames,
        CurrentValue = "Red",
        Callback = function(c) settingsTable.tracerColor[1] = ColorPalette[c] end
    })
    tab:CreateDropdown({
        Name = "Tracer Origin",
        Options = {"Bottom", "Top", "Middle"},
        CurrentValue = settingsTable.tracerOrigin,
        Callback = function(v) settingsTable.tracerOrigin = v end
    })
    
    tab:CreateToggle({
        Name = "Off-Screen Arrow",
        CurrentValue = settingsTable.offScreenArrow,
        Callback = function(v) settingsTable.offScreenArrow = v end
    })
    tab:CreateSlider({
        Name = "Arrow Size",
        Range = {5, 50},
        Increment = 1,
        CurrentValue = settingsTable.offScreenArrowSize,
        Callback = function(v) settingsTable.offScreenArrowSize = v end
    })
    tab:CreateSlider({
        Name = "Arrow Radius",
        Range = {50, 500},
        Increment = 10,
        CurrentValue = settingsTable.offScreenArrowRadius,
        Callback = function(v) settingsTable.offScreenArrowRadius = v end
    })

    tab:CreateToggle({
        Name = "Chams (Glow)",
        CurrentValue = settingsTable.chams,
        Callback = function(v) settingsTable.chams = v end
    })
    -- UPDATED: Replaced Colorpicker with a Dropdown
    tab:CreateDropdown({
        Name = "Chams Fill Color",
        Options = ColorNames,
        CurrentValue = "Red",
        Callback = function(c) settingsTable.chamsFillColor[1] = ColorPalette[c] end
    })
    tab:CreateSlider({
        Name = "Chams Fill Transparency",
        Range = {0, 1},
        Increment = 0.05,
        CurrentValue = settingsTable.chamsFillColor[2],
        Callback = function(v) settingsTable.chamsFillColor[2] = v end
    })
end


function Module.CreateTab(Window, Sense)
    
    local SenseTab = Window:CreateTab("Sense ESP", "eye")

    -- ===================================================================
    -- ENEMY SETTINGS
    -- ===================================================================
    SenseTab:CreateSection("Enemy Settings")
    CreateTeamSettings(SenseTab, Sense.teamSettings.enemy)

    -- ===================================================================
    -- FRIENDLY SETTINGS
    -- ===================================================================
    SenseTab:CreateSection("Friendly Settings")
    CreateTeamSettings(SenseTab, Sense.teamSettings.friendly)

    -- ===================================================================
    -- SHARED SETTINGS
    -- ===================================================================
    SenseTab:CreateSection("Shared Settings")

    SenseTab:CreateToggle({
        Name = "Use Team Color",
        CurrentValue = Sense.sharedSettings.useTeamColor,
        Flag = "Sense_Shared_UseTeamColor",
        Callback = function(v) Sense.sharedSettings.useTeamColor = v end
    })

    SenseTab:CreateToggle({
        Name = "Limit Distance",
        CurrentValue = Sense.sharedSettings.limitDistance,
        Flag = "Sense_Shared_LimitDistance",
        Callback = function(v) Sense.sharedSettings.limitDistance = v end
    })

    SenseTab:CreateSlider({
        Name = "Max Distance",
        Range = {50, 2000},
        Increment = 50,
        Suffix = "studs",
        CurrentValue = Sense.sharedSettings.maxDistance,
        Flag = "Sense_Shared_MaxDistance",
        Callback = function(v) Sense.sharedSettings.maxDistance = v end
    })
    
    SenseTab:CreateSlider({
        Name = "Text Size",
        Range = {10, 24},
        Increment = 1,
        CurrentValue = Sense.sharedSettings.textSize,
        Flag = "Sense_Shared_TextSize",
        Callback = function(v) Sense.sharedSettings.textSize = v end
    })

end

return Module