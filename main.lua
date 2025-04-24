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
local level_stats = require "scripts/level_stats"
local pause_menu = require "scripts/pause_menu"
local scenario = require "scripts/scenario"

require("scripts/init_fonts")()

-- Define arena margin and make it accessible to other modules
arena_margin = 32
scenario.settings.arena_margin = arena_margin

local enemy_spawn_timer = 0
-- Wave and boss escalation variables
wave_timer = settings.wave_duration or 15
boss_timer = settings.boss_duration or 60
current_wave = 1
current_boss = 0



function love.resize(w, h)
    -- Update scenario dimensions on window resize
    scenario.resize(w, h)
end

function love.load()
    -- Load custom cursor image
    custom_cursor = {
        image = love.graphics.newImage("assets/img/target1-idle.png"),
        enabled = true
    }
    -- Hide system cursor
    love.mouse.setVisible(false)
    
    hud.load_fonts() -- Ensure HUD fonts are loaded before anything else
    hud.reset() -- Ensure HUD and fonts are always initialized
    player.init()
    camera.init(gamepad.x, gamepad.y, settings.main.camera_delay)
    -- Initialize scenario system (floor, background, etc.)
    -- Make sure scenario uses the correct arena margin
    scenario.settings.arena_margin = arena_margin
    scenario.init()
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
    -- Always update game over screen if active, and halt all gameplay mechanics
    if game_over.active then
        if game_over.update then game_over.update(dt) end
        return
    end
    hud.update(dt)
    -- Update popups (must be called every frame)
    require("scripts/popup").update(dt)
    -- Keep level_stats in sync
    if level_stats then
        level_stats.set_wave(current_wave)
        if current_boss and current_boss > 0 then
            level_stats.set_boss(current_boss)
        else
            level_stats.set_boss(nil)
        end
    end
    -- Pause logic
    if pause_menu.active or game_paused then
        return
    end
    -- Main gameplay update
    player.update(dt)
    enemy.update(dt, gamepad.x, gamepad.y, weapon.projectiles)
    weapon.update(dt)
    loot.update(dt, gamepad.x, gamepad.y, player.radius)
    gamepad.update(dt)
    camera.update(dt, gamepad.x, gamepad.y)
    -- Drones update (skip if paused)
    if not (pause_menu.active or game_paused) and player.drones then
        for _, drone in ipairs(player.drones) do
            drone:update(dt)
        end
    end
    -- Enemy spawn logic
    enemy_spawn_timer = enemy_spawn_timer + dt
    
    -- Get current wave settings
    local current_wave_settings = settings.waves[current_wave] or settings.waves[1]
    
    if #enemy.enemies < current_wave_settings.max_enemies and enemy_spawn_timer >= current_wave_settings.spawn_rate then
        enemy.spawn_far(gamepad.x, gamepad.y)
        -- debug.log("Enemy spawned.")
        enemy_spawn_timer = 0
    end
    -- Wave escalation logic
    wave_timer = wave_timer - dt
    boss_timer = boss_timer - dt
    if wave_timer <= 0 then
        if current_wave < #settings.waves then
            current_wave = current_wave + 1
            -- Wave settings are now used directly in enemy.lua, no need to copy to settings.enemy
            -- Just update the global current_wave variable which is already done above
            wave_timer = settings.wave_duration or 15
            debug.log("Wave "..current_wave.." started!")
            
            -- Create big wave announcement popup using the same style as boss notifications
            popup.create_notification("WAVE " .. current_wave, popup.STYLES.MAIN, {0.1, 0.8, 0.1, 1}) -- Green
            
            -- Play sound effect if available
            if sfx and sfx.play then
                sfx.play('wave')
            end
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
            
            -- Create dramatic boss announcement popup using the notification system
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            
            -- Boss warning popup using main style
            popup.create_notification("BOSS " .. current_boss .. " INCOMING!!", popup.STYLES.MAIN, {1, 0.1, 0.1, 1}) -- Brighter red
            
            -- Second popup using subhead style
            popup.create_notification("Prepare for battle!", popup.STYLES.SUBHEAD, {1, 0.8, 0, 1}) -- Gold text
            
            -- Update level stats display
            local level_stats = require "scripts/level_stats"
            level_stats.set_boss(current_boss)
            
            -- Play boss alert sound
            if sfx and sfx.play then
                sfx.play(boss_sfx or 'boss')
            end
            
            -- Spawn the boss
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
    popup.update(dt)
    -- Use beat checker outline radius for attraction & pickup
    local outline_radius = (player.outline_radius or gamepad.radius)
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
                    
                    -- Add to inventory but get the result to know what happened
                    local success, action, category, level = inventory.add(d.id)
                    sfx.play('weapon')
                    
                    -- Get weapon info
                    local md = settings.item_data
                    local weapon_settings = settings.weapons[category]
                    local display_name = weapon_settings and weapon_settings.display_name or category:upper()
                    
                    -- Get weapon color for color-coding the notification
                    local color = md.Items[d.id] and md.Items[d.id].color or {1, 1, 1, 1}
                    
                    -- Display notification ONLY if it's a new weapon ('added')
                    -- Level Up and Max Level popups are handled inside inventory.add()
                    if action == "added" then
                        -- New weapon notification
                        popup.create_notification("Got a new " .. display_name .. "!!", popup.STYLES.WEAPON, color)
                    end
                    -- Note: 'level_up' and 'max_level' popups handled internally by inventory.add
                    -- If action is "full", inventory is full, no popup needed here.
                end
                table.remove(loot.drops, i)
            end
        end
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
    -- Draw game state: game over, pause menu, or normal gameplay
    if game_over.active then
        game_over.draw()
    elseif pause_menu.active or game_paused then
        debug.log("[Main] Drawing pause menu (pause_menu.active=" .. tostring(pause_menu.active) .. ", game_paused=" .. tostring(game_paused) .. ")")
        -- Only pause_menu.draw handles the pause overlay and UI
        pause_menu.draw()
    else
        -- Camera translation (centered on player)
        camera.attach()
        -- Draw everything else first...
        -- (Beat checker text removed as requested)
        -- Draw everything that should move with the camera
        -- Draw everything that moves with the camera
        
        -- Draw floor tiles
        scenario.draw_floor()
        
        -- Draw arena boundary (now as a faint outline since we have floor tiles)
        love.graphics.setColor(0.3, 0.3, 0.3, 0.4)
        love.graphics.rectangle("line", arena_margin, arena_margin, settings.main.window_width-arena_margin*2, settings.main.window_height-arena_margin*2)
        -- Draw corpses under entities
        love.graphics.setColor(0.5,0.5,0.5,1)
        for _, c in ipairs(enemy.corpses) do
            love.graphics.line(c.x-8, c.y-8, c.x+8, c.y+8)
            love.graphics.line(c.x+8, c.y-8, c.x-8, c.y+8)
        end
        -- Draw loot drops
        loot.draw()
        love.graphics.setColor(1,1,1,1)
        player.draw()
        enemy.draw()
        loot.draw(gamepad.x, gamepad.y)
        weapon.draw(gamepad.x, gamepad.y)
        camera.detach()
    end
    
    -- Draw UI elements that should be on top, regardless of game state
    -- Draw popups above gameplay and UI
    require("scripts/popup").draw()
    
    -- Draw loot/weapon attraction debug overlay
    loot.draw_debug(gamepad.x, gamepad.y, (player.outline_radius or gamepad.radius))
    
    -- Draw wave and boss info at top bar when not in game over
    if not game_over.active then
        love.graphics.setColor(1,1,1,1)
        local wave_text = string.format("Wave: %d", current_wave)
        local boss_text = string.format("Mini Boss: %d", current_boss)
        love.graphics.print(wave_text, 320, 16)
        love.graphics.print(boss_text, 480, 16)
    end
    
    -- Draw 'Game paused' left of hamburger menu if paused
    if game_paused and not pause_menu.active then
        local menu_x, menu_y = 24, 24
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print("Game paused", menu_x + 50, menu_y)
    end
    
    -- Draw HUD overlay
    hud.draw()
    
    -- Draw debug overlay at the very end, over absolutely everything else
    debug.draw()
    
    -- Draw custom cursor last (if in gameplay)
    if custom_cursor.enabled and not (game_over.active or pause_menu.active or game_paused) then
        love.graphics.setColor(1, 1, 1, 1)
        local mx, my = love.mouse.getPosition()
        love.graphics.draw(custom_cursor.image, mx, my, 0, 1, 1, custom_cursor.image:getWidth()/2, custom_cursor.image:getHeight()/2)
    end
end

-- Ensure hud. receives mouse and key events
function love.mousepressed(x, y, button)
    print('DEBUG: love.mousepressed called')
    -- Check for game over screen interactions first
    if game_over.active then
        if game_over.mousepressed(x, y, button) then return end
    end
    
    -- Check for pause menu interactions when paused
    if pause_menu.active or game_paused then
        if pause_menu.mousepressed(x, y, button) then return end
    end
    
    -- Handle HUD interactions
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
            -- Toggle the dedicated pause menu and sync global pause flag
            pause_menu.toggle()
            game_paused = pause_menu.active
        end
    end
    if key == "space" or key == "z" then
        player.register_fire() -- Use register_fire, not try_fire
    end
    print('DEBUG: love.keypressed called, forwarding to hud')
    if hud.active then hud.keypressed(key) return end
    -- (rest of your key handling logic here)
end
