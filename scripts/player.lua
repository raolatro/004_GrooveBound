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
        -- Spawn popup using new popup system
        local popup = require "scripts/popup"
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
    else
        player.on_beat_fire = false
        player.beat_flash = 0.12
    end
end

function player.init()
    gamepad.init(settings.main.window_width / 2, settings.main.window_height / 2)
    player.hp = settings.player.hp
    player.want_to_fire = false
    player.fire_timer = 0
end

function player.update(dt)
    gamepad.update(dt)
    gamepad.clamp_to_bounds(settings.main.window_width, settings.main.window_height)

    -- Always aim toward mouse cursor
    local mx, my = love.mouse.getPosition()
    -- Convert screen to world coordinates (camera centered on player)
    local cx, cy = love.graphics.getWidth()/2, love.graphics.getHeight()/2
    local wx = gamepad.x + (mx - cx)
    local wy = gamepad.y + (my - cy)
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
    -- Draw dashed aim line from player to mouse
    local center_x, center_y = gamepad.x, gamepad.y
    local mx, my = love.mouse.getPosition()
    -- Convert mouse to world coordinates (camera centered on player)
    local cx, cy = love.graphics.getWidth()/2, love.graphics.getHeight()/2
    local wx = gamepad.x + (mx - cx)
    local wy = gamepad.y + (my - cy)
    love.graphics.setColor(1,1,1,0.3)
    love.graphics.setLineWidth(1)
    local dash = 12
    local gap = 7
    local dx, dy = wx - center_x, wy - center_y
    local len = math.sqrt(dx*dx + dy*dy)
    local steps = math.floor(len / (dash + gap))
    for i=0,steps-1 do
        local t1 = (i * (dash + gap)) / len
        local t2 = ((i * (dash + gap)) + dash) / len
        if t2 > 1 then t2 = 1 end
        local x1 = center_x + dx * t1
        local y1 = center_y + dy * t1
        local x2 = center_x + dx * t2
        local y2 = center_y + dy * t2
        love.graphics.line(x1, y1, x2, y2)
    end
    love.graphics.setColor(1,1,1,1)
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
