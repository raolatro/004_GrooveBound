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
local settings_menu = require "scripts/settings_menu"

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
    settings_menu.update(dt)
    if settings_menu.active then return end -- Pause game logic if menu is open
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
    -- Shooting logic is now handled in love.mousepressed (left click)
    player.fire_timer = player.fire_timer or 0
    player.fire_timer = player.fire_timer - dt
    -- (Space bar shooting removed)

end

function love.draw()
    -- Draw everything else first...
    -- (Beat checker text removed as requested)
    -- Draw everything that should move with the camera
    -- Draw everything that moves with the camera
    camera.attach()
    love.graphics.setColor(0.1,0.1,0.1,1)
    love.graphics.rectangle("fill", arena_margin, arena_margin, settings.main.window_width-arena_margin*2, settings.main.window_height-arena_margin*2)
    love.graphics.setColor(1,1,1,1)
    enemy.draw()
    player.draw()
    weapon.draw(gamepad.x, gamepad.y)
    popup.draw()
    -- Draw corpses (placeholder: gray X) INSIDE camera so they are fixed in world
    love.graphics.setColor(0.5,0.5,0.5,1)
    for _, c in ipairs(enemy.corpses) do
        love.graphics.line(c.x-8, c.y-8, c.x+8, c.y+8)
        love.graphics.line(c.x+8, c.y-8, c.x-8, c.y+8)
    end
    camera.detach()
    -- Draw everything that should stay fixed on screen (UI, overlays)

    -- Draw settings menu overlay LAST, outside of camera, so it is always in the foreground and doesn't affect camera stack
    settings_menu.draw()
    -- Draw debug overlay
    debug.draw()
    -- (Beat checker box and duplicate player.draw() removed to avoid camera stack errors and UI clutter)

    -- Draw popups (should be on top)
    -- (Removed duplicate popup.draw() to prevent duplicate popups)
end

-- Ensure settings menu receives mouse and key events
function love.mousepressed(x, y, button)
    print('DEBUG: love.mousepressed called, forwarding to settings_menu')
    settings_menu.mousepressed(x, y, button)
    if settings_menu.active then return end
    -- Player shooting with left mouse button
    if button == 1 then
        if player.fire_timer == nil or player.fire_timer <= 0 then
            local dir = gamepad.dir or 0
            local on_beat = player.on_beat_fire
            weapon.spawn(gamepad.x, gamepad.y, dir, on_beat)
            debug.log("Weapon fired (mouse click).")
            player.register_fire()
            player.fire_timer = settings.projectile.fire_rate
        end
    end
    -- (rest of your mouse handling logic here)
end

function love.keypressed(key)
    print('DEBUG: love.keypressed called, forwarding to settings_menu')
    if settings_menu.active then settings_menu.keypressed(key) return end
    -- (rest of your key handling logic here)
end
