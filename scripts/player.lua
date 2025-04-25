-- scripts/player.lua: Handles player logic
local paths = require "paths"
local settings = require "settings"
local gamepad = require "scripts/gamepad"
local debug = require "scripts/debug"
local player = {}

-- === Power-up System Fields ===
-- Stores acquired power-ups and their stat modifiers
player.powerups = {}     -- Stores acquired power-ups: {id1 = true, id2 = true}
-- Tracks all acquired power-up effects, their stack count, and targets for future display
player.powerup_effects = {}  -- [powerup_id] = { count = N, targets = { ... }, last_applied = os.time() }
player.modifiers = {     -- Multipliers for all stats
    -- Global modifiers
    fire_rate = 1.0,     -- Multiplier for weapon fire rate
    damage = 1.0,        -- Multiplier for weapon damage
    projectile_speed = 1.0, -- Multiplier for projectile speed
    spread = 1.0,        -- Multiplier for weapon spread (lower is better)
    reload_time = 1.0,   -- Multiplier for reload time (lower is better)
    max_ammo = 1.0,      -- Multiplier for maximum ammo capacity
    cash_value = 1.0,    -- Multiplier for cash pickup value
    
    -- Special modifiers
    crit_chance = 0.0,   -- Chance to deal critical damage (0.0 to 1.0)
    pierce = 0,          -- Additional enemies that projectiles can hit
    ricochet_chance = 0.0, -- Chance to bounce off walls/enemies
    ricochet_bounces = 0, -- Number of bounces per shot if ricochet happens
    slow = 0.0,          -- Slow effect on hit (0.0 to 1.0)
    slow_duration = 0.0, -- Duration of slow effect in seconds
    chain_chance = 0.0,  -- Chance to chain to nearby enemies
    chain_targets = 0,   -- Number of additional targets for chain effect
    aoe_explosion = false, -- Whether kills create explosions
    aoe_radius = 0,      -- Radius of explosion
    aoe_damage = 0.0,    -- Damage multiplier for explosion
    vampirism = 0,       -- Damage needed to heal 1 HP
    free_ammo_chance = 0.0, -- Chance to not consume ammo
}

-- Category-specific modifiers
player.category_modifiers = {}

-- Weapon-specific modifiers
player.weapon_modifiers = {}

-- Temporary modifiers with durations
player.temp_modifiers = {}

-- === Modular Player Animation System (state/direction/frame/shadow) ===
local anim_settings = settings.player1
player.anim = {
    state = anim_settings.default_state,
    direction = anim_settings.directions.down, -- 1=down, 2=up, 3=left, 4=right
    frame = 1,
    timer = 0,
    quads = {},
    images = {},
    shadows = {},
    shadow_quads = {},
}

-- Preload all images and quads for player and shadow for each state
local function load_player_sprites()
    for state, conf in pairs(anim_settings.states) do
        -- Load main sprite
        player.anim.images[state] = love.graphics.newImage(conf.sprite)
        player.anim.quads[state] = {}
        for row=1,conf.grid.rows do
            player.anim.quads[state][row] = {}
            for col=1,conf.grid.cols do
                player.anim.quads[state][row][col] = love.graphics.newQuad(
                    (col-1)*conf.frame_size.w,
                    (row-1)*conf.frame_size.h,
                    conf.frame_size.w,
                    conf.frame_size.h,
                    player.anim.images[state]:getDimensions()
                )
            end
        end
        -- Load shadow sprite
        player.anim.shadows[state] = love.graphics.newImage(conf.shadow)
        player.anim.shadow_quads[state] = {}
        for row=1,conf.grid.rows do
            player.anim.shadow_quads[state][row] = {}
            for col=1,conf.grid.cols do
                player.anim.shadow_quads[state][row][col] = love.graphics.newQuad(
                    (col-1)*conf.frame_size.w,
                    (row-1)*conf.frame_size.h,
                    conf.frame_size.w,
                    conf.frame_size.h,
                    player.anim.shadows[state]:getDimensions()
                )
            end
        end
    end
end

-- Beat/visual cue state
player.last_beat_time = 0
player.last_beat_step = 0
player.beat_flash = 0
player.on_beat_fire = false
player.outline_scale = 1.0
player.outline_target_scale = 1.0
player.outline_anim_ease = settings.main.beat_checker_ease or 0.18

-- Call this from main.lua when a new beat subdivision occurs
function player.on_beat(beat_step)
    player.last_beat_time = love.timer.getTime()
    player.last_beat_step = beat_step
    player.beat_flash = settings.main.beat_flash or 0.25 -- seconds to flash
    player.on_beat_fire = false
    -- Animate outline: off-beat (white) scales down, on-beat (green) will scale up in register_fire
    player.outline_scale = settings.main.on_beat_scale_initial or 1.7
    player.outline_target_scale = settings.main.on_beat_scale_final or 1.0
end

