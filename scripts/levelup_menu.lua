--[[
    levelup_menu.lua
    Handles the level-up interface where players can choose power-ups or weapon upgrades
    Using the modular menu_template system
]]

local settings = require "settings"
local debug = require "scripts/debug"
local hud = require "scripts/hud"
local powerup = require "scripts/powerup"
local menu_template = require "scripts/menu_template"

local levelup_menu = {}

-- Level up state
levelup_menu.active = false
levelup_menu.current_level = 1
levelup_menu.available_items = {}  -- Power-ups available for selection
levelup_menu.items_per_page = 3    -- Always show 3 options

-- Menu template state
levelup_menu.menu_state = nil      -- Will be initialized in show()

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
    
    -- Use the enhanced function that supports weapons in the level up menu
    -- Pass the current level/wave to control weapon probability
    local options = powerup.roll_enhanced_level_up_options(settings.powerups.level_up_count or 3, level)
    debug.log("[LevelUpMenu] Roll returned " .. #options .. " options")
    
    -- If we got options (power-ups or weapons), add them to available items
    if #options > 0 then
        -- Track used IDs to avoid duplicates
        local used_ids = {}
        
        for i, option in ipairs(options) do
            -- Skip if we've already added this item (avoid duplicates)
            if used_ids[option.id] then
                debug.log("[LevelUpMenu] Skipping duplicate item: " .. option.id)
            else
                local is_weapon = option.is_weapon or option.data.is_weapon or false
                local item_type = is_weapon and "weapon" or "powerup"
                debug.log("[LevelUpMenu] Adding " .. item_type .. " option " .. i .. ": " .. option.id .. " (" .. option.data.name .. ")")
                
                -- Mark as used
                used_ids[option.id] = true
                
                -- Add to available items
                table.insert(levelup_menu.available_items, {
                    id = option.id,
                    data = option.data,
                    is_weapon = is_weapon,
                    color = powerup.get_rarity_color(option.data.rarity)
                })
            end
        end
    else
        debug.log("[LevelUpMenu] Warning: No options available for level up")
    end
    
    -- Ensure we always have exactly 3 options
    while #levelup_menu.available_items < 3 do
        -- Add filler option if we don't have enough
        debug.log("[LevelUpMenu] Adding filler option to reach 3 options")
        table.insert(levelup_menu.available_items, {
            id = "filler_" .. #levelup_menu.available_items + 1,
            data = {
                name = "No More Options",
                description = "All other power-ups are unavailable",
                rarity = "common"
            },
            is_weapon = false,
            color = {0.5, 0.5, 0.5, 1},
            is_filler = true
        })
    end
    
    -- If we have more than 3, limit to first 3
    if #levelup_menu.available_items > 3 then
        levelup_menu.available_items = {
            levelup_menu.available_items[1],
            levelup_menu.available_items[2],
            levelup_menu.available_items[3]
        }
    end
    
    debug.log("[LevelUpMenu] Final menu has exactly " .. #levelup_menu.available_items .. " options")
    
    -- Initialize menu state with available items
    levelup_menu.init_menu_state()
end

-- Initialize the menu state with our template
function levelup_menu.init_menu_state()
    -- Create the menu config with needed callbacks and settings
    local config = {
        title = "LEVEL UP!",
        subtitle = "Choose ONE weapon to upgrade:",
        box_w = 700,
        box_h = 450,
        item_box_w = 200,
        item_box_h = 240,
        items_per_page = levelup_menu.items_per_page,
        border_color = {0.4, 0.6, 1, 1}, -- Blue border for level up
        title_color = {0.4, 0.6, 1, 1}, -- Blue text for level up title
        fonts = levelup_menu._fonts,
        buttons = {
            {
                text = "SKIP",
                callback = function() return levelup_menu.close() end,
                width = 160,
                height = 50
            }
        },
        callbacks = {
            -- Draw each level up item
            drawItem = function(item, box, hover)
                levelup_menu.draw_item(item, box, hover)
            end,
            -- Handle item selection
            onItemSelected = function(index, item)
                if not item.is_filler then
                    levelup_menu.select_item(index, item)
                end
                return true
            end
        }
    }
    
    -- Initialize menu state with our template
    levelup_menu.menu_state = menu_template.init_state(levelup_menu.available_items, config)
    
    -- Update the menu state
    menu_template.update_state(levelup_menu.menu_state)
end

-- Show the level up menu when leveling up
function levelup_menu.show(level)
    levelup_menu.active = true
    levelup_menu.current_level = level
    
    -- Pause the game while level up menu is active
    _G.game_paused = true
    
    -- Show system cursor when level up menu is active
    love.mouse.setVisible(true)
    
    -- Generate level up items
    levelup_menu.generate_items(level)
    
    debug.log("[LevelUpMenu] Level up menu opened at level " .. level)
end

-- Draw a single level up item
function levelup_menu.draw_item(item, box, hover)
    -- If it's a filler option, show a "no option" indicator
    if item.is_filler then
        -- Empty slot (darker grey)
        love.graphics.setColor(0.15, 0.15, 0.15, 0.7)
        love.graphics.rectangle("fill", box.x, box.y, box.w, box.h, box.r, box.r)
        love.graphics.setColor(0.4, 0.4, 0.4, 0.5)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", box.x, box.y, box.w, box.h, box.r, box.r)
        
        -- No more options text
        love.graphics.setColor(0.7, 0.7, 0.7, 0.7)
        love.graphics.setFont(levelup_menu._fonts.body)
        love.graphics.printf("No More Options", box.x, box.y + box.h/2 - 10, box.w, "center")
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
    love.graphics.setFont(levelup_menu._fonts.body) -- Ensure correct font for item name/title
    love.graphics.printf(name, box.x, box.y + 70, box.w, "center")
    love.graphics.setColor(0.85, 0.85, 0.85, 1)
    love.graphics.printf(description, box.x + 10, box.y + 95, box.w - 20, "center")
    
    -- Category tag at bottom
    love.graphics.setColor(item.is_weapon and {1, 0.8, 0, 1} or {0.6, 0.8, 1, 1})
    love.graphics.setFont(levelup_menu._fonts.body)
    love.graphics.printf(item.is_weapon and "WEAPON" or "POWER-UP", box.x, box.y + box.h - 30, box.w, "center")
end

-- Select an item from the level up menu
function levelup_menu.select_item(index, item)
    if not item then return false end
    
    debug.log("[LevelUpMenu] Selected item " .. item.id)
    
    -- Grant the item to the player
    if item.is_weapon then
        -- Add weapon to inventory
        local inventory = require "scripts/inventory"
        inventory.add(item.id)
        debug.log("[LevelUpMenu] Added weapon " .. item.id .. " to inventory")
    else
        -- Grant power-up effect
        powerup.apply(item.id)
        debug.log("[LevelUpMenu] Applied power-up " .. item.id)
    end
    
    -- Play sound effect
    local sfx = require "scripts/sfx"
    if sfx.play then
        sfx.play("powerup")
    end
    
    -- Close the level up menu
    levelup_menu.hide()
    return true
end

-- Close without selecting anything
function levelup_menu.close()
    levelup_menu.hide()
    return true
end

-- Hide the level up menu and continue gameplay
function levelup_menu.hide()
    levelup_menu.active = false
    
    -- Hide system cursor when returning to gameplay
    love.mouse.setVisible(false)
    
    -- Unpause the game
    _G.game_paused = false
    
    debug.log("[LevelUpMenu] Level up menu closed, continuing game")
end

-- Draw the level up menu
function levelup_menu.draw()
    if not levelup_menu.active then return end
    
    -- Full screen semi-transparent black overlay
    love.graphics.setColor(0, 0, 0, 0.7)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.rectangle("fill", 0, 0, w, h)
    
    -- Draw the menu using our template
    if levelup_menu.menu_state then
        menu_template.draw(levelup_menu.menu_state, w, h)
    end
end

-- Handle mouse movement (hover detection)
function levelup_menu.mousemoved(x, y, dx, dy)
    if not levelup_menu.active or not levelup_menu.menu_state then return false end
    
    -- Use template's mouse move handler
    menu_template.handle_mouse_move(levelup_menu.menu_state, x, y)
    return true
end

-- Handle mouse clicks in the level up menu
function levelup_menu.mousepressed(x, y, button)
    if not levelup_menu.active or not levelup_menu.menu_state or button ~= 1 then return false end
    
    -- Use template's click handler
    local handled = menu_template.handle_mouse_click(levelup_menu.menu_state, x, y) 
    return handled
end

-- Handle keyboard input in level up menu
function levelup_menu.keypressed(key)
    if not levelup_menu.active then return false end
    
    -- ESC or Space closes level up menu
    if key == "escape" or key == "space" or key == "return" then
        levelup_menu.hide()
        return true
    end
    
    return false
end

-- Update level up menu (animations, etc)
function levelup_menu.update(dt)
    -- Any animations or time-based effects can be updated here
    return levelup_menu.active
end

return levelup_menu
