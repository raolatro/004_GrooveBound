-- popup.lua: General-purpose popup system for GrooveBound
-- Allows popups to be placed on any entity (player, enemy, etc) with customizable appearance
local popup = {}
popup.active = {}
popup.notification_stack = {} -- Special stack for notification popups (centered at top)
popup._fonts = {} -- cache fonts by size
local settings = require "settings"

-- Types of popups
popup.TYPES = {
    NOTIFICATION = "notification", -- Big notifications like wave start, boss, level up
    STANDARD = "standard"        -- Regular popups like pickups, etc
}

-- Notification styles
popup.STYLES = {
    MAIN = "main",         -- For major announcements (boss, wave)
    SUBHEAD = "subhead",  -- For secondary information
    WEAPON = "weapon"     -- For weapon pickups and level-ups
}
local font = settings.main.fonts

-- Popup spawn
-- Helper function to create a notification popup with a predefined style
function popup.create_notification(text, style_name, color)
    -- Filter notifications - only allow wave and boss notifications
    -- Skip weapon-related notifications by checking the style and text content
    if style_name == popup.STYLES.WEAPON then
        -- Skip all weapon-related notifications
        return nil
    end
    
    -- Also skip level up notifications, keeping only wave and boss
    if text:match("LEVEL UP") then
        -- We still want to show the main level up notification
        if style_name ~= popup.STYLES.MAIN then
            return nil
        end
    end
    
    local style = settings.popup.styles[style_name] or settings.popup.styles.subhead
    if not style then
        style = {}
    end
    
    -- Override font size to ensure uniform smaller size for all notifications
    local uniform_font_size = 24 -- Smaller uniform size for all notifications
    
    -- Apply the style's settings with size override, but remove box and outline for notifications
    local args = {
        text = text,
        color = color or style.color or {1, 1, 1, 1},
        font_size = uniform_font_size, -- Use uniform size instead of style's font_size
        fade_duration = style.fade_duration,
        hold_time = style.hold_time,
        box = false, -- Remove background box
        box_color = nil,
        box_padding = 0,
        outline = false, -- Remove outline
        outline_color = nil,
        outline_width = 0,
        shadow = style.shadow,
        shadow_color = style.shadow_color,
        shadow_offset = style.shadow_offset,
        popup_type = popup.TYPES.NOTIFICATION,  -- Always a notification
        right_aligned = true -- Flag to indicate right alignment
    }
    
    return popup.spawn(args)
end

-- Helper function to find non-overlapping position for popups
local function find_non_overlapping_position(base_x, base_y, existing_popups)
    local padding = 15
    local attempts = 0
    local x, y = base_x, base_y
    
    while attempts < 10 do
        local collision = false
        for _, p in ipairs(existing_popups) do
            if math.abs(p.x - x) < padding and math.abs(p.y - y) < padding then
                collision = true
                x = x + (math.random() * 20 - 10)
                y = y - padding
                break
            end
        end
        if not collision then break end
        attempts = attempts + 1
    end
    return x, y
end

function popup.spawn(args)
    -- args: {x, y, text, color, font_size, fade_duration, hold_time, y_offset, box, box_color, box_padding, outline, outline_color, outline_width, shadow, shadow_color, shadow_offset, popup_type}
    local s = settings.popup
    
    -- Hold time: how long to show at full opacity before fading
    local hold_time = args.hold_time or 2.0 -- Default 2 seconds hold time
    
    -- Use the provided font size directly without reduction
    local font_size = args.font_size or s.font_size
    
    local p = {
        x = args.x or 0,
        y = args.y or 0,
        text = args.text or s.text,
        color = args.on_beat and settings.main.on_beat_color or (args.color or s.color),
        font_size = font_size,
        fade_duration = args.on_beat and settings.main.beat_checker_on_beat_anim_time or (args.fade_duration or s.fade_duration),
        timer = args.on_beat and settings.main.beat_checker_on_beat_anim_time or (args.fade_duration or s.fade_duration) + hold_time, -- Add hold time to total life
        hold_time = hold_time, -- Store hold time for alpha calculation
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
        -- Add popup type to classify different popups
        popup_type = args.popup_type or popup.TYPES.STANDARD,
        -- Calculated width and height (filled in when drawn)
        width = 0,
        height = 0
    }
    
    -- Handle notification popups differently
    if p.popup_type == popup.TYPES.NOTIFICATION then
        -- For notifications, position on the right side below Kills HUD
        local w = love.graphics.getWidth()
        local right_margin = 20 -- Space from right edge
        local top_margin = 260  -- MUCH larger margin from top for more space below HUD
        
        -- Position x on the right side of the screen
        p.x = w - right_margin
        p.y = top_margin -- Increased Y position below the Kills HUD
        
        -- Stack notifications to avoid overlapping
        -- Calculate position based on existing notifications
        local total_height = 0
        for _, existing in ipairs(popup.notification_stack) do
            total_height = total_height + existing.height + 10 -- 10px spacing between stacked notifications
        end
        p.y = p.y + total_height
        
        -- Set right-aligned flag
        p.right_aligned = args.right_aligned or false
        
        -- Add to notification stack
        table.insert(popup.notification_stack, p)
    else
        -- For standard popups, use position collision avoidance
        local player = require "scripts/player"
        local px = (player and player.x) or (love.graphics.getWidth() / 2)
        local py = (player and player.y) or (love.graphics.getHeight() / 2)
        if type(px) ~= 'number' then px = love.graphics.getWidth() / 2 end
        if type(py) ~= 'number' then py = love.graphics.getHeight() / 2 end
        local x, y = find_non_overlapping_position(px, py - 50, popup.active)
        p.x = x
        p.y = y
    end
    
    table.insert(popup.active, p)
    return p