-- Call this from main.lua when the player fires
function player.register_fire()
    -- Check if fire is within a short window after the last beat
    local t = love.timer.getTime()
    if t - player.last_beat_time < 0.12 then
        player.on_beat_fire = true
        player.beat_flash = settings.main.beat_flash or 0.25
        -- Animate green outline scaling up
        player.outline_scale = settings.main.beat_checker_scale_min or 1.0
        player.outline_target_scale = settings.main.beat_checker_scale_max or 1.4
        -- Fire all active weapons in inventory
        local inventory = require "scripts/inventory"
        local weapon = require "scripts/weapon"
        -- Fire all active weapons in inventory
        for _, w in ipairs(inventory.get_active()) do
            local weapon_settings = settings.weapons[w.category] and settings.weapons[w.category][w.level or 1] or {}
            if w.category == "forward" then
                -- Use weapon settings for forward gun
                local dir = gamepad.dir or 0
                weapon.spawn(gamepad.x, gamepad.y, dir, true, weapon_settings)
            elseif w.category == "cross" then
                -- Use weapon settings for cross gun
                local dirs = {}
                local n = weapon_settings.directions or 4
                for i=1,n do
                    table.insert(dirs, (2*math.pi/n)*(i-1))
                end
                for _, dir in ipairs(dirs) do
                    weapon.spawn(gamepad.x, gamepad.y, dir, true, weapon_settings)
                end
            elseif w.category == "drones" then
                -- Drone logic: spawn projectiles in a circle around the player
                -- Use orbit_radius and drone_radius from settings
                local enemy = require "scripts/enemy"
                local num_drones = weapon_settings.count or 2
                local orbit_radius = weapon_settings.orbit_radius or (48 + 8 * (w.level or 1))
                local drone_radius = weapon_settings.drone_radius or 10
                local orbit_speed = weapon_settings.orbit_speed or 0.7
                local engaged_orbit_speed = weapon_settings.engaged_orbit_speed or 0.2
                -- Get drone range from settings if available
                local drone_level = w.level or 1
                local drone_settings = settings.weapons.drones and settings.weapons.drones[drone_level] or {}
                local drone_range = drone_settings.range or ((w.hit_area_mult or 3) * drone_radius)
                local hit_area_radius = drone_range
                local t = love.timer.getTime()
                for i = 1, num_drones do
                -- Find nearest enemy within hit area for this drone
                local px = gamepad.x + math.cos((2 * math.pi / num_drones) * (i-1)) * orbit_radius
                local py = gamepad.y + math.sin((2 * math.pi / num_drones) * (i-1)) * orbit_radius
                local nearest_enemy = nil
                local min_dist = drone_settings.range or 100
                for _, e in ipairs(enemy.enemies) do
                    local ex, ey = e.x, e.y
                    local dist = math.sqrt((ex - px)^2 + (ey - py)^2)
                    if dist < min_dist then
                        min_dist = dist
                        nearest_enemy = e
                    end
                end
                -- Use engaged orbit speed if locked on, otherwise normal
                local speed = nearest_enemy and engaged_orbit_speed or orbit_speed
                local angle = (2 * math.pi / num_drones) * (i-1) + t * speed
                px = gamepad.x + math.cos(angle) * orbit_radius
                py = gamepad.y + math.sin(angle) * orbit_radius
                local dir = angle
                    weapon.spawn(px, py, dir, true, weapon_settings)
                    -- Draw drone as solid cyan dot
                    love.graphics.setColor(0,1,1,1)
                    love.graphics.circle("fill", px, py, drone_radius)
                end
            elseif w.category == "area" then
                -- Area/shotgun logic: fire multiple pellets in a spread
                local pellets = weapon_settings.pellets or 5
                local spread = weapon_settings.spread or 30
                local dir = gamepad.dir or 0
                for i = 1, pellets do
                    local angle = dir + math.rad(-spread/2 + spread*(i-1)/(pellets-1))
                    weapon.spawn(gamepad.x, gamepad.y, angle, true, weapon_settings)
                end
            end
        end
        -- Spawn popup using new popup system
        local popup = require "scripts/popup"
        if settings.popup.enable_groove_popup then
            popup.spawn({
                x = gamepad.x,
                y = gamepad.y,
                text = settings.popup.text,
                color = settings.popup.color,
                font_scale = settings.popup.font_scale,
                fade_duration = settings.popup.fade_duration,
                y_offset = settings.popup.y_offset,
                box = settings.popup.box,
                box_color = settings.popup.box_color,
                box_padding = settings.popup.box_padding,
                outline = settings.popup.outline,
                outline_color = settings.popup.outline_color,
                outline_width = settings.popup.outline_width,
                shadow = settings.popup.shadow,
                shadow_color = settings.popup.shadow_color,
                shadow_offset = settings.popup.shadow_offset,
            })
        end
    else
        player.on_beat_fire = false
        player.beat_flash = 0.12
    end
end

-- Power-up Related Functions

-- Check if player has a specific power-up
function player.has_powerup(id)
    return player.powerups[id] == true
end

-- Add a power-up to the player
function player.add_powerup(id, data)
    -- Stack count and effect tracking for future display
    if not player.powerup_effects[id] then
        player.powerup_effects[id] = { count = 0, targets = {}, last_applied = os.time() }
    end
    player.powerup_effects[id].count = player.powerup_effects[id].count + 1
    player.powerup_effects[id].targets = data.scope or { type = "global" }
    player.powerup_effects[id].last_applied = os.time()

    player.powerups[id] = true
    debug.log("[Player] Added power-up: " .. data.name .. " (stack: " .. player.powerup_effects[id].count .. ")")

    -- If it's a weapon level up, handle it specially
    if data.modifiers and data.modifiers.weapon_level_up then
        player.level_up_all_weapons(data.modifiers.weapon_level_up)
        return
    end

    -- Apply effect based on scope
    if data.scope then
        if data.scope.type == "global" then
            player.apply_global_modifiers(data.modifiers)
        elseif data.scope.type == "category" and data.scope.category then
            player.apply_category_modifiers(data.scope.category, data.modifiers)
        elseif data.scope.type == "weapon" and data.scope.weapon then
            player.apply_weapon_modifiers(data.scope.weapon, data.modifiers)
        end
    end
