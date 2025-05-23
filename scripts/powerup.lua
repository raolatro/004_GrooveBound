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
    
    debug.log("[PowerUp] Initialization complete: " .. level_up_count .. " level-up items, " .. shop_count .. " shop items")
    
    -- Debug: Show first 5 items in level-up pool
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
        if weapon and weapon.category then
            debug.log("[PowerUp] Found player weapon: " .. weapon.category)
            player_weapons[weapon.category] = true
        end
    end
    
    -- Always mark the forward gun (pistol) as owned, since it's the starting weapon
    -- This ensures it never shows up in level-up options even if inventory is bugged
    player_weapons["forward"] = true
    debug.log("[PowerUp] Excluding pistol (forward) from level-up options")
    
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
        local weapon_desc = weapon.data.name or weapon.id
        debug.log("[PowerUp] Guaranteed weapon slot: " .. weapon_desc)
        table.insert(options, weapon)
        remaining_slots = remaining_slots - 1
    end
    
    -- Fill the rest with a mix of weapons and power-ups
    while remaining_slots > 0 do
        -- Determine what pool to pull from
        local total_pool_size = #weapons_available + #powerups_available
        if total_pool_size == 0 then break end
        
        -- Calculate weighted chance for a weapon (higher in early waves)
        local weapon_chance = 0.3 -- Default 30% chance for a weapon
        if wave > 0 and wave <= 4 then
            weapon_chance = 0.5 -- 50% chance in early waves
        end
        
        -- Adjust if one pool is empty
        if #weapons_available == 0 then 
            weapon_chance = 0
        elseif #powerups_available == 0 then
            weapon_chance = 1
        end
        
        -- Roll to determine what type we get
        local roll = math.random()
        local selected_item
        
        if roll < weapon_chance and #weapons_available > 0 then
            -- Select weapon
            local idx = math.random(#weapons_available)
            selected_item = weapons_available[idx]
            table.remove(weapons_available, idx)
        elseif #powerups_available > 0 then
            -- Select power-up
            local idx = math.random(#powerups_available)
            selected_item = powerups_available[idx]
            table.remove(powerups_available, idx)
        elseif #weapons_available > 0 then
            -- Fallback to weapons if powerups empty
            local idx = math.random(#weapons_available)
            selected_item = weapons_available[idx]
            table.remove(weapons_available, idx)
        else
            -- No more options
            break
        end
        
        table.insert(options, selected_item)
        remaining_slots = remaining_slots - 1
    end
    
    -- Log what we're offering
    for i, opt in ipairs(options) do
        local opt_type = opt.is_weapon and "weapon" or "powerup"
        debug.log("[PowerUp] Level up option " .. i .. ": " .. opt_type .. " - " .. opt.id)
    end
    
    -- De-duplicate options (ensure each unique weapon appears only once)
    local deduped = {}
    local unique = {}
    
    for _, opt in ipairs(options) do
        if opt.is_weapon then
            if not unique[opt.id] then
                unique[opt.id] = true
                table.insert(deduped, opt)
            end
        else
            table.insert(deduped, opt)
        end
    end
    debug.log("[PowerUp] Final level-up menu has " .. #deduped .. " unique options")
    return deduped
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
    
    -- Keep track of IDs to prevent duplicates
    local used_ids = {}
    
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
    if has_empty_slots then -- Only show weapons if player has slots
        for category, _ in pairs(all_weapon_categories) do
            if not player_weapons[category] then
                -- Create a weapon entry with a name and price
                local weapon_data = settings_data.weapons[category]
                local display_name = weapon_data.display_name or category:gsub("^%l", string.upper)
                local price = (settings_data.shop and settings_data.shop.weapon_prices and settings_data.shop.weapon_prices[category]) or 150
                
                -- Add this weapon to the available pool
                table.insert(weapons_available, {
                    id = category,
                    price = price,
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
                local weight = powerup.get_rarity_weight(data.rarity)
                if data.rarity == "legendary" or data.rarity == "extremely_legendary" then
                    weight = weight * 2 -- Double weight for legendary items in shop
                end
                
                -- Get price from a variety of sources
                local price = 0
                if data.price then
                    -- If powerup has defined price
                    price = data.price
                elseif settings_data.shop and settings_data.shop.prices and settings_data.shop.prices[data.rarity] then
                    -- If settings has prices by rarity
                    price = settings_data.shop.prices[data.rarity]
                else
                    -- Fallback default prices based on rarity
                    local rarity_prices = {
                        common = 50,
                        uncommon = 100,
                        rare = 150,
                        epic = 250,
                        legendary = 500,
                        extremely_legendary = 1000
                    }
                    price = rarity_prices[data.rarity] or 100
                end
                
                for i = 1, weight do
                    table.insert(powerups_available, {id = id, data = data, price = price})
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
        -- Add weapons to the start of the shop
        for i = 1, weapon_count do
            if #weapons_available == 0 then break end
            local idx = math.random(#weapons_available)
            local weapon = weapons_available[idx]
            table.remove(weapons_available, idx)
            
            -- Skip this weapon if it was already added (using ID as key)
            if used_ids[weapon.id] then
                i = i - 1 -- Try again
            else
                used_ids[weapon.id] = true
                table.insert(options, weapon)
            end
        end
    end
    
    -- Fill the rest with power-ups
    while #options < max_items and #powerups_available > 0 do
        local idx = math.random(#powerups_available)
        local powerup_option = powerups_available[idx]
        table.remove(powerups_available, idx)
        
        -- Skip duplicates
        if used_ids[powerup_option.id] then
            -- Skip this power-up
        else
            used_ids[powerup_option.id] = true
            table.insert(options, powerup_option)
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
    if settings.powerups and settings.powerups.weights and settings.powerups.weights[rarity] then
        return settings.powerups.weights[rarity]
    end
    
    -- Default weights by rarity
    local weights = {
        common = 80,
        uncommon = 60,
        rare = 40,
        epic = 20,
        legendary = 10,
        extremely_legendary = 1
    }
    
    return weights[rarity] or 50
end

-- Acquire a power-up (permanent effect)
function powerup.acquire(id, free)
    if not id then 
        debug.log("[PowerUp] Attempted to acquire nil power-up")
        return false
    end
    
    local data = powerup.data and powerup.data[id]
    if not data then
        debug.log("[PowerUp] Unable to acquire power-up " .. id .. " - data not found")
        return false
    end
    
    -- If it's not free, check player cash
    if not free then
        -- Get price, falling back to defaults
        local price = data.price or (data.rarity and settings.shop and settings.shop.prices and settings.shop.prices[data.rarity]) or 100
        
        -- Attempt to spend cash
        local hud = require "scripts/hud"
        local player_cash = hud.cash or 0
        if player_cash < price then
            debug.log("[PowerUp] Not enough cash to acquire " .. id .. " (need " .. price .. ", have " .. player_cash .. ")")
            return false, "not_enough_cash", price
        end
        
        hud.cash = player_cash - price
        debug.log("[PowerUp] Spent " .. price .. " cash to acquire " .. id)
    end
    
    -- Apply the power-up to the player
    player.add_powerup(id, data)
    
    -- Trigger power-up effect and visual feedback
    powerup.apply_effect(id, data)
    
    debug.log("[PowerUp] Acquired " .. id .. " (" .. (data.name or "unnamed") .. ")")
    return true
end

-- Apply a one-time power-up effect, with associated particle/UI feedback
function powerup.apply_effect(id, data)
    if not data then
        data = powerup.data and powerup.data[id]
        if not data then
            debug.log("[PowerUp] Cannot apply effect for " .. id .. " - data not found")
            return false
        end
    end
    
    -- Create visual effect based on rarity
    local color = powerup.get_rarity_color(data.rarity)
    
    -- Create floating notification
    popup.spawn({
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2 - 50,
        text = data.name,
        color = color,
        font_size = 24,
        fade_duration = 0.3,
        stay_duration = 1.5,
        popup_type = popup.TYPES.NOTIFICATION
    })
    
    -- Play sound effect based on rarity
    if sfx and sfx.play then
        local sound_name = "powerup"
        if data.rarity == "legendary" or data.rarity == "extremely_legendary" then
            sound_name = "powerup_legendary"
        end
        sfx.play(sound_name)
    end
    
    return true
end

-- Register a trigger for event-based power-ups
function powerup.register_trigger(trigger_type, id, data)
    -- Ensure the trigger list exists
    if not powerup.active_triggers[trigger_type] then
        powerup.active_triggers[trigger_type] = {}
    end
    
    -- Add the trigger
    table.insert(powerup.active_triggers[trigger_type], {
        id = id,
        data = data,
        cooldown = data.cooldown or 5.0, -- Default 5 second cooldown
        last_trigger = 0,
        active = false,
        activation_time = 0
    })
    
    debug.log("[PowerUp] Registered trigger: " .. trigger_type .. " for " .. id)
end

-- Process "on_hit" triggers
function powerup.on_hit(hit_enemy, projectile)
    -- Process on-hit triggers
    if powerup.active_triggers["on_hit"] then
        for _, trigger in ipairs(powerup.active_triggers["on_hit"]) do
            if love.timer.getTime() - trigger.last_trigger > trigger.cooldown then
                local data = trigger.data
                local chance = data.trigger_chance or 0.1 -- Default 10% chance
                
                -- Roll for trigger
                if math.random() < chance then
                    trigger.last_trigger = love.timer.getTime()
                    
                    -- Activate the effect
                    powerup.activate_triggered_effect(trigger)
                end
            end
        end
    end
end

-- Process "on_kill" triggers
function powerup.on_kill(killed_enemy, killed_on_beat)
    -- Process on-kill triggers
    if powerup.active_triggers["on_kill"] then
        for _, trigger in ipairs(powerup.active_triggers["on_kill"]) do
            if love.timer.getTime() - trigger.last_trigger > trigger.cooldown then
                local data = trigger.data
                local chance = data.trigger_chance or 0.2 -- Default 20% chance
                
                -- Check for on-beat condition if required
                if data.require_on_beat and not killed_on_beat then
                    -- Skip if on-beat required but kill wasn't on beat
                else
                    -- Roll for trigger
                    if math.random() < chance then
                        trigger.last_trigger = love.timer.getTime()
                        
                        -- Activate the effect
                        powerup.activate_triggered_effect(trigger)
                    end
                end
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
    -- Use colors from settings if available
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
