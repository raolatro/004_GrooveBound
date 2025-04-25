-- scripts/powerup.lua
-- Manages power-up acquisition, application, and effect processing

local settings = require "settings"
local debug = require "scripts/debug"
local player = require "scripts/player"
local popup = require "scripts/popup"
local sfx = require "scripts/sfx"

local powerup = {}

-- Load all power-up data
powerup.data = require "data/powerups"

-- Initialize power-up pools
powerup.level_up_pool = {}
powerup.shop_pool = {}

-- Track currently active powerups and their effects
powerup.active_effects = {}
powerup.active_triggers = {}

-- Called on game init to prepare pools
function powerup.init()
    debug.log("[PowerUp] Starting initialization...")
    -- Make sure we have access to the powerup data
    if not powerup.data then
        powerup.data = require "data/powerups"
        debug.log("[PowerUp] Loaded power-up data: " .. powerup.count_items(powerup.data) .. " power-ups found")
    end

    -- Separate power-ups into appropriate pools
    powerup.level_up_pool = {}
    powerup.shop_pool = {}
    
    -- Check that we have powerup data before proceeding
    if not powerup.data or type(powerup.data) ~= "table" then
        debug.log("[PowerUp] ERROR: Could not load power-up data!")
        return
    end
    
    -- Count how many items will be in each pool for debugging
    local level_up_count = 0
    local shop_count = 0
    
    for id, data in pairs(powerup.data) do
        -- Add to shop pool
        powerup.shop_pool[id] = data
        shop_count = shop_count + 1
        
        -- Add to level-up pool if not shop_only
        if not data.shop_only then
            powerup.level_up_pool[id] = data
            level_up_count = level_up_count + 1
        end
    end
    
    -- Reset active effects
    powerup.active_effects = {}
    powerup.active_triggers = {}
    
    debug.log("[PowerUp] Initialization complete: " .. level_up_count .. 
              " level-up power-ups and " .. shop_count .. " shop power-ups")
              
    -- For debugging, print out the first few level-up power-ups
    local count = 0
    for id, data in pairs(powerup.level_up_pool) do
        debug.log("[PowerUp] Level-up pool item: " .. id .. " (" .. data.name .. ")")
        count = count + 1
        if count >= 5 then break end
    end
end

