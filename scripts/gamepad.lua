-- scripts/gamepad.lua: Handles all player input and movement logic
local paths = require "paths"
local settings = require "settings"
local gamepad = {}

gamepad.dir = 0        -- radians, facing direction

function gamepad.init(px, py)
    gamepad.x = px
    gamepad.y = py
    gamepad.radius = 16
    gamepad.speed = settings.main.bpm / settings.main.beat_subdivisions * settings.player.speed
    gamepad.aim_x = 1
    gamepad.aim_y = 0
end

function gamepad.update(dt)
    local move_x, move_y = 0, 0
    if love.keyboard.isDown("w") or love.keyboard.isDown("up") then move_y = move_y - 1 end
    if love.keyboard.isDown("s") or love.keyboard.isDown("down") then move_y = move_y + 1 end
    if love.keyboard.isDown("a") or love.keyboard.isDown("left") then move_x = move_x - 1 end
    if love.keyboard.isDown("d") or love.keyboard.isDown("right") then move_x = move_x + 1 end
    if move_x ~= 0 or move_y ~= 0 then
        local len = math.sqrt(move_x*move_x + move_y*move_y)
        move_x, move_y = move_x/len, move_y/len
        gamepad.x = gamepad.x + move_x * gamepad.speed * dt
        gamepad.y = gamepad.y + move_y * gamepad.speed * dt
        gamepad.dir = math.atan2(move_y, move_x)
        gamepad.aim_x = move_x
        gamepad.aim_y = move_y
    else
        -- No movement: set aim_x/aim_y to 0 so player.update detects idle state
        gamepad.aim_x = 0
        gamepad.aim_y = 0
    end
end

function gamepad.clamp_to_bounds(w, h)
    gamepad.x = math.max(gamepad.radius, math.min(w - gamepad.radius, gamepad.x))
    gamepad.y = math.max(gamepad.radius, math.min(h - gamepad.radius, gamepad.y))
end

return gamepad
