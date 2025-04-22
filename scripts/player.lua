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
    -- Determine sprite rotation based on direction
    -- 0 = down, pi/2 = left, pi = up, -pi/2 = right
    local dir = gamepad.dir or 0
    -- Draw sprite at full opacity, no fade
    player.sprite:draw(gamepad.x, gamepad.y, 1, dir - math.pi/2, {1,1,1,1})
    -- (Optional: draw hit circle for debugging)
    -- love.graphics.setColor(1,0,0,0.2)
    -- love.graphics.circle("line", gamepad.x, gamepad.y, gamepad.radius)
end

return player
