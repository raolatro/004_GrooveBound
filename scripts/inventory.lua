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
end

-- Helper: find index of slot by weapon category
function inventory.find_by_category(category)
    for i, slot in ipairs(inventory.slots) do
        if slot and slot.category == category then return i end
    end
    return nil
end

-- Add a weapon (itemId or item table) to inventory or level up existing weapon
function inventory.add(item)
    local data = settings.item_data
    local debug = require "scripts/debug"
    local popup = require "scripts/popup"
    
    -- Accept either itemId or item table
    if type(item) == "string" then
        item = data.Items[item]
    end
    
    if not item or item.type ~= "weapon" then
        debug.log("Inventory: invalid or non-weapon item " .. tostring(item and item.id or item))
        return
    end
    
    -- Check if weapon of same category exists, attempt to level it up
    local idx = inventory.find_by_category(item.category)
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
            
            -- Create centered popup for weapon level-up
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            
            -- Get weapon color (default to white if not found)
            local weapon_color = {1, 1, 1, 1}
            if data.Items[category .. "Gun"] and data.Items[category .. "Gun"].color then
                weapon_color = data.Items[category .. "Gun"].color
            end
            
            -- Main level up popup (centered)
            popup.spawn({
                x = w/2,
                y = h/2 - 20,
                text = category:gsub("^%l", string.upper) .. " LEVEL UP!", -- Capitalize first letter
                color = weapon_color,
                font_size = 56,
                fade_duration = 2.5,
                box = true,
                box_color = {0, 0, 0, 0.8},
                box_padding = 20,
                outline = true,
                outline_color = {1, 1, 1, 0.9},
                outline_width = 3,
                shadow = true,
                shadow_color = {0, 0, 0, 0.7},
                shadow_offset = {3, 3}
            })
            
            -- Level indicator popup (below main popup)
            popup.spawn({
                x = w/2,
                y = h/2 + 50,
                text = "LEVEL " .. new_level,
                color = {1, 0.9, 0.2, 1}, -- Gold color for level
                font_size = 42,
                fade_duration = 2.3,
                shadow = true,
                shadow_color = {0, 0, 0, 0.8},
                shadow_offset = {2, 2}
            })
            
            -- Play level up sound if available
            if sfx and sfx.play then
                sfx.play('levelup')
            end
            
            -- Trigger a visual effect or feedback for level-up
            return true, "level_up", category, new_level
        else
            debug.log("Inventory: " .. category .. " weapon already at max level (" .. current_level .. ")")
            
            -- Create "max level" popup
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            popup.spawn({
                x = w/2,
                y = h/2,
                text = category:gsub("^%l", string.upper) .. " MAXED OUT!",
                color = {0.8, 0.8, 0.8, 1}, -- Silver color for max level
                font_size = 48,
                fade_duration = 2.0,
                box = true,
                box_color = {0.1, 0.1, 0.1, 0.9},
                box_padding = 15,
                outline = true,
                outline_color = {0.6, 0.6, 0.6, 1},
                outline_width = 2,
                shadow = true,
                shadow_color = {0, 0, 0, 0.7},
                shadow_offset = {2, 2}
            })
            
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
