-- scripts/camera.lua: Smooth camera follow system with zoom support
local camera = {
    x = 0,
    y = 0,
    tx = 0,
    ty = 0,
    delay = 0.5,
    zoom = 1.0,         -- Current zoom level (1.0 = normal)
    zoom_min = 0.7,     -- Minimum zoom (zoomed out)
    zoom_max = 2.0,     -- Maximum zoom (zoomed in)
    zoom_step = 0.1     -- Zoom increment per keypress
}

function camera.init(px, py, delay)
    camera.x, camera.y = px, py
    camera.tx, camera.ty = px, py
    camera.delay = delay or 0.5
    camera.zoom = 1.0  -- Reset zoom to default
end

function camera.update(dt, target_x, target_y)
    camera.tx, camera.ty = target_x, target_y
    local lerp = 1 - math.exp(-dt / camera.delay)
    camera.x = camera.x + (camera.tx - camera.x) * lerp
    camera.y = camera.y + (camera.ty - camera.y) * lerp
end

-- Zoom in (increase zoom level)
function camera.zoom_in()
    camera.zoom = math.min(camera.zoom + camera.zoom_step, camera.zoom_max)
    print("Camera zoom: " .. string.format("%.1f", camera.zoom))
end

-- Zoom out (decrease zoom level)
function camera.zoom_out()
    camera.zoom = math.max(camera.zoom - camera.zoom_step, camera.zoom_min)
    print("Camera zoom: " .. string.format("%.1f", camera.zoom))
end

function camera.attach()
    love.graphics.push()
    -- Apply zoom and translation together
    love.graphics.translate(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
    love.graphics.scale(camera.zoom, camera.zoom)
    love.graphics.translate(-camera.x, -camera.y)
end

function camera.detach()
    love.graphics.pop()
end

return camera
