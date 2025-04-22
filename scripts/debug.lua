-- scripts/debug.lua: Simple debug overlay system
local debug = {}
debug.messages = {}

debug.enabled = true

debug.max_lines = 30

function debug.log(msg)
    table.insert(debug.messages, 1, msg)
    if #debug.messages > debug.max_lines then
        table.remove(debug.messages)
    end
end

function debug.draw()
    if not debug.enabled then return end
    love.graphics.setColor(1,0,0,1)
    for i, msg in ipairs(debug.messages) do
        love.graphics.print(msg, 8, 8 + 16*(i-1))
    end
    love.graphics.setColor(1,1,1,1)
end

return debug
