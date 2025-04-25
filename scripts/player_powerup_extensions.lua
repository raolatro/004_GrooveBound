-- The following will be added to player.lua to support the new power-up system
-- This is a PREVIEW file that shows what will be added - it is not actually used

-- New player fields for power-up system
player.powerups = {}     -- Stores acquired power-ups: {id1 = true, id2 = true}
player.modifiers = {     -- Multipliers for all stats
    -- Global modifiers
    fire_rate = 1.0,     -- Multiplier for weapon fire rate
    damage = 1.0,        -- Multiplier for weapon damage
    projectile_speed = 1.0, -- Multiplier for projectile speed
    spread = 1.0,        -- Multiplier for weapon spread (lower is better)
    reload_time = 1.0,   -- Multiplier for reload time (lower is better)
    max_ammo = 1.0,      -- Multiplier for maximum ammo capacity
    cash_value = 1.0,    -- Multiplier for cash pickup value
    
    -- Special modifiers
    crit_chance = 0.0,   -- Chance to deal critical damage (0.0 to 1.0)
    pierce = 0,          -- Additional enemies that projectiles can hit
    ricochet_chance = 0.0, -- Chance to bounce off walls/enemies
    ricochet_bounces = 0, -- Number of bounces per shot if ricochet happens
    slow = 0.0,          -- Slow effect on hit (0.0 to 1.0)
    slow_duration = 0.0, -- Duration of slow effect in seconds
    chain_chance = 0.0,  -- Chance to chain to nearby enemies
    chain_targets = 0,   -- Number of additional targets for chain effect
    aoe_explosion = false, -- Whether kills create explosions
    aoe_radius = 0,      -- Radius of explosion
    aoe_damage = 0.0,    -- Damage multiplier for explosion
    vampirism = 0,       -- Damage needed to heal 1 HP
    free_ammo_chance = 0.0, -- Chance to not consume ammo
}

-- Category-specific modifiers
player.category_modifiers = {
    -- Will be populated for each category as needed
    -- Format: category_name = { fire_rate = 1.0, damage = 1.0, etc }
}

-- Weapon-specific modifiers
player.weapon_modifiers = {
    -- Will be populated for each weapon as needed  
    -- Format: weapon_id = { fire_rate = 1.0, damage = 1.0, etc }
}

-- Temporary modifiers with durations
player.temp_modifiers = {
    -- Format: { modifiers = {fire_rate = 1.2, etc}, end_time = time }
}

-- Check if player has a specific power-up
function player.has_powerup(id)
    return player.powerups[id] == true
end

-- Add a power-up to the player
function player.add_powerup(id, data)
    player.powerups[id] = true
    debug.log("[Player] Added power-up: " .. data.name)
    
    -- If it's a weapon level up, handle it specially
    if data.modifiers and data.modifiers.weapon_level_up then
        player.level_up_all_weapons(data.modifiers.weapon_level_up)
        return
    end
end

-- Apply global stat modifiers from a power-up
function player.apply_global_modifiers(modifiers)
    for stat, value in pairs(modifiers) do
        if player.modifiers[stat] ~= nil then
            -- Different handling for additive vs multiplicative stats
            if stat == "pierce" or stat == "ricochet_bounces" or stat == "chain_targets" 
               or stat == "aoe_radius" or stat == "vampirism" then
                -- Additive stats
                player.modifiers[stat] = player.modifiers[stat] + value
            elseif stat == "crit_chance" or stat == "ricochet_chance" or stat == "chain_chance" 
                   or stat == "slow" or stat == "free_ammo_chance" then
                -- Probability stats are capped at a maximum (usually 1.0)
                player.modifiers[stat] = math.min(1.0, player.modifiers[stat] + value)
            elseif stat == "aoe_explosion" then
                -- Boolean toggle
                player.modifiers[stat] = value
            else
                -- Multiplicative stats
                player.modifiers[stat] = player.modifiers[stat] * value
            end
            
            debug.log("[Player] Updated global modifier " .. stat .. " to " .. tostring(player.modifiers[stat]))
        end
    end
end

