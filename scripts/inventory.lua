-- scripts/inventory.lua: manage player weapons inventory
-- scripts/inventory.lua: Dynamic grid-based weapon inventory system
local settings = require "settings"
local inventory = {}

-- Initialize inventory slots as a list (grid)
function inventory.reset()
    inventory.slots = {}
    for i = 1, settings.inventory.max_slots do
        inventory.slots[i] = nil
    end
    -- Always add the pistol (forwardGun) as the starting weapon
    inventory.init_starting_weapons()
end

-- Add starting weapons to inventory (always include the pistol)
function inventory.init_starting_weapons()
    local debug = require "scripts/debug"
    
    -- First, try using inventory.add with item ID
    local data = settings.item_data and settings.item_data.Items
    if data and data.forwardGun then
        inventory.add("forwardGun", true) -- silent: don't show popup
        debug.log("Inventory: Added starting pistol via normal method")
    else
        -- Fallback: Manually add the pistol to the first slot
        inventory.slots[1] = {
            id = "forwardGun",
            category = "forward",
            type = "weapon",
            level = 1,
            damage = 1,
            color = {1,1,1,1}
        }
        debug.log("Inventory: Added starting pistol via fallback method")
    end
    
    -- Verify the pistol was added
    local has_pistol = false
    for _, slot in ipairs(inventory.slots) do
        if slot and slot.category == "forward" then
            has_pistol = true
            break
        end
    end
    
    if has_pistol then
        debug.log("Inventory: Successfully verified pistol in inventory")
    else
        debug.log("Inventory: WARNING - Failed to add starting pistol to inventory!")
    end
end

-- Helper: find index of slot by weapon category
function inventory.find_by_category(category)
    for i, slot in ipairs(inventory.slots) do
        if slot and slot.category == category then return i end
    end
    return nil
end

-- Add a weapon (itemId or item table) to inventory or level up existing weapon
-- The silent parameter suppresses notifications and sounds, useful for initial game load
function inventory.add(item, silent)
    local data = settings.item_data
    local debug = require "scripts/debug"
    local popup = require "scripts/popup"
    
    debug.log("Inventory: Adding item: " .. tostring(item and item.id or item))
    
    -- Handle case where a category string is passed directly (from level-up or shop menu)
    if type(item) == "string" and settings.weapons[item] then
        -- This is a weapon category! Create a valid weapon item
        debug.log("Inventory: Creating weapon from category: " .. item)
        item = {
            id = item .. "Gun", -- Convention: crossGun, dronesGun, etc.
            type = "weapon",
            category = item,
            level = 1,
            damage = settings.weapons[item][1] and settings.weapons[item][1].damage or 1
        }
    -- Otherwise try to look it up in item_data.Items
    elseif type(item) == "string" then
        debug.log("Inventory: Looking up item in settings.item_data.Items: " .. item)
        item = data.Items[item]
    end
    
    if not item or item.type ~= "weapon" then
        debug.log("Inventory: invalid or non-weapon item " .. tostring(item and item.id or item))
        return
    end
    
    debug.log("Inventory: Processing weapon: " .. item.category .. ", type: " .. item.type)
    
    -- Check if weapon of same category exists, attempt to level it up
    local idx = inventory.find_by_category(item.category)
    local player = require "scripts/player"

    -- If this is a new weapon (not in inventory), apply all relevant power-up effects
    if not idx then
        local weapon_id = item.id or item.category
        -- Apply all stacked power-up effects to this weapon
        for powerup_id, effect in pairs(player.powerup_effects or {}) do
            local data = require("data/powerups")[powerup_id]
            if data and data.modifiers then
                local count = effect.count or 1
                local scope = effect.targets or { type = "global" }
                for i = 1, count do
                    if scope.type == "global" then
                        player.apply_global_modifiers(data.modifiers)
                    elseif scope.type == "category" and scope.category == item.category then
                        player.apply_category_modifiers(scope.category, data.modifiers)
                    elseif scope.type == "weapon" and (scope.weapon == weapon_id or scope.weapon == item.category) then
                        player.apply_weapon_modifiers(weapon_id, data.modifiers)
                    end
                end
            end
        end
    end

    -- If we found an existing weapon, try to level it up
    if idx then
        local current_weapon = inventory.slots[idx]
        local current_level = current_weapon.level or 1
        local category = current_weapon.category
        local weapon_levels = settings.weapons[category]
        
        -- Check if next level exists
        if weapon_levels and current_level < #weapon_levels then
            -- Level up the weapon
            local new_level = current_level + 1
            current_weapon.level = new_level
            
            -- Apply any stats from the settings if needed
            -- (the actual stats are used from settings.weapons when firing)
            
            debug.log("Inventory: leveled up " .. category .. " weapon to level " .. new_level)
            
            -- Only show notification if not silent
            if not silent then
                -- Get weapon color and display name
                local weapon_color = {1, 1, 1, 1}
                local weapon_settings = settings.weapons[category]
                local display_name = weapon_settings and weapon_settings.display_name or category:gsub("^%l", string.upper)
                
                -- Use ONLY the weapon style for level up notification (no extra popups)
                popup.create_notification(display_name .. " LEVEL " .. new_level, popup.STYLES.WEAPON, weapon_color)
                
                -- Play weapon-specific level up sound
                local sfx = require "scripts/sfx"
                if sfx.play then
                    sfx.play('weapon_levelup', category)
                end
            end
            
            -- Trigger a visual effect or feedback for level-up
            return true, "level_up", category, new_level
        else
            debug.log("Inventory: " .. category .. " weapon already at max level (" .. current_level .. ")")
            
            -- Only show notification if not silent
            if not silent then
                -- Get weapon display name
                local weapon_settings = settings.weapons[category]
                local display_name = weapon_settings and weapon_settings.display_name or category:gsub("^%l", string.upper)
                
                -- Use the weapon style for max level notification with silver color
                popup.create_notification(display_name .. " MAXED OUT!", popup.STYLES.WEAPON, {0.8, 0.8, 0.8, 1})
            end
            
            return false, "max_level", category, current_level
        end
    end
    
    -- If not found, add to first empty slot
    for i = 1, settings.inventory.max_slots do
        if not inventory.slots[i] then
            inventory.slots[i] = item
            debug.log("Inventory: added " .. item.category .. " weapon to slot " .. i)
            return true, "added", item.category, item.level or 1
        end
    end
    
    debug.log("Inventory: all slots full, cannot add " .. item.id)
    return false, "full", nil, nil
end

-- Get all active (non-nil) weapons
function inventory.get_active()
    local weapons = {}
    for i, slot in ipairs(inventory.slots) do
        if slot then table.insert(weapons, slot) end
    end
    return weapons
end

-- Is inventory full?
function inventory.is_full()
    for i = 1, settings.inventory.max_slots do
        if not inventory.slots[i] then return false end
    end
    return true
end

-- Debug print
function inventory.debug_print()
    print("[DEBUG] Inventory slots:")
    for i, slot in ipairs(inventory.slots) do
        if slot then
            print(string.format("  [%d] %s (%s, lvl %d)", i, slot.id or "?", slot.category or "?", slot.level or 1))
        else
            print(string.format("  [%d] (empty)", i))
        end
    end
end

-- Initialize on load
inventory.reset()

return inventory
