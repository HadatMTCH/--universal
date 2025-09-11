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
-- 2. GET THE GAME NAME SAFELY
-- ===================================================================
local MarketplaceService = game:GetService("MarketplaceService")
local gameName = ""
local placeId = game.PlaceId

-- We use pcall because the web request can sometimes fail
local success, productInfo = pcall(function()
    return MarketplaceService:GetProductInfo(placeId)
end)

if success and productInfo then
    gameName = productInfo.Name
    print("Currently playing: " .. gameName .. " (ID: " .. placeId .. ")")
else
    warn("Could not fetch game name for Place ID: " .. placeId)
end

-- ===================================================================
-- 3. LOAD & INITIALIZE MODULES FROM GITHUB
-- ===================================================================
-- Load Universal Scripts Module (Infinite Yield, Dex, etc.)
local universalScripts = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/universal/script/main.lua"))()
universalScripts.CreateTab(Window)

if gameName == "Pressure" or gameName == "PRESSURE" then
    local monsterEsp = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/pressure/esp/monster.lua"))()
    monsterEsp.CreateTab(Window)
else
    -- Load Player ESP Module
    local playerEsp = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/universal/esp/player/main.lua"))()
    playerEsp.CreateTab(Window, Sense)

    -- Load Object ESP Module
    local objectEsp = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/universal/esp/object/main.lua"))()
    objectEsp.CreateTab(Window)

    -- Load Player Modifier Module (Speed, Jump, etc.)
    local playerModifier = loadstring(game:HttpGet("https://raw.githubusercontent.com/HadatMTCH/--universal/refs/heads/master/main/universal/player_modifier/main.lua"))()
    playerModifier.CreateTab(Window)
end
-- ===================================================================
-- 3. FINAL SETUP
-- ===================================================================
Rayfield:LoadConfiguration()
Sense.Load()