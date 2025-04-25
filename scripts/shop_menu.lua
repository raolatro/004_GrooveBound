-- scripts/shop_menu.lua: Handles the post-boss shop menu interface with power-up purchasing
local settings = require "settings"
local debug = require "scripts/debug"
local hud = require "scripts/hud"
local powerup = require "scripts/powerup"

local shop_menu = {}

-- Shop state
shop_menu.active = false
shop_menu.current_level = 1
shop_menu.available_items = {}  -- Items currently available for purchase
shop_menu.hover_item = nil      -- Item player is hovering over

-- Pagination and reroll support
shop_menu.current_page = 1       -- Current page of shop items (3 items per page)
shop_menu.total_items = 5        -- Total number of items in the shop
shop_menu.items_per_page = 3     -- Number of items visible per page
shop_menu.purchased = {}         -- Track which items have been purchased
shop_menu.can_reroll = true      -- Whether reroll button is available

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

-- Generate a random selection of power-ups and weapons for the shop based on player level
function shop_menu.generate_items(level)
    -- Reset shop state
    shop_menu.available_items = {}
    shop_menu.current_page = 1
    shop_menu.purchased = {}
    -- Only allow reroll if not already used
    if shop_menu.can_reroll == nil then
        shop_menu.can_reroll = true
    end
    
    -- Use the enhanced powerup module to roll shop options including weapons
    -- Total items is fixed at 5 (with pagination showing 3 at a time)
    local options = powerup.roll_enhanced_shop_options(5, true, 5)
    
    -- If we got items (power-ups or weapons), add them to available items
    if #options > 0 then
        for i, option in ipairs(options) do
            local is_weapon = option.is_weapon or option.data.is_weapon or false
            local item_type = is_weapon and "weapon" or "powerup"
            debug.log("[ShopMenu] Adding " .. item_type .. " option " .. i .. ": " .. option.id .. " (" .. option.data.name .. ")")
            
            table.insert(shop_menu.available_items, {
                id = option.id,
                data = option.data,
                is_weapon = is_weapon,
                purchased = false,  -- Track purchase state for each item
                price = option.data.cost or (is_weapon and 300 or 200),  -- Default prices
                color = powerup.get_rarity_color(option.data.rarity)
            })
        end
    else
        debug.log("[ShopMenu] Warning: No items available for shop")
    end
    
    shop_menu.total_items = #shop_menu.available_items
    debug.log("[ShopMenu] Generated " .. shop_menu.total_items .. " shop items")
end

-- Show the shop menu when leveling up
function shop_menu.show(level)
    shop_menu.active = true
    shop_menu.current_level = level
    shop_menu.current_page = 1
    shop_menu.can_reroll = true
    
    -- Pause the game while shop menu is active
    _G.game_paused = true
    
    -- Show system cursor when shop menu is active
    love.mouse.setVisible(true)
    
    -- Generate shop items
    shop_menu.generate_items(level)
    
    -- Initialize UI elements
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    
    -- Create shop item boxes (3 visible at a time)
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
    
    -- Create navigation arrows for pagination
    local arrow_size = 40
    shop_menu._left_arrow = {
        x = start_x - arrow_size - 20,
        y = h/2,
        w = arrow_size,
        h = arrow_size,
        enabled = false  -- Disabled on first page
    }
    
    shop_menu._right_arrow = {
        x = start_x + total_width + 20,
        y = h/2,
        w = arrow_size,
        h = arrow_size,
        enabled = shop_menu.total_items > shop_menu.items_per_page  -- Enabled if more items than visible
    }
    
    -- Centered action buttons (REROLL and SKIP) as a group below the shop box
    local btn_w, btn_h = 140, 44
    local group_margin = 24
    local group_total_w = btn_w * 2 + group_margin
    local group_start_x = (w - group_total_w) / 2
    local btn_y = h/2 + 170
    shop_menu._reroll_btn = {
        x = group_start_x,
        y = btn_y,
        w = btn_w,
        h = btn_h,
        price = 50,
        enabled = shop_menu.can_reroll
    }
    shop_menu._continue_btn = {
        x = group_start_x + btn_w + group_margin,
        y = btn_y,
        w = btn_w,
        h = btn_h
    }
    
    -- Initialize cash display
    if not hud.cash then hud.cash = 0 end
    
    debug.log("[ShopMenu] Shop menu opened at level " .. level .. ", player has $" .. hud.cash)
end

