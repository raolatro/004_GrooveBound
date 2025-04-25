--[[
    shop_menu.lua
    Handles the shop interface where players can purchase items and powerups
    Using the modular menu_template system
]]

local settings = require "settings"
local debug = require "scripts/debug"
local hud = require "scripts/hud"
local powerup = require "scripts/powerup"
local menu_template = require "scripts/menu_template"

local shop_menu = {}

-- Shop state
shop_menu.active = false
shop_menu.current_level = 1
shop_menu.available_items = {}  -- Items currently available for purchase
shop_menu.can_reroll = true     -- Whether reroll button is available
shop_menu.items_per_page = 3    -- Number of items visible per page

-- Menu template state
shop_menu.menu_state = nil      -- Will be initialized in show()

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
    -- Reset available items
    shop_menu.available_items = {}
    
    -- Only allow reroll if not already used
    if shop_menu.can_reroll == nil then
        shop_menu.can_reroll = true
    end
    
    -- Use the enhanced powerup module to roll shop options including weapons
    -- Total items is fixed at 5 (with pagination showing 3 at a time)
    local options = powerup.roll_enhanced_shop_options(5, true, 5)
    
    -- If we got items (power-ups or weapons), add them to available items
    if #options > 0 then
        -- Track used IDs to avoid duplicates
        local used_ids = {}
        
        for i, option in ipairs(options) do
            -- Skip if we've already added this item (avoid duplicates)
            if used_ids[option.id] then
                debug.log("[ShopMenu] Skipping duplicate item: " .. option.id)
            else
                local is_weapon = option.is_weapon or option.data.is_weapon or false
                local item_type = is_weapon and "weapon" or "powerup"
                debug.log("[ShopMenu] Adding " .. item_type .. " option " .. i .. ": " .. option.id .. " (" .. option.data.name .. ")")
                
                -- Mark as used
                used_ids[option.id] = true
                
                -- Add to available items
                table.insert(shop_menu.available_items, {
                    id = option.id,
                    data = option.data,
                    is_weapon = is_weapon,
                    price = option.data.cost or (is_weapon and 300 or 200),  -- Default prices
                    color = powerup.get_rarity_color(option.data.rarity)
                })
            end
        end
    else
        debug.log("[ShopMenu] Warning: No items available for shop")
    end
    
    debug.log("[ShopMenu] Generated " .. #shop_menu.available_items .. " shop items")
    
    -- Initialize menu state with available items
    shop_menu.init_menu_state()
end

-- Initialize the menu state with our template
function shop_menu.init_menu_state()
    -- Create the menu config with needed callbacks and settings
    local config = {
        title = "SHOP",
        subtitle = "Choose items to purchase:",
        box_w = 700,
        box_h = 450,
        item_box_w = 200,
        item_box_h = 240,
        items_per_page = shop_menu.items_per_page,
        border_color = {0.4, 0.8, 0.2, 1}, -- Green border for shop
        title_color = {0.4, 0.8, 0.2, 1}, -- Green text for shop title
        fonts = shop_menu._fonts,
        buttons = {
            {
                text = "REROLL [$500]",
                callback = function() return shop_menu.reroll_items() end,
                enabled = shop_menu.can_reroll,
                price = 500,
                width = 160,
                height = 50
            },
            {
                text = "CLOSE",
                callback = function() return shop_menu.close() end,
                width = 160,
                height = 50
            }
        },
        callbacks = {
            -- Draw each shop item
            drawItem = function(item, box, hover)
                shop_menu.draw_item(item, box, hover)
            end,
            -- Handle item selection
            onItemSelected = function(index, item)
                shop_menu.purchase_item(index, item)
                return true
            end
        }
    }
    
    -- Initialize menu state with our template
    shop_menu.menu_state = menu_template.init_state(shop_menu.available_items, config)
    
    -- Update the menu state
    menu_template.update_state(shop_menu.menu_state)
end

-- Show the shop menu when leveling up
function shop_menu.show(level)
    shop_menu.active = true
    shop_menu.current_level = level
    shop_menu.can_reroll = true
    
    -- Pause the game while shop menu is active
    _G.game_paused = true
    
    -- Show system cursor when shop menu is active
    love.mouse.setVisible(true)
    
    -- Generate shop items
    shop_menu.generate_items(level)
    
    -- Initialize cash display
    if not hud.cash then hud.cash = 0 end
    
    debug.log("[ShopMenu] Shop menu opened at level " .. level .. ", player has $" .. hud.cash)
end

-- Draw a single shop item
function shop_menu.draw_item(item, box, hover)
    -- If sold out, show a 'sold out' indicator
    if not item then
        -- Empty slot (darker grey)
        love.graphics.setColor(0.15, 0.15, 0.15, 0.7)
        love.graphics.rectangle("fill", box.x, box.y, box.w, box.h, box.r, box.r)
        love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", box.x, box.y, box.w, box.h, box.r, box.r)
        return
    end
    
    -- Item box background (medium grey, lighter if hovered)
    love.graphics.setColor(hover and 0.4 or 0.3, hover and 0.4 or 0.3, hover and 0.4 or 0.3, 0.95)
    love.graphics.rectangle("fill", box.x, box.y, box.w, box.h, box.r, box.r)
    
    -- Item box border (color based on rarity)
    love.graphics.setColor(item.color)
    love.graphics.setLineWidth(hover and 3 or 2)
    love.graphics.rectangle("line", box.x, box.y, box.w, box.h, box.r, box.r)
    love.graphics.setLineWidth(1)
    
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
    
    -- Item name and description
    love.graphics.setColor(rarity_colors)
    love.graphics.setFont(shop_menu._fonts.body) -- Ensure correct font for item name/title
    love.graphics.printf(name, box.x, box.y + 70, box.w, "center")
    love.graphics.setColor(0.85, 0.85, 0.85, 1)
    love.graphics.printf(description, box.x + 10, box.y + 95, box.w - 20, "center")
    
    -- Category tag at bottom
    love.graphics.setColor(item.is_weapon and {1, 0.8, 0, 1} or {0.6, 0.8, 1, 1})
    love.graphics.setFont(shop_menu._fonts.body)
    love.graphics.printf(item.is_weapon and "WEAPON" or "POWER-UP", box.x, box.y + box.h - 48, box.w, "center")
    
    -- Price tag lower at bottom
    love.graphics.setColor(1, 0.9, 0, 1)
    love.graphics.printf("$" .. item.price, box.x, box.y + box.h - 30, box.w, "center")
end

-- Purchase an item from the shop
function shop_menu.purchase_item(index, item)
    if not item then return false end
    
    -- Check if player has enough cash
    if hud.cash >= item.price then
        -- Deduct cash and grant the powerup
        hud.cash = hud.cash - item.price
        debug.log("[ShopMenu] Purchased item " .. item.id .. " for $" .. item.price)
        
        -- Grant the item to the player
        if item.is_weapon then
            -- Add weapon to inventory
            local inventory = require "scripts/inventory"
            inventory.add(item.id)
            debug.log("[ShopMenu] Added weapon " .. item.id .. " to inventory")
        else
            -- Grant power-up effect
            powerup.apply(item.id) 
            debug.log("[ShopMenu] Applied power-up " .. item.id)
        end
        
        -- Play purchase sound
        local sfx = require "scripts/sfx"
        if sfx.play then
            sfx.play("coin")
        end
        
        -- Remove the purchased item from the shop
        menu_template.remove_item(shop_menu.menu_state, index)
        
        return true
    else
        -- Not enough cash - show error
        debug.log("[ShopMenu] Not enough cash to purchase " .. item.id .. " ($" .. item.price .. ")")
        
        -- Play error sound
        local sfx = require "scripts/sfx"
        if sfx.play then
            sfx.play("error")
        end
        
        return false
    end
end

-- Reroll shop items
function shop_menu.reroll_items()
    -- Check if player has enough cash for reroll
    if not shop_menu.can_reroll then
        debug.log("[ShopMenu] Reroll already used")
        return false
    end
    
    if hud.cash >= 500 then  -- Reroll cost is $500
        -- Deduct cash
        hud.cash = hud.cash - 500
        debug.log("[ShopMenu] Rerolling shop items for $500")
        
        -- Disable reroll for this shop session
        shop_menu.can_reroll = false
        
        -- Update button state in menu
        if shop_menu.menu_state and shop_menu.menu_state.config and shop_menu.menu_state.config.buttons then
            shop_menu.menu_state.config.buttons[1].enabled = false
        end
        
        -- Generate new shop items
        shop_menu.generate_items(shop_menu.current_level)
        
        -- Play reroll sound
        local sfx = require "scripts/sfx"
        if sfx.play then
            sfx.play("powerup")
        end
        
        return true
    else
        -- Not enough cash - show error
        debug.log("[ShopMenu] Not enough cash to reroll ($500 required)")
        
        -- Play error sound
        local sfx = require "scripts/sfx"
        if sfx.play then
            sfx.play("error")
        end
        
        return false
    end
end

-- Close the shop
function shop_menu.close()
    shop_menu.hide()
    return true
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

-- Draw the shop menu
function shop_menu.draw()
    if not shop_menu.active then return end
    
    -- Full screen semi-transparent black overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Draw the menu using our template
    if shop_menu.menu_state then
        menu_template.draw(shop_menu.menu_state, w, h)
    end
end

-- Handle mouse movement (hover detection)
function shop_menu.mousemoved(x, y, dx, dy)
    if not shop_menu.active or not shop_menu.menu_state then return false end
    
    -- Use template's mouse move handler
    menu_template.handle_mouse_move(shop_menu.menu_state, x, y)
    return true
end

-- Handle mouse clicks in the shop menu
function shop_menu.mousepressed(x, y, button)
    if not shop_menu.active or not shop_menu.menu_state or button ~= 1 then return false end
    
    -- Use template's click handler
    local handled = menu_template.handle_mouse_click(shop_menu.menu_state, x, y) 
    return handled
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

-- Update shop menu (animations, etc)
function shop_menu.update(dt)
    -- Any animations or time-based effects can be updated here
    return shop_menu.active
end

return shop_menu
