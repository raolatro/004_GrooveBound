-- scripts/enemy.lua: Handles enemy logic
local paths = require "paths"
local settings = require "settings"
local sfx = require "scripts/sfx"
local collision = require "scripts/collision"
local debug = require "scripts/debug"

local settings_menu = require "scripts/hud"
local scoring = require "scripts/scoring"
local loot = require "scripts/loot"
local enemy = {}
enemy.enemies = {}
enemy.corpses = {}

defaults = { enemy_speed = 60, enemy_hp = 2, enemy_flash_duration = 0.18 }

-- Load enemy1 walk and death spritesheets
local enemy1_walk_img = love.graphics.newImage(settings.enemy1.walk_sprite)
local enemy1_death_img = love.graphics.newImage(settings.enemy1.death_sprite)

-- Precompute enemy1 walk and death quads
local walk_quads = {}
for row=1,settings.enemy1.walk_grid.rows do
    walk_quads[row] = {}
    for col=1,settings.enemy1.walk_grid.cols do
        walk_quads[row][col] = love.graphics.newQuad(
            (col-1)*settings.enemy1.walk_frame_size.w,
            (row-1)*settings.enemy1.walk_frame_size.h,
            settings.enemy1.walk_frame_size.w,
            settings.enemy1.walk_frame_size.h,
            enemy1_walk_img:getDimensions()
        )
    end
end
local death_quads = {}
for row=1,settings.enemy1.death_grid.rows do
    death_quads[row] = {}
    for col=1,settings.enemy1.death_grid.cols do
        death_quads[row][col] = love.graphics.newQuad(
            (col-1)*settings.enemy1.death_frame_size.w,
            (row-1)*settings.enemy1.death_frame_size.h,
            settings.enemy1.death_frame_size.w,
            settings.enemy1.death_frame_size.h,
            enemy1_death_img:getDimensions()
        )
    end
end

-- Helper: get direction row from dx, dy
local function get_direction_row(dx, dy)
    local absdx, absdy = math.abs(dx), math.abs(dy)
    if absdx > absdy then
        return dx > 0 and settings.enemy1.directions.right or settings.enemy1.directions.left
    else
        return dy > 0 and settings.enemy1.directions.down or settings.enemy1.directions.up
    end
end


local function get_settings(k)
    -- Get current wave settings
    local current_wave = _G.current_wave or 1
    local wave = settings.waves[current_wave] or settings.waves[1]
    
    -- Map keys to settings
    local map = {
        enemy_speed = wave.speed,
        enemy_hp = wave.hp,
        enemy_flash_duration = settings.enemy.flash_duration, -- Keep this from settings.enemy as it's not in waves
        window_width = settings.main.window_width,
        window_height = settings.main.window_height,
        max_enemies = wave.max_enemies,
        enemy_spawn_rate = wave.spawn_rate
    }
    return map[k] or defaults[k]
end

function enemy.spawn_far(player_x, player_y)
    -- Spawn at a random position at least 200px from player
    local min_dist = 200
    local tries = 0
    local x, y
    repeat
        x = math.random(get_settings('window_width'))
        y = math.random(get_settings('window_height'))
        tries = tries + 1
    until ((x-player_x)^2 + (y-player_y)^2) > min_dist^2 or tries > 10
    -- Get HP from wave settings
    local hp = get_settings('enemy_hp')
    -- Initialize animation state for walk
    table.insert(enemy.enemies, {
        x=x, y=y, hp=hp, max_hp=hp, flash=0,
        anim_timer=0, anim_frame=1, anim_row=settings.enemy1.directions.down, state="walk", dead_time=0, death_played=false
    })
    -- debug.log("Enemy spawned far.")
end

