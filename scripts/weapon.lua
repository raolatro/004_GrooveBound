-- scripts/weapon.lua: Handles weapon/projectile logic
local paths = require "paths"
local settings = require "settings"
local collision = require "scripts/collision"
local weapon = {}
weapon.projectiles = {}

local projectile_radius = 5

function weapon.spawn(x, y, dir, on_beat)
    -- You can expand here for spread/multishot
    table.insert(weapon.projectiles, {
        x = x,
        y = y,
        dir = dir,
        speed = settings.projectile.speed,
        damage = settings.projectile.damage,
        range = settings.projectile.range,
        traveled = 0,
        radius = projectile_radius,
        on_beat = on_beat or false
    })
end

function weapon.update(dt)
    for i = #weapon.projectiles, 1, -1 do
        local p = weapon.projectiles[i]
        local dx = math.cos(p.dir) * p.speed * dt
        local dy = math.sin(p.dir) * p.speed * dt
        p.x = p.x + dx
        p.y = p.y + dy
        p.traveled = p.traveled + math.sqrt(dx*dx + dy*dy)
        if p.traveled > p.range then
            table.remove(weapon.projectiles, i)
        end
    end
end

function weapon.draw(player_x, player_y)
    for _, p in ipairs(weapon.projectiles) do
        local scale = p.on_beat and settings.projectile.on_beat_scale or settings.projectile.normal_scale
        local color = p.on_beat and settings.projectile.on_beat_color or settings.projectile.normal_color
        love.graphics.setColor(color)
        love.graphics.circle("fill", p.x, p.y, projectile_radius * scale)
    end
end

-- Call this in update to decrement popup timers
function weapon.update(dt)
    for i = #weapon.projectiles, 1, -1 do
        local p = weapon.projectiles[i]
        local dx = math.cos(p.dir) * p.speed * dt
        local dy = math.sin(p.dir) * p.speed * dt
        p.x = p.x + dx
        p.y = p.y + dy
        p.traveled = p.traveled + math.sqrt(dx*dx + dy*dy)
        if p.traveled > p.range then
            table.remove(weapon.projectiles, i)
        elseif p.on_beat and p.popup then
            p.popup.timer = p.popup.timer - dt
            if p.popup.timer < 0 then p.popup.timer = 0 end
        end
    end
end

return weapon
