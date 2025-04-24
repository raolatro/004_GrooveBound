-- scripts/shop_menu.lua: Handles the level up shop menu interface with weapon purchasing
local settings = require "settings"
local debug = require "scripts/debug"
local hud = require "scripts/hud"

local shop_menu = {}

-- Shop state
shop_menu.active = false
shop_menu.current_level = 1
shop_menu.available_items = {}  -- Items currently available for purchase
shop_menu.hover_item = nil      -- Item player is hovering over

-- Font system for shop menu
function shop_menu.reload_fonts()
    shop_menu._fonts = {
        header = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.header),
        body = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.body),
        button = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.button)
    }
end

-- Load fonts on module load
shop_menu.reload_fonts()

-- Generate a random selection of weapons for the shop based on player level
function shop_menu.generate_items(level)
    local data = settings.item_data
    local inventory = require "scripts/inventory"
    local weapons = {}
    
    -- Reset available items
    shop_menu.available_items = {}
    
    -- Gather all weapon types
    for id, item in pairs(data.Items) do
        if item.type == "weapon" then
            -- Find if player already has this weapon and its level
            local has_weapon = false
            local player_weapon_level = 1
            
            for _, slot in ipairs(inventory.slots) do
                if slot and slot.id == id then
                    has_weapon = true
                    player_weapon_level = slot.level or 1
                    break
                end
            end
            
            -- Add to potential shop items with correct level and price
            table.insert(weapons, {
                id = id,
                category = item.category,
                has_weapon = has_weapon,
                player_level = player_weapon_level,
                shop_level = has_weapon and player_weapon_level + 1 or 1,
                color = item.color or {1, 1, 1, 1},
                -- Scale price with level and rarity
                price = (has_weapon and player_weapon_level + 1 or 1) * 
                        (item.category == "forward" and 100 or 
                         item.category == "cross" and 150 or 
                         item.category == "drones" and 200 or 
                         item.category == "area" and 250 or 100)
            })
        end
    end
    
    -- Shuffle the weapons list
    for i = #weapons, 2, -1 do
        local j = math.random(i)
        weapons[i], weapons[j] = weapons[j], weapons[i]
    end
    
    -- Select up to 3 weapons for the shop
    local count = math.min(3, #weapons)
    for i = 1, count do
        table.insert(shop_menu.available_items, weapons[i])
    end
    
    debug.log("Generated " .. count .. " shop items")
end

-- Show the shop menu when leveling up
function shop_menu.show(level)
    shop_menu.active = true
    shop_menu.current_level = level
    
    -- Show system cursor when shop menu is active
    love.mouse.setVisible(true)
    
    -- Generate shop items
    shop_menu.generate_items(level)
    
    -- Initialize UI elements
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Create shop item boxes
    shop_menu.item_boxes = {}
    local box_w, box_h = 180, 200
    local margin = 30
    local total_width = (box_w * 3) + (margin * 2)
    local start_x = (w - total_width) / 2
    
    for i = 1, 3 do
        shop_menu.item_boxes[i] = {
            x = start_x + (i-1) * (box_w + margin),
            y = h/2 - 100,
            w = box_w,
            h = box_h
        }
    end
    
    -- Create continue/skip button
    local btn_w, btn_h = 180, 48
    local btn_x, btn_y = w/2-btn_w/2, h/2+150
    shop_menu._continue_btn = {x=btn_x, y=btn_y, w=btn_w, h=btn_h}
    
    -- Initialize cash display
    if not hud.cash then hud.cash = 0 end
    
    debug.log("Shop menu opened at level " .. level .. ", player has $" .. hud.cash)
end

-- Hide the shop menu and continue gameplay
function shop_menu.hide()
    shop_menu.active = false
    
    -- Hide system cursor when returning to gameplay
    love.mouse.setVisible(false)
    
    -- Unpause the game
    _G.game_paused = false
    
    debug.log("Shop menu closed, continuing game")
end

-- Draw the shop menu with purchasable weapons
function shop_menu.draw()
    if not shop_menu.active then return end
    
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Darken the background
    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Shop menu container (wider to accommodate 3 shop items side by side)
    local box_w, box_h = 700, 450
    local box_x, box_y = (w-box_w)/2, (h-box_h)/2
    
    -- Shop background
    love.graphics.setColor(0.15, 0.15, 0.15, 0.95)
    love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, 20, 20)
    
    -- Shop border
    love.graphics.setColor(0.4, 0.6, 1, 1) -- Blue border for level up
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", box_x, box_y, box_w, box_h, 20, 20)
    love.graphics.setLineWidth(1)
    
    -- Title
    love.graphics.setFont(shop_menu._fonts.header)
    love.graphics.setColor(0.4, 0.6, 1, 1) -- Blue color for level up
    love.graphics.printf("LEVEL UP!", box_x, box_y + 30, box_w, "center")
    
    -- Level and cash display
    love.graphics.setFont(shop_menu._fonts.body)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("You reached level " .. shop_menu.current_level, box_x, box_y + 70, box_w, "center")
    
    -- Display available cash in yellow
    love.graphics.setColor(1, 0.9, 0, 1) -- Gold color
    love.graphics.printf("Your Cash: $" .. (hud.cash or 0), box_x, box_y + 100, box_w, "center")
    
    -- Shop instruction
    love.graphics.setColor(0.8, 0.8, 0.8, 1)
    love.graphics.printf("Select a weapon to buy or upgrade:", box_x, box_y + 130, box_w, "center")
    
    -- Draw shop items (3 side by side)
    for i = 1, math.min(3, #shop_menu.available_items) do
        local item = shop_menu.available_items[i]
        local box = shop_menu.item_boxes[i]
        
        -- Check if this item is being hovered over
        local hover = shop_menu.hover_item == i
        
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
        love.graphics.setFont(shop_menu._fonts.body)
        
        -- Get display name from settings if available
        local category = item.category or "unknown"
        local weapon_settings = settings.weapons[category] or {}
        local display_name = weapon_settings.display_name or category:upper()
        
        -- Weapon name
        love.graphics.printf(display_name, box.x, box.y + 80, box.w, "center")
        
        -- Weapon level indicator
        local level_text = item.has_weapon and "LEVEL " .. item.shop_level or "NEW"
        love.graphics.printf(level_text, box.x, box.y + 110, box.w, "center")
        
        -- Price in gold/yellow
        love.graphics.setColor(1, 0.9, 0, 1) -- Gold
        love.graphics.printf("$" .. item.price, box.x, box.y + 140, box.w, "center")
        
        -- Show if can afford or not
        local can_afford = (hud.cash or 0) >= item.price
        if not can_afford then
            -- Red "Cannot Afford" text
            love.graphics.setColor(1, 0.3, 0.3, 1) -- Red
            love.graphics.printf("Can't Afford", box.x, box.y + 170, box.w, "center")
        else
            -- Green "Click to Buy" text
            love.graphics.setColor(0.3, 1, 0.3, 1) -- Green
            love.graphics.printf("Click to Buy", box.x, box.y + 170, box.w, "center")
        end
    end
    
    -- Draw continue/skip button
    local btn = shop_menu._continue_btn
    love.graphics.setColor(0.3, 0.5, 0.9, 1)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 10, 10)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(shop_menu._fonts.button)
    love.graphics.printf("SKIP", btn.x, btn.y + 12, btn.w, "center")
