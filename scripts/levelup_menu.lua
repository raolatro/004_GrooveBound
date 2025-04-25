-- scripts/levelup_menu.lua: Handles the level up power-up selection interface
local settings = require "settings"
local debug = require "scripts/debug"
local hud = require "scripts/hud"
local powerup = require "scripts/powerup"

local levelup_menu = {}

-- Level up state
levelup_menu.active = false
levelup_menu.current_level = 1
levelup_menu.available_items = {}  -- Power-ups available for selection
levelup_menu.hover_item = nil      -- Power-up player is hovering over

-- Font system for level up menu
function levelup_menu.reload_fonts()
    levelup_menu._fonts = {
        header = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.header),
        body = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.body),
        button = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.button)
    }
end

-- Load fonts on module load
levelup_menu.reload_fonts()

-- Generate a random selection of power-ups for the level up menu
function levelup_menu.generate_items(level)
    -- Reset available items
    levelup_menu.available_items = {}
    
    debug.log("[LevelUpMenu] Generating options for level " .. level)
    
    -- Use the new enhanced function that supports weapons in the level up menu
    -- Pass the current level/wave to control weapon probability
    local options = powerup.roll_enhanced_level_up_options(settings.powerups.level_up_count or 3, level)
    debug.log("[LevelUpMenu] Roll returned " .. #options .. " options")
    
    -- If we got options (power-ups or weapons), add them to available items
    if #options > 0 then
        for i, option in ipairs(options) do
            local is_weapon = option.is_weapon or option.data.is_weapon or false
            local item_type = is_weapon and "weapon" or "powerup"
            debug.log("[LevelUpMenu] Adding " .. item_type .. " option " .. i .. ": " .. option.id .. " (" .. option.data.name .. ")")
            
            table.insert(levelup_menu.available_items, {
                id = option.id,
                data = option.data,
                is_weapon = is_weapon,
                color = powerup.get_rarity_color(option.data.rarity)
            })
        end
    else
        debug.log("[LevelUpMenu] Warning: No options available for level up")
    end
    
    debug.log("[LevelUpMenu] Final menu has " .. #levelup_menu.available_items .. " options")
end

-- Show the level up menu when leveling up
function levelup_menu.show(level)
    levelup_menu.active = true
    levelup_menu.current_level = level
    
    -- Show system cursor when level up menu is active
    love.mouse.setVisible(true)
    
    -- Generate level up items
    levelup_menu.generate_items(level)
    
    -- Initialize UI elements
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Create level up item boxes
    levelup_menu.item_boxes = {}
    local box_w, box_h = 180, 200
    local margin = 30
    local total_width = (box_w * 3) + (margin * 2)
    local start_x = (w - total_width) / 2
    
    for i = 1, 3 do
        levelup_menu.item_boxes[i] = {
            x = start_x + (i-1) * (box_w + margin),
            y = h/2 - 100,
            w = box_w,
            h = box_h
        }
    end
    
    -- Create skip button
    local btn_w, btn_h = 180, 48
    local btn_x, btn_y = w/2-btn_w/2, h/2+150
    levelup_menu._skip_btn = {x=btn_x, y=btn_y, w=btn_w, h=btn_h}
    
    debug.log("Level up menu opened at level " .. level)
end

-- Hide the level up menu and continue gameplay
function levelup_menu.hide()
    levelup_menu.active = false
    
    -- Hide system cursor when returning to gameplay
    love.mouse.setVisible(false)
    
    -- Unpause the game
    _G.game_paused = false
    
    debug.log("Level up menu closed, continuing game")
end

-- Draw the level up menu with selectable weapons
function levelup_menu.draw()
    if not levelup_menu.active then return end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Darken the background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Level up menu container (wider to accommodate 3 items side by side)
    local box_w, box_h = 700, 450
    local box_x, box_y = (w-box_w)/2, (h-box_h)/2
    
    -- Level up background
    love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, 20, 20)
    
    -- Level up border
    love.graphics.setColor(0.4, 0.6, 1, 1) -- Blue border for level up
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", box_x, box_y, box_w, box_h, 20, 20)
    love.graphics.setLineWidth(1)
    
    -- Title
    love.graphics.setFont(levelup_menu._fonts.header)
    love.graphics.setColor(0.4, 0.6, 1, 1) -- Blue color for level up
    love.graphics.printf("LEVEL UP!", box_x, box_y + 30, box_w, "center")
    
    -- Level display
    -- love.graphics.setFont(levelup_menu._fonts.body)
    -- love.graphics.setColor(1, 1, 1, 1)
    -- love.graphics.printf("You reached level " .. levelup_menu.current_level, box_x, box_y + 70, box_w, "center")
    
    -- Level up instruction
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.printf("Choose ONE weapon to upgrade:", box_x, box_y + 100, box_w, "center")
    
    -- Draw level up items (3 side by side)
    for i = 1, math.min(3, #levelup_menu.available_items) do
        local item = levelup_menu.available_items[i]
        local box = levelup_menu.item_boxes[i]
        
        -- Check if this item is being hovered over
        local hover = levelup_menu.hover_item == i
        
        -- Item box background (medium grey, lighter if hovered)
        love.graphics.setColor(hover and 0.4 or 0.3, hover and 0.4 or 0.3, hover and 0.4 or 0.3, 0.95)
        love.graphics.rectangle("fill", box.x, box.y, box.w, box.h, 15, 15)
        
        -- Item box border
        love.graphics.setColor(item.color)
        love.graphics.setLineWidth(hover and 3 or 2)
        love.graphics.rectangle("line", box.x, box.y, box.w, box.h, 15, 15)
        love.graphics.setLineWidth(1)
        
        -- Draw power-up icon (colored gem/crystal)
        local icon_size = 20
        local icon_y = box.y + 40
        
        -- Set icon color based on rarity
        local power_data = item.data
        local rarity_colors = settings.powerups.colors[power_data.rarity] or {1, 1, 1, 1}
        love.graphics.setColor(rarity_colors)
        
        -- Draw a hexagon gem icon
        local sides = 6
        local radius = icon_size
        local x, y = box.x + box.w/2, icon_y
        
        -- Draw gem/crystal
        for i = 1, sides do
            local angle1 = (i - 1) * (2 * math.pi / sides)
            local angle2 = i * (2 * math.pi / sides)
            local x1 = x + radius * math.cos(angle1)
            local y1 = y + radius * math.sin(angle1)
            local x2 = x + radius * math.cos(angle2)
            local y2 = y + radius * math.sin(angle2)
            love.graphics.polygon("fill", x, y, x1, y1, x2, y2)
        end
        
        -- Outline
        love.graphics.setColor(1, 1, 1, 0.6)
        love.graphics.setLineWidth(1)
        for i = 1, sides do
            local angle1 = (i - 1) * (2 * math.pi / sides)
            local angle2 = i * (2 * math.pi / sides)
            local x1 = x + radius * math.cos(angle1)
            local y1 = y + radius * math.sin(angle1)
            local x2 = x + radius * math.cos(angle2)
            local y2 = y + radius * math.sin(angle2)
            love.graphics.line(x1, y1, x2, y2)
        end
        
        -- Power-up name and description
        local power_data = item.data
        local name = power_data.name or "Unknown Power-up"
        local description = power_data.description or ""
        
        -- Set color based on rarity
        local rarity_colors = settings.powerups.colors[power_data.rarity] or {1, 1, 1, 1}
        love.graphics.setColor(rarity_colors)
        
        -- Power-up name
        love.graphics.printf(name, box.x, box.y + 70, box.w, "center")
        
        -- Reset color for description
        love.graphics.setColor(0.85, 0.85, 0.85, 1)
        love.graphics.setFont(levelup_menu._fonts.body)
        
        -- Power-up description (with word wrap)
        love.graphics.printf(description, box.x + 10, box.y + 100, box.w - 20, "center")
        
        -- Action text in a nice color
        love.graphics.setColor(0.3, 1, 0.5, 1) -- Green
        love.graphics.printf("Select", box.x, box.y + 150, box.w, "center")
    end
    
    -- Draw skip button
    local btn = levelup_menu._skip_btn
    love.graphics.setColor(0.5, 0.5, 0.5, 1) -- Gray for skip
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 10, 10)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(levelup_menu._fonts.button)
    love.graphics.printf("SKIP", btn.x, btn.y + 12, btn.w, "center")
end

-- Handle item selection (could be a power-up or weapon)
function levelup_menu.select_item(item_index)
    local item = levelup_menu.available_items[item_index]
    if not item then return false end
    
    local success = false
    
    -- Handle differently based on item type
    if item.is_weapon then
        -- It's a weapon, add it to inventory
        local inventory = require "scripts/inventory"
        local debug = require "scripts/debug"
        local popup = require "scripts/popup"
        
        debug.log("[LevelUpMenu] Adding weapon to inventory: " .. item.id)
        
        -- Create a weapon item for inventory using the category
        local weapon_item = {
            type = "weapon",
            category = item.data.category or item.id,
            level = 1,
            color = powerup.get_rarity_color("rare")
        }
        
        -- Add to inventory
        local result, action = inventory.add(weapon_item, false)
        success = (result == true)
        
        if success then
            -- Show weapon acquisition notification
            local display_name = item.data.name or item.id:gsub("^%l", string.upper)
            popup.create_notification("NEW WEAPON: " .. display_name, popup.STYLES.WEAPON, weapon_item.color)
            
            -- Play weapon pickup sound
            local sfx = require "scripts/sfx"
            if sfx.play then
                sfx.play('weapon_pickup')
            end
        end
    else
        -- It's a regular power-up
        success = powerup.acquire(item.id, true)
    end
    
    if success then
        -- Close the level up menu
        levelup_menu.hide()
        return true
    end
    
    return false
end

-- Handle mouse clicks on the level up menu
function levelup_menu.mousepressed(x, y, button)
    if not levelup_menu.active or button ~= 1 then return false end
    
    -- Check if any item was clicked
    for i, box in ipairs(levelup_menu.item_boxes) do
        if i <= #levelup_menu.available_items and
           x >= box.x and x <= box.x + box.w and
           y >= box.y and y <= box.y + box.h then
            -- Select this item
            levelup_menu.select_item(i)
            return true -- Signal that we handled the click
        end
    end
    
    -- Check if skip button was clicked
    local btn = levelup_menu._skip_btn
    if x >= btn.x and x <= btn.x + btn.w and
       y >= btn.y and y <= btn.y + btn.h then
        -- Hide level up menu and continue game
        levelup_menu.hide()
        return true -- Signal that we handled the click
    end
    
    return false -- We didn't handle the click
end

-- Handle mouse movement over the level up menu
function levelup_menu.mousemoved(x, y)
    if not levelup_menu.active then return end
    
    -- Track which item is being hovered over
    levelup_menu.hover_item = nil
    
    for i, box in ipairs(levelup_menu.item_boxes) do
        if i <= #levelup_menu.available_items and
           x >= box.x and x <= box.x + box.w and
           y >= box.y and y <= box.y + box.h then
            levelup_menu.hover_item = i
            break
        end
    end
end

-- Helper function to check if a point is inside a rectangle
function mouse_in_box(x, y, box)
    return x >= box.x and x <= box.x+box.w and y >= box.y and y <= box.y+box.h
end

return levelup_menu
