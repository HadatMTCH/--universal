local Module = {}

-- This function creates all the UI elements for one team type (enemy or friendly)
-- This avoids writing the same code twice!
local function CreateTeamSettings(section, settingsTable)
    section:CreateToggle({
        Name = "Enabled",
        CurrentValue = settingsTable.enabled,
        Callback = function(v) settingsTable.enabled = v end
    })

    section:CreateToggle({
        Name = "Box ESP",
        CurrentValue = settingsTable.box,
        Callback = function(v) settingsTable.box = v end
    })
    section:CreateColorpicker({
        Name = "Box Color",
        Color = settingsTable.boxColor[1],
        Callback = function(c) settingsTable.boxColor[1] = c end
    })

    section:CreateToggle({
        Name = "Name ESP",
        CurrentValue = settingsTable.name,
        Callback = function(v) settingsTable.name = v end
    })
    section:CreateColorpicker({
        Name = "Name Color",
        Color = settingsTable.nameColor[1],
        Callback = function(c) settingsTable.nameColor[1] = c end
    })

    section:CreateToggle({
        Name = "Health Bar",
        CurrentValue = settingsTable.healthBar,
        Callback = function(v) settingsTable.healthBar = v end
    })

    section:CreateToggle({
        Name = "Tracer",
        CurrentValue = settingsTable.tracer,
        Callback = function(v) settingsTable.tracer = v end
    })
    section:CreateColorpicker({
        Name = "Tracer Color",
        Color = settingsTable.tracerColor[1],
        Callback = function(c) settingsTable.tracerColor[1] = c end
    })
    section:CreateDropdown({
        Name = "Tracer Origin",
        Options = {"Bottom", "Top", "Middle"},
        CurrentValue = settingsTable.tracerOrigin,
        Callback = function(v) settingsTable.tracerOrigin = v end
    })
    
    section:CreateToggle({
        Name = "Off-Screen Arrow",
        CurrentValue = settingsTable.offScreenArrow,
        Callback = function(v) settingsTable.offScreenArrow = v end
    })
    section:CreateSlider({
        Name = "Arrow Size",
        Range = {5, 50},
        Increment = 1,
        CurrentValue = settingsTable.offScreenArrowSize,
        Callback = function(v) settingsTable.offScreenArrowSize = v end
    })
    section:CreateSlider({
        Name = "Arrow Radius",
        Range = {50, 500},
        Increment = 10,
        CurrentValue = settingsTable.offScreenArrowRadius,
        Callback = function(v) settingsTable.offScreenArrowRadius = v end
    })

    section:CreateToggle({
        Name = "Chams (Glow)",
        CurrentValue = settingsTable.chams,
        Callback = function(v) settingsTable.chams = v end
    })
    section:CreateColorpicker({
        Name = "Chams Fill Color",
        Color = settingsTable.chamsFillColor[1],
        Callback = function(c) settingsTable.chamsFillColor[1] = c end
    })
    section:CreateSlider({
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