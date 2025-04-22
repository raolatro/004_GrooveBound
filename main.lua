-- main.lua for Groove Bound (Prototype)
-- Entry point for the game. Handles game loop, initialization, and orchestrates modules.

local paths = require "paths"
local settings = require "settings"
local player = require "scripts/player"
local enemy = require "scripts/enemy"
local weapon = require "scripts/weapon"
local beat = require "scripts/beat"
local debug = require "scripts/debug"
local camera = require "scripts/camera"
local gamepad = require "scripts/gamepad"
local collision = require "scripts/collision"
local popup = require "scripts/popup"

local arena_margin = 32
local enemy_spawn_timer = 0


function love.load()
    player.init()
    camera.init(gamepad.x, gamepad.y, settings.main.camera_delay)
    debug.log("Game loaded.")
    enemy.spawn_far(gamepad.x, gamepad.y)
    debug.log("Enemy spawned.")
    -- Hook beat event to player visual cue
    beat.on_beat(player.on_beat)
end

function love.update(dt)
    beat.update(dt)
    player.update(dt)
    weapon.update(dt)
    enemy.update(dt, gamepad.x, gamepad.y, weapon.projectiles)
    camera.update(dt, gamepad.x, gamepad.y)
    popup.update(dt)
    -- Enemy spawn logic
    enemy_spawn_timer = enemy_spawn_timer + dt
    if #enemy.enemies < settings.enemy.max_enemies and enemy_spawn_timer >= settings.enemy.spawn_rate then
        enemy.spawn_far(gamepad.x, gamepad.y)
        debug.log("Enemy spawned.")
        enemy_spawn_timer = 0
    end
    -- Shooting logic
    player.fire_timer = player.fire_timer or 0
    player.fire_timer = player.fire_timer - dt
    if love.keyboard.isDown("space") and player.fire_timer <= 0 then
        local dir = gamepad.dir or 0
        local on_beat = player.on_beat_fire
        weapon.spawn(gamepad.x, gamepad.y, dir, on_beat)
        debug.log("Weapon fired.")
        player.register_fire()
        player.fire_timer = settings.projectile.fire_rate
    end
end

function love.draw()
    camera.attach()
    -- Draw arena
    love.graphics.setColor(0.1,0.1,0.1,1)
    love.graphics.rectangle("fill", arena_margin, arena_margin, settings.main.window_width-2*arena_margin, settings.main.window_height-2*arena_margin)
    -- Draw projectiles and Groove! popup
    weapon.draw(gamepad.x, gamepad.y)
    -- Draw enemies and their HP
    enemy.draw()
    -- Draw corpses (placeholder: gray X)
    love.graphics.setColor(0.5,0.5,0.5,1)
    for _, c in ipairs(enemy.corpses) do
        love.graphics.line(c.x-8, c.y-8, c.x+8, c.y+8)
        love.graphics.line(c.x+8, c.y-8, c.x-8, c.y+8)
    end
    -- Draw player (with direction arrow)
    player.draw()
    camera.detach()
    -- Draw beat checker box (top right)
    local beat_num = (beat.current_beat_step or 0) + 1
    local total_beats = settings.main.beat_subdivisions or 4
    local text = tostring(beat_num) .. " / " .. tostring(total_beats)
    local font = love.graphics.getFont()
    local tw, th = font:getWidth(text), font:getHeight()
    local pad = 12
    local box_w, box_h = tw + pad*2, th + pad*2
    local x = love.graphics.getWidth() - box_w - 16
    local y = 16
    love.graphics.setColor(0.2,0.2,0.2,0.85)
    love.graphics.rectangle("fill", x, y, box_w, box_h, 12, 12)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf(text, x, y+pad, box_w, "center")
    -- Draw debug overlay
    debug.draw()
    -- Draw popups (should be on top)
    popup.draw()
end
