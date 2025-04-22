-- scripts/game_over.lua: Handles the game over page UI and logic for GrooveBound
local settings = require "settings"
local player = require "scripts/player"
local enemy = require "scripts/enemy"
local weapon = require "scripts/weapon"
local gamepad = require "scripts/gamepad"
local game_over = {}

game_over.active = false

game_over.score = 0

game_over.kills = 0

function game_over.show(score, kills, player_hp)
    game_over.active = true
    game_over.score = score or 0
    game_over.kills = kills or 0
    game_over.player_hp = player_hp or 0
end

function game_over.hide()
    game_over.active = false
end

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
    love.graphics.setFont(love.graphics.newFont(32))
    love.graphics.printf("GAME OVER", box_x, box_y+28, box_w, "center")
    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.printf("Final Score", box_x, box_y+90, box_w, "center")
    love.graphics.setFont(love.graphics.newFont(28))
    love.graphics.printf(tostring(game_over.score), box_x, box_y+120, box_w, "center")
    love.graphics.setFont(love.graphics.newFont(22))
    love.graphics.printf("Kills", box_x, box_y+170, box_w, "center")
    love.graphics.setFont(love.graphics.newFont(28))
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
    love.graphics.setFont(love.graphics.newFont(24))
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
            local settings_menu = require "scripts/settings_menu"
            settings_menu.score = 0
            settings_menu.kills = 0
            settings_menu.player_hp = tonumber(settings.player.hp) or 5
            settings_menu.player_max_hp = tonumber(settings.player.hp) or 5
            settings_menu.game_over = false
            player.init()
            enemy.enemies = {}
            enemy.corpses = {}
            enemy.explosions = {}
            weapon.projectiles = {}
            gamepad.init(settings.main.window_width/2, settings.main.window_height/2)
            enemy.spawn_far(gamepad.x, gamepad.y)
            return true
        end
    end
    return false
end

return game_over
