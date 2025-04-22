-- scripts/camera.lua: Smooth camera follow system
local camera = {x = 0, y = 0, tx = 0, ty = 0, delay = 0.5}

function camera.init(px, py, delay)
    camera.x, camera.y = px, py
    camera.tx, camera.ty = px, py
    camera.delay = delay or 0.5
end

function camera.update(dt, target_x, target_y)
    camera.tx, camera.ty = target_x, target_y
    local lerp = 1 - math.exp(-dt / camera.delay)
    camera.x = camera.x + (camera.tx - camera.x) * lerp
    camera.y = camera.y + (camera.ty - camera.y) * lerp
end

function camera.attach()
    love.graphics.push()
    love.graphics.translate(love.graphics.getWidth()/2 - camera.x, love.graphics.getHeight()/2 - camera.y)
end

function camera.detach()
    love.graphics.pop()
end

return camera
