-- scripts/shop_menu.lua: Handles the level up shop menu interface
local settings = require "settings"
local debug = require "scripts/debug"

local shop_menu = {}

shop_menu.active = false
shop_menu.current_level = 1

-- Font system for shop menu
function shop_menu.reload_fonts()
    shop_menu._fonts = {
        header = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.header),
        body = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.body),
        button = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.button)
    }
end

-- Load fonts on module load
shop_menu.reload_fonts()

-- Show the shop menu when leveling up
function shop_menu.show(level)
    shop_menu.active = true
    shop_menu.current_level = level
    
    -- Show system cursor when shop menu is active
    love.mouse.setVisible(true)
    
    -- Create continue button
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local btn_w, btn_h = 180, 48
    local btn_x, btn_y = w/2-btn_w/2, h/2+100
    shop_menu._continue_btn = {x=btn_x, y=btn_y, w=btn_w, h=btn_h}
    
    debug.log("Shop menu opened at level " .. level)
end

-- Hide the shop menu and continue gameplay
function shop_menu.hide()
    shop_menu.active = false
    
    -- Hide system cursor when returning to gameplay
    love.mouse.setVisible(false)
    
    -- Unpause the game
    _G.game_paused = false
    
    debug.log("Shop menu closed, continuing game")
end

-- Draw the shop menu
function shop_menu.draw()
    if not shop_menu.active then return end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Darken the background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Shop menu container
    local box_w, box_h = 500, 400
    local box_x, box_y = (w-box_w)/2, (h-box_h)/2
    
    -- Shop background
    love.graphics.setColor(0.1, 0.1, 0.1, 0.95)
    love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, 20, 20)
    
    -- Shop border
    love.graphics.setColor(0.4, 0.6, 1, 1) -- Blue border for level up
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", box_x, box_y, box_w, box_h, 20, 20)
    love.graphics.setLineWidth(1)
    
    -- Title
    love.graphics.setFont(shop_menu._fonts.header)
    love.graphics.setColor(0.4, 0.6, 1, 1) -- Blue color for level up
    love.graphics.printf("LEVEL UP!", box_x, box_y + 30, box_w, "center")
    
    -- Level display
    love.graphics.setFont(shop_menu._fonts.body)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("You reached level " .. shop_menu.current_level, box_x, box_y + 80, box_w, "center")
    
    -- Future shop items placeholder text
    love.graphics.printf("Future upgrades will appear here", box_x + 50, box_y + 150, box_w - 100, "center")
    
    -- Draw continue button
    local btn = shop_menu._continue_btn
    love.graphics.setColor(0.3, 0.5, 0.9, 1)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 10, 10)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(shop_menu._fonts.button)
    love.graphics.printf("CONTINUE", btn.x, btn.y + 12, btn.w, "center")
end

-- Handle mouse clicks on the shop menu
function shop_menu.mousepressed(x, y, button)
    if not shop_menu.active or button ~= 1 then return false end
    
    -- Check if continue button was clicked
    if shop_menu._continue_btn and mouse_in_box(x, y, shop_menu._continue_btn) then
        shop_menu.hide()
        return true
    end
    
    return false
end

-- Helper function to check if a point is inside a rectangle
function mouse_in_box(x, y, box)
    return x >= box.x and x <= box.x+box.w and y >= box.y and y <= box.y+box.h
end

return shop_menu
