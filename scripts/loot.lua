-- scripts/loot.lua: spawn and draw loot drops
local debug = require "scripts/debug"
local settings = require "settings"
local loot = {}
loot.drops = {}

-- Update loot drops: attraction and pickup logic
function loot.update(dt, player_x, player_y, outline_radius)
    local loot_settings = settings.loot
    local weapon_settings = settings.weapon
    for i = #loot.drops, 1, -1 do
        local d = loot.drops[i]
        local dx, dy = d.x - player_x, d.y - player_y
        local dist = math.sqrt(dx*dx + dy*dy)
        local is_money = (d.id == "money")
        local attr_enabled = is_money and loot_settings.attraction_enabled or weapon_settings.attraction_enabled
        local attr_speed = is_money and loot_settings.attraction_speed or weapon_settings.attraction_speed
        local attr_mult = is_money and loot_settings.attraction_radius_mult or weapon_settings.attraction_radius_mult
        -- Attraction radius is based on outline_radius * attraction_radius_mult
        local attr_radius = outline_radius * (attr_mult or 2)
        -- Pickup radius is now outline_radius * loot.pickup_radius_mult (controllable in settings)
        local pickup_mult = is_money and (loot_settings.pickup_radius_mult or 1.3) or 1.0
        local pickup_radius = outline_radius * pickup_mult
        -- Attraction: if within attraction radius but outside pickup radius
        d._attracting = d._attracting or false
        if attr_enabled and dist < attr_radius and dist > 1 then
            if not d._attracting then
                debug.log((is_money and 'Coin' or 'Weapon')..' attraction started!')
                d._attracting = true
            end
            -- Ease-in (starts slow, finishes fast): use quadratic ease-in for lerp factor
            local t = 1 - (dist-pickup_radius)/(attr_radius-pickup_radius)
            local lerp_factor = math.min(0.15 + 0.6 * (t^2), 1) -- quadratic ease-in
            d.x = d.x + (player_x - d.x) * lerp_factor * dt * 2
            d.y = d.y + (player_y - d.y) * lerp_factor * dt * 2
        else
            d._attracting = false
        end
        -- Pickup logic: if within pickup radius and not money, add to inventory
        if not is_money and dist < pickup_radius then
            local inventory = require "scripts/inventory"
            inventory.add(d.id)
            inventory.debug_print() -- Debug: print inventory after pickup
            table.remove(loot.drops, i)
        end
    end
end

-- Draw debug radius for attraction and pickup
-- Attraction debug overlay is now handled in player.draw for accuracy. This function is no longer needed.
function loot.draw_debug() end

-- Spawn a new drop near (x,y) with random offset
function loot.spawn(x, y)
    local data = settings.item_data
    -- roll drop table by weight
    local total = 0
    for _, entry in ipairs(data.DropTable) do total = total + entry.weight end
    local r = math.random() * total
    local acc = 0
    local chosen = data.DropTable[1]
    for _, entry in ipairs(data.DropTable) do
        acc = acc + entry.weight
        if r <= acc then chosen = entry break end
    end
    -- offset spawn position
    local angle = math.random() * 2 * math.pi
    local dist = math.random(20, 40)
    local dropX = x + math.cos(angle) * dist
    local dropY = y + math.sin(angle) * dist
    table.insert(loot.drops, { x = dropX, y = dropY, id = chosen.id, rarity = chosen.rarity })
end

-- Draw all loot drops
function loot.draw()
    local data = settings.item_data
    for _, d in ipairs(loot.drops) do
        local item = data.Items[d.id]
        local color = (item and item.color) or (data.Rarity[d.rarity] and data.Rarity[d.rarity].color) or {1,1,1,1}
        love.graphics.setColor(color)
        love.graphics.circle("fill", d.x, d.y, 6)
    end
    love.graphics.setColor(1,1,1,1)
end

return loot
