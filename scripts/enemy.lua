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

local function get_settings(k)
    -- Map old keys to new grouped settings
    local map = {
        enemy_speed = settings.enemy.speed,
        enemy_hp = settings.enemy.hp,
        enemy_flash_duration = settings.enemy.flash_duration,
        window_width = settings.main.window_width,
        window_height = settings.main.window_height,
        max_enemies = settings.enemy.max_enemies,
        enemy_spawn_rate = settings.enemy.spawn_rate
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
    table.insert(enemy.enemies, {x=x, y=y, hp=get_settings('enemy_hp'), flash=0})
    -- debug.log("Enemy spawned far.")
end

function enemy.update(dt, player_x, player_y, projectiles)
    local player_radius = 16
    local enemy_radius = 12
    enemy.explosions = enemy.explosions or {}
    for i = #enemy.enemies, 1, -1 do
        local e = enemy.enemies[i]
        -- Draw HP above enemy (move this to enemy.draw or love.draw)
        -- (This block will be moved to enemy.draw implementation)
        -- Move toward player, but stop at collision radius
        local dx, dy = player_x - e.x, player_y - e.y
        local dist = math.sqrt(dx*dx + dy*dy)
        if dist > player_radius + enemy_radius then
            e.x = e.x + get_settings('enemy_speed') * dx/dist * dt
            e.y = e.y + get_settings('enemy_speed') * dy/dist * dt
        else
            -- Enemy touches player: sacrifice, deal damage, and explode
            local player = require "scripts/player"
            player.damage(1)
            -- Mark explosion (store with timestamp)
            table.insert(enemy.explosions, {x=e.x, y=e.y, t=love.timer.getTime()})
            sfx.play('dead') -- Play death SFX
            table.remove(enemy.enemies, i)
            -- debug.log("Enemy sacrificed: player damaged!")
            -- No corpse left
            -- continue to next enemy (no goto)
        end
        -- check collision with projectiles
        for j = #projectiles, 1, -1 do
            local p = projectiles[j]
            local e_radius = e.is_boss and (e.boss_radius or 40) or (e.radius or settings.enemy.radius or 20)
if collision.circle_circle(e.x, e.y, e_radius, p.x, p.y, p.radius) then
                -- Scalable: use projectile damage type
                local dmg = p.on_beat and settings.projectile.on_beat_damage or settings.projectile.normal_damage
                e.hp = e.hp - dmg
                e.flash = get_settings('enemy_flash_duration')
                local killed_by_groove = (p.on_beat and e.hp <= 0)
                table.remove(projectiles, j)
                -- debug.log("Enemy hit!" .. (killed_by_groove and " Killed by groove!" or ""))
                if e.hp <= 0 then
                    table.insert(enemy.corpses, {x=e.x, y=e.y})
                    -- Spawn loot drop near corpse
                    loot.spawn(e.x, e.y)
                    sfx.play('dead') -- Play death SFX
                    table.remove(enemy.enemies, i)
                    -- debug.log("Enemy dead!")
                    -- Score system
                    scoring.add_kill(killed_by_groove)
                    -- Popup if killed by groove
                    if killed_by_groove then
                        local popup = require "scripts/popup"
                        popup.spawn({
                            x = e.x + (settings.enemy.radius or 20) + 20,
                            y = e.y,
                            text = settings.popup.killed_text,
                            color = settings.popup.killed_color,
                            font_size = 18,
                            fade_duration = settings.popup.fade_duration,
                            stay_duration = settings.popup.stay_duration,
                            y_offset = 0,
                        })
                    end
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
    -- Cache font by size
    enemy._hp_font = enemy._hp_font or love.graphics.newFont(hp_settings.font_size)
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
        if e.is_boss then
            -- Draw miniboss with custom color and radius
            love.graphics.setColor(e.boss_color or {1,1,0,1})
            love.graphics.circle("fill", e.x, e.y, e.boss_radius or 40)
            -- Yellow outline for miniboss
            love.graphics.setColor(1,1,0,1)
            love.graphics.setLineWidth(4)
            love.graphics.circle("line", e.x, e.y, (e.boss_radius or 40) + 2)
            love.graphics.setLineWidth(1)
        else
            -- Draw normal enemy
            love.graphics.setColor(1,0.2,0.2,1)
            love.graphics.circle("fill", e.x, e.y, settings.enemy.radius or 20)
        end
        -- Draw HP above enemy
        if e.hp and e.hp > 0 then
            local prev_font = love.graphics.getFont()
            love.graphics.setFont(enemy._hp_font)
            love.graphics.setColor(hp_settings.color)
            local hp_text = tostring(e.hp)
            local text_width = enemy._hp_font:getWidth(hp_text)
            love.graphics.print(hp_text, e.x - text_width / 2, e.y + (hp_settings.y_offset or -18))
            love.graphics.setFont(prev_font)
            love.graphics.setColor(1,1,1,1)
        end
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
    table.insert(enemy.enemies, {
        x = x, y = y, hp = hp, speed = speed, radius = radius, is_boss = true,
        boss_color = color, boss_radius = radius, boss_sfx = sfx, flash = 0
    })
    local sfxmod = require "scripts/sfx"
    if sfx then sfxmod.play(sfx) end
    -- debug.log("Mini Boss spawned!")
end

return enemy
