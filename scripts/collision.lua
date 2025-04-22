-- scripts/collision.lua: General collision system
local collision = {}

function collision.circle_circle(x1, y1, r1, x2, y2, r2)
    local dx, dy = x2 - x1, y2 - y1
    return (dx*dx + dy*dy) <= (r1 + r2)^2
end

function collision.rect_rect(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

return collision
