-- data/items.lua: defines rarities, item definitions, and drop table

local Rarity = {
    Common    = { multiplier = 1, color = {1,1,0,1}, weight = 80 },
    Rare      = { multiplier = 2, color = {0,0,1,1}, weight = 40 },
    Legendary = { multiplier = 5, color = {1,0,1,1}, weight = 5 },
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
}

-- drop entries: id, rarity, and custom weight
local DropTable = {
    { id = "money",     rarity = "Common",    weight = Rarity.Common.weight },
    { id = "forwardGun", rarity = "Common",    weight = 10 },
    { id = "crossGun",   rarity = "Rare",      weight = 7 },
    { id = "drone",      rarity = "Legendary", weight = 3 },
}

return {
    Rarity    = Rarity,
    Items     = Items,
    DropTable = DropTable,
}
