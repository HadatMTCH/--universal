local Module = {}

-- UPDATED: This function now accepts the 'tab' object instead of the 'section' object.
local function CreateTeamSettings(tab, settingsTable)
    -- UPDATED: All UI elements are now created on the 'tab' object.
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
    tab:CreateColorpicker({
        Name = "Box Color",
        Color = settingsTable.boxColor[1],
        Callback = function(c) settingsTable.boxColor[1] = c end
    })

    tab:CreateToggle({
        Name = "Name ESP",
        CurrentValue = settingsTable.name,
        Callback = function(v) settingsTable.name = v end
    })
    tab:CreateColorpicker({
        Name = "Name Color",
        Color = settingsTable.nameColor[1],
        Callback = function(c) settingsTable.nameColor[1] = c end
    })

    tab:CreateToggle({
        Name = "Health Bar",
        CurrentValue = settingsTable.healthBar,
        Callback = function(v) settingsTable.healthBar = v end
    })

    tab:CreateToggle({
        Name = "Tracer",
        CurrentValue = settingsTable.tracer,
        Callback = function(v) settingsTable.tracer = v end
    })
    tab:CreateColorpicker({
        Name = "Tracer Color",
        Color = settingsTable.tracerColor[1],
        Callback = function(c) settingsTable.tracerColor[1] = c end
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
    tab:CreateColorpicker({
        Name = "Chams Fill Color",
        Color = settingsTable.chamsFillColor[1],
        Callback = function(c) settingsTable.chamsFillColor[1] = c end
    })
    tab:CreateSlider({
        Name = "Chams Fill Transparency",
        Range = {0, 1},
        Increment = 0.05,
        CurrentValue = settingsTable.chamsFillColor[2],
        Callback = function(v) settingsTable.chamsFillColor[2] = v end
    })
end


-- UPDATED: The second argument is now named 'Sense' to avoid confusion.
function Module.CreateTab(Window, Sense)
    
    local SenseTab = Window:CreateTab("Sense ESP", "eye")

    -- ===================================================================
    -- ENEMY SETTINGS
    -- ===================================================================
    SenseTab:CreateSection("Enemy Settings")
    -- UPDATED: Pass the main 'SenseTab' to the helper function.
    CreateTeamSettings(SenseTab, Sense.teamSettings.enemy)

    -- ===================================================================
    -- FRIENDLY SETTINGS
    -- ===================================================================
    SenseTab:CreateSection("Friendly Settings")
    -- UPDATED: Pass the main 'SenseTab' to the helper function.
    CreateTeamSettings(SenseTab, Sense.teamSettings.friendly)

    -- ===================================================================
    -- SHARED SETTINGS
    -- ===================================================================
    local SharedSection = SenseTab:CreateSection("Shared Settings")

    -- These are correct because they are called on the Tab (SenseTab), not the Section.
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