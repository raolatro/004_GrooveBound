-- hud.lua: In-game HUD for GrooveBound
-- Only the top bar HUD: hearts, weapon slots, score, kills, money, auto-fire and aim-line toggles

local settings = require "settings"
local inventory = require "scripts/inventory"
local hud = {}

hud.score = 0
hud.kills = 0
hud.money = 0
hud.auto_fire_enabled = false
hud.aim_line_enabled = true
hud.player_hp = nil
hud.player_max_hp = nil

-- Heart sprite
local paths = require "paths"
hud.hp_img = hud.hp_img or love.graphics.newImage(paths.assets.hp)
hud.hp_full_quad = love.graphics.newQuad(0,0,64,56,hud.hp_img:getDimensions())
hud.hp_empty_quad = love.graphics.newQuad(64,0,64,56,hud.hp_img:getDimensions())

function hud.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local margin = 16
    local bar_height = 38
    local heart_w, heart_h = 32, 28
    local n_hearts = tonumber(hud.player_max_hp) or 3
    local bar_x = margin
    local bar_y = margin
    -- Draw hearts as sprites
    for i=1,n_hearts do
        local x = bar_x + (i-1)*heart_w
        local quad = (i <= (hud.player_hp or 0)) and hud.hp_full_quad or hud.hp_empty_quad
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(hud.hp_img, quad, x, bar_y, 0, heart_w/64, heart_h/56)
    end
    -- Weapons slots HUD
    do
        -- Draw weapon slots as a dynamic grid using inventory.slots (list)
        local slot_size = 28
        local slot_spacing = 8
        local max_slots = settings.inventory.max_slots or 4
        local slot_start_x = bar_x + n_hearts*heart_w + 24
        for idx = 1, max_slots do
            local x0 = slot_start_x + (idx-1)*(slot_size + slot_spacing)
            local y0 = bar_y + (bar_height - slot_size)/2
            love.graphics.setColor(1,1,1,1)
            love.graphics.rectangle("line", x0, y0, slot_size, slot_size, 6,6)
            local s = inventory.slots[idx]
            if s then
                love.graphics.setColor(s.color or {1,1,1,1})
                love.graphics.circle("fill", x0 + slot_size/2, y0 + slot_size/2, slot_size/2 - 4)
                -- Optionally: draw weapon icon or category letter
                love.graphics.setColor(0,0,0,1)
                love.graphics.printf(s.category:sub(1,1):upper(), x0, y0+slot_size/2-7, slot_size, "center")
            else
                -- Optionally: draw a faded icon for empty slot
            end
        end
    end
    local after_hearts_x = bar_x + n_hearts*heart_w + 24 + (28*4 + 8*3)
    -- Money HUD color matches popup text
    local money_color = settings.item_data and settings.item_data.Rarity and settings.item_data.Rarity.Common and settings.item_data.Rarity.Common.color or {1,1,0,1}
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", after_hearts_x, bar_y, 100, bar_height, 10, 10)
    love.graphics.setColor(money_color)
    love.graphics.printf("Money: "..tostring(hud.money), after_hearts_x, bar_y+8, 100, "center")
    love.graphics.setColor(1,1,1,1)
    local after_money_x = after_hearts_x + 100 + 12
    -- Score
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", after_money_x, bar_y, 100, bar_height, 10, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Score: "..tostring(hud.score), after_money_x, bar_y+8, 100, "center")
    local after_score_x = after_money_x + 100 + 12
    -- Kills
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", after_score_x, bar_y, 80, bar_height, 10, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Kills: "..tostring(hud.kills), after_score_x, bar_y+8, 80, "center")
    local after_kills_x = after_score_x + 80 + 12
    -- Auto-Fire toggle
    local af_width = 160
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", after_kills_x, bar_y, af_width, bar_height, 10, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Auto-Fire", after_kills_x+0, bar_y+8, af_width-36, "right")
    love.graphics.setColor(hud.auto_fire_enabled and {0,1,0,1} or {1,0,0,1})
    love.graphics.circle("fill", after_kills_x+af_width-20, bar_y+bar_height/2, 12)
    love.graphics.setColor(1,1,1,1)
    -- Aim Line toggle
    local aim_width = 160
    local aim_x = after_kills_x + af_width + 12
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", aim_x, bar_y, aim_width, bar_height, 10, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Aim Line", aim_x, bar_y+8, aim_width-36, "right")
    love.graphics.setColor(hud.aim_line_enabled and {0.9,0.9,0,1} or {0.5,0.5,0.2,1})
    love.graphics.circle("fill", aim_x+aim_width-20, bar_y+bar_height/2, 12)
    love.graphics.setColor(1,1,1,1)
    -- Draw bottom-center instruction (always visible)
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", w/2-230, h-54, 460, 36, 10, 10)
    love.graphics.setColor(1,1,1,1)
    local old_font = love.graphics.getFont()
    love.graphics.printf("Move: WASD   |   Aim: Mouse   |   Shoot: Left Click or Auto-Fire", w/2-220, h-48, 440, "center")
    love.graphics.setFont(old_font)
end

function hud.update(dt)
    -- No-op: HUD does not require update logic in minimal mode
end

function hud.mousepressed(x, y, button)
    -- No-op: HUD does not handle mouse input in minimal mode
end

return hud
