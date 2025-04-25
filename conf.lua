-- conf.lua: LÖVE configuration for GrooveBound-prototype
function love.conf(t)
    -- Use dofile to load settings.lua as a table, since require is not available here
    -- Try to load settings.lua from the root directory; fallback to defaults if not found
    local settings = { window_width = 1280, window_height = 720 }
    local ok, loaded = pcall(dofile, "settings.lua")
    if ok and type(loaded) == "table" then
        settings = loaded
    else
        print("[conf.lua] Warning: Could not load settings.lua, using default window size.")
    end
    t.window.title = "GrooveBound-prototype"
    t.window.width = (settings.main and settings.main.window_width) or settings.window_width
    t.window.height = (settings.main and settings.main.window_height) or settings.window_height
end
