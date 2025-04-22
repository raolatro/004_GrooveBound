-- settings_menu.lua: In-game settings menu UI for GrooveBound
-- Draws a hamburger icon, menu popup, and lets user adjust main settings in real time
-- Start with only the main settings group (bpm, beat_subdivisions, etc)

local settings = require "settings"
local settings_menu = {}

settings_menu.active = false
settings_menu.page = 1
settings_menu.pages = {"main"}
settings_menu.icon_size = 36
settings_menu.icon_margin = 12
settings_menu.selected = 1 -- selected row in menu
settings_menu.auto_fire_enabled = false -- Auto-Fire toggle

-- List of settings to show on the first page (main)
settings_menu.main_settings = {
    { key = "bpm", label = "BPM", min = 10, max = 300, step = 1 },
    { key = "beat_subdivisions", label = "Beat Subdivisions", min = 1, max = 16, step = 1 },
    { key = "beat_checker_base_radius", label = "Checker Radius", min = 8, max = 256, step = 1 },
    { key = "on_beat_scale", label = "On-Beat Scale", min = 0.5, max = 3, step = 0.05 },
    { key = "beat_checker_on_beat_buffer", label = "On-Beat Buffer", min = 0.01, max = 0.5, step = 0.01 },
}

function settings_menu.toggle()
    settings_menu.active = not settings_menu.active
end

function settings_menu.update(dt)
    -- Pause game logic if menu is active (handled in main.lua)
end

function settings_menu.keypressed(key)
    if not settings_menu.active then return end
    if key == "escape" then settings_menu.active = false end
    if key == "down" then settings_menu.selected = math.min(settings_menu.selected+1, #settings_menu.main_settings) end
    if key == "up" then settings_menu.selected = math.max(settings_menu.selected-1, 1) end
    local sel = settings_menu.main_settings[settings_menu.selected]
    if key == "+" or key == "right" then
        local v = settings.main[sel.key]
        settings.main[sel.key] = math.min(sel.max, v + sel.step)
    elseif key == "-" or key == "left" then
        local v = settings.main[sel.key]
        settings.main[sel.key] = math.max(sel.min, v - sel.step)
    end
end

function settings_menu.mousepressed(x, y, button)
    print('DEBUG: mousepressed called, active='..tostring(settings_menu.active)..', x='..x..', y='..y..', button='..tostring(button))
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local ix, iy = w - settings_menu.icon_size - settings_menu.icon_margin, settings_menu.icon_margin
    local af_width = 220
    local af_height = 38
    local af_x = ix - af_width - 24
    local af_y = iy
    -- Check Auto-Fire toggle button (always clickable)
    if button == 1 and x >= af_x and x <= af_x+af_width and y >= af_y and y <= af_y+af_height then
        settings_menu.auto_fire_enabled = not settings_menu.auto_fire_enabled
        print('DEBUG: Auto-Fire toggled to', tostring(settings_menu.auto_fire_enabled))
        return
    end
    if not settings_menu.active then
        -- Check if hamburger icon clicked (only left mouse button)
        if button == 1 then
            print('DEBUG: Left mouse button pressed')
            if x >= ix and x <= ix+settings_menu.icon_size and y >= iy and y <= iy+settings_menu.icon_size then
                print('DEBUG: Hamburger icon clicked! Activating menu.')
                settings_menu.active = true
            end
        end
    else
        print('DEBUG: Menu already active, mouse interaction for +/- not implemented yet')
    end
end

function settings_menu.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    -- Draw hamburger icon (top right)
    local ix, iy = w - settings_menu.icon_size - settings_menu.icon_margin, settings_menu.icon_margin
    print('DEBUG: draw() called, drawing hamburger icon at', ix, iy)
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.rectangle("fill", ix, iy, settings_menu.icon_size, settings_menu.icon_size, 8, 8)
    love.graphics.setColor(0,0,0,1)
    for i=1,3 do
        love.graphics.rectangle("fill", ix+8, iy+8*i, settings_menu.icon_size-16, 4, 2, 2)
    end
    love.graphics.setColor(1,1,1,1)
    -- Draw prominent Auto-Fire toggle button (horizontal, wide, one line)
    local af_width = 220
    local af_height = 38
    local af_x = ix - af_width - 24
    local af_y = iy
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", af_x, af_y, af_width, af_height, 12, 12)
    love.graphics.setColor(1,1,1,1)
    love.graphics.setFont(love.graphics.newFont(18))
    love.graphics.printf("Auto-Fire", af_x + 0, af_y + 8, af_width - 36, "right")
    love.graphics.setColor(settings_menu.auto_fire_enabled and {0,1,0,1} or {1,0,0,1})
    love.graphics.circle("fill", af_x + af_width - 20, af_y + af_height/2, 12)
    love.graphics.setColor(1,1,1,1)
    -- Draw popup menu if active
    if settings_menu.active then
        print('DEBUG: settings_menu.active, drawing popup menu')
        love.graphics.setColor(0,0,0,0.92)
        love.graphics.rectangle("fill", w/2-180, h/2-140, 360, 280, 16, 16)
        love.graphics.setColor(1,1,1,1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", w/2-180, h/2-140, 360, 280, 16, 16)
        love.graphics.setLineWidth(1)
        love.graphics.printf("SETTINGS", w/2-180, h/2-132, 360, "center")
        for i, entry in ipairs(settings_menu.main_settings) do
            local y = h/2-100 + (i-1)*38
            local v = settings.main[entry.key]
            if i == settings_menu.selected then
                love.graphics.setColor(0.2,0.8,1,1)
            else
                love.graphics.setColor(1,1,1,1)
            end
            love.graphics.printf(entry.label .. ": ", w/2-150, y, 140, "right")
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf(string.format("%.2f", v), w/2-10, y, 60, "left")
            -- Draw +/- buttons
            love.graphics.setColor(0.7,0.7,0.7,1)
            love.graphics.rectangle("fill", w/2+60, y, 28, 28, 6, 6)
            love.graphics.rectangle("fill", w/2+100, y, 28, 28, 6, 6)
            love.graphics.setColor(0,0,0,1)
            love.graphics.printf("-", w/2+60, y+4, 28, "center")
            love.graphics.printf("+", w/2+100, y+4, 28, "center")
        end
        love.graphics.setColor(1,1,1,1)
    end
    -- Draw bottom-center instruction (always visible)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", w/2-230, h-54, 460, 36, 10, 10)
    love.graphics.setColor(1,1,1,1)
    local old_font = love.graphics.getFont()
    local instr_font = love.graphics.newFont(18)
    love.graphics.setFont(instr_font)
    love.graphics.printf("Move: WASD   |   Aim: Mouse   |   Shoot: Left Click or Auto-Fire", w/2-220, h-48, 440, "center")
    love.graphics.setFont(old_font)
end

return settings_menu