function enemy.update(dt, player_x, player_y, projectiles)
    -- Handle shop timer if a boss was recently killed
    if enemy.pending_shop and enemy.shop_timer then
        enemy.shop_timer = enemy.shop_timer - dt
        
        if enemy.shop_timer <= 0 then
            -- Reset the timer and flag
            enemy.shop_timer = nil
            enemy.pending_shop = false
            
            -- Get current player level
            local player_level = require("scripts/player").level or 1
            
            -- Show the shop menu using the global shop_menu variable
            shop_menu.show(player_level)
            
            -- Force game to pause
            _G.game_paused = true
            
            debug.log("Shop menu opened after boss kill - menu active: " .. tostring(shop_menu.active))
        end
    end
    
    local player_radius = 16
    local enemy_radius = 12
    enemy.explosions = enemy.explosions or {}
    for i = #enemy.enemies, 1, -1 do
        local e = enemy.enemies[i]
        -- Animation: determine direction (row) based on movement toward player
        local dx, dy = player_x - e.x, player_y - e.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if e.state == "walk" then
            -- Move toward player, but stop at collision radius
            local move_speed = e.is_boss and (e.speed or get_settings('enemy_speed') * 1.5) or get_settings('enemy_speed')
            local collision_radius = e.is_boss and (e.radius or 40) or enemy_radius
            
            if dist > player_radius + collision_radius then
                e.x = e.x + move_speed * dx/dist * dt
                e.y = e.y + move_speed * dy/dist * dt
                e.anim_row = get_direction_row(dx, dy)
            else
                -- Enemy touches player: deal damage, trigger explosion, and remove enemy
                local player = require "scripts/player"
                local damage = e.is_boss and 2 or 1 -- Bosses deal more damage
                player.damage(damage)
                table.insert(enemy.explosions, {x=e.x, y=e.y, t=love.timer.getTime()})
                sfx.play(e.boss_sfx or 'dead') -- Play boss-specific SFX if available
                table.remove(enemy.enemies, i)
                -- No corpse left, continue to next enemy
                break
            end
            -- Animation timer for walk
            e.anim_timer = e.anim_timer + dt
            local fps = settings.enemy1.walk_fps
            if e.anim_timer > 1/fps then
                e.anim_timer = e.anim_timer - 1/fps
                e.anim_frame = e.anim_frame % settings.enemy1.walk_grid.cols + 1
            end
        elseif e.state == "death" then
            -- Death animation timer
            e.anim_timer = e.anim_timer + dt
            local fps = settings.enemy1.death_fps
            if not e.death_played then
                if e.anim_timer > 1/fps then
                    e.anim_timer = e.anim_timer - 1/fps
                    e.anim_frame = e.anim_frame + 1
                    if e.anim_frame > settings.enemy1.death_grid.cols then
                        e.anim_frame = settings.enemy1.death_grid.cols
                        e.death_played = true
                        e.dead_time = love.timer.getTime()
                    end
                end
            else
                -- Remove enemy after death animation has played fully (wait 0.2s)
                if love.timer.getTime() - e.dead_time > 0.2 then
                    table.remove(enemy.enemies, i)
                end
            end
        end
        -- check collision with projectiles
        for j = #projectiles, 1, -1 do
            local p = projectiles[j]
            local e_radius = e.is_boss and (e.boss_radius or 40) or (e.radius or 30)
            if collision.circle_circle(e.x, e.y, e_radius, p.x, p.y, p.radius) then
                -- Scalable: use projectile damage type
                local base_dmg = p.on_beat and settings.projectile.on_beat_damage or settings.projectile.normal_damage
                
                -- Bosses take 2.5x damage from player attacks
                local dmg_multiplier = e.is_boss and 2.5 or 1
                local final_dmg = base_dmg * dmg_multiplier
                
                -- Apply damage and show debug message for boss hits
                e.hp = e.hp - final_dmg
                if e.is_boss then
                    debug.log("Boss hit! Damage: " .. final_dmg .. " (" .. base_dmg .. " x " .. dmg_multiplier .. ")")
                end
                e.flash = get_settings('enemy_flash_duration')
                local killed_by_groove = (p.on_beat and e.hp <= 0)
                table.remove(projectiles, j)
                -- debug.log("Enemy hit!" .. (killed_by_groove and " Killed by groove!" or ""))
                if e.hp <= 0 and e.state ~= "death" then
                    table.insert(enemy.corpses, {x=e.x, y=e.y})
                    
                    -- Spawn multiple loot drops based on enemy type and current wave
                    local current_wave = _G.current_wave or 1
                    local total_loot_value = loot.spawn_multiple(
                        e.x, e.y,         -- Position 
                        e.is_boss,         -- Is this a boss?
                        killed_by_groove,  -- Was it killed with rhythm/groove?
                        current_wave       -- Current wave for scaling
                    )
                    
                    -- Play death sound effect
                    sfx.play(e.is_boss and (e.boss_sfx or 'boss_death') or 'dead')
                    
                    -- Save enemy's original HP (for XP) before removing it
                    local original_hp = get_settings('enemy_hp')
                    local enemy_x, enemy_y = e.x, e.y
                    
                    -- Debug log for loot drops
                    debug.log(string.format("%s dropped $%d worth of loot", 
                        e.is_boss and "Boss" or "Enemy", total_loot_value))
                    
                    -- If this was a boss, trigger the shop menu after a short delay
                    if e.is_boss then
                        debug.log("Boss killed! Opening shop menu soon...")
                        -- Create a timer to open the shop after the death animation
                        -- This ensures everything resolves before the shop appears
                        enemy.shop_timer = 1.5 -- seconds delay
                        enemy.pending_shop = true
                    end
                    
                    -- Start death animation
                    e.state = "death"
                    e.anim_frame = 1
                    e.anim_timer = 0
                    e.anim_row = e.anim_row or settings.enemy1.directions.down
                    e.death_played = false
                    -- Score system - pass HP and position for XP
                    scoring.add_kill(killed_by_groove, original_hp, enemy_x, enemy_y)
                    -- Popup if killed by groove
                    -- if killed_by_groove then
                        -- local popup = require "scripts/popup"
                        -- popup.spawn({
                        --     x = e.x + 30 + 20, -- Use fixed radius of 30 (from settings.enemy.radius)
                        --     y = e.y,
                        --     text = settings.popup.killed_text,
                        --     color = settings.popup.killed_color,
                        --     font_size = 18,
                        --     fade_duration = settings.popup.fade_duration,
                        --     stay_duration = settings.popup.stay_duration,
                        --     y_offset = 0,
                        -- })
                    -- end
                    break
                end
            end
        end
        -- Flash timer
        if e.flash and e.flash > 0 then
            e.flash = e.flash - dt
            if e.flash < 0 then e.flash = 0 end
        end
    end
