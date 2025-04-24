-- scripts/scoring.lua: Handles all scoring logic for GrooveBound
local settings = require "settings"
local hud = require "scripts/hud"
local popup = require "scripts/popup"

local scoring = {}

-- Add XP to the player and show popup
function scoring.add_xp(x, y, amount)
    -- Initialize XP if not set
    hud.xp = (hud.xp or 0) + amount
    hud.level = hud.level or 1
    
    -- Create XP gain popup with blue color
    popup.spawn({
        x = x,
        y = y,
        text = string.format(settings.popup.xp_text, amount),
        color = settings.popup.xp_color,
        font_size = 22,
        fade_duration = 0.8
    })
    
    -- Check for level up
    local current_level = scoring.get_level_for_xp(hud.xp - amount) -- Previous level
    local new_level = scoring.get_level_for_xp(hud.xp) -- New level after XP gain
    
    if new_level > current_level then
        -- Level up detected
        hud.level = new_level
        scoring.trigger_level_up(new_level)
    end
end

-- Calculate player level based on XP
function scoring.get_level_for_xp(xp_amount)
    local xp_amount = xp_amount or 0
    local max_level = #settings.xp.levels
    
    for i = max_level, 1, -1 do
        if xp_amount >= settings.xp.levels[i].threshold then
            return settings.xp.levels[i].level
        end
    end
    
    return 1 -- Default to level 1 if no threshold matched
end

-- Get XP needed for next level
function scoring.get_next_level_threshold(current_level)
    current_level = current_level or hud.level or 1
    
    for i, level_data in ipairs(settings.xp.levels) do
        if level_data.level > current_level then
            return level_data.threshold
        end
    end
    
    -- Max level reached
    return settings.xp.levels[#settings.xp.levels].threshold
end

-- Trigger level up and shop menu
function scoring.trigger_level_up(new_level)
    -- Create level up notification
    popup.create_notification("LEVEL UP! " .. new_level, popup.STYLES.MAIN, {0.4, 0.6, 1, 1})
    
    -- Activate the shop menu (will be implemented in shop_menu.lua)
    local shop_menu = require "scripts/shop_menu"
    shop_menu.show(new_level)
    
    -- Pause the game during level up
    _G.game_paused = true
end

-- Original scoring function, now enhanced to also add XP
function scoring.add_kill(is_groove, enemy_hp, enemy_x, enemy_y)
    -- Track kills
    hud.kills = (hud.kills or 0) + 1
    
    -- Add score points
    local pts = settings.main.scoring and (is_groove and settings.main.scoring.groove_kill_point or settings.main.scoring.kill_point) or (is_groove and 2 or 1)
    hud.score = (hud.score or 0) + pts
    
    -- Add XP equal to the enemy's spawning HP
    scoring.add_xp(enemy_x, enemy_y, enemy_hp)
end

return scoring