end

-- Handle item purchases
function shop_menu.purchase_item(item_index)
    local item = shop_menu.available_items[item_index]
    if not item then return false end
    
    -- Check if player can afford it
    if (hud.cash or 0) < item.price then
        debug.log("Cannot afford item: $" .. item.price .. " (have $" .. (hud.cash or 0) .. ")")
        return false
    end
    
    -- Deduct the cash
    hud.cash = hud.cash - item.price
    
    -- Add the weapon to inventory or level it up
    local inventory = require "scripts/inventory"
    local popup = require "scripts/popup"
    local success, action, category, level = inventory.add(item.id)
    
    if success then
        -- Play purchase sound
        local sfx = require "scripts/sfx"
        if sfx.play then
            sfx.play('purchase')
        end
        
        -- Create a popup for the purchase
        if action == "level_up" then
            popup.create_notification(category:upper() .. " UPGRADED TO LEVEL " .. level, popup.STYLES.WEAPON, item.color)
        else
            popup.create_notification("PURCHASED NEW " .. category:upper(), popup.STYLES.WEAPON, item.color)
        end
        
        -- Recalculate item price for this slot (for multiple purchases)
        item.has_weapon = true
        item.player_level = level
        item.shop_level = level + 1
        item.price = item.shop_level * 
                    (item.category == "forward" and 100 or 
                     item.category == "cross" and 150 or 
                     item.category == "drones" and 200 or 
                     item.category == "area" and 250 or 100)
        
        debug.log("Purchased " .. category .. " for $" .. item.price .. ", now at level " .. level)
        return true
    end
    
    return false
end

-- Handle mouse clicks on the shop menu
function shop_menu.mousepressed(x, y, button)
    if not shop_menu.active or button ~= 1 then return false end
    
    -- Check if any item was clicked
    for i, box in ipairs(shop_menu.item_boxes) do
        if i <= #shop_menu.available_items and
           x >= box.x and x <= box.x + box.w and
           y >= box.y and y <= box.y + box.h then
            -- Attempt to purchase this item
            shop_menu.purchase_item(i)
            return true -- Signal that we handled the click
        end
    end
    
    -- Check if continue/skip button was clicked
    local btn = shop_menu._continue_btn
    if x >= btn.x and x <= btn.x + btn.w and
       y >= btn.y and y <= btn.y + btn.h then
        -- Hide shop and continue game
        shop_menu.hide()
        return true -- Signal that we handled the click
    end
    
    return false -- We didn't handle the click
end

-- Handle mouse movement over the shop menu
function shop_menu.mousemoved(x, y)
    if not shop_menu.active then return end
    
    -- Track which item is being hovered over
    shop_menu.hover_item = nil
    
    for i, box in ipairs(shop_menu.item_boxes) do
        if i <= #shop_menu.available_items and
           x >= box.x and x <= box.x + box.w and
           y >= box.y and y <= box.y + box.h then
            shop_menu.hover_item = i
            break
        end
    end
end

-- Helper function to check if a point is inside a rectangle
function mouse_in_box(x, y, box)
    return x >= box.x and x <= box.x+box.w and y >= box.y and y <= box.y+box.h
end

return shop_menu