end

function enemy.draw()
    -- Draw all enemies and their HP
    local hp_settings = settings.enemy_hp_display
    -- Draw explosions (sacrificed enemies)
    enemy.explosions = enemy.explosions or {}
    local now = love.timer.getTime()
    for i = #enemy.explosions, 1, -1 do
        local ex = enemy.explosions[i]
        local t = now - ex.t
        local duration = 0.6
        if t > duration then
            table.remove(enemy.explosions, i)
        else
            local alpha = 1 - t/duration
            local radius = 20 + 60 * (t/duration)
            love.graphics.setColor(1,0.4,0.1,alpha)
            love.graphics.circle("fill", ex.x, ex.y, radius)
            love.graphics.setColor(1,1,0.3,alpha*0.6)
            love.graphics.circle("fill", ex.x, ex.y, radius*0.6)
            love.graphics.setColor(1,1,1,1)
        end
    end
    for _, e in ipairs(enemy.enemies) do
        -- Store reference to max HP if not already stored
        -- This helps us track the original HP for the HP bar
        if not e.max_hp and e.hp then
            e.max_hp = e.hp
        end
        
        if e.is_boss then
            -- Draw miniboss with custom color and radius
            love.graphics.setColor(e.boss_color or {1,1,0,1})
            love.graphics.circle("fill", e.x, e.y, e.boss_radius or 40)
            -- Yellow outline for miniboss
            love.graphics.setColor(1,1,0,1)
            love.graphics.setLineWidth(4)
            love.graphics.circle("line", e.x, e.y, (e.boss_radius or 40) + 2)
            love.graphics.setLineWidth(1)
            
            -- Draw red HP bar under boss
            if e.hp and e.max_hp and e.hp > 0 and e.state ~= "death" then
                -- HP bar dimensions and positioning
                local bar_width = (e.boss_radius or 40) * 2
                local bar_height = 8
                local bar_x = e.x - bar_width / 2
                local bar_y = e.y + (e.boss_radius or 40) + 5
                
                -- Background (black outline)
                love.graphics.setColor(0, 0, 0, 0.8)
                love.graphics.rectangle("fill", bar_x - 1, bar_y - 1, bar_width + 2, bar_height + 2)
                
                -- Red HP bar
                love.graphics.setColor(0.9, 0.2, 0.2, 1)
                local hp_ratio = e.hp / e.max_hp
                love.graphics.rectangle("fill", bar_x, bar_y, bar_width * hp_ratio, bar_height)
            end
        else
            -- Draw enemy1 sprite (walk or death)
            love.graphics.setColor(1,1,1,1)
            local quad, img
            if e.state == "walk" then
                quad = walk_quads[e.anim_row or settings.enemy1.directions.down][e.anim_frame]
                img = enemy1_walk_img
            elseif e.state == "death" then
                quad = death_quads[e.anim_row or settings.enemy1.directions.down][e.anim_frame]
                img = enemy1_death_img
            end
            if quad and img then
                love.graphics.draw(img, quad, e.x - settings.enemy1.walk_frame_size.w/2, e.y - settings.enemy1.walk_frame_size.h/2)
            end
            
            -- Draw red HP bar under regular enemy
            if e.hp and e.max_hp and e.hp > 0 and e.state ~= "death" then
                -- HP bar dimensions and positioning
                local bar_width = settings.enemy1.walk_frame_size.w
                local bar_height = 4
                local bar_x = e.x - bar_width / 2
                local bar_y = e.y + settings.enemy1.walk_frame_size.h/2 + 2
                
                -- Background (black outline)
                love.graphics.setColor(0, 0, 0, 0.8)
                love.graphics.rectangle("fill", bar_x - 1, bar_y - 1, bar_width + 2, bar_height + 2)
                
                -- Red HP bar
                love.graphics.setColor(0.9, 0.2, 0.2, 1)
                local hp_ratio = e.hp / e.max_hp
                love.graphics.rectangle("fill", bar_x, bar_y, bar_width * hp_ratio, bar_height)
            end
        end
        
        -- (Removed HP text display for a cleaner look)
    end
end

-- Spawn a miniboss with custom stats
function enemy.spawn_boss(player_x, player_y, hp, speed, radius, color, sfx)
    -- Spawn at a random position at least 300px from player
    local min_dist = 300
    local tries = 0
    local x, y
    repeat
        x = math.random(settings.main.window_width)
        y = math.random(settings.main.window_height)
        tries = tries + 1
    until ((x-player_x)^2 + (y-player_y)^2) > min_dist^2 or tries > 10
    
    -- Add essential state and animation properties for proper movement
    table.insert(enemy.enemies, {
        x = x, y = y, hp = hp, max_hp = hp, speed = speed, radius = radius, is_boss = true,
        boss_color = color, boss_radius = radius, boss_sfx = sfx, flash = 0,
        -- Add these essential properties for update logic to work
        state = "walk", -- This is critical - allows update to move the boss
        anim_timer = 0,
        anim_frame = 1,
        anim_row = settings.enemy1.directions.down
    })
    
    local sfxmod = require "scripts/sfx"
    if sfx then sfxmod.play(sfx) end
    debug.log("Boss spawned with speed: " .. speed)
end

return enemy