-- Hide the shop menu and continue gameplay
function shop_menu.hide()
    shop_menu.active = false
    
    -- Hide system cursor when returning to gameplay
    love.mouse.setVisible(false)
    
    -- Unpause the game
    _G.game_paused = false
    
    debug.log("[ShopMenu] Shop menu closed, continuing game")
end

-- Draw the shop menu with purchasable power-ups
function shop_menu.draw()
    if not shop_menu.active then return end
    
    -- debug.log("[ShopMenu] Drawing shop menu - active=" .. tostring(shop_menu.active) .. ", game_paused=" .. tostring(_G.game_paused))
    
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
    
    -- Shop title in blue
    love.graphics.setFont(shop_menu._fonts.header)
    love.graphics.setColor(0.4, 0.6, 1, 1) -- Blue color for level up
    love.graphics.printf("TIME FOR SOME UPGRADES!", box_x, box_y + 30, box_w, "center")
    
    -- Extra visible message for debugging
    -- Debug overlay removed for cleaner shop UI
    
    -- Level and cash display
    -- love.graphics.setFont(shop_menu._fonts.body)
    -- love.graphics.setColor(1, 1, 1, 1)
    -- love.graphics.printf("You reached level " .. shop_menu.current_level, box_x, box_y + 70, box_w, "center")
    
    -- Display available cash in yellow
    -- love.graphics.setColor(1, 0.9, 0, 1) -- Gold color
    --love.graphics.printf("Your Cash: $" .. (hud.cash or 0), box_x, box_y + 100, box_w, "center")
    
    -- Shop instruction
    -- love.graphics.setColor(0.8, 0.8, 0.8, 1)
    -- love.graphics.printf("Select a power-up to buy:", box_x, box_y + 130, box_w, "center")
    
    -- Calculate visible item range for current page
    local start_idx = (shop_menu.current_page - 1) * shop_menu.items_per_page + 1
    local end_idx = math.min(start_idx + shop_menu.items_per_page - 1, #shop_menu.available_items)
    
    -- Draw shop items (3 side by side)
    for i = 1, shop_menu.items_per_page do
        local item_idx = start_idx + i - 1
        local box = shop_menu.item_boxes[i]
        -- Only draw if this item exists and hasn't been purchased
        if item_idx <= #shop_menu.available_items then
            local item = shop_menu.available_items[item_idx]
            local hover = shop_menu.hover_item == i
            -- Not enough cash tag logic
            local show_not_enough = (shop_menu.last_failed_purchase == item_idx)
            -- If item has been purchased, show empty slot
            if item.purchased then
                -- Empty slot (darker grey)
                love.graphics.setColor(0.15, 0.15, 0.15, 0.7)
                love.graphics.rectangle("fill", box.x, box.y, box.w, box.h, 15, 15)
                
                -- Sold out border
                love.graphics.setColor(0.5, 0.5, 0.5, 0.5) -- Grey for sold out
                love.graphics.setLineWidth(1)
                love.graphics.rectangle("line", box.x, box.y, box.w, box.h, 15, 15)
                
                -- Sold out text
                love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
                love.graphics.setFont(shop_menu._fonts.body)
                love.graphics.printf("SOLD OUT", box.x, box.y + box.h/2 - 10, box.w, "center")
            else
                -- Item box background (medium grey, lighter if hovered)
                love.graphics.setColor(hover and 0.4 or 0.3, hover and 0.4 or 0.3, hover and 0.4 or 0.3, 0.95)
                love.graphics.rectangle("fill", box.x, box.y, box.w, box.h, 15, 15)
                -- Item box border (color based on rarity)
                love.graphics.setColor(item.color)
                love.graphics.setLineWidth(hover and 3 or 2)
                love.graphics.rectangle("line", box.x, box.y, box.w, box.h, 15, 15)
                love.graphics.setLineWidth(1)
                -- Show 'Not enough cash' tag if last purchase failed here
                if show_not_enough then
                    love.graphics.setColor(1, 0.3, 0.3, 1)
                    love.graphics.setFont(shop_menu._fonts.body)
                    love.graphics.printf("Not enough cash", box.x, box.y + 8, box.w, "center")
                end
                -- Draw power-up icon (colored gem/crystal)
                local icon_size = 20
                local icon_y = box.y + 40
                local power_data = item.data
                local name = power_data.name or "Unknown Power-up"
                local description = power_data.description or ""
                local rarity_colors = settings.powerups.colors[power_data.rarity] or {1, 1, 1, 1}
                love.graphics.setColor(rarity_colors)
                -- Draw a hexagon gem icon
                local sides = 6
                local radius = icon_size
                local x, y = box.x + box.w/2, icon_y
                for j = 1, sides do
                    local angle1 = (j - 1) * (2 * math.pi / sides)
                    local angle2 = j * (2 * math.pi / sides)
                    local x1 = x + radius * math.cos(angle1)
                    local y1 = y + radius * math.sin(angle1)
                    local x2 = x + radius * math.cos(angle2)
                    local y2 = y + radius * math.sin(angle2)
                    love.graphics.polygon("fill", x, y, x1, y1, x2, y2)
                end
                -- Outline
                love.graphics.setColor(1, 1, 1, 0.6)
                love.graphics.setLineWidth(1)
                for j = 1, sides do
                    local angle1 = (j - 1) * (2 * math.pi / sides)
                    local angle2 = j * (2 * math.pi / sides)
                    local x1 = x + radius * math.cos(angle1)
                    local y1 = y + radius * math.sin(angle1)
                    local x2 = x + radius * math.cos(angle2)
                    local y2 = y + radius * math.sin(angle2)
                    love.graphics.line(x1, y1, x2, y2)
                end
                love.graphics.setColor(rarity_colors)
love.graphics.setFont(shop_menu._fonts.body) -- Ensure correct font for item name/title
love.graphics.printf(name, box.x, box.y + 70, box.w, "center")
love.graphics.setColor(0.85, 0.85, 0.85, 1)
                love.graphics.setFont(shop_menu._fonts.body)
                love.graphics.printf(description, box.x + 10, box.y + 95, box.w - 20, "center")
                -- Category tag at bottom
                love.graphics.setColor(item.is_weapon and {1, 0.8, 0, 1} or {0.6, 0.8, 1, 1})
                love.graphics.setFont(shop_menu._fonts.body)
                love.graphics.printf(item.is_weapon and "WEAPON" or "POWER-UP", box.x, box.y + box.h - 48, box.w, "center")
                -- Price tag lower at bottom
                love.graphics.setColor(1, 0.9, 0, 1)
                love.graphics.printf("$" .. item.price, box.x, box.y + box.h - 30, box.w, "center")
            end
        else
            -- Empty slot (darker grey)
            love.graphics.setColor(0.15, 0.15, 0.15, 0.7)
            love.graphics.rectangle("fill", box.x, box.y, box.w, box.h, 15, 15)
            love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", box.x, box.y, box.w, box.h, 15, 15)
        end
    end
    
    -- Draw pagination arrows if we have more than one page of items
    if shop_menu.total_items > shop_menu.items_per_page then
        -- Left arrow (flipped horizontally)
        local left = shop_menu._left_arrow
        local left_enabled = shop_menu.current_page > 1
        love.graphics.setColor(left_enabled and {1, 1, 1, 1} or {0.5, 0.5, 0.5, 0.5})
        -- Flipped: triangle points left
        love.graphics.polygon('fill', 
            left.x, left.y, 
            left.x + left.w, left.y - left.h/2, 
            left.x + left.w, left.y + left.h/2
        )
        -- Right arrow (flipped horizontally)
        local right = shop_menu._right_arrow
        local right_enabled = shop_menu.current_page < math.ceil(shop_menu.total_items / shop_menu.items_per_page)
        love.graphics.setColor(right_enabled and {1, 1, 1, 1} or {0.5, 0.5, 0.5, 0.5})
        -- Flipped: triangle points right
        love.graphics.polygon('fill', 
            right.x + right.w, right.y, 
            right.x, right.y - right.h/2, 
            right.x, right.y + right.h/2
        )
    end
    -- Move page indicator below the shop box
    if shop_menu.total_items > shop_menu.items_per_page then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.setFont(shop_menu._fonts.body)
        local total_pages = math.ceil(shop_menu.total_items / shop_menu.items_per_page)
        local w, h = love.graphics.getWidth(), love.graphics.getHeight()
        local box_w, box_h = 700, 450
        local box_x, box_y = (w-box_w)/2, (h-box_h)/2
        love.graphics.printf("Page " .. shop_menu.current_page .. " of " .. total_pages,
            box_x, box_y + box_h + 24, box_w, "center")
    end
    
    -- Draw REROLL button (left)
    local reroll = shop_menu._reroll_btn
    if shop_menu.can_reroll then
        love.graphics.setColor(0.1, 0.6, 0.1, 1)
    else
        love.graphics.setColor(0.5, 0.5, 0.5, 0.3) -- Greyed out and faded
    end
    love.graphics.rectangle("fill", reroll.x, reroll.y, reroll.w, reroll.h, 10, 10)
    love.graphics.setColor(1, 1, 1, shop_menu.can_reroll and 1 or 0.4)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", reroll.x, reroll.y, reroll.w, reroll.h, 10, 10)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(shop_menu._fonts.button)
    love.graphics.printf("REROLL [$" .. reroll.price .. "]", reroll.x, reroll.y + reroll.h/2 - 12, reroll.w, "center")
    -- Draw SKIP button (right)
    local btn = shop_menu._continue_btn
    love.graphics.setColor(0.3, 0.5, 0.9, 1)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 10, 10)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 10, 10)
    love.graphics.setLineWidth(1)
    love.graphics.setFont(shop_menu._fonts.button)
    love.graphics.printf("SKIP", btn.x, btn.y + btn.h/2 - 12, btn.w, "center")

