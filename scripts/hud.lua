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
    hud.cash = 0 -- Use cash instead of money for consistency with main.lua
    hud.xp = 0
    hud.level = 1
    hud.auto_fire_enabled = true
    hud.aim_line_enabled = false
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
    -- Top left: HP hearts and inventory (drawn under overlay)
    local left_x = 16
    local left_y = 16
    local heart_box_width = n_hearts * heart_w + 24
    local heart_box_height = bar_height + 8
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", left_x, left_y, heart_box_width, heart_box_height, 10, 10)
    love.graphics.setColor(1,1,1,1)
    for i=1,n_hearts do
        local x = left_x + 12 + (i-1)*heart_w
        local quad = (i <= (hud.player_hp or 0)) and hud.hp_full_quad or hud.hp_empty_quad
        love.graphics.draw(hud.hp_img, quad, x, left_y + 8, 0, heart_w/64, heart_h/56)
    end
    
    -- XP bar below hearts
    local xp_bar_height = settings.xp.bar_height
    local xp_box_height = xp_bar_height + 50 -- Increased bottom padding so XP text and bar are inside the same container box
    local xp_box_width = heart_box_width
    local xp_box_x = left_x
    local xp_box_y = left_y + heart_box_height + 12 -- Increased margin between hearts and XP bar
    
    -- XP bar background
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", xp_box_x, xp_box_y, xp_box_width, xp_box_height, 10, 10)
    
    -- Get current level and XP progress using the scoring module
    local scoring = require "scripts/scoring"
    local current_xp = hud.xp or 0
    local current_level = hud.level or 1
    
    -- Get the correct thresholds for the current level
    -- This will correctly show increasing thresholds (50, 100, 150, etc.) based on level
    local next_threshold = scoring.get_next_level_threshold(current_level)  
    local prev_threshold = scoring.get_current_level_threshold(current_level)
    
    -- Debug output to verify thresholds
    if hud.last_threshold_debug ~= current_level then
        hud.last_threshold_debug = current_level
        print(string.format("HUD: Level %d showing thresholds %d → %d (XP: %d)", 
                          current_level, prev_threshold, next_threshold, current_xp))
    end
    
    -- Calculate progress percentage for this level
    local xp_for_this_level = current_xp - prev_threshold
    local xp_needed_for_next = next_threshold - prev_threshold
    local progress = math.min(1, xp_for_this_level / math.max(1, xp_needed_for_next))
    
    -- Draw empty XP bar
    local xp_bar_x = xp_box_x + 12
    local xp_bar_y = xp_box_y + 10 -- Adjusted for better vertical centering
    local xp_bar_width = xp_box_width - 24
    love.graphics.setColor(settings.xp.empty_color)
    love.graphics.rectangle("fill", xp_bar_x, xp_bar_y, xp_bar_width, xp_bar_height, 5, 5)
    
    -- Draw filled portion of XP bar
    love.graphics.setColor(settings.xp.color)
    love.graphics.rectangle("fill", xp_bar_x, xp_bar_y, xp_bar_width * progress, xp_bar_height, 5, 5)
    
    -- Draw XP text with proper level-based thresholds
    love.graphics.setColor(1, 1, 1, 1)
    
    -- Format: "LVL X - Current/Target XP" with accurate values for each level
    -- Shows absolute XP values to ensure thresholds are increasing (e.g., 315/350 for Level 8)
    local xp_text = string.format("LVL %d - %d/%d XP", 
                                current_level, 
                                current_xp,     -- Show total accumulated XP
                                next_threshold) -- Show actual next threshold
    
    love.graphics.setFont(hud.font)
    love.graphics.printf(xp_text, xp_box_x, xp_bar_y + xp_bar_height + 16, xp_box_width, "center") -- Adjusted text offset for increased bottom padding
    
    -- Inventory slots below XP bar
    local slot_size = 28
    local slot_spacing = 8
    local max_slots = settings.inventory.max_slots or 4
    local slot_box_width = max_slots * (slot_size + slot_spacing) + 24
    local slot_box_x = left_x
    local slot_box_y = xp_box_y + xp_box_height + 14 -- Increased margin between XP bar and inventory
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", slot_box_x, slot_box_y, slot_box_width, slot_size + 16, 10, 10)
    for idx = 1, max_slots do
        local x0 = slot_box_x + 12 + (idx-1)*(slot_size + slot_spacing)
        local y0 = slot_box_y + 8
        local s = inventory.slots[idx]
        if s then
            -- Always use color from settings if available, fallback to slot color, else white
            local weapon_color = {1,1,1,1}
            if s.category and settings.weapons[s.category] and settings.weapons[s.category].color then
                weapon_color = settings.weapons[s.category].color
            elseif s.color then
                weapon_color = s.color
            end
            love.graphics.setColor(weapon_color)
            love.graphics.circle("fill", x0 + slot_size/2, y0 + slot_size/2, slot_size/2 - 4)
            love.graphics.setColor(0,0,0,1)
            love.graphics.setFont(hud.font)
            -- Show weapon level instead of first letter
            love.graphics.printf(tostring(s.level or 1), x0, y0+slot_size/2-7, slot_size, "center")
        end
    end

    -- Top right: money, score, kills
    local right_box_width = 110
    local right_x = w - right_box_width - 16
    local right_y = 16
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", right_x, right_y, right_box_width, bar_height, 10, 10)
    love.graphics.setColor(1,0.9,0,1) -- gold for cash
    love.graphics.printf("Cash: $"..tostring(hud.cash or 0), right_x, right_y+8, right_box_width, "center")
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

    -- Draw bottom-center instruction (always visible)
    local instruction_bar_width = 700
    local instruction_font = hud.font_instruction
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", w/2-instruction_bar_width/2, h-54, instruction_bar_width, 36, 10, 10)
    love.graphics.setColor(1,1,1,1)
    local prev_font = love.graphics.getFont()
    love.graphics.setFont(instruction_font)
    love.graphics.printf("Move: WASD or Arrows | Aim: Mouse | Shoot: Left Click | ESC: Pause & Settings", w/2-instruction_bar_width/2+10, h-48, instruction_bar_width-20, "center")
    love.graphics.setFont(prev_font)
end

function hud.update(dt)
    -- No-op: HUD does not require update logic in minimal mode
end

function hud.mousepressed(x, y, button)
    -- No-op: HUD does not handle mouse input in minimal mode
end

return hud