end

-- Apply global stat modifiers from a power-up
function player.apply_global_modifiers(modifiers)
    for stat, value in pairs(modifiers) do
        if player.modifiers[stat] ~= nil then
            -- Different handling for additive vs multiplicative stats
            if stat == "pierce" or stat == "ricochet_bounces" or stat == "chain_targets" 
               or stat == "aoe_radius" or stat == "vampirism" then
                -- Additive stats
                player.modifiers[stat] = player.modifiers[stat] + value
            elseif stat == "crit_chance" or stat == "ricochet_chance" or stat == "chain_chance" 
                   or stat == "slow" or stat == "free_ammo_chance" then
                -- Probability stats are capped at a maximum (usually 1.0)
                player.modifiers[stat] = math.min(1.0, player.modifiers[stat] + value)
            elseif stat == "aoe_explosion" then
                -- Boolean toggle
                player.modifiers[stat] = value
            else
                -- Multiplicative stats
                player.modifiers[stat] = player.modifiers[stat] * value
            end
            
            debug.log("[Player] Updated global modifier " .. stat .. " to " .. tostring(player.modifiers[stat]))
        end
    end
end

-- Apply category-specific modifiers
function player.apply_category_modifiers(category, modifiers)
    -- Ensure category is a string for keying and logging
    if type(category) == "table" then
        category = tostring(category.id or category.name or "unknown_category")
    end
    -- Initialize category if it doesn't exist
    if not player.category_modifiers[category] then
        player.category_modifiers[category] = {}
        for stat, default in pairs(player.modifiers) do
            if type(default) == "number" then
                player.category_modifiers[category][stat] = (stat == "pierce" or stat == "ricochet_bounces" 
                    or stat == "chain_targets" or stat == "aoe_radius" or stat == "vampirism") and 0 or 1.0
            elseif type(default) == "boolean" then
                player.category_modifiers[category][stat] = false
            end
        end
    end
    
    -- Apply modifiers to the category
    for stat, value in pairs(modifiers) do
        if player.category_modifiers[category][stat] ~= nil then
            -- Different handling for additive vs multiplicative stats
            if stat == "pierce" or stat == "ricochet_bounces" or stat == "chain_targets" 
               or stat == "aoe_radius" or stat == "vampirism" then
                -- Additive stats
                player.category_modifiers[category][stat] = player.category_modifiers[category][stat] + value
            elseif stat == "crit_chance" or stat == "ricochet_chance" or stat == "chain_chance" 
                   or stat == "slow" or stat == "free_ammo_chance" then
                -- Probability stats are capped at a maximum (usually 1.0)
                player.category_modifiers[category][stat] = math.min(1.0, player.category_modifiers[category][stat] + value)
            elseif stat == "aoe_explosion" then
                -- Boolean toggle
                player.category_modifiers[category][stat] = value
            else
                -- Multiplicative stats
                player.category_modifiers[category][stat] = player.category_modifiers[category][stat] * value
            end
            
            debug.log("[Player] Updated " .. tostring(category) .. " modifier " .. stat .. " to " .. tostring(player.category_modifiers[category][stat]))
        end
    end
end

-- Apply weapon-specific modifiers
function player.apply_weapon_modifiers(weapon_id, modifiers)
    -- Initialize weapon if it doesn't exist
    if not player.weapon_modifiers[weapon_id] then
        player.weapon_modifiers[weapon_id] = {}
        for stat, default in pairs(player.modifiers) do
            if type(default) == "number" then
                player.weapon_modifiers[weapon_id][stat] = (stat == "pierce" or stat == "ricochet_bounces" 
                    or stat == "chain_targets" or stat == "aoe_radius" or stat == "vampirism") and 0 or 1.0
            elseif type(default) == "boolean" then
                player.weapon_modifiers[weapon_id][stat] = false
            end
        end
    end
    
    -- Apply modifiers to the weapon
    for stat, value in pairs(modifiers) do
        if player.weapon_modifiers[weapon_id][stat] ~= nil then
            -- Different handling for additive vs multiplicative stats
            if stat == "pierce" or stat == "ricochet_bounces" or stat == "chain_targets" 
               or stat == "aoe_radius" or stat == "vampirism" then
                -- Additive stats
                player.weapon_modifiers[weapon_id][stat] = player.weapon_modifiers[weapon_id][stat] + value
            elseif stat == "crit_chance" or stat == "ricochet_chance" or stat == "chain_chance" 
                   or stat == "slow" or stat == "free_ammo_chance" then
                -- Probability stats are capped at a maximum (usually 1.0)
                player.weapon_modifiers[weapon_id][stat] = math.min(1.0, player.weapon_modifiers[weapon_id][stat] + value)
            elseif stat == "aoe_explosion" then
                -- Boolean toggle
                player.weapon_modifiers[weapon_id][stat] = value
            else
                -- Multiplicative stats
                player.weapon_modifiers[weapon_id][stat] = player.weapon_modifiers[weapon_id][stat] * value
            end
            
            debug.log("[Player] Updated " .. weapon_id .. " modifier " .. stat .. " to " .. tostring(player.weapon_modifiers[weapon_id][stat]))
        end
    end
