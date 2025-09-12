-- ===================================================================
-- 1. RAYFIELD UI LIBRARY INITIALIZATION
-- ===================================================================
local Rayfield =
    loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
local Sense = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/lib/sense/sense.lua"))()

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
playerEsp.CreateTab(Window, Sense)

-- Load Object ESP Module
local objectEsp = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/universal/esp/object/main.lua"))()
objectEsp.CreateTab(Window)

local monsterEsp = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/pressure/esp/monster.lua"))()
monsterEsp.CreateTab(Window)

-- local currencyEsp = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/pressure/esp/currency.lua"))()
-- currencyEsp.CreateTab(Window)

-- local rooms_objectEsp = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/pressure/esp/rooms_object.lua"))()
-- rooms_objectEsp.CreateTab(Window)

-- ===================================================================
-- 3. FINAL SETUP
-- ===================================================================
Rayfield:LoadConfiguration()
Sense.Load()