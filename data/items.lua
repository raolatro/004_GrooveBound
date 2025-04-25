-- data/items.lua: defines rarities, item definitions, and drop table

local Rarity = {
    Common    = { multiplier = 1, color = {1,1,0,1}, weight = 80 },
    Uncommon  = { multiplier = 1.5, color = {0,1,0,1}, weight = 60 },
    Rare      = { multiplier = 2, color = {0,0,1,1}, weight = 40 },
    Epic      = { multiplier = 3, color = {1,0.5,0,1}, weight = 20 },
    Legendary = { multiplier = 5, color = {1,0,1,1}, weight = 10 },
}

-- Define a function to reset all weapons to level 1
local function reset_weapons()
    return {
        money = {
            type      = "money",
            baseValue = 10,
        },
        forwardGun = {
            type     = "weapon",
            category = "forward",
            damage   = 1,
            level    = 1,
            color    = {1,1,1,1}, -- White for loot/inventory
        },
        crossGun = {
            type     = "weapon",
            category = "cross",
            damage   = 2,
            level    = 1,
            color    = {0,1,0,1},
        },
        drone = {
            type     = "weapon",
            category = "drones",
            damage   = 1,
            level    = 1,
            color    = {0,1,1,1},
        },
        area = {
            type     = "weapon",
            category = "area",
            damage   = 5,
            level    = 1,
            color    = {1,0.5,0,1}, -- Orange for area weapon
            hit_area_mult = 3,
            hit_area_radius = 10,
            hit_area_color = {1,0.5,0,0.1}, -- Orange 10% opacity
            hit_area_max_angle = 45,
        },
    }
end

-- Use the function to initialize the items
local Items = reset_weapons()

-- Make the reset function accessible
_G.reset_item_levels = reset_weapons

-- Expanded loot types with variations in value, size, color, and rarity
local LootTypes = {
    -- Common loot (small coins)
    { 
        name = "Penny", 
        id = "coin_small", 
        value = 5, 
        size = 8, 
        tint = {1, 0.9, 0.3, 1}, -- Light gold
        rarity = "Common",
        weight = Rarity.Common.weight * 2
    },
    { 
        name = "Dollar", 
        id = "coin_medium", 
        value = 10, 
        size = 10, 
        tint = {1, 0.85, 0.2, 1}, -- Medium gold
        rarity = "Common",
        weight = Rarity.Common.weight
    },
    -- Uncommon loot (medium value)
    { 
        name = "MP3 Player", 
        id = "coin_large", 
        value = 25, 
        size = 12, 
        tint = {1, 0.8, 0.1, 1}, -- Rich gold
        rarity = "Uncommon",
        weight = Rarity.Uncommon.weight
    },
    -- Rare loot (high value)
    { 
        name = "iPhone", 
        id = "gold_nugget", 
        value = 50, 
        size = 14, 
        tint = {1, 0.75, 0.05, 1}, -- Deep gold
        rarity = "Rare",
        weight = Rarity.Rare.weight
    },
    -- Epic loot (very high value)
    { 
        name = "Macbook Pro", 
        id = "gold_bar", 
        value = 100, 
        size = 16, 
        tint = {1, 0.7, 0, 1}, -- Orange gold
        rarity = "Epic",
        weight = Rarity.Epic.weight
    },
    -- Legendary loot (extremely high value)
    { 
        name = "Stratocaster Guitar", 
        id = "treasure", 
        value = 250, 
        size = 20, 
        tint = {1, 0.65, 0, 1}, -- Deep orange gold
        rarity = "Legendary",
        weight = Rarity.Legendary.weight / 2
    },
}

-- Add pricing to weapon levels
local function add_weapon_prices()
    -- Forward gun prices (pistol)
    for i=1, 11 do -- 11 levels
        if Items.forwardGun and Items.forwardGun.level == i then
            Items.forwardGun.price = 100 * i
        end
    end
    
    -- Cross gun prices (blaster)
    for i=1, 10 do -- 10 levels
        if Items.crossGun and Items.crossGun.level == i then
            Items.crossGun.price = 150 * i
        end
    end
    
    -- Drone prices
    for i=1, 10 do -- 10 levels
        if Items.drone and Items.drone.level == i then
            Items.drone.price = 200 * i
        end
    end
    
    -- Area weapon prices
    for i=1, 10 do -- 10 levels
        if Items.area and Items.area.level == i then
            Items.area.price = 250 * i
        end
    end
 end

-- Set initial prices
add_weapon_prices()

-- Modified drop table - only money drops of different types (no weapons)
local DropTable = {}
for _, loot in ipairs(LootTypes) do
    table.insert(DropTable, { id = loot.id, rarity = loot.rarity, weight = loot.weight })
end

return {
    Rarity    = Rarity,
    Items     = Items,
    DropTable = DropTable,
    LootTypes = LootTypes,
    add_weapon_prices = add_weapon_prices, -- Export for use after level changes
}