end

-- Apply temporary modifiers with duration
function player.apply_temp_modifiers(modifiers, duration)
    -- Create a new temporary modifier entry
    local end_time = love.timer.getTime() + duration
    table.insert(player.temp_modifiers, {
        modifiers = modifiers,
        end_time = end_time
    })
    
    debug.log("[Player] Applied temporary modifiers for " .. duration .. " seconds")
end

-- Get the effective modifier value for a stat based on weapon category and ID
function player.get_effective_modifier(stat, weapon_id, category)
    -- Start with the global modifier
    local value = player.modifiers[stat] or 1.0
    
    -- Apply category modifier if it exists
    if category and player.category_modifiers[category] and player.category_modifiers[category][stat] then
        if stat == "pierce" or stat == "ricochet_bounces" or stat == "chain_targets" 
           or stat == "aoe_radius" or stat == "vampirism" then
            -- Additive stats
            value = value + player.category_modifiers[category][stat]
        elseif stat == "aoe_explosion" then
            -- Boolean toggle (OR operation)
            value = value or player.category_modifiers[category][stat]
        else
            -- Multiplicative stats
            value = value * player.category_modifiers[category][stat]
        end
    end
    
    -- Apply weapon modifier if it exists
    if weapon_id and player.weapon_modifiers[weapon_id] and player.weapon_modifiers[weapon_id][stat] then
        if stat == "pierce" or stat == "ricochet_bounces" or stat == "chain_targets" 
           or stat == "aoe_radius" or stat == "vampirism" then
            -- Additive stats
            value = value + player.weapon_modifiers[weapon_id][stat]
        elseif stat == "aoe_explosion" then
            -- Boolean toggle (OR operation)
            value = value or player.weapon_modifiers[weapon_id][stat]
        else
            -- Multiplicative stats
            value = value * player.weapon_modifiers[weapon_id][stat]
        end
    end
    
    -- Apply temporary modifiers if they exist
    for _, temp in ipairs(player.temp_modifiers) do
        if temp.modifiers[stat] then
            if stat == "pierce" or stat == "ricochet_bounces" or stat == "chain_targets" 
               or stat == "aoe_radius" or stat == "vampirism" then
                -- Additive stats
                value = value + temp.modifiers[stat]
            elseif stat == "aoe_explosion" then
                -- Boolean toggle (OR operation)
                value = value or temp.modifiers[stat]
            else
                -- Multiplicative stats
                value = value * temp.modifiers[stat]
            end
        end
    end
    
    return value
end

-- Level up all weapons (used by Ultimate Upgrade)
function player.level_up_all_weapons(levels)
    levels = levels or 1
    local inventory = require "scripts/inventory"
    
    -- Apply level up to all active weapons
    local settings = require "settings"
    for _, weapon in ipairs(inventory.get_active()) do
        weapon.level = (weapon.level or 1) + levels
        local display_name = (weapon.category and settings.weapons[weapon.category] and settings.weapons[weapon.category].display_name) or weapon.category or "Unknown"
        debug.log("[Player] Leveled up weapon " .. display_name .. " to level " .. weapon.level)
    end
    
    -- Visual feedback
    local popup = require "scripts/popup"
    popup.spawn({
        x = love.graphics.getWidth() / 2,
        y = love.graphics.getHeight() / 2 - 100,
        text = "All weapons leveled up!",
        color = {1, 0.1, 0.1, 1},  -- Red for ultimate upgrade
        font_size = 26,
        fade_duration = 0.5,
        stay_duration = 2.0,
        popup_type = popup.TYPES.NOTIFICATION
    })
end

-- Spend cash (returns true if successful)
function player.spend_cash(amount)
    local hud = require "scripts/hud"
    
    if not hud.cash or hud.cash < amount then
        return false
    end
    
    hud.cash = hud.cash - amount
    debug.log("[Player] Spent " .. amount .. " cash")
    return true
end

-- Update function to process temporary modifiers
function player.update_powerups(dt)
    -- Remove expired temporary modifiers
    local now = love.timer.getTime()
    for i = #player.temp_modifiers, 1, -1 do
        if player.temp_modifiers[i].end_time <= now then
            table.remove(player.temp_modifiers, i)
            debug.log("[Player] Removed expired temporary modifier")
        end
    end
end

-- Reset power-up system (new game)
function player.reset_powerups()
    player.powerups = {}
    player.powerup_effects = {}
    
    -- Reset all modifiers to default values
    player.modifiers = {
        fire_rate = 1.0,
        damage = 1.0,
        projectile_speed = 1.0,
        spread = 1.0,
        reload_time = 1.0,
        max_ammo = 1.0,
        cash_value = 1.0,
        crit_chance = 0.0,
        pierce = 0,
        ricochet_chance = 0.0,
        ricochet_bounces = 0,
        slow = 0.0,
        slow_duration = 0.0,
        chain_chance = 0.0,
        chain_targets = 0,
        aoe_explosion = false,
        aoe_radius = 0,
        aoe_damage = 0.0,
        vampirism = 0,
        free_ammo_chance = 0.0,
    }
    
    player.category_modifiers = {}
    player.weapon_modifiers = {}
    player.temp_modifiers = {}
    
    debug.log("[Player] Reset all power-ups and modifiers")
