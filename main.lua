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
local sfx = require "scripts/sfx"
local hud = require "scripts/hud"
local game_over = require "scripts/game_over"
local loot = require "scripts/loot"
local inventory = require "scripts/inventory"

local arena_margin = 32
local enemy_spawn_timer = 0
-- Wave and boss escalation variables
wave_timer = settings.wave_duration or 15
boss_timer = settings.boss_duration or 60
current_wave = 1
current_boss = 0



function love.load()
    hud.reset() -- Ensure HUD and fonts are always initialized
    player.init()
    camera.init(gamepad.x, gamepad.y, settings.main.camera_delay)
    debug.log("Game loaded.")
    -- debug.log("Milestone: Attraction and snap/ease-in features enabled.")
    enemy.spawn_far(gamepad.x, gamepad.y)
    -- debug.log("Enemy spawned.")
    -- Hook beat event to player visual cue
    beat.on_beat(player.on_beat)
    -- Give player starting forward gun
    inventory.add("forwardGun")
    -- Reset escalation
    wave_timer = settings.wave_duration or 15
    boss_timer = settings.boss_duration or 60
    current_wave = 1
    current_boss = 0
end

game_paused = game_paused or false

function love.update(dt)
    hud.update(dt)
    if hud.active or game_over.active or game_paused then return end -- Pause game logic if menu is open, game over, or paused
    -- Wave escalation logic
    wave_timer = wave_timer - dt
    boss_timer = boss_timer - dt
    if wave_timer <= 0 then
        if current_wave < #settings.waves then
            current_wave = current_wave + 1
            local wave = settings.waves[current_wave]
            if wave then
                settings.enemy.hp = wave.hp
                settings.enemy.speed = wave.speed
                settings.enemy.spawn_rate = wave.spawn_rate
                settings.enemy.max_enemies = wave.max_enemies
            end
            wave_timer = settings.wave_duration or 15
            debug.log("Wave "..current_wave.." started!")
        else
            -- Last wave reached, pause wave timer
            wave_timer = 0
        end
    end
    -- Boss escalation logic
    if boss_timer <= 0 then
        if current_boss < #settings.boss.hp then
            current_boss = current_boss + 1
            -- Spawn miniboss
            local boss_hp = settings.boss.hp[math.min(current_boss,#settings.boss.hp)]
            local boss_speed = settings.boss.speed[math.min(current_boss,#settings.boss.speed)]
            local boss_radius = settings.boss.radius[math.min(current_boss,#settings.boss.radius)]
            local boss_color = settings.boss.color[math.min(current_boss,#settings.boss.color)]
            local boss_sfx = settings.boss.sfx[math.min(current_boss,#settings.boss.sfx)]
            if enemy.spawn_boss then
                enemy.spawn_boss(gamepad.x, gamepad.y, boss_hp, boss_speed, boss_radius, boss_color, boss_sfx)
            end
            boss_timer = settings.boss_duration or 60
            debug.log("Mini Boss "..current_boss.." spawned!")
        else
            -- Absolute final boss reached
            debug.log("ABSOLUTE FINAL BOSS REACHED!!!!!!!")
            boss_timer = 0
        end
    end
    if boss_timer <= 0 then
        current_boss = current_boss + 1
        -- Spawn miniboss
        local boss_hp = settings.boss.hp[math.min(current_boss,#settings.boss.hp)]
        local boss_speed = settings.boss.speed[math.min(current_boss,#settings.boss.speed)]
        local boss_radius = settings.boss.radius[math.min(current_boss,#settings.boss.radius)]
        local boss_color = settings.boss.color[math.min(current_boss,#settings.boss.color)]
        local boss_sfx = settings.boss.sfx[math.min(current_boss,#settings.boss.sfx)]
        if enemy.spawn_boss then
            enemy.spawn_boss(gamepad.x, gamepad.y, boss_hp, boss_speed, boss_radius, boss_color, boss_sfx)
        end
        boss_timer = settings.boss_duration or 60
        debug.log("Mini Boss "..current_boss.." spawned!")
    end
    beat.update(dt)
    player.update(dt)
    weapon.update(dt)
    enemy.update(dt, gamepad.x, gamepad.y, weapon.projectiles)
    camera.update(dt, gamepad.x, gamepad.y)
    popup.update(dt)
    -- Use beat checker outline radius for attraction & pickup
    local outline_radius = (player.outline_radius or gamepad.radius)
    loot.update(dt, gamepad.x, gamepad.y, outline_radius)
    -- Handle loot pickup collisions
    do
        local px, py = gamepad.x, gamepad.y
        for i = #loot.drops, 1, -1 do
            local d = loot.drops[i]
            local dx, dy = d.x - px, d.y - py
            local pickup_radius = outline_radius
            if dx*dx + dy*dy <= pickup_radius*pickup_radius then
                if d.id == "money" then
                    -- debug.log('Coin picked up!')
                    sfx.play('coin')
                    local md = settings.item_data
                    local amt = md.Items.money.baseValue * md.Rarity[d.rarity].multiplier
                    hud.money = (hud.money or 0) + amt
                    popup.spawn({ x = px, y = py - 20, text = "+"..amt.."₵", color = md.Rarity[d.rarity].color })
                else
                    debug.log('Weapon picked up: '..d.id..' | Rarity: '..d.rarity)
                    inventory.add(d.id)
                    sfx.play('weapon')
                    local md = settings.item_data
                    popup.spawn({ x = px, y = py - 20, text = "New "..d.id, color = md.Items[d.id].color })
                end
                table.remove(loot.drops, i)
            end
        end
    end
    -- Enemy spawn logic
    enemy_spawn_timer = enemy_spawn_timer + dt
    if #enemy.enemies < settings.enemy.max_enemies and enemy_spawn_timer >= settings.enemy.spawn_rate then
        enemy.spawn_far(gamepad.x, gamepad.y)
        -- debug.log("Enemy spawned.")
        enemy_spawn_timer = 0
    end
    -- Auto-Fire and manual fire logic
    player.fire_timer = player.fire_timer or 0
    player.fire_timer = player.fire_timer - dt

    if not hud.auto_fire_enabled then
        -- Manual: fire only while mouse is held
        if player.is_mouse_down and player.fire_timer <= 0 then
            local dir = gamepad.dir or 0
            local on_beat = player.on_beat_fire
            weapon.spawn(gamepad.x, gamepad.y, dir, on_beat)
            -- debug.log("Weapon fired (mouse held down).")
            player.register_fire()
            player.fire_timer = settings.projectile.fire_rate
        end
    else
        -- Auto-Fire: fire if aiming at enemy
        local found = false
        for _, e in ipairs(enemy.enemies) do
            local dx, dy = e.x - gamepad.x, e.y - gamepad.y
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0 then
                local angle_to_enemy = math.atan2(dy, dx)
                local angle_diff = math.abs((angle_to_enemy - (gamepad.dir or 0) + math.pi) % (2*math.pi) - math.pi)
                if angle_diff < (settings.main.auto_fire_angle or 0.15) then -- configurable auto-fire angle
                    found = true
                    break
                end
            end
        end
        if found and player.fire_timer <= 0 then
            local dir = gamepad.dir or 0
            local on_beat = player.on_beat_fire
            weapon.spawn(gamepad.x, gamepad.y, dir, on_beat)
            debug.log("Weapon auto-fired at enemy.")
            player.register_fire()
            player.fire_timer = settings.projectile.fire_rate
        end
    end

end

function love.draw()
    if game_over.active then
        game_over.draw()
        return
    end
    -- Draw everything else first...
    -- (Beat checker text removed as requested)
    -- Draw everything that should move with the camera
    -- Draw everything that moves with the camera
    camera.attach()
    love.graphics.setColor(0.1,0.1,0.1,1)
    love.graphics.rectangle("fill", arena_margin, arena_margin, settings.main.window_width-arena_margin*2, settings.main.window_height-arena_margin*2)
    -- Draw corpses under entities
    love.graphics.setColor(0.5,0.5,0.5,1)
    for _, c in ipairs(enemy.corpses) do
        love.graphics.line(c.x-8, c.y-8, c.x+8, c.y+8)
        love.graphics.line(c.x+8, c.y-8, c.x-8, c.y+8)
    end
    -- Draw loot drops
    loot.draw()
    love.graphics.setColor(1,1,1,1)
    enemy.draw()
    player.draw()
    weapon.draw(gamepad.x, gamepad.y)
    popup.draw()
    camera.detach()
    -- Draw everything that should stay fixed on screen (UI, overlays)

    -- Draw hud. overlay LAST, outside of camera, so it is always in the foreground and doesn't affect camera stack
    hud.draw()
    -- Draw debug overlay
    debug.draw()
    -- Draw loot/weapon attraction debug overlay
    loot.draw_debug(gamepad.x, gamepad.y, (player.outline_radius or gamepad.radius))
    -- (Beat checker box and duplicate player.draw() removed to avoid camera stack errors and UI clutter)

    -- Draw popups (should be on top)
    -- (Removed duplicate popup.draw() to prevent duplicate popups)

    -- Draw wave and boss info at top bar
    love.graphics.setColor(1,1,1,1)
    local wave_text = string.format("Wave: %d", current_wave)
    local boss_text = string.format("Mini Boss: %d", current_boss)
    love.graphics.print(wave_text, 320, 16)
    love.graphics.print(boss_text, 480, 16)
    love.graphics.setColor(1,1,1,1)

    -- Draw 'Game paused' left of hamburger menu if paused
    if game_paused then
        local menu_x, menu_y = 24, 24
        local font = love.graphics.getFont()
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Game paused", menu_x + 50, menu_y)
        love.graphics.setColor(1,1,1,1)
    end
end

-- Ensure hud. receives mouse and key events
function love.mousepressed(x, y, button)
    print('DEBUG: love.mousepressed called')
    if game_over.active then
        if game_over.mousepressed(x, y, button) then return end
    end
    hud.mousepressed(x, y, button)
    if hud.active then return end
    -- Track mouse down for firing
    if button == 1 then
        player.is_mouse_down = true
    end
    -- (rest of your mouse handling logic here)
end

function love.mousereleased(x, y, button)
    if button == 1 then
        player.is_mouse_down = false
    end
end

function love.keypressed(key)
    if key == "escape" then
        if hud.active then
            hud.active = false
        else
            game_paused = not game_paused
        end
    end
    if key == "space" or key == "z" then
        player.register_fire() -- Use register_fire, not try_fire
    end
    print('DEBUG: love.keypressed called, forwarding to hud')
    if hud.active then hud.keypressed(key) return end
    -- (rest of your key handling logic here)
end
