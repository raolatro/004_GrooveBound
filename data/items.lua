-- data/items.lua: defines rarities, item definitions, and drop table

local Rarity = {
    Common    = { multiplier = 1, color = {1,1,0,1}, weight = 80 },
    Rare      = { multiplier = 2, color = {0,0,1,1}, weight = 40 },
    Legendary = { multiplier = 5, color = {1,0,1,1}, weight = 100 },
}

local Items = {
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

-- drop entries: id, rarity, and custom weight
local DropTable = {
    { id = "money",     rarity = "Common",    weight = Rarity.Common.weight },
    { id = "forwardGun", rarity = "Common",    weight = 2 },
    { id = "crossGun",   rarity = "Rare",      weight = 10 },
    { id = "drone",      rarity = "Legendary", weight = 10 },
    { id = "area",      rarity = "Legendary", weight = 10 },
}

return {
    Rarity    = Rarity,
    Items     = Items,
    DropTable = DropTable,
}