end

function player.init()
    gamepad.init(settings.main.window_width / 2, settings.main.window_height / 2)
    player.max_hp = settings.player.hp or 3
    
    -- Initialize power-up system
    player.reset_powerups()
    player.hp = player.max_hp
    player.want_to_fire = false
    player.fire_timer = 0
    -- Ensure player always starts with the forward gun
    local inventory = require "scripts/inventory"
    -- Sync HP to hud for UI
    local hud = require "scripts/hud"
    hud.player_max_hp = player.max_hp
    hud.player_hp = player.hp
    -- Load all player and shadow sprites/quads for all states
    load_player_sprites()
    -- Reset animation state
    player.anim.state = anim_settings.default_state
    player.anim.direction = anim_settings.directions.down
    player.anim.frame = 1
    player.anim.timer = 0
end

function player.damage(amount)
    local hud = require "scripts/hud"
    player.hp = math.max(0, player.hp - (amount or 1))
    hud.player_hp = player.hp
    if player.hp <= 0 then
        local game_over = require "scripts/game_over"
        game_over.show(hud.score, hud.kills, player.hp)
    end
end

function player.update(dt)
    local inventory = require "scripts/inventory"
    local weapon = require "scripts/weapon"
    -- Table to track fire timers for each secondary weapon
    if not player.secondary_timers then player.secondary_timers = {} end
    
    -- Update power-up temporary modifiers
    player.update_powerups(dt)
    for _, w in ipairs(inventory.get_active()) do
        if w.category ~= "forward" and w.category ~= "drones" then
            -- Secondary weapons (blaster, shotgun, etc) fire continuously, ignoring enemy presence
            local weapon_settings = settings.weapons[w.category] and settings.weapons[w.category][w.level or 1] or {}
            local fire_rate = weapon_settings.fire_rate or 1
            if not player.secondary_timers[w.category] then
                player.secondary_timers[w.category] = 0
            end
            player.secondary_timers[w.category] = player.secondary_timers[w.category] - dt
            if player.secondary_timers[w.category] <= 0 then
                -- Special case for cross/blaster weapon pattern
                if w.category == "cross" then
                    -- Cross gun fires in multiple directions forming a star/cross pattern
                    local dirs = {}
                    local n = weapon_settings.directions or 4 -- Default to 4 directions
                    local player_aim = gamepad.dir or 0 -- Use player aim as rotation angle
                    
                    -- Create evenly spaced directions and rotate by player aim
                    for i=1,n do
                        table.insert(dirs, player_aim + (2*math.pi/n)*(i-1))
                    end
                    
                    -- Fire in all directions simultaneously
                    for _, dir in ipairs(dirs) do
                        weapon.spawn(gamepad.x, gamepad.y, dir, true, weapon_settings)
                    end
                elseif w.category == "area" then
                    -- Area/shotgun pattern
                    local pellets = weapon_settings.pellets or 5
                    local spread = weapon_settings.spread or 30
                    local dir = gamepad.dir or 0
                    for i = 1, pellets do
                        local angle = dir + math.rad(-spread/2 + spread*(i-1)/(pellets-1))
                        weapon.spawn(gamepad.x, gamepad.y, angle, true, weapon_settings)
                    end
                else
                    -- Other secondary weapons: fire straight ahead
                    local dir = gamepad.dir or 0
                    weapon.spawn(gamepad.x, gamepad.y, dir, true, weapon_settings)
                end
                player.secondary_timers[w.category] = 1 / fire_rate
            end
        end
    end
    gamepad.update(dt)
    gamepad.clamp_to_bounds(settings.main.window_width, settings.main.window_height)

    -- Always aim toward mouse cursor
    local camera = require "scripts/camera"
    local mx, my = love.mouse.getPosition()
    local cx, cy = love.graphics.getWidth()/2, love.graphics.getHeight()/2
    local wx = camera.x + (mx - cx)
    local wy = camera.y + (my - cy)
    local dx, dy = wx - gamepad.x, wy - gamepad.y
    
    -- CRITICAL: Set actual aim direction for shooting
    local angle = math.atan2(wy - gamepad.y, wx - gamepad.x)
    gamepad.dir = angle  -- This is what fixes the aiming
    
    -- Determine sprite direction (row) based on player position relative to mouse/target
    -- This makes the sprite always face the mouse (twin-stick style)
    -- Use PI to convert radians to cardinal directions
    -- Note: The sprite sheet rows are: 1=down, 2=up, 3=left, 4=right
    local dir
    -- Convert angle to 0-360 degrees for easier logic
    local degrees = (angle * 180 / math.pi) % 360
    if degrees > 45 and degrees <= 135 then
        -- Bottom quadrant - sprite faces down
        dir = anim_settings.directions.down -- 1
    elseif degrees > 135 and degrees <= 225 then
        -- Left quadrant - sprite faces left 
        dir = anim_settings.directions.left -- 3
    elseif degrees > 225 and degrees <= 315 then
        -- Top quadrant - sprite faces up
        dir = anim_settings.directions.up -- 2
    else
        -- Right quadrant - sprite faces right
        dir = anim_settings.directions.right -- 4
    end
    player.anim.direction = dir
    -- Determine state (idle, run, attack, death)
    -- (You may want to add more sophisticated logic for attack/death)
    local moving = (math.abs(gamepad.aim_x) > 0.1 or math.abs(gamepad.aim_y) > 0.1)
    if player.hp <= 0 then
        player.anim.state = "death"
    elseif player.want_to_fire then
        player.anim.state = "attack"
    elseif moving then
        player.anim.state = "run"
    else
        player.anim.state = "idle"
    end
    -- Animation timing
    local conf = anim_settings.states[player.anim.state]
    player.anim.timer = player.anim.timer + dt
    if player.anim.timer > 1/(conf.fps or 12) then
        player.anim.timer = player.anim.timer - 1/(conf.fps or 12)
        -- Clamp frame to grid.cols
        player.anim.frame = (player.anim.frame % conf.grid.cols) + 1
        if player.anim.frame > conf.grid.cols then player.anim.frame = 1 end
    end
    -- Beat flash decay
    if player.beat_flash > 0 then
        player.beat_flash = player.beat_flash - dt
        if player.beat_flash < 0 then player.beat_flash = 0 end
    end
    -- Animate outline scale
    if math.abs(player.outline_scale - player.outline_target_scale) > 0.01 then
        player.outline_scale = player.outline_scale + (player.outline_target_scale - player.outline_scale) * math.min(dt/player.outline_anim_ease, 1)
    else
        player.outline_scale = player.outline_target_scale
    end