end

-- Handle power-up purchases
function shop_menu.purchase_item(item_index)
    -- Calculate actual item index based on pagination
    local start_idx = (shop_menu.current_page - 1) * shop_menu.items_per_page
    local actual_idx = start_idx + item_index
    
    local item = shop_menu.available_items[actual_idx]
    if not item then return false end
    
    -- If already purchased, ignore click
    if item.purchased then return false end
    
    -- Check if player can afford it
    if (hud.cash or 0) < item.price then
        debug.log("[ShopMenu] Cannot afford item: $" .. item.price .. " (have $" .. (hud.cash or 0) .. ")")
        -- Play error sound
        local sfx = require "scripts/sfx"
        if sfx.play then sfx.play('error') end
        -- Show error popup near the item
        local popup = require "scripts/popup"
        local box = shop_menu.item_boxes[item_index]
        popup.spawn({
            x = box and (box.x + box.w/2) or (love.graphics.getWidth() / 2),
            y = box and (box.y + 24) or (love.graphics.getHeight() / 2 - 50),
            text = "Not enough cash!",
            color = {1, 0.3, 0.3, 1},
            font_size = 18,
            fade_duration = 0.3,
            stay_duration = 1.0,
            popup_type = popup.TYPES.NOTIFICATION
        })
        -- Track last failed purchase for UI tag
        shop_menu.last_failed_purchase = item_idx
        return false
    end
    
    local success = false
    
    -- Handle weapon vs power-up differently
    if item.is_weapon then
        -- Add weapon to inventory
        local inventory = require "scripts/inventory"
        local popup = require "scripts/popup"
        
        -- Create a weapon item based on the category
        local weapon_item = {
            type = "weapon",
            category = item.data.category or item.id,
            level = 1,
            color = item.color or {1, 1, 1, 1}
        }
        
        -- Add weapon to inventory
        local result, action = inventory.add(weapon_item, false)
        success = (result == true)
        
        if success then
            -- Deduct cash
            hud.cash = hud.cash - item.price
            
            -- Play purchase sound
            local sfx = require "scripts/sfx"
            if sfx.play then
                sfx.play('weapon_pickup')
            end
            
            -- Show purchase notification
            local display_name = item.data.name or item.id:gsub("^%l", string.upper)
            popup.create_notification("Purchased: " .. display_name, popup.STYLES.WEAPON, item.color)
        end
    else
        -- It's a regular power-up - acquire normally (this handles cash deduction)
        success = powerup.acquire(item.id, false)
    end
    
    if success then
        -- Mark as purchased instead of removing
        item.purchased = true
        shop_menu.purchased[actual_idx] = true
        
        -- If stackable, keep it in the shop but update price
        if item.data.stackable then
            item.purchased = false -- Reset purchased flag
            local new_price = math.floor(item.price * 1.5)
            item.price = new_price
            debug.log("[ShopMenu] Stackable power-up price increased to $" .. new_price)
        else
            debug.log("[ShopMenu] Marked item as purchased (keeping slot empty)")
        end
        
        return true
    end
    
    debug.log("[ShopMenu] Failed to purchase power-up: " .. item.id)
    return false