-- Count items in a table
function powerup.count_items(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Roll random power-ups for level up menu (old version, kept for compatibility)
-- Returns a table of {id, data} pairs
function powerup.roll_level_up_options(count)
    return powerup.roll_enhanced_level_up_options(count, 0) -- Pass 0 as wave to get original behavior
end

-- Enhanced version that includes weapons in the level-up pool
-- wave: current wave number, affects weapon probability
-- Returns a table of {id, data, is_weapon} to distinguish weapons and power-ups
function powerup.roll_enhanced_level_up_options(count, wave)
    count = count or 3
    wave = wave or 0
    local options = {}
    local weapons_available = {}
    local powerups_available = {}
    local inventory = require "scripts/inventory"
    local settings_data = require "settings"
    
    debug.log("[PowerUp] Rolling enhanced level up options, count: " .. count .. ", wave: " .. wave)
    
    -- Check if player is missing any weapons
    local player_weapons = {}
    for _, weapon in ipairs(inventory.get_active() or {}) do
        player_weapons[weapon.category] = true
    end
    
    -- Get all available weapons from settings
    local all_weapon_categories = {}
    for category, _ in pairs(settings_data.weapons or {}) do
        all_weapon_categories[category] = true
    end
    
    -- First, collect all unowned weapons into the weapon pool
    for category, _ in pairs(all_weapon_categories) do
        if not player_weapons[category] then
            -- Create a weapon entry with a name and description
            local weapon_data = settings_data.weapons[category]
            local display_name = weapon_data.display_name or category:gsub("^%l", string.upper)
            
            -- Determine weapon weight based on wave
            local weapon_weight = 40 -- Base "Rare" weight
            
            -- Early waves (1-4): Higher probability of weapons
            if wave > 0 and wave <= 4 then
                weapon_weight = weapon_weight * 2 -- Double weight for early waves
            elseif wave > 4 then
                weapon_weight = weapon_weight * 0.5 -- Half weight after wave 4
            end
            
            debug.log("[PowerUp] Adding unowned weapon: " .. category .. " with weight " .. weapon_weight)
            
            for i = 1, weapon_weight do
                table.insert(weapons_available, {
                    id = category,
                    data = {
                        name = display_name,
                        description = "New weapon: " .. display_name,
                        rarity = "rare", -- All weapons are classified as "Rare"
                        is_weapon = true,
                        category = category
                    }
                })
            end
        end
    end
    
    -- Now collect power-ups into a separate pool
    for id, data in pairs(powerup.level_up_pool) do
        -- Skip power-ups the player already has if they're non-stackable
        if not data.stackable and player and player.has_powerup and player.has_powerup(id) then
            debug.log("[PowerUp] Skipping " .. id .. " because player already has it")
            -- Skip this power-up
        else
            -- Weight by rarity
            local weight = powerup.get_rarity_weight(data.rarity)
            for i = 1, weight do
                table.insert(powerups_available, {id = id, data = data})
            end
        end
    end
    
    -- Debug logging
    debug.log("[PowerUp] Available weapons: " .. #weapons_available)
    debug.log("[PowerUp] Available power-ups: " .. #powerups_available)
    
    -- If weapons and power-ups both empty, return empty table
    if #weapons_available == 0 and #powerups_available == 0 then
        debug.log("[PowerUp] No options available for level up")
        return {}
    end
    
    -- For waves 1-4, ensure at least one weapon if any are available
    local guarantee_weapon = (wave > 0 and wave <= 4 and #weapons_available > 0)
    
    -- Select random options from both pools
    local remaining_slots = count
    
    -- If we need to guarantee a weapon, add one first
    if guarantee_weapon then
        local idx = math.random(#weapons_available)
        local weapon = weapons_available[idx]
        weapon.is_weapon = true -- Mark as weapon for the UI
        table.insert(options, weapon)
        table.remove(weapons_available, idx)
        remaining_slots = remaining_slots - 1
        debug.log("[PowerUp] Guaranteed weapon slot filled with: " .. weapon.id)
    end
    
    -- Create a combined pool of remaining weapons and power-ups
    local combined_pool = {}
    for _, item in ipairs(weapons_available) do
        item.is_weapon = true
        table.insert(combined_pool, item)
    end
    for _, item in ipairs(powerups_available) do
        item.is_weapon = false
        table.insert(combined_pool, item)
    end
    
    -- Fill remaining slots randomly
    for i = 1, math.min(remaining_slots, #combined_pool) do
        local idx = math.random(#combined_pool)
        table.insert(options, combined_pool[idx])
        table.remove(combined_pool, idx)
    end
    
    debug.log("[PowerUp] Final level-up menu has " .. #options .. " options")
    return options
end

-- Roll random power-ups for shop menu (legacy version for compatibility)
-- Returns a table of {id, data} pairs
function powerup.roll_shop_options(count, allow_levelup_items)
    return powerup.roll_enhanced_shop_options(count, allow_levelup_items, 5) -- Max 5 items by default
end

-- Enhanced version that includes weapons in the shop menu and supports pagination
-- Returns a table of {id, data, is_weapon} pairs with maximum 'max_items' entries
function powerup.roll_enhanced_shop_options(count, allow_levelup_items, max_items)
    count = count or 3
    allow_levelup_items = allow_levelup_items ~= false -- default to true
    max_items = max_items or 5 -- Default max items per shop
    
    local options = {}
    local weapons_available = {}
    local powerups_available = {}
    local inventory = require "scripts/inventory"
    local settings_data = require "settings"
    
    debug.log("[PowerUp] Rolling enhanced shop options, count: " .. count)
    
    -- Check if player is missing any weapons
    local player_weapons = {}
    for _, weapon in ipairs(inventory.get_active() or {}) do
        player_weapons[weapon.category] = true
    end
    
    -- See if player has empty weapon slots
    local has_empty_slots = not inventory.is_full()
    
    -- Get all available weapons from settings
    local all_weapon_categories = {}
    for category, _ in pairs(settings_data.weapons or {}) do
        all_weapon_categories[category] = true
    end
    
    -- First, collect all unowned weapons into the weapon pool
    for category, _ in pairs(all_weapon_categories) do
        if not player_weapons[category] then
            -- Create a weapon entry with name, description and shop price
            local weapon_data = settings_data.weapons[category]
            local display_name = weapon_data.display_name or category:gsub("^%l", string.upper)
            
            -- Set a base shop price for weapons (can be adjusted based on weapon power)
            local weapon_price = 300 -- Base price for all weapons
            
            debug.log("[PowerUp] Adding unowned weapon to shop: " .. category)
            
            table.insert(weapons_available, {
                id = category,
                data = {
                    name = display_name,
                    description = "New weapon: " .. display_name,
                    rarity = "rare", -- All weapons are "Rare"
                    is_weapon = true,
                    category = category,
                    cost = weapon_price
                }
            })
        end
    end
    
    -- Now collect power-ups for the shop pool
    for id, data in pairs(powerup.shop_pool) do
        -- Skip power-ups the player already has if they're non-stackable
        if not data.stackable and player and player.has_powerup and player.has_powerup(id) then
            debug.log("[PowerUp] Skipping shop item " .. id .. " because player already has it")
        else
            -- Skip level-up items if not allowed
            if not allow_levelup_items and not data.shop_only then
                -- Skip non-shop items
            else
                -- Weight by rarity (legendary appears more in shop)
                local weight = powerup.get_shop_rarity_weight(data.rarity)
                for i = 1, weight do
                    table.insert(powerups_available, {id = id, data = data})
                end
            end
        end
    end
    
    -- Debug logging
    debug.log("[PowerUp] Available shop weapons: " .. #weapons_available)
    debug.log("[PowerUp] Available shop power-ups: " .. #powerups_available)
    
    -- If weapons and power-ups both empty, return empty table
    if #weapons_available == 0 and #powerups_available == 0 then
        debug.log("[PowerUp] No options available for shop")
        return {}
    end
    
    -- Ensure at least 2 weapons if player has empty slots and weapons are available
    local weapon_count = math.min(2, #weapons_available)
    if has_empty_slots and weapon_count > 0 then
        -- Add at least 2 weapons (or as many as available) to ensure player can get weapons
        for i = 1, weapon_count do
            if #weapons_available > 0 then
                local idx = math.random(#weapons_available)
                local weapon = weapons_available[idx]
                weapon.is_weapon = true -- Mark as weapon for the UI
                table.insert(options, weapon)
                table.remove(weapons_available, idx)
                debug.log("[PowerUp] Guaranteed weapon slot filled with: " .. weapon.id)
            end
        end
    end
    
    -- Create a combined pool of remaining weapons and power-ups
    local combined_pool = {}
    for _, item in ipairs(weapons_available) do
        item.is_weapon = true
        table.insert(combined_pool, item)
    end
    for _, item in ipairs(powerups_available) do
        item.is_weapon = false
        table.insert(combined_pool, item)
    end
    
    -- Fill remaining slots randomly up to max_items total
    local remaining_slots = math.min(max_items - #options, #combined_pool)
    for i = 1, remaining_slots do
        if #combined_pool > 0 then
            local idx = math.random(#combined_pool)
            table.insert(options, combined_pool[idx])
            table.remove(combined_pool, idx)
        end
    end
    
    -- Always add Ultimate Upgrade if it's a post-boss shop
    if allow_levelup_items and #options < max_items then
        -- Find the ultimate upgrade
        for id, data in pairs(powerup.shop_pool) do
            if data.rarity == "extremely_legendary" then
                -- Add it to the options
                table.insert(options, {id = id, data = data, is_weapon = false})
                
                break
            end
        end
    end
    
    return options
end

-- Get weight multiplier based on rarity for level-up rolls
function powerup.get_rarity_weight(rarity)
    -- Use weights from settings if available, otherwise use defaults
    if settings.powerups and settings.powerups.level_up_weights and settings.powerups.level_up_weights[rarity] then
        return settings.powerups.level_up_weights[rarity]
    end
    
    -- Fallback default weights
    local weights = {
        common = 10,
        uncommon = 8,
        rare = 5,
        epic = 3,
        legendary = 1,
        extremely_legendary = 0 -- Never in level-up menu
    }
    return weights[rarity] or 0
end

-- Get weight multiplier based on rarity for shop rolls
function powerup.get_shop_rarity_weight(rarity)
    -- Use weights from settings if available, otherwise use defaults
    if settings.powerups and settings.powerups.shop_weights and settings.powerups.shop_weights[rarity] then
        return settings.powerups.shop_weights[rarity]
    end
    
    -- Fallback default weights
    local weights = {
        common = 1,
        uncommon = 2,
        rare = 3,
        epic = 4,
        legendary = 5,
        extremely_legendary = 0 -- Special handling for extremely legendary
    }
    return weights[rarity] or 0
end

-- Apply a power-up to the player
function powerup.acquire(id, free)
    free = free or false
    local data = powerup.data[id]
    
    if not data then
        debug.log("[PowerUp] Error: tried to acquire unknown power-up " .. tostring(id))
        return false
    end
    
    -- If not free, check and deduct cash
    if not free then
        local cost = data.cost or 0
        if cost > 0 and (not player.spend_cash or not player.spend_cash(cost)) then
            debug.log("[PowerUp] Not enough cash to acquire " .. data.name)
            return false
        end
    end
    
    -- Add to player's acquired power-ups
    player.add_powerup(id, data)
    
    -- Show acquisition popup
    popup.spawn({
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2 - 100,
        text = "Acquired: " .. data.name,
        color = powerup.get_rarity_color(data.rarity),
        font_size = 24,
        fade_duration = 0.5,
        stay_duration = 1.5,
        popup_type = popup.TYPES.NOTIFICATION
    })
    
    -- Play acquisition sound
    sfx.play("powerup_acquire")
    
    -- Apply modifiers based on scope type
    powerup.apply_modifiers(id, data)
    
    debug.log("[PowerUp] Acquired " .. data.name)
    return true
end

-- Apply power-up modifiers based on scope
function powerup.apply_modifiers(id, data)
    if not data.scope then return end
    
    -- Store in active effects for triggering
    if data.scope.type == "triggered" then
        powerup.register_trigger(id, data)
    end
    
    -- Apply immediate stat modifiers based on scope
    if data.scope.type == "global" then
        -- Apply to all weapons
        player.apply_global_modifiers(data.modifiers)
    elseif data.scope.type == "category" then
        -- Apply to specific weapon category(ies)
        local categories = data.scope.category
        if type(categories) == "string" then
            categories = {categories}
        end
        
        for _, category in ipairs(categories) do
            player.apply_category_modifiers(category, data.modifiers)
        end
    elseif data.scope.type == "weapon" then
        -- Apply to specific weapon
        local weapon_id = data.scope.weapon_id
        player.apply_weapon_modifiers(weapon_id, data.modifiers)
    end
end

-- Register a trigger-based power-up
function powerup.register_trigger(id, data)
    if not data.scope or data.scope.type ~= "triggered" or not data.scope.trigger then
        return
    end
    
    local trigger_type = data.scope.trigger
    
    if not powerup.active_triggers[trigger_type] then
        powerup.active_triggers[trigger_type] = {}
    end
    
    table.insert(powerup.active_triggers[trigger_type], {
        id = id,
        data = data,
        active = false,
        activation_time = 0,
        cooldown = data.cooldown or 0,
        last_trigger = 0,
        streak_counter = 0
    })
end

-- Handle on-kill trigger checks
function powerup.on_kill(killed_enemy, killed_on_beat)
    -- Process on-kill triggers
    if powerup.active_triggers["on_kill"] then
        for _, trigger in ipairs(powerup.active_triggers["on_kill"]) do
            if love.timer.getTime() - trigger.last_trigger > trigger.cooldown then
                trigger.last_trigger = love.timer.getTime()
                -- Apply the effect
                powerup.activate_triggered_effect(trigger)
            end
        end
    end
    
    -- Process on-beat-kill triggers
    if killed_on_beat and powerup.active_triggers["on_beat_kill"] then
        for _, trigger in ipairs(powerup.active_triggers["on_beat_kill"]) do
            if love.timer.getTime() - trigger.last_trigger > trigger.cooldown then
                trigger.last_trigger = love.timer.getTime()
                -- Apply the effect
                powerup.activate_triggered_effect(trigger)
            end
        end
    end
    
    -- Process kill streak triggers
    if powerup.active_triggers["on_kill_streak"] then
        for _, trigger in ipairs(powerup.active_triggers["on_kill_streak"]) do
            trigger.streak_counter = trigger.streak_counter + 1
            if trigger.streak_counter >= (trigger.data.scope.streak or 5) then
                trigger.streak_counter = 0
                -- Apply the effect
                powerup.activate_triggered_effect(trigger)
            end
        end
    end
end

-- Activate a triggered effect
function powerup.activate_triggered_effect(trigger)
    local data = trigger.data
    
    -- Skip if already active and not stackable
    if trigger.active and not data.stackable then
        return
    end
    
    -- Set active state
    trigger.active = true
    trigger.activation_time = love.timer.getTime()
    
    -- Apply temporary modifiers
    if data.modifiers then
        -- Apply temporary modifiers through the player module
        player.apply_temp_modifiers(data.modifiers, data.modifiers.duration or 3.0)
        
        -- Show effect activation popup
        popup.spawn({
            x = love.graphics.getWidth() / 2,
            y = love.graphics.getHeight() / 2 - 50,
            text = data.name .. " activated!",
            color = powerup.get_rarity_color(data.rarity),
            font_size = 20,
            fade_duration = 0.3,
            stay_duration = 1.0,
            popup_type = popup.TYPES.NOTIFICATION
        })
        
        -- Play activation sound
        sfx.play("powerup_activate")
    end
end

-- Update function for time-based effects
function powerup.update(dt)
    -- Update triggered effects
    for trigger_type, triggers in pairs(powerup.active_triggers) do
        for i, trigger in ipairs(triggers) do
            if trigger.active then
                local duration = trigger.data.modifiers.duration or 3.0
                if love.timer.getTime() - trigger.activation_time > duration then
                    -- Deactivate effect
                    trigger.active = false
                end
            end
        end
    end
end

-- Get color based on rarity for UI
function powerup.get_rarity_color(rarity)
    -- Use colors from settings if available, otherwise use defaults
    if settings.powerups and settings.powerups.colors and settings.powerups.colors[rarity] then
        return settings.powerups.colors[rarity]
    end
    
    -- Fallback default colors
    local colors = {
        common = {0.7, 0.7, 0.7, 1},       -- Gray
        uncommon = {0.0, 0.7, 0.0, 1},     -- Green
        rare = {0.0, 0.4, 0.9, 1},         -- Blue
        epic = {0.7, 0.2, 0.9, 1},         -- Purple
        legendary = {1.0, 0.6, 0.0, 1},    -- Orange
        extremely_legendary = {1.0, 0.1, 0.1, 1} -- Red
    }
    return colors[rarity] or {1, 1, 1, 1}
end

-- Reset all power-ups (new game)
function powerup.reset()
    powerup.active_effects = {}
    powerup.active_triggers = {}
    debug.log("[PowerUp] Reset all power-ups")
end

return powerup