-- Apply category-specific modifiers
function player.apply_category_modifiers(category, modifiers)
    -- Initialize category if it doesn't exist
    if not player.category_modifiers[category] then
        player.category_modifiers[category] = {}
        for stat, default in pairs(player.modifiers) do
            if type(default) == "number" then
                player.category_modifiers[category][stat] = (stat == "pierce" or stat == "ricochet_bounces" 
                    or stat == "chain_targets" or stat == "aoe_radius" or stat == "vampirism") and 0 or 1.0
            elseif type(default) == "boolean" then
                player.category_modifiers[category][stat] = false
            end
        end
    end
    
    -- Apply modifiers to the category
    for stat, value in pairs(modifiers) do
        if player.category_modifiers[category][stat] ~= nil then
            -- Different handling for additive vs multiplicative stats
            if stat == "pierce" or stat == "ricochet_bounces" or stat == "chain_targets" 
               or stat == "aoe_radius" or stat == "vampirism" then
                -- Additive stats
                player.category_modifiers[category][stat] = player.category_modifiers[category][stat] + value
            elseif stat == "crit_chance" or stat == "ricochet_chance" or stat == "chain_chance" 
                   or stat == "slow" or stat == "free_ammo_chance" then
                -- Probability stats are capped at a maximum (usually 1.0)
                player.category_modifiers[category][stat] = math.min(1.0, player.category_modifiers[category][stat] + value)
            elseif stat == "aoe_explosion" then
                -- Boolean toggle
                player.category_modifiers[category][stat] = value
            else
                -- Multiplicative stats
                player.category_modifiers[category][stat] = player.category_modifiers[category][stat] * value
            end
            
            debug.log("[Player] Updated " .. category .. " modifier " .. stat .. " to " .. tostring(player.category_modifiers[category][stat]))
        end
    end
end

-- Apply weapon-specific modifiers
function player.apply_weapon_modifiers(weapon_id, modifiers)
    -- Initialize weapon if it doesn't exist
    if not player.weapon_modifiers[weapon_id] then
        player.weapon_modifiers[weapon_id] = {}
        for stat, default in pairs(player.modifiers) do
            if type(default) == "number" then
                player.weapon_modifiers[weapon_id][stat] = (stat == "pierce" or stat == "ricochet_bounces" 
                    or stat == "chain_targets" or stat == "aoe_radius" or stat == "vampirism") and 0 or 1.0
            elseif type(default) == "boolean" then
                player.weapon_modifiers[weapon_id][stat] = false
            end
        end
    end
    
    -- Apply modifiers to the weapon
    for stat, value in pairs(modifiers) do
        if player.weapon_modifiers[weapon_id][stat] ~= nil then
            -- Different handling for additive vs multiplicative stats
            if stat == "pierce" or stat == "ricochet_bounces" or stat == "chain_targets" 
               or stat == "aoe_radius" or stat == "vampirism" then
                -- Additive stats
                player.weapon_modifiers[weapon_id][stat] = player.weapon_modifiers[weapon_id][stat] + value
            elseif stat == "crit_chance" or stat == "ricochet_chance" or stat == "chain_chance" 
                   or stat == "slow" or stat == "free_ammo_chance" then
                -- Probability stats are capped at a maximum (usually 1.0)
                player.weapon_modifiers[weapon_id][stat] = math.min(1.0, player.weapon_modifiers[weapon_id][stat] + value)
            elseif stat == "aoe_explosion" then
                -- Boolean toggle
                player.weapon_modifiers[weapon_id][stat] = value
            else
                -- Multiplicative stats
                player.weapon_modifiers[weapon_id][stat] = player.weapon_modifiers[weapon_id][stat] * value
            end
            
            debug.log("[Player] Updated " .. weapon_id .. " modifier " .. stat .. " to " .. tostring(player.weapon_modifiers[weapon_id][stat]))
        end
    end
end

-- Apply temporary modifiers with duration
function player.apply_temp_modifiers(modifiers, duration)
    -- Create a new temporary modifier entry
    local end_time = love.timer.getTime() + duration
    table.insert(player.temp_modifiers, {
        modifiers = modifiers,
        end_time = end_time
    })
    
    debug.log("[Player] Applied temporary modifiers for " .. duration .. " seconds")
end

