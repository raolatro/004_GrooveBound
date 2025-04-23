-- scripts/weapon.lua: Handles weapon/projectile logic
local paths = require "paths"
local settings = require "settings"
local sfx = require "scripts/sfx"
local collision = require "scripts/collision"
local weapon = {}
weapon.projectiles = {}

local projectile_radius = 10

-- weapon.spawn now takes weapon_settings for custom stats
function weapon.spawn(x, y, dir, on_beat, weapon_settings)
    sfx.play('projectile')
    local main = settings.main
    local on_beat_buffer = main.beat_checker_on_beat_buffer or 0.1
    weapon_settings = weapon_settings or {}
    -- Use orange for area projectiles, fallback to other color if not set
    local proj_color = weapon_settings.color
    table.insert(weapon.projectiles, {
        x = x,
        y = y,
        dir = dir,
        speed = weapon_settings.speed or settings.projectile.speed,
        damage = weapon_settings.damage or settings.projectile.damage,
        range = weapon_settings.range or settings.projectile.range,
        traveled = 0,
        radius = weapon_settings.radius or projectile_radius,
        color = proj_color, -- Area gun passes orange here
        on_beat = on_beat or false,
        on_beat_buffer = on_beat_buffer
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
    local main = settings.main
    for _, p in ipairs(weapon.projectiles) do
        local scale = p.on_beat and (main.on_beat_scale or settings.projectile.on_beat_scale) or settings.projectile.normal_scale
        -- Use custom color for area projectiles, else fallback
        local color = p.color or (p.on_beat and (main.on_beat_color or settings.projectile.on_beat_color) or settings.projectile.normal_color)
        love.graphics.setColor(color)
        love.graphics.circle("fill", p.x, p.y, (p.radius or projectile_radius) * scale)
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
