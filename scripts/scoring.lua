-- scripts/scoring.lua: Handles all scoring logic for GrooveBound
local settings = require "settings"
local hud = require "scripts/hud"
local popup = require "scripts/popup"
local debug = require "scripts/debug" -- Add debug module for logging

local scoring = {}

-- Add XP to the player and show popup
function scoring.add_xp(x, y, amount)
    -- Initialize XP if not set
    local previous_xp = hud.xp or 0
    hud.xp = previous_xp + amount
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
    
    -- Check for level up based on thresholds in settings
    local old_level = scoring.get_level_for_xp(previous_xp)
    local new_level = scoring.get_level_for_xp(hud.xp)
    
    -- Debug info for level thresholds
    debug.log(string.format("XP: %d -> %d | Level: %d -> %d", 
                          previous_xp, hud.xp, old_level, new_level))
    
    if new_level > old_level then
        -- Level up detected - threshold has been crossed
        debug.log("LEVEL UP! " .. old_level .. " -> " .. new_level .. 
                 " (XP: " .. hud.xp .. " crossed threshold: " .. 
                 settings.xp.levels[new_level].threshold .. ")")
        
        hud.level = new_level
        scoring.trigger_level_up(new_level)
    end
end

-- Calculate player level based on XP thresholds
function scoring.get_level_for_xp(xp_amount)
    local xp_amount = xp_amount or 0
    local max_level = #settings.xp.levels
    
    -- Check thresholds from highest to lowest
    -- This ensures we get the correct level for the current XP
    for i = max_level, 1, -1 do
        if xp_amount >= settings.xp.levels[i].threshold then
            return settings.xp.levels[i].level
        end
    end
    
    return 1 -- Default to level 1 if no threshold matched
end

-- Get XP threshold needed for next level
function scoring.get_next_level_threshold(current_level)
    current_level = current_level or hud.level or 1
    
    -- Find the next level threshold in the settings
    for i, level_data in ipairs(settings.xp.levels) do
        if level_data.level > current_level then
            return level_data.threshold
        end
    end
    
    -- Max level reached - return highest threshold
    return settings.xp.levels[#settings.xp.levels].threshold
end

-- Get XP threshold for the current level
function scoring.get_current_level_threshold(current_level)
    current_level = current_level or hud.level or 1
    
    -- Find this level's threshold in the settings
    for i, level_data in ipairs(settings.xp.levels) do
        if level_data.level == current_level then
            return level_data.threshold
        end
    end
    
    -- Fallback to level 1
    return settings.xp.levels[1].threshold
end

-- Trigger level up and shop menu
function scoring.trigger_level_up(new_level)
    -- Create level up notification
    popup.create_notification("LEVEL UP! " .. new_level, popup.STYLES.MAIN, {0.4, 0.6, 1, 1})
    
    -- Get XP requirements for debug
    local current_threshold = scoring.get_current_level_threshold(new_level)
    local next_threshold = scoring.get_next_level_threshold(new_level)
    debug.log("Level " .. new_level .. " reached! XP: " .. hud.xp .. 
             " | Next level at: " .. next_threshold .. 
             " (need " .. (next_threshold - hud.xp) .. " more XP)")
    
    -- Activate the shop menu
    local shop_menu = require "scripts/shop_menu"
    shop_menu.show(new_level)
    
    -- Pause the game during level up
    _G.game_paused = true
end

-- Original scoring function, now enhanced to also add XP with proper scaling
function scoring.add_kill(is_groove, enemy_hp, enemy_x, enemy_y)
    -- Track kills
    hud.kills = (hud.kills or 0) + 1
    
    -- Add score points
    local pts = settings.main.scoring and (is_groove and settings.main.scoring.groove_kill_point or settings.main.scoring.kill_point) or (is_groove and 2 or 1)
    hud.score = (hud.score or 0) + pts
    
    -- Scale XP gain based on current wave and groove kills for better progression
    local current_wave = _G.current_wave or 1
    local base_xp = enemy_hp
    local wave_multiplier = math.max(1, current_wave / 2) -- Waves give more XP as you progress
    local groove_multiplier = is_groove and 1.5 or 1.0  -- 50% bonus for rhythm kills
    
    -- Calculate final XP with scaling
    local xp_gain = math.floor(base_xp * wave_multiplier * groove_multiplier)
    
    -- Debug info
    debug.log("XP gained: " .. xp_gain .. " (Wave " .. current_wave .. ", Groove: " .. tostring(is_groove) .. ")")
    
    -- Add the calculated XP
    scoring.add_xp(enemy_x, enemy_y, xp_gain)
end

return scoring
