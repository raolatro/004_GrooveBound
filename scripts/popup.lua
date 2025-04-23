-- popup.lua: General-purpose popup system for GrooveBound
-- Allows popups to be placed on any entity (player, enemy, etc) with customizable appearance
local popup = {}
popup.active = {}
popup._fonts = {} -- cache fonts by size
local settings = require "settings"

-- Popup spawn
function popup.spawn(args)
    -- args: {x, y, text, color, font_size, fade_duration, y_offset, box, box_color, box_padding, outline, outline_color, outline_width, shadow, shadow_color, shadow_offset}
    local s = settings.popup
    local p = {
        x = args.x or 0,
        y = args.y or 0,
        text = args.text or s.text,
        color = args.on_beat and settings.main.on_beat_color or (args.color or s.color),
        font_size = args.font_size or s.font_size,
        fade_duration = args.on_beat and settings.main.beat_checker_on_beat_anim_time or (args.fade_duration or s.fade_duration),
        timer = args.on_beat and settings.main.beat_checker_on_beat_anim_time or (args.fade_duration or s.fade_duration),
        y_offset = args.y_offset or s.y_offset,
        box = args.box == nil and s.box or args.box,
        box_color = args.box_color or s.box_color,
        box_padding = args.box_padding or s.box_padding,
        outline = args.outline == nil and s.outline or args.outline,
        outline_color = args.outline_color or s.outline_color,
        outline_width = args.outline_width or s.outline_width,
        shadow = args.shadow == nil and s.shadow or args.shadow,
        shadow_color = args.shadow_color or s.shadow_color,
        shadow_offset = args.shadow_offset or s.shadow_offset,
    }
    table.insert(popup.active, p)
    return p
end

function popup.update(dt)
    for i = #popup.active, 1, -1 do
        local p = popup.active[i]
        p.timer = p.timer - dt
        if p.timer <= 0 then table.remove(popup.active, i) end
    end
end

function popup.draw()
    local font = love.graphics.getFont()
    for _, p in ipairs(popup.active) do
        local alpha = math.max(0, p.timer / p.fade_duration)
        local text = p.text
        love.graphics.push()
        love.graphics.translate(p.x, p.y + (p.y_offset or 0))
        -- Set font for popup
        local hud = require "scripts/hud"
        local popup_font = popup._fonts[p.font_size]
        if not popup_font then
            -- Use the main HUD font if the size matches, else create/cached
            if p.font_size == hud.font_size then
                popup_font = hud.font
            else
                popup_font = love.graphics.newFont(hud.font_path, p.font_size)
            end
            popup._fonts[p.font_size] = popup_font
        end
        local prev_font = love.graphics.getFont()
        love.graphics.setFont(popup_font)
        -- Shadow
        if p.shadow then
            love.graphics.setColor(p.shadow_color[1], p.shadow_color[2], p.shadow_color[3], (p.shadow_color[4] or 1) * alpha)
            love.graphics.print(text, (p.shadow_offset and p.shadow_offset[1]) or 2, (p.shadow_offset and p.shadow_offset[2]) or 2)
        end
        -- Box
        if p.box then
            local tw = font:getWidth(text) * (p.font_size or 1)
            local th = font:getHeight() * (p.font_size or 1)
            love.graphics.setColor(p.box_color[1], p.box_color[2], p.box_color[3], (p.box_color[4] or 1) * alpha)
            love.graphics.rectangle("fill", -p.box_padding, -p.box_padding, tw + p.box_padding*2, th + p.box_padding*2, 8, 8)
        end
        -- Outline
        if p.outline then
            local tw = font:getWidth(text) * (p.font_size or 1)
            local th = font:getHeight() * (p.font_size or 1)
            love.graphics.setColor(p.outline_color[1], p.outline_color[2], p.outline_color[3], (p.outline_color[4] or 1) * alpha)
            love.graphics.setLineWidth(p.outline_width or 2)
            love.graphics.rectangle("line", -p.box_padding, -p.box_padding, tw + p.box_padding*2, th + p.box_padding*2, 8, 8)
            love.graphics.setLineWidth(1)
        end
        -- Text
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], (p.color[4] or 1) * alpha)
        love.graphics.print(text, 0, 0)
        love.graphics.setFont(prev_font)
        love.graphics.pop()
    end
end

return popup