-- Get the effective modifier value for a stat based on weapon category and ID
function player.get_effective_modifier(stat, weapon_id, category)
    -- Start with the global modifier
    local value = player.modifiers[stat] or 1.0
    
    -- Apply category modifier if it exists
    if category and player.category_modifiers[category] and player.category_modifiers[category][stat] then
        if stat == "pierce" or stat == "ricochet_bounces" or stat == "chain_targets" 
           or stat == "aoe_radius" or stat == "vampirism" then
            -- Additive stats
            value = value + player.category_modifiers[category][stat]
        elseif stat == "aoe_explosion" then
            -- Boolean toggle (OR operation)
            value = value or player.category_modifiers[category][stat]
        else
            -- Multiplicative stats
            value = value * player.category_modifiers[category][stat]
        end
    end
    
    -- Apply weapon modifier if it exists
    if weapon_id and player.weapon_modifiers[weapon_id] and player.weapon_modifiers[weapon_id][stat] then
        if stat == "pierce" or stat == "ricochet_bounces" or stat == "chain_targets" 
           or stat == "aoe_radius" or stat == "vampirism" then
            -- Additive stats
            value = value + player.weapon_modifiers[weapon_id][stat]
        elseif stat == "aoe_explosion" then
            -- Boolean toggle (OR operation)
            value = value or player.weapon_modifiers[weapon_id][stat]
        else
            -- Multiplicative stats
            value = value * player.weapon_modifiers[weapon_id][stat]
        end
    end
    
    -- Apply temporary modifiers if they exist
    for _, temp in ipairs(player.temp_modifiers) do
        if temp.modifiers[stat] then
            if stat == "pierce" or stat == "ricochet_bounces" or stat == "chain_targets" 
               or stat == "aoe_radius" or stat == "vampirism" then
                -- Additive stats
                value = value + temp.modifiers[stat]
            elseif stat == "aoe_explosion" then
                -- Boolean toggle (OR operation)
                value = value or temp.modifiers[stat]
            else
                -- Multiplicative stats
                value = value * temp.modifiers[stat]
            end
        end
    end
    
    return value
end

-- Level up all weapons (used by Ultimate Upgrade)
function player.level_up_all_weapons(levels)
    levels = levels or 1
    local inventory = require "scripts/inventory"
    
    -- Apply level up to all active weapons
    for _, weapon in ipairs(inventory.get_active()) do
        weapon.level = (weapon.level or 1) + levels
        debug.log("[Player] Leveled up weapon " .. weapon.name .. " to level " .. weapon.level)
    end
    
    -- Visual feedback
    local popup = require "scripts/popup"
    popup.spawn({
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2 - 100,
        text = "All weapons leveled up!",
        color = {1, 0.1, 0.1, 1},  -- Red for ultimate upgrade
        font_size = 26,
        fade_duration = 0.5,
        stay_duration = 2.0,
        popup_type = popup.TYPES.NOTIFICATION
    })
end

-- Spend cash (returns true if successful)
function player.spend_cash(amount)
    local hud = require "scripts/hud"
    
    if not hud.cash or hud.cash < amount then
        return false
    end
    
    hud.cash = hud.cash - amount
    debug.log("[Player] Spent " .. amount .. " cash")
    return true
end

-- Update function to process temporary modifiers
function player.update_powerups(dt)
    -- Remove expired temporary modifiers
    local now = love.timer.getTime()
    for i = #player.temp_modifiers, 1, -1 do
        if player.temp_modifiers[i].end_time <= now then
            table.remove(player.temp_modifiers, i)
            debug.log("[Player] Removed expired temporary modifier")
        end
    end
end

-- Reset power-up system (new game)
function player.reset_powerups()
    player.powerups = {}
    
    -- Reset all modifiers to default values
    player.modifiers = {
        fire_rate = 1.0,
        damage = 1.0,
        projectile_speed = 1.0,
        spread = 1.0,
        reload_time = 1.0,
        max_ammo = 1.0,
        cash_value = 1.0,
        crit_chance = 0.0,
        pierce = 0,
        ricochet_chance = 0.0,
        ricochet_bounces = 0,
        slow = 0.0,
        slow_duration = 0.0,
        chain_chance = 0.0,
        chain_targets = 0,
        aoe_explosion = false,
        aoe_radius = 0,
        aoe_damage = 0.0,
        vampirism = 0,
        free_ammo_chance = 0.0,
    }
    
    player.category_modifiers = {}
    player.weapon_modifiers = {}
    player.temp_modifiers = {}
    
    debug.log("[Player] Reset all power-ups and modifiers")
end
