-- ===================================================================
-- 1. RAYFIELD UI LIBRARY INITIALIZATION
-- ===================================================================
local Rayfield =
    loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
local Alerts = loadstring(game:HttpGet('https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/utils/alert.lua'))()
local Window = Rayfield:CreateWindow({
    Name = "Universal Script",
    LoadingTitle = "Universal Script",
    LoadingSubtitle = "by Hadat Skywalker",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "UniversalScriptConfig",
        FileName = "Universal"
    }
})

-- ===================================================================
-- 2. LOAD & INITIALIZE MODULES FROM GITHUB
-- ===================================================================

-- Load Player Modifier Module (Speed, Jump, etc.)
local playerModifier = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/universal/player_modifier/main.lua"))()
playerModifier.CreateTab(Window)

-- Load Universal Scripts Module (Infinite Yield, Dex, etc.)
local universalScripts = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/universal/script/main.lua"))()
universalScripts.CreateTab(Window)

-- Load Player ESP Module
local playerEsp = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/universal/esp/player/main.lua"))()
playerEsp.CreateTab(Window)

-- Load Object ESP Module
local objectEsp = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/universal/esp/object/main.lua"))()
objectEsp.CreateTab(Window)

local monsterEsp = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/pressure/esp/monster.lua"))()
monsterEsp.CreateTab(Window, Alerts)

-- ===================================================================
-- 3. FINAL SETUP
-- ===================================================================
Rayfield:LoadConfiguration()