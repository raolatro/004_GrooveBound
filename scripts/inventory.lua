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

-- Add a weapon (itemId or item table) to inventory
function inventory.add(item)
    local data = settings.item_data
    -- Accept either itemId or item table
    if type(item) == "string" then
        item = data.Items[item]
    end
    if not item or item.type ~= "weapon" then
        print("Inventory: invalid or non-weapon item", item and item.id or item)
        return
    end
    -- Only one weapon per category: replace if present
    local idx = inventory.find_by_category(item.category)
    if idx then
        inventory.slots[idx] = item
        print("Inventory: replaced weapon in slot", idx, "with", item.id)
        return
    end
    -- Add to first empty slot
    for i = 1, settings.inventory.max_slots do
        if not inventory.slots[i] then
            inventory.slots[i] = item
            print("Inventory: added weapon", item.id, "to slot", i)
            return
        end
    end
    print("Inventory: all slots full, cannot add", item.id)
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
