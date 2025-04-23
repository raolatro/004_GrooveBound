-- scripts/game_over.lua: Handles the game over page UI and logic for GrooveBound
local settings = require "settings"
local player = require "scripts/player"
local enemy = require "scripts/enemy"
local weapon = require "scripts/weapon"
local gamepad = require "scripts/gamepad"
local game_over = {}

-- Font system for game over screen
function game_over.reload_fonts()
    game_over._fonts = {
        header = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.header),
        body = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.body),
        button = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.button)
    }
end
game_over.reload_fonts()

game_over.active = false

game_over.score = 0

game_over.kills = 0

function game_over.show(score, kills, player_hp)
    game_over.active = true
    game_over.score = score or 0
    game_over.kills = kills or 0
    game_over.player_hp = player_hp or 0
    -- Show system cursor on game over screen
    love.mouse.setVisible(true)
end

function game_over.hide()
    game_over.active = false
    -- Hide system cursor when returning to gameplay
    love.mouse.setVisible(false)
end

local hud = require "scripts/hud"
function game_over.draw()
    if not game_over.active then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local box_w, box_h = 400, 320
    local box_x, box_y = (w-box_w)/2, (h-box_h)/2
    love.graphics.setColor(0,0,0,0.92)
    love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, 18, 18)
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", box_x, box_y, box_w, box_h, 18, 18)
    love.graphics.setLineWidth(1)
    love.graphics.setColor(1,0.2,0.2,1)
    love.graphics.setFont(hud.font)
    love.graphics.printf("GAME OVER", 0, h/2-80, w, "center")
    love.graphics.setFont(hud.font)
    love.graphics.printf("Final Score", box_x, box_y+90, box_w, "center")
    love.graphics.setFont(hud.font)
    love.graphics.printf(tostring(game_over.score), box_x, box_y+120, box_w, "center")
    love.graphics.setFont(hud.font)
    love.graphics.printf("Kills", box_x, box_y+170, box_w, "center")
    love.graphics.setFont(hud.font)
    love.graphics.setFont(game_over._fonts.header)
    love.graphics.printf(tostring(game_over.kills), box_x, box_y+200, box_w, "center")
    -- Restart button
    local btn_w, btn_h = 180, 48
    local btn_x, btn_y = w/2-btn_w/2, box_y+box_h-80
    game_over._restart_btn = {x=btn_x, y=btn_y, w=btn_w, h=btn_h}
    love.graphics.setColor(0.15,0.7,1,1)
    love.graphics.rectangle("fill", btn_x, btn_y, btn_w, btn_h, 12, 12)
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", btn_x, btn_y, btn_w, btn_h, 12, 12)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(game_over._fonts.button)
    love.graphics.printf("RESTART", btn_x, btn_y+10, btn_w, "center")
end

local function mouse_in_box(x, y, box)
    return x >= box.x and x <= box.x+box.w and y >= box.y and y <= box.y+box.h
end

function game_over.mousepressed(x, y, button)
    if game_over.active and game_over._restart_btn and button == 1 then
        if mouse_in_box(x, y, game_over._restart_btn) then
            -- Reset all properties and stats
            game_over.hide()
            local hud = require "scripts/hud"
            local debug = require "scripts/debug"
            
            -- Reset HUD and stats
            debug.log("[Game] Restarting game - resetting all stats and weapons")
            hud.score = 0
            hud.kills = 0
            hud.money = 0 
            hud.reset() -- Fully reset HUD state and fonts
            hud.player_hp = tonumber(settings.player.hp) or 5
            hud.player_max_hp = tonumber(settings.player.hp) or 5
            hud.game_over = false
            
            -- CRITICAL FIX: Reset all item level definitions to level 1
            if _G.reset_item_levels then
                debug.log("[Game] Resetting all weapon level definitions to level 1")
                settings.item_data.Items = _G.reset_item_levels()
            end
            
            -- Reset inventory - first fully clear all slots
            local inventory = require "scripts/inventory"
            inventory.reset() -- This empties all inventory slots
            
            -- Add only starting weapon at level 1
            inventory.add('forwardGun')
            debug.log("[Game] Reset inventory to only level 1 forward gun")
            
            -- Remove any drone timers or other weapon-specific state
            if player.drone_timers then player.drone_timers = {} end
            if player.drone_flash then player.drone_flash = {} end
            
            -- Reset player position and state
            player.init()
            
            -- Clear ALL enemies, projectiles, corpses, etc.
            enemy.enemies = {}
            enemy.corpses = {}
            if enemy.explosions then enemy.explosions = {} end
            weapon.projectiles = {}
            debug.log("[Game] Cleared all enemies and projectiles")
            
            -- Reset loot drops
            local loot = require "scripts/loot"
            loot.drops = {}
            
            -- Reset to Wave 1
            if package.loaded["main"] then
                _G.current_wave = 1
                debug.log("[Game] Reset to Wave 1")
            end
            
            -- Reset escalation system to wave 1
            if package.loaded["main"] then
                local main = package.loaded["main"]
                _G.wave_timer = settings.wave_duration or 10
                _G.boss_timer = settings.boss_duration or 30
                _G.current_wave = 1
                _G.current_boss = 0
                debug.log("[Game] Reset to wave 1")
            end
            
            -- Reset level_stats display
            local level_stats = require "scripts/level_stats"
            level_stats.set_wave(1)
            level_stats.set_boss(nil)
            
            -- Reinitialize player position
            gamepad.init(settings.main.window_width/2, settings.main.window_height/2)
            
            -- Spawn a single wave 1 enemy
            enemy.spawn_far(gamepad.x, gamepad.y)
            
            debug.log("[Game] Game successfully restarted")
            return true
        end
    end
    return false
end

return game_over
