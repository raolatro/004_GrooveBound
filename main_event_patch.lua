-- Patch: Add love.mousepressed and love.keypressed to main.lua
-- Ensures settings_menu receives events and hamburger menu works

local settings_menu = require "scripts/settings_menu"

function love.mousepressed(x, y, button)
    print('DEBUG: love.mousepressed called, forwarding to settings_menu')
    settings_menu.mousepressed(x, y, button)
    if settings_menu.active then return end
    -- (rest of your mouse handling logic here)
end

function love.keypressed(key)
    print('DEBUG: love.keypressed called, forwarding to settings_menu')
    if settings_menu.active then settings_menu.keypressed(key) return end
    -- (rest of your key handling logic here)
end