end

function player.draw()
    local hud = require "scripts/hud"
    local center_x, center_y = gamepad.x, gamepad.y
    if type(center_x) ~= "number" or type(center_y) ~= "number" then
        return -- Don't draw if coordinates are invalid
    end
    -- Draw aim line if enabled
    if hud.aim_line_enabled then
        if type(center_x) ~= "number" or type(center_y) ~= "number" then
            return -- Don't draw if coordinates are invalid
        end
        local camera = require "scripts/camera"
        local mx, my = love.mouse.getPosition()
        -- Convert mouse to world coordinates (camera position)
        local cx, cy = love.graphics.getWidth()/2, love.graphics.getHeight()/2
        local wx = camera.x + (mx - cx)
        local wy = camera.y + (my - cy)
        -- Thin dotted line with low opacity (manual implementation since dashed isn't available)
        love.graphics.setColor(1,1,1,0.3) -- White with 30% opacity
        love.graphics.setLineWidth(1) -- Thin line
        
        -- Create a dotted line effect manually
        local dist = math.sqrt((wx-center_x)^2 + (wy-center_y)^2)
        local dash_length = 5 -- Length of each dash
        local gap_length = 5 -- Length of each gap
        local step_size = dash_length + gap_length
        local steps = math.floor(dist / step_size)
        
        -- Draw dots for dotted effect
        for i = 0, steps do
            local t = i * step_size / dist
            local dot_x = center_x + (wx - center_x) * t
            local dot_y = center_y + (wy - center_y) * t
            love.graphics.circle("fill", dot_x, dot_y, 1) -- Small dot
        end
        
        love.graphics.setColor(1,1,1,1) -- Reset color
    end
    -- === Beat Checker Visual Parameters (from settings) ===
    local main = settings.main
    local base_radius = gamepad.radius + (main.beat_checker_base_radius or 32)
    local full_beat_outline_width = main.beat_checker_full_outline_width or 2
    local full_beat_opacity = main.beat_checker_full_opacity or 1.0
    local quarter_count = (main.beat_checker_quarter_count or 3)
    local quarter_outline_width = main.beat_checker_quarter_outline_width or 0.5
    local quarter_opacity = main.beat_checker_quarter_opacity or 0.3
    local on_beat_buffer = main.beat_checker_on_beat_buffer or 0.10 -- seconds
    local on_beat_anim_time = main.beat_checker_on_beat_anim_time or 0.5 -- seconds
    -- Timing
    local bpm = main.bpm or 120
    local beat_subdiv = main.beat_subdivisions or 4
    local full_beat_duration = 60/bpm
    local quarter_duration = full_beat_duration/beat_subdiv
    local now = love.timer.getTime()
    local since_full_beat = (now - (player.last_beat_time or 0)) % full_beat_duration

    -- Beat checker circles are now hidden
    love.graphics.setLineWidth(1)
    -- === Drone Visuals ===
    local inventory = require "scripts/inventory"
    local enemy = require "scripts/enemy"
    for _, w in ipairs(inventory.get_active()) do
        if w.category == "drones" then
            -- Always use up-to-date settings for orbit, size, and speed
            local drone_level = w.level or 1
            local drone_settings = settings.weapons.drones and settings.weapons.drones[drone_level] or {}
            local num_drones = drone_settings.count or 2
            local orbit_radius = drone_settings.orbit_radius or (48 + 8 * drone_level)
            local drone_radius = drone_settings.drone_radius or 10
            local orbit_speed = drone_settings.orbit_speed or 0.7
            local engaged_orbit_speed = drone_settings.engaged_orbit_speed or 0.2
            
            -- Get drone weapon parameters from settings
            local drone_damage = drone_settings.damage or 1
            local drone_fire_rate = drone_settings.fire_rate or 0.5  -- Shots per second
            local drone_range = drone_settings.range or ((w.hit_area_mult or 3) * drone_radius)
            local hit_area_radius = drone_range
            
            -- Cache current time
            local t = love.timer.getTime()
            
            -- Initialize drone firing timers if needed
            if not player.drone_timers then
                player.drone_timers = {}
            end
            
            -- Create weapon module reference
            local weapon = require "scripts/weapon"
            
            for i = 1, num_drones do
                -- Initialize timer for this drone if needed
                if not player.drone_timers[i] then
                    player.drone_timers[i] = 0
                end
                
                -- Calculate drone position based on orbit
                local angle = (2 * math.pi / num_drones) * (i-1) + t * orbit_speed
                local px = center_x + math.cos(angle) * orbit_radius
                local py = center_y + math.sin(angle) * orbit_radius
                
                -- Find nearest enemy within hit area
                local nearest_enemy = nil
                local min_dist = hit_area_radius
                for _, e in ipairs(enemy.enemies) do
                    local ex, ey = e.x, e.y
                    local dist = math.sqrt((ex - px)^2 + (ey - py)^2)
                    if dist < min_dist then
                        min_dist = dist
                        nearest_enemy = e
                    end
                end
                
                -- Calculate aim direction (points to nearest enemy or mouse if none)
                local aim_angle
                if nearest_enemy then
                    aim_angle = math.atan2(nearest_enemy.y - py, nearest_enemy.x - px)
                    
                    -- Fire at enemies if timer allows
                    if player.drone_timers[i] <= 0 then
                        -- Fire projectile at enemy using drone settings
                        local drone_projectile_settings = {
                            damage = drone_damage,
                            color = drone_settings.color or {0,0.7,1,1},  -- Use drone color for projectiles
                            speed = drone_settings.projectile_speed or 400,
                            radius = drone_settings.projectile_radius or 6,
                            range = drone_range * 0.8  -- Slightly shorter than detection range
                        }
                        
                        weapon.spawn(px, py, aim_angle, false, drone_projectile_settings)
                        
                        -- Reset firing timer for this drone
                        player.drone_timers[i] = 1 / drone_fire_rate
                        
                        -- Visual feedback that drone fired
                        if not player.drone_flash then player.drone_flash = {} end
                        player.drone_flash[i] = 0.1  -- Flash for 0.1 seconds
                    end
                else
                    -- Just aim at mouse if no enemies
                    local mx, my = love.mouse.getPosition()
                    aim_angle = math.atan2(my - py, mx - px)
                end
                
                -- Update drone firing timer
                if player.drone_timers[i] > 0 then
                    player.drone_timers[i] = player.drone_timers[i] - love.timer.getDelta()
                end
                
                -- Store aim angle for drawing
                local arrow_angle = aim_angle
                -- Initialize drone sprite if it doesn't exist yet
                if not player.drone_sprite then
                    -- Load the drone sprite sheet
                    local drone_settings = settings.weapons.drones
                    local sprite_path = drone_settings.sprite_path
                    local sprite_rows = drone_settings.sprite_rows or 2
                    local sprite_cols = drone_settings.sprite_cols or 2
                    local frame_width = drone_settings.sprite_frame_width or 64
                    local frame_height = drone_settings.sprite_frame_height or 64
                    
                    -- Create the sprite data
                    player.drone_sprite = {
                        image = love.graphics.newImage(sprite_path),
                        quads = {},
                        current_frame = 1,
                        frames = drone_settings.sprite_frames or 4,
                        anim_speed = drone_settings.sprite_anim_speed or 8,
                        anim_timer = 0
                    }
                    
                    -- Create quads for each frame
                    for row = 0, sprite_rows - 1 do
                        for col = 0, sprite_cols - 1 do
                            local index = col + row * sprite_cols + 1
                            if index <= player.drone_sprite.frames then
                                player.drone_sprite.quads[index] = love.graphics.newQuad(
                                    col * frame_width, row * frame_height,
                                    frame_width, frame_height,
                                    player.drone_sprite.image:getDimensions()
                                )
                            end
                        end
                    end
                end
                
                -- Update animation
                player.drone_sprite.anim_timer = player.drone_sprite.anim_timer or 0
                player.drone_sprite.anim_timer = player.drone_sprite.anim_timer + love.timer.getDelta()
                
                if player.drone_sprite.anim_timer >= 1 / player.drone_sprite.anim_speed then
                    player.drone_sprite.current_frame = player.drone_sprite.current_frame % player.drone_sprite.frames + 1
                    player.drone_sprite.anim_timer = 0
                end
                
                -- Pulsating blue glow under the drone (30% opacity, blurred edges)
                local glow_color = drone_settings.color or {0, 0.7, 1, 0.7}
                local t = love.timer.getTime()
                local pulse = 0.7 + 0.3 * math.sin(t * 2)
                local base_alpha = ((glow_color[4] or 0.7) * pulse) * 0.3
                local base_radius = drone_radius * (1.5 + 0.2 * pulse)
                -- Draw blurred glow: multiple circles, larger and more transparent
                for i=5,1,-1 do
                    local blur_alpha = base_alpha * (i/6)
                    local blur_radius = base_radius * (1 + i*0.18)
                    love.graphics.setColor(glow_color[1], glow_color[2], glow_color[3], blur_alpha)
                    love.graphics.circle("fill", px, py, blur_radius)
                end
                -- Draw drone sprite with no tint
                love.graphics.setColor(1,1,1,1)
                love.graphics.draw(
                    player.drone_sprite.image,
                    player.drone_sprite.quads[player.drone_sprite.current_frame],
                    px, py,
                    arrow_angle, -- rotate towards target
                    drone_radius / 32, drone_radius / 32, -- scale to match drone_radius
                    32, 32 -- center of 64x64 frame
                )
                -- The hit area circle is now hidden but still used for collision
                love.graphics.setColor(1,1,1,1)
            end
        end
    end
    -- === On-Beat State & Input ===
    -- Detect if a quarter circle is reaching the full beat (on-beat window)
    local on_beat = false
    for i=1,quarter_count do
        local quarter_start = (i-1)*quarter_duration
        local quarter_progress = (since_full_beat - quarter_start)/quarter_duration
        if math.abs(quarter_progress-1) < (on_beat_buffer/quarter_duration) then
            on_beat = true
            break
        end
    end
    player._on_beat_active = player._on_beat_active or false
    player._on_beat_anim = player._on_beat_anim or 0
    -- Handle spacebar press for on-beat hit
    if on_beat and love.keyboard.isDown("space") and not player._on_beat_active then
        player._on_beat_active = true
        player._on_beat_anim = on_beat_anim_time
        -- Set global on-beat state for projectile and popup
        player._on_beat_triggered = true
        player._on_beat_triggered_time = love.timer.getTime()
        -- Update projectile and popup logic to use the same on-beat settings as beat checker
        local on_beat_color = main.on_beat_color
        local on_beat_scale = main.on_beat_scale
        local on_beat_buffer_time = on_beat_buffer
        -- Spawn projectile using new projectile system
        local weapon = require "scripts/weapon"
        weapon.spawn(gamepad.x, gamepad.y, gamepad.dir or 0, true) -- on_beat
        -- All visuals and logic for on_beat come from settings.main
        -- Spawn popup using new popup system
        local popup = require "scripts/popup"
        popup.spawn({
            x = gamepad.x,
            y = gamepad.y,
            text = settings.popup.text,
            color = on_beat_color,
            font_scale = settings.popup.font_scale,
            fade_duration = settings.popup.fade_duration,
            y_offset = settings.popup.y_offset,
            box = settings.popup.box,
            box_color = settings.popup.box_color,
            box_padding = settings.popup.box_padding,
            outline = settings.popup.outline,
            outline_color = settings.popup.outline_color,
            outline_width = settings.popup.outline_width,
            shadow = settings.popup.shadow,
            shadow_color = settings.popup.shadow_color,
            shadow_offset = settings.popup.shadow_offset,
        })
    end
    -- Animate green fill if on-beat was hit
    if player._on_beat_anim > 0 then
        local t = 1 - (player._on_beat_anim/on_beat_anim_time)
        local ease = 1 - (1-t)^2 -- ease out
        love.graphics.setColor(main.on_beat_color[1], main.on_beat_color[2], main.on_beat_color[3], 1-ease)
        love.graphics.circle("fill", center_x, center_y, base_radius * (main.on_beat_scale or 1.0))
        player._on_beat_anim = math.max(0, player._on_beat_anim - love.timer.getDelta())
        if player._on_beat_anim == 0 then player._on_beat_active = false end
    end
    -- === Draw Player Sprite & Shadow (modular animation system) ===
    local state = player.anim.state
    local conf = anim_settings.states[state]
    -- Defensive: fallback to idle if state is missing/misconfigured
    if not conf or not player.anim.images[state] or not player.anim.quads[state] then
        state = "idle"
        conf = anim_settings.states[state]
    end
    -- Clamp direction and frame to valid grid size
    local dir = math.max(1, math.min(player.anim.direction or 1, conf.grid.rows))
    local frame = math.max(1, math.min(player.anim.frame or 1, conf.grid.cols))
    -- Fallback if quad is missing
    local shadow_quad = player.anim.shadow_quads[state] and player.anim.shadow_quads[state][dir] and player.anim.shadow_quads[state][dir][frame]
    local player_quad = player.anim.quads[state] and player.anim.quads[state][dir] and player.anim.quads[state][dir][frame]
    if not shadow_quad or not player_quad then
        print("[Player] Missing quad for state="..tostring(state).." dir="..tostring(dir).." frame="..tostring(frame)..". Falling back to frame 1, dir 1.")
        dir = 1
        frame = 1
        shadow_quad = player.anim.shadow_quads[state] and player.anim.shadow_quads[state][dir] and player.anim.shadow_quads[state][dir][frame]
        player_quad = player.anim.quads[state] and player.anim.quads[state][dir] and player.anim.quads[state][dir][frame]
    end
    -- Draw shadow first
    love.graphics.setColor(1,1,1,0.6)
    if player.anim.shadows[state] and shadow_quad then
        love.graphics.draw(player.anim.shadows[state], shadow_quad, center_x - conf.frame_size.w/2, center_y - conf.frame_size.h/2 + 8)
    end
    -- Draw player sprite
    love.graphics.setColor(1,1,1,1)
    if player.anim.images[state] and player_quad then
        love.graphics.draw(player.anim.images[state], player_quad, center_x - conf.frame_size.w/2, center_y - conf.frame_size.h/2)
    end
    -- (Optional: draw hit circle for debugging)
    -- love.graphics.setColor(1,0,0,0.2)
    -- love.graphics.circle("line", center_x, center_y, gamepad.radius)
end


return player
