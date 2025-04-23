-- level_stats.lua: Displays wave and boss info in a stacked outlined module at top center
local settings = require "settings"
local level_stats = {}

level_stats.wave = 1
level_stats.boss = nil

level_stats.font = nil

function level_stats.set_wave(wave)
    level_stats.wave = wave
end

function level_stats.set_boss(boss)
    level_stats.boss = boss
end

function level_stats.load_font(path, size)
    level_stats.font = love.graphics.newFont(path, size)
end

function level_stats.draw()
    -- Always center at top using current window width
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local box_width, box_height = 220, 70
    local box_x = math.floor((w - box_width) / 2 + 0.5)
    local box_y = 16
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", box_x, box_y, box_width, box_height, 10, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", box_x, box_y, box_width, box_height, 10, 10)
    love.graphics.setLineWidth(1)
    if level_stats.font then love.graphics.setFont(level_stats.font) end
    love.graphics.printf("Wave: "..tostring(level_stats.wave), box_x, box_y+12, box_width, "center")
    if level_stats.boss then
        love.graphics.setColor(1,0.8,0.2,1)
        love.graphics.printf("Mini-Boss: "..tostring(level_stats.boss), box_x, box_y+38, box_width, "center")
        love.graphics.setColor(1,1,1,1)
    end
end

return level_stats
