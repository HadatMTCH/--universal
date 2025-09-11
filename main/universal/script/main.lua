local Module = {}

function Module.CreateTab(Window)
    -- ALL THE UI LOGIC IS NOW INSIDE THIS FUNCTION
    local UniversalScriptsTab = Window:CreateTab("Universal Scripts", "code")

    UniversalScriptsTab:CreateButton({
        Name = "Infinite Yield",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
        end
    })

    UniversalScriptsTab:CreateButton({
        Name = "Dex Explorer Peyton",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/peyton2465/Dex/master/out.lua"))()
        end
    })

    UniversalScriptsTab:CreateButton({
        Name = "Dex Explorer Hosvile",
        Callback = function()
            loadstring(game:HttpGet("https://github.com/Hosvile/DEX-Explorer/releases/latest/download/main.lua", true))
        end
    })

    UniversalScriptsTab:CreateButton({
        Name = "Dex Explorer WRD",
        Callback = function()
            loadstring(game:HttpGet("https://obj.wearedevs.net/2/scripts/Dex%20Explorer.lua"))()
        end
    })

    UniversalScriptsTab:CreateButton({
        Name = "StackZero",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/boregondev/SKYSCRIPTS/refs/heads/main/SKYSCRIPTS.lua", true))()
        end
    })

    UniversalScriptsTab:CreateButton({
        Name = "Yoxi Hub",
        Callback = function()
            loadstring(game:HttpGet("https://raw.githubusercontent.com/Yomkaa/YOXI-HUB/refs/heads/main/loader", true))()
        end
    })

    UniversalScriptsTab:CreateButton({
        Name = "Personal Hub",
        Callback = function()
            loadstring(game:HttpGet("https://pastebin.com/raw/MyhX2sT3"))()
        end
    })
end

return Module