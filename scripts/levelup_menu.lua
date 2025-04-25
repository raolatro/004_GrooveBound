-- scripts/levelup_menu.lua: Handles the level up weapon selection interface
local settings = require "settings"
local debug = require "scripts/debug"
local hud = require "scripts/hud"

local levelup_menu = {}

-- Level up state
levelup_menu.active = false
levelup_menu.current_level = 1
levelup_menu.available_items = {}  -- Items available for selection
levelup_menu.hover_item = nil      -- Item player is hovering over

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

-- Generate a random selection of weapons for the level up based on player level
function levelup_menu.generate_items(level)
    local data = settings.item_data
    local inventory = require "scripts/inventory"
    local weapons = {}
    
    -- Reset available items
    levelup_menu.available_items = {}
    
    -- Gather all weapon types
    for id, item in pairs(data.Items) do
        if item.type == "weapon" then
            -- Find if player already has this weapon and its level by category
            local has_weapon = false
            local player_weapon_level = 1
            
            -- Look for weapons by category instead of ID, since that's how inventory.add works
            local idx = inventory.find_by_category(item.category)
            if idx then
                local slot = inventory.slots[idx]
                has_weapon = true
                player_weapon_level = slot.level or 1
                debug.log("Found existing weapon: " .. item.category .. " at level " .. player_weapon_level)
            end
            
            -- Calculate next level
            local next_level = has_weapon and player_weapon_level + 1 or 1
            
            debug.log("Adding levelup item: " .. item.category .. ", level: " .. 
                      (has_weapon and player_weapon_level or "not owned") .. 
                      ", next level: " .. next_level)
            
            -- Add to potential levelup items
            table.insert(weapons, {
                id = id,
                category = item.category,
                has_weapon = has_weapon,
                player_level = player_weapon_level,
                next_level = next_level,
                color = item.color or {1, 1, 1, 1}
            })
        end
    end
    
    -- Shuffle the weapons list
    for i = #weapons, 2, -1 do
        local j = math.random(i)
        weapons[i], weapons[j] = weapons[j], weapons[i]
    end
    
    -- Select up to 3 weapons for the level up screen
    local count = math.min(3, #weapons)
    for i = 1, count do
        table.insert(levelup_menu.available_items, weapons[i])
    end
    
    debug.log("Generated " .. count .. " level up options")
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
    love.graphics.setFont(levelup_menu._fonts.body)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("You reached level " .. levelup_menu.current_level, box_x, box_y + 70, box_w, "center")
    
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
        
        -- Draw weapon dot 3x bigger
        local dot_size = 15  -- 3x the normal size
        love.graphics.circle("fill", box.x + box.w/2, box.y + 50, dot_size)
        love.graphics.setColor(1, 1, 1, 0.4)
        love.graphics.circle("line", box.x + box.w/2, box.y + 50, dot_size + 1)
        
        -- Weapon name and level
        love.graphics.setColor(item.color)
        love.graphics.setFont(levelup_menu._fonts.body)
        
        -- Get display name from settings if available
        local category = item.category or "unknown"
        local weapon_settings = settings.weapons[category] or {}
        local display_name = weapon_settings.display_name or category:upper()
        
        -- Weapon name
        love.graphics.printf(display_name, box.x, box.y + 80, box.w, "center")
        
        -- Weapon level indicator
        local level_text = item.has_weapon and "Level up to LVL " .. item.next_level or "New weapon!"
        love.graphics.printf(level_text, box.x, box.y + 110, box.w, "center")
        
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

-- Handle item selection
function levelup_menu.select_item(item_index)
    local item = levelup_menu.available_items[item_index]
    if not item then return false end
    
    -- Add the weapon to inventory or level it up
    local inventory = require "scripts/inventory"
    local popup = require "scripts/popup"
    local success, action, category, level = inventory.add(item.id)
    
    if success then
        -- Play selection sound
        local sfx = require "scripts/sfx"
        if sfx.play then
            sfx.play('purchase')
        end
        
        -- Create a popup for the selection
        if action == "level_up" then
            popup.create_notification(category:upper() .. " upgraded to LVL " .. level, popup.STYLES.WEAPON, item.color)
        else
            popup.create_notification("Acquired " .. category:upper(), popup.STYLES.WEAPON, item.color)
        end
        
        -- Close the level up menu and continue the game
        levelup_menu.hide()
        
        debug.log(category .. " " .. (action == "level_up" and "upgraded" or "acquired") .. " to level " .. level)
        return true
    end
    
    debug.log("Failed to upgrade " .. (item.category or "unknown"))
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
