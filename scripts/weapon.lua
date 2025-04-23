-- scripts/weapon.lua: Handles weapon/projectile logic
local paths = require "paths"
local settings = require "settings"
local sfx = require "scripts/sfx"
local collision = require "scripts/collision"
local weapon = {}
weapon.projectiles = {}

local projectile_radius = 10

-- Cache for projectile images
weapon.projectile_images = {}

-- weapon.spawn now takes weapon_settings for custom stats
function weapon.spawn(x, y, dir, on_beat, weapon_settings)
    sfx.play('projectile')
    local main = settings.main
    local on_beat_buffer = main.beat_checker_on_beat_buffer or 0.1
    weapon_settings = weapon_settings or {}
    -- Use orange for area projectiles, fallback to other color if not set
    local proj_color = weapon_settings.color
    
    -- Get weapon type for image rendering
    local weapon_type = weapon_settings.weapon_type or "forward"
    
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
        on_beat_buffer = on_beat_buffer,
        weapon_type = weapon_type -- Store weapon type for image rendering
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
    
    -- Load the pistol projectile image if not already loaded
    if not weapon.projectile_images.forward and settings.weapons.forward.projectile_image then
        weapon.projectile_images.forward = love.graphics.newImage(settings.weapons.forward.projectile_image)
    end
    
    for _, p in ipairs(weapon.projectiles) do
        local scale = p.on_beat and (main.on_beat_scale or settings.projectile.on_beat_scale) or settings.projectile.normal_scale
        -- Use custom color for area projectiles, else fallback
        local color = p.color or (p.on_beat and (main.on_beat_color or settings.projectile.on_beat_color) or settings.projectile.normal_color)
        love.graphics.setColor(color)
        
        -- For pistol projectiles, use the image
        if p.weapon_type == "forward" and weapon.projectile_images.forward then
            local img = weapon.projectile_images.forward
            love.graphics.draw(img, p.x, p.y, p.dir, scale, scale, img:getWidth()/2, img:getHeight()/2)
        else
            -- For other weapons, use the default circle
            love.graphics.circle("fill", p.x, p.y, (p.radius or projectile_radius) * scale)
        end
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