end

-- Handle mouse clicks on the shop menu
function shop_menu.mousepressed(x, y, button)
    if not shop_menu.active or button ~= 1 then return false end
    
    -- Handle REROLL button click (disable after use)
    local reroll = shop_menu._reroll_btn
    if shop_menu.can_reroll and x >= reroll.x and x <= reroll.x + reroll.w and y >= reroll.y and y <= reroll.y + reroll.h then
        shop_menu.can_reroll = false -- Disable reroll after use
        shop_menu.generate_items(shop_menu.current_level) -- Reroll items
        return true
    end
    
    -- Check if any item was clicked
    for i, box in ipairs(shop_menu.item_boxes) do
        -- Calculate the actual item index based on current page
        local item_idx = (shop_menu.current_page - 1) * shop_menu.items_per_page + i
        if item_idx <= #shop_menu.available_items and
           x >= box.x and x <= box.x + box.w and
           y >= box.y and y <= box.y + box.h then
            -- Buy this item if not already purchased
            if not shop_menu.available_items[item_idx].purchased then
                shop_menu.purchase_item(i)
                return true -- Signal that we handled the click
            end
        end
    end
    
    -- Check if left arrow was clicked (pagination)
    local left = shop_menu._left_arrow
    if shop_menu.current_page > 1 and
       x >= left.x and x <= left.x + left.w and
       y >= left.y - left.h/2 and y <= left.y + left.h/2 then
        -- Navigate to previous page
        shop_menu.current_page = shop_menu.current_page - 1
        shop_menu.hover_item = nil -- Reset hover when changing pages
        
        -- Play navigation sound
        local sfx = require "scripts/sfx"
        if sfx.play then
            sfx.play('menu_click')
        end
        
        return true
    end
    
    -- Check if right arrow was clicked (pagination)
    local right = shop_menu._right_arrow
    local total_pages = math.ceil(shop_menu.total_items / shop_menu.items_per_page)
    if shop_menu.current_page < total_pages and
       x >= right.x and x <= right.x + right.w and
       y >= right.y - right.h/2 and y <= right.y + right.h/2 then
        -- Navigate to next page
        shop_menu.current_page = shop_menu.current_page + 1
        shop_menu.hover_item = nil -- Reset hover when changing pages
        
        -- Play navigation sound
        local sfx = require "scripts/sfx"
        if sfx.play then
            sfx.play('menu_click')
        end
        
        return true
    end
    
    -- Check if reroll button was clicked
    if shop_menu.can_reroll then
        local reroll = shop_menu._reroll_btn
        if x >= reroll.x and x <= reroll.x + reroll.w and
           y >= reroll.y and y <= reroll.y + reroll.h then
            -- Check if player can afford reroll
            if (hud.cash or 0) >= reroll.price then
                -- Deduct reroll price
                hud.cash = hud.cash - reroll.price
                
                -- Play reroll sound
                local sfx = require "scripts/sfx"
                if sfx.play then
                    sfx.play('powerup_activate')
                end
                
                -- Regenerate shop items
                shop_menu.generate_items(shop_menu.current_level)
                shop_menu.current_page = 1
                shop_menu.can_reroll = false -- Can only reroll once per shop visit
                
                -- Show reroll notification
                local popup = require "scripts/popup"
                popup.create_notification("Shop Refreshed!", popup.STYLES.NOTIFICATION, {0.2, 0.8, 0.2, 1})
                
                return true
            else
                -- Can't afford reroll
                local popup = require "scripts/popup"
                popup.create_notification("Can't afford reroll!", popup.STYLES.NOTIFICATION, {1, 0.3, 0.3, 1})
                
                -- Play error sound
                local sfx = require "scripts/sfx"
                if sfx.play then
                    sfx.play('error')
                end
                
                return true
            end
        end
    end
    
    -- Check if continue/skip button was clicked
    local btn = shop_menu._continue_btn
    if x >= btn.x and x <= btn.x + btn.w and
       y >= btn.y and y <= btn.y + btn.h then
        -- Hide shop menu and continue game
        shop_menu.hide()
        return true -- Signal that we handled the click
    end
    
    return false -- Did not click on any UI element
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

-- Hide shop menu and resume game
function shop_menu.hide()
    shop_menu.active = false
    _G.game_paused = false
    
    -- Return to default cursor for gameplay
    love.mouse.setVisible(false)
    
    debug.log("[ShopMenu] Shop menu closed")
    
    -- Check if we should update player level after shop
    if shop_menu.should_level_up then
        shop_menu.should_level_up = false
        -- You could trigger the level up functionality here if needed
    end
end

-- Handle keyboard input in shop menu
function shop_menu.keypressed(key)
    if not shop_menu.active then return false end
    
    -- ESC or Space closes shop menu
    if key == "escape" or key == "space" or key == "return" then
        shop_menu.hide()
        return true
    end
    
    return false
end

return shop_menu
