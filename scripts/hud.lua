-- hud.lua: In-game HUD for GrooveBound
-- Only the top bar HUD: hearts, weapon slots, score, kills, money, auto-fire and aim-line toggles

local settings = require "settings"
local inventory = require "scripts/inventory"
local paths = require "paths"
local hud = {}

-- Load and cache the main external font for all UI (HUD, popups, instructions)
hud.font_path = settings.main.fonts.path or "assets/font.ttf"
hud.font_size = settings.main.fonts.body or 24
function hud.load_fonts()
    hud.font = love.graphics.newFont(hud.font_path, hud.font_size)
    hud.font_instruction_size = math.floor(hud.font_size * 0.8)
    hud.font_instruction = love.graphics.newFont(hud.font_path, hud.font_instruction_size)
end
hud.load_fonts()

-- Resets all HUD values and state (call on restart)
function hud.reset()
    hud.score = 0
    hud.kills = 0
    hud.money = 0
    hud.auto_fire_enabled = false
    hud.aim_line_enabled = true
    hud.player_hp = nil
    hud.player_max_hp = nil
    -- Reset any font objects if needed
    hud.hp_img = love.graphics.newImage(paths.assets.hp)
    hud.hp_full_quad = love.graphics.newQuad(0,0,64,56,hud.hp_img:getDimensions())
    hud.hp_empty_quad = love.graphics.newQuad(64,0,64,56,hud.hp_img:getDimensions())
    -- Re-cache fonts on reset if needed
    hud.font = love.graphics.newFont(hud.font_path, hud.font_size)
    hud.font_instruction = love.graphics.newFont(hud.font_path, hud.font_instruction_size)
end

-- Initialize HUD state
hud.reset()

function hud.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local margin = 16
    local bar_height = 38
    local bar_width = w - 2 * margin -- Full width
    local heart_w, heart_h = 32, 28
    local n_hearts = tonumber(hud.player_max_hp) or 3
    local bar_x = margin
    local bar_y = margin

    -- [REMOVED] Pause overlay and text are now handled exclusively by pause_menu.lua. No legacy HUD overlay remains.

    -- Top left: HP hearts and inventory (drawn under overlay)
    local left_x = 16
    local left_y = 16
    local heart_box_width = n_hearts * heart_w + 24
    local heart_box_height = bar_height + 8
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", left_x, left_y, heart_box_width, heart_box_height, 10, 10)
    -- No outline around HP hearts box
    love.graphics.setColor(1,1,1,1)
    -- (Removed rectangle line for HP hearts box)
    for i=1,n_hearts do
        local x = left_x + 12 + (i-1)*heart_w
        local quad = (i <= (hud.player_hp or 0)) and hud.hp_full_quad or hud.hp_empty_quad
        love.graphics.draw(hud.hp_img, quad, x, left_y + 8, 0, heart_w/64, heart_h/56)
    end
    -- Inventory slots below hearts

    -- [REMOVED] Legacy pause toggles/overlay code fully deleted. All pause logic is handled by pause_menu.lua only.
    local slot_size = 28
    local slot_spacing = 8
    local max_slots = settings.inventory.max_slots or 4
    local slot_box_width = max_slots * (slot_size + slot_spacing) + 24
    local slot_box_x = left_x
    local slot_box_y = left_y + heart_box_height + 8
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", slot_box_x, slot_box_y, slot_box_width, slot_size + 16, 10, 10)
    -- No rectangle("line", ...) for slot box or items
    for idx = 1, max_slots do
        local x0 = slot_box_x + 12 + (idx-1)*(slot_size + slot_spacing)
        local y0 = slot_box_y + 8
        -- No border/rectangle for inventory item slot
        local s = inventory.slots[idx]
        if s then
            love.graphics.setColor(s.color or {1,1,1,1})
            love.graphics.circle("fill", x0 + slot_size/2, y0 + slot_size/2, slot_size/2 - 4)
            love.graphics.setColor(0,0,0,1)
            love.graphics.setFont(hud.font)
            love.graphics.printf(s.category:sub(1,1):upper(), x0, y0+slot_size/2-7, slot_size, "center")
        end
    end

    -- Top right: money, score, kills
    local right_box_width = 110
    local right_x = w - right_box_width - 16
    local right_y = 16
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", right_x, right_y, right_box_width, bar_height, 10, 10)
    love.graphics.setColor(1,1,0,1) -- yellow for money
    love.graphics.printf("Money: "..tostring(hud.money), right_x, right_y+8, right_box_width, "center")
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line", right_x, right_y, right_box_width, bar_height, 10, 10)
    local score_y = right_y + bar_height + 8
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", right_x, score_y, right_box_width, bar_height, 10, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Score: "..tostring(hud.score), right_x, score_y+8, right_box_width, "center")
    love.graphics.rectangle("line", right_x, score_y, right_box_width, bar_height, 10, 10)
    local kills_y = score_y + bar_height + 8
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", right_x, kills_y, right_box_width, bar_height, 10, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Kills: "..tostring(hud.kills), right_x, kills_y+8, right_box_width, "center")
    love.graphics.rectangle("line", right_x, kills_y, right_box_width, bar_height, 10, 10)

    -- [REMOVED] Pause toggles/overlay are now handled exclusively by pause_menu. This block is intentionally deleted for clarity and to prevent UI conflicts.


    -- Draw bottom-center instruction (always visible)
    local instruction_bar_width = 700
    local instruction_font = hud.font_instruction
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", w/2-instruction_bar_width/2, h-54, instruction_bar_width, 36, 10, 10)
    love.graphics.setColor(1,1,1,1)
    local prev_font = love.graphics.getFont()
    love.graphics.setFont(instruction_font)
    love.graphics.printf("Move: WASD   |   Aim: Mouse   |   Shoot: Left Click or Auto-Fire", w/2-instruction_bar_width/2+10, h-48, instruction_bar_width-20, "center")
    love.graphics.setFont(prev_font)
end

function hud.update(dt)
    -- No-op: HUD does not require update logic in minimal mode
end

function hud.mousepressed(x, y, button)
    -- No-op: HUD does not handle mouse input in minimal mode
end

return hud
