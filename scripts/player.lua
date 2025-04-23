-- scripts/player.lua: Handles player logic
local paths = require "paths"
local settings = require "settings"
local gamepad = require "scripts/gamepad"
local sprite_registry = require "scripts/sprite_registry"
local player = {}

player.sprite = sprite_registry.player

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
                local num_drones = weapon_settings.count or 2
                local orbit_radius = weapon_settings.orbit_radius or (48 + 8 * (w.level or 1))
                local drone_radius = weapon_settings.drone_radius or 10
                local t = love.timer.getTime()
                for i = 1, num_drones do
                    local angle = (2 * math.pi / num_drones) * (i-1) + t * 0.7 -- rotate with time
                    local px = gamepad.x + math.cos(angle) * orbit_radius
                    local py = gamepad.y + math.sin(angle) * orbit_radius
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

function player.init()
    gamepad.init(settings.main.window_width / 2, settings.main.window_height / 2)
    player.max_hp = settings.player.hp or 3
    player.hp = player.max_hp
    player.want_to_fire = false
    player.fire_timer = 0
    -- Ensure player always starts with the forward gun
    local inventory = require "scripts/inventory"
    inventory.add('forwardGun')
    inventory.debug_print() -- Debug: print inventory after adding forwardGun
    -- Sync HP to hud for UI
    local hud = require "scripts/hud"
    hud.player_max_hp = player.max_hp
    hud.player_hp = player.hp
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
    gamepad.update(dt)
    gamepad.clamp_to_bounds(settings.main.window_width, settings.main.window_height)

    -- Always aim toward mouse cursor
    local camera = require "scripts/camera"
    local mx, my = love.mouse.getPosition()
    -- Convert screen to world coordinates (camera position)
    local cx, cy = love.graphics.getWidth()/2, love.graphics.getHeight()/2
    local wx = camera.x + (mx - cx)
    local wy = camera.y + (my - cy)
    local dx, dy = wx - gamepad.x, wy - gamepad.y
    if dx ~= 0 or dy ~= 0 then
        gamepad.dir = math.atan2(dy, dx)
    end

    -- Sprite animation state logic
    local moving = (math.abs(gamepad.aim_x) > 0.1 or math.abs(gamepad.aim_y) > 0.1)
    if moving then
        player.sprite:set_state("walk")
    else
        player.sprite:set_state("idle")
    end
    player.sprite:update(dt)
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
        love.graphics.setColor(1,1,0,0.8)
        love.graphics.setLineWidth(2)
        love.graphics.line(center_x, center_y, wx, wy)
        love.graphics.setColor(1,1,1,1)
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

    -- === Full Beat Circle (always visible) ===
    love.graphics.setColor(1,1,1,full_beat_opacity)
    love.graphics.setLineWidth(full_beat_outline_width)
    love.graphics.circle("line", center_x, center_y, base_radius)
    -- === Quarter Beat Circles ===
    for i=1,quarter_count do
        local quarter_start = (i-1)*quarter_duration
        local quarter_progress = (since_full_beat - quarter_start)/quarter_duration
        if quarter_progress >= 0 and quarter_progress < 1 then
            local scale = quarter_progress
            local alpha = quarter_opacity
            love.graphics.setColor(1,1,1,alpha)
            love.graphics.setLineWidth(quarter_outline_width)
            love.graphics.circle("line", center_x, center_y, base_radius*scale)
        end
    end
    love.graphics.setLineWidth(1)
    -- === Drone Visuals ===
    local inventory = require "scripts/inventory"
    local enemy = require "scripts/enemy"
    for _, w in ipairs(inventory.get_active()) do
        if w.category == "drones" then
            -- Always use up-to-date settings for orbit and size
            local drone_level = w.level or 1
            local drone_settings = settings.weapons.drones and settings.weapons.drones[drone_level] or {}
            local num_drones = drone_settings.count or 2
            local orbit_radius = drone_settings.orbit_radius or (48 + 8 * drone_level)
            local drone_radius = drone_settings.drone_radius or 10
            -- Get drone range from settings if available
            local drone_level = w.level or 1
            local drone_settings = settings.weapons.drones and settings.weapons.drones[drone_level] or {}
            local drone_range = drone_settings.range or ((w.hit_area_mult or 3) * drone_radius)
            local hit_area_radius = drone_range
            local t = love.timer.getTime()
            for i = 1, num_drones do
                local angle = (2 * math.pi / num_drones) * (i-1) + t * 0.7
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
                -- Calculate arrow direction: points to nearest enemy or mouse if none
                local arrow_angle
                if nearest_enemy then
                    arrow_angle = math.atan2(nearest_enemy.y - py, nearest_enemy.x - px)
                else
                    local mx, my = love.mouse.getPosition()
                    arrow_angle = math.atan2(my - py, mx - px)
                end
                -- Draw drone body
                love.graphics.setColor(w.color or {0,1,1,1})
                love.graphics.circle("fill", px, py, drone_radius)
                -- Draw hit area: thin outline and 10% opacity fill
                love.graphics.setColor((w.color and {w.color[1],w.color[2],w.color[3],0.10}) or {0,1,1,0.10})
                love.graphics.circle("fill", px, py, hit_area_radius)
                love.graphics.setColor((w.color and {w.color[1],w.color[2],w.color[3],0.7}) or {0,1,1,0.7})
                love.graphics.setLineWidth(2)
                love.graphics.circle("line", px, py, hit_area_radius)
                love.graphics.setLineWidth(1)
                -- Draw arrow (triangle) inside drone
                local arrow_len = drone_radius * 0.9
                local arrow_w = drone_radius * 0.7
                local tip_x = px + math.cos(arrow_angle) * arrow_len
                local tip_y = py + math.sin(arrow_angle) * arrow_len
                local left_x = px + math.cos(arrow_angle + math.pi*0.75) * (arrow_w/2)
                local left_y = py + math.sin(arrow_angle + math.pi*0.75) * (arrow_w/2)
                local right_x = px + math.cos(arrow_angle - math.pi*0.75) * (arrow_w/2)
                local right_y = py + math.sin(arrow_angle - math.pi*0.75) * (arrow_w/2)
                love.graphics.setColor(0,0,0,0.8)
                love.graphics.polygon("fill", tip_x, tip_y, left_x, left_y, right_x, right_y)
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
    -- Draw the player sprite (rotated)
    local dir = gamepad.dir or 0
    player.sprite:draw(center_x, center_y, 1, dir - math.pi/2, {1,1,1,1})
    -- (Optional: draw hit circle for debugging)
    -- love.graphics.setColor(1,0,0,0.2)
    -- love.graphics.circle("line", center_x, center_y, gamepad.radius)
end


return player