end

-- Function moved above popup.spawn

function popup.update(dt)
    -- Update all active popups
    for i = #popup.active, 1, -1 do
        local p = popup.active[i]
        p.timer = p.timer - dt
        
        -- Remove expired popups
        if p.timer <= 0 then 
            -- Also remove from notification stack if it's a notification
            if p.popup_type == popup.TYPES.NOTIFICATION then
                for j = #popup.notification_stack, 1, -1 do
                    if popup.notification_stack[j] == p then
                        table.remove(popup.notification_stack, j)
                        break
                    end
                end
            end
            table.remove(popup.active, i) 
        end
    end
    
    -- Reposition notification stack after removing any expired popups
    if #popup.notification_stack > 0 then
        local current_y = 100 -- Start with top margin
        for _, p in ipairs(popup.notification_stack) do
            p.y = current_y + (p.height / 2) -- Center point of the popup
            current_y = current_y + p.height + 10 -- Add height + spacing
        end
    end
end

function popup.draw()
    for _, p in ipairs(popup.active) do
        -- Calculate alpha with hold time: full opacity during hold time, then fade
        local alpha = 1.0
        if p.timer <= p.fade_duration then
            alpha = math.max(0, p.timer / p.fade_duration)
        end
        local text = p.text
        love.graphics.push()
        
        -- Special handling for notification popups (centered at top)
        if p.popup_type == popup.TYPES.NOTIFICATION then
            -- Notifications are positioned in absolute coordinates
            -- NOTE: y_offset is ignored for notification popups since they use fixed positioning
            love.graphics.translate(p.x, p.y)
        else
            -- Standard popups use their original position + y_offset
            -- This is where y_offset from settings is applied
            love.graphics.translate(p.x, p.y + (p.y_offset or -30))  -- Bring closer to character
        end
        
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
        
        -- Calculate popup dimensions for stacking
        local tw = popup_font:getWidth(text)
        local th = popup_font:getHeight()
        
        -- Box dimensions (with padding)
        local box_width = tw + (p.box_padding or 0) * 2
        local box_height = th + (p.box_padding or 0) * 2
        
        -- Store dimensions for positioning in stack
        p.width = box_width
        p.height = box_height
        
        -- For notifications, position text based on alignment
        local text_x = 0
        if p.popup_type == popup.TYPES.NOTIFICATION then
            if p.right_aligned then
                text_x = -tw  -- Right-align the text
            else
                text_x = -tw/2  -- Center the text horizontally
            end
        end
        
        -- Shadow
        if p.shadow then
            -- Handle both number and table for shadow_offset
            local sx, sy = 2, 2
            if type(p.shadow_offset) == "table" then
                sx = p.shadow_offset[1] or 2
                sy = p.shadow_offset[2] or 2
            elseif type(p.shadow_offset) == "number" then
                sx = p.shadow_offset
                sy = p.shadow_offset
            end
            love.graphics.setColor(p.shadow_color[1], p.shadow_color[2], p.shadow_color[3], (p.shadow_color[4] or 1) * alpha)
            love.graphics.print(text, text_x + sx, sy)
        end
        
        -- Box
        -- (Notification popups no longer draw a box or background)
        
        -- Outline
        -- (Notification popups no longer draw an outline or border)
        
        -- Text
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], (p.color[4] or 1) * alpha)
        love.graphics.print(text, text_x, 0)
        love.graphics.setFont(prev_font)
        love.graphics.pop()
    end
end

return popup
