-- pause_menu.lua: Dedicated pause state UI for GrooveBound
local settings = require "settings"
local hud = require "scripts/hud"
local debug = require "scripts/debug"
local popup = require "scripts/popup"
local pause_menu = {}

pause_menu.active = false

-- Button areas for hit detection
pause_menu.buttons = {
    auto_fire = {x = 0, y = 0, width = 0, height = 0}, -- Coordinates set in draw()
    aim_assist = {x = 0, y = 0, width = 0, height = 0}  -- Coordinates set in draw()
}

-- Show the pause menu
function pause_menu.activate()
    debug.log("[PauseMenu] Activating pause menu")
    pause_menu.active = true
    game_paused = true
    -- Show system cursor in pause menu
    love.mouse.setVisible(true)
    popup.create_notification("Game Paused", popup.STYLES.SUBHEAD)
end

-- Hide the pause menu
function pause_menu.deactivate()
    debug.log("[PauseMenu] Deactivating pause menu")
    pause_menu.active = false
    game_paused = false
    -- Hide system cursor in pause menu
    love.mouse.setVisible(false)
end

-- Toggle the pause menu
function pause_menu.toggle()
    debug.log("[PauseMenu] toggle() called. New state: " .. tostring(not pause_menu.active))
    if pause_menu.active then
        pause_menu.deactivate()
    else
        pause_menu.activate()
    end
end

-- Toggle auto-fire state
function pause_menu.toggle_auto_fire()
    debug.log("[PauseMenu] toggle_auto_fire() called")
    hud.auto_fire_enabled = not hud.auto_fire_enabled
end

-- Toggle aim assist state
function pause_menu.toggle_aim_assist()
    debug.log("[PauseMenu] toggle_aim_assist() called")
    hud.aim_line_enabled = not hud.aim_line_enabled
end

-- Handle mouse interaction with pause menu
function pause_menu.mousepressed(x, y, button)
    if not pause_menu.active then return false end
    if button ~= 1 then return false end -- Only handle left clicks
    
    -- Check if auto-fire button was clicked
    local auto = pause_menu.buttons.auto_fire
    if x >= auto.x and x <= auto.x + auto.width and
       y >= auto.y and y <= auto.y + auto.height then
        pause_menu.toggle_auto_fire()
        return true
    end
    
    -- Check if aim assist button was clicked
    local aim = pause_menu.buttons.aim_assist
    if x >= aim.x and x <= aim.x + aim.width and
       y >= aim.y and y <= aim.y + aim.height then
        pause_menu.toggle_aim_assist()
        return true
    end
    
    return false
end

-- Draw the pause menu UI (no overlay)
function pause_menu.draw()
    if not pause_menu.active then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local box_width, box_height = 340, 240
    local box_x = math.floor((w - box_width) / 2 + 0.5)
    local box_y = math.floor((h - box_height) / 2 + 0.5)
    debug.log("[PauseMenu] draw() called. Drawing pause module.")
    
    -- Draw pause module container (solid)
    love.graphics.setColor(0.13,0.13,0.13,0.98)
    love.graphics.rectangle("fill", box_x, box_y, box_width, box_height, 16, 16)
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", box_x, box_y, box_width, box_height, 16, 16)
    love.graphics.setLineWidth(1)
    
    -- Use cached HUD font for all elements
    local font = hud.font
    if not font then
        debug.log("[PauseMenu] hud.font is nil! Using default font.")
        font = love.graphics.getFont()
    end
    love.graphics.setFont(font)
    
    -- Title
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("PAUSED", box_x, box_y + 32, box_width, "center")
    
    -- Button dimensions
    local btn_width = box_width - 64
    local btn_height = 40
    local btn_radius = 8
    
    -- Auto Fire toggle button
    local af_y = box_y + 100
    local af_x = box_x + 32
    -- Store button area for hit detection
    pause_menu.buttons.auto_fire = {x = af_x, y = af_y, width = btn_width, height = btn_height}
    
    -- Button background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", af_x, af_y, btn_width, btn_height, btn_radius, btn_radius)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("line", af_x, af_y, btn_width, btn_height, btn_radius, btn_radius)
    
    -- Button text
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("AUTO-FIRE", af_x + 10, af_y + 12, btn_width - 50, "left")
    
    -- Status indicator
    love.graphics.setColor(hud.auto_fire_enabled and {0,1,0,1} or {1,0,0,1})
    love.graphics.circle("fill", af_x + btn_width - 20, af_y + btn_height/2, 12)
    
    -- Aim Line toggle button
    local aim_y = af_y + 60
    local aim_x = af_x
    -- Store button area for hit detection
    pause_menu.buttons.aim_assist = {x = aim_x, y = aim_y, width = btn_width, height = btn_height}
    

    
    -- Button background
    love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
    love.graphics.rectangle("fill", aim_x, aim_y, btn_width, btn_height, btn_radius, btn_radius)
    love.graphics.setColor(0.5, 0.5, 0.5, 1)
    love.graphics.rectangle("line", aim_x, aim_y, btn_width, btn_height, btn_radius, btn_radius)
    
    -- Button text
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("AIM ASSIST", aim_x + 10, aim_y + 12, btn_width - 50, "left")
    
    -- Status indicator (green = active, red = inactive)
    love.graphics.setColor(hud.aim_line_enabled and {0,1,0,1} or {1,0,0,1})
    love.graphics.circle("fill", aim_x + btn_width - 20, aim_y + btn_height/2, 12)
    
    love.graphics.setColor(1,1,1,1)
end

return pause_menu

