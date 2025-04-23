-- scripts/inventory.lua: manage player weapons inventory
local settings = require "settings"
local inventory = {
    slots = {
        forward = nil,
        cross = nil,
        drone = nil,
    }
}

-- Add a weapon to inventory (replace if slot occupied)
function inventory.add(itemId)
    local data = settings.item_data
    local item = data.Items[itemId]
    if not item then
        print("Inventory: unknown item", itemId)
        return
    end
    if item.type ~= "weapon" then return end
    local cat = item.category
    inventory.slots[cat] = {
        id = itemId,
        damage = item.damage,
        level = item.level,
        color = item.color,
    }
    print("Inventory: added weapon", itemId)
end

-- (Future: functions to upgrade, swap, draw UI, etc.)

return inventory
