--[[
    menu_template.lua
    A modular, reusable menu system for GrooveBound
    
    This template can be used for shop menus, level-up menus, and other similar interfaces
    with consistent styling and behavior.
]]

local menu_template = {}

-- Default settings that can be overridden
menu_template.defaults = {
    box_w = 700,
    box_h = 450,
    items_per_page = 3,
    item_box_w = 200,
    item_box_h = 240,
    item_box_padding = 20,
    title_y_offset = 30,
    subtitle_y_offset = 100,
    items_y_offset = 150,
    border_radius = 20,
    item_border_radius = 15,
    arrow_size = 30,
    arrow_y_offset = 240,
    page_text_y_offset = 420
}

-- Initialize a menu state object with defaults
function menu_template.init_state(items, config)
    local state = {
        items = items or {},                       -- List of items to display
        visible_items = {},                        -- Items visible on current page
        current_page = 1,                          -- Current page number
        total_pages = 1,                           -- Total number of pages
        hover_item = nil,                          -- Currently hovered item index
        item_boxes = {},                           -- Bounding boxes for item slots
        nav_arrows = {                             -- Navigation arrows
            left = {active = false, box = {}},
            right = {active = false, box = {}}
        },
        removed_indices = {},                      -- Tracks removed items (e.g. purchased)
        button_boxes = {}                          -- Bounding boxes for buttons
    }
    
    -- Apply configuration
    state.config = config or {}
    
    return state
end

-- Update menu state (pagination, visible items, etc.)
function menu_template.update_state(state)
    -- Filter out removed items
    local active_items = {}
    for i, item in ipairs(state.items) do
        if not state.removed_indices[i] then
            table.insert(active_items, {item = item, original_index = i})
        end
    end
    
    -- Calculate total pages
    local items_per_page = state.config.items_per_page or menu_template.defaults.items_per_page
    state.total_pages = math.max(1, math.ceil(#active_items / items_per_page))
    
    -- Ensure current page is valid
    if state.current_page > state.total_pages then
        state.current_page = state.total_pages
    end
    
    -- Set visible items for current page
    state.visible_items = {}
    local start_idx = (state.current_page - 1) * items_per_page + 1
    for i = start_idx, math.min(start_idx + items_per_page - 1, #active_items) do
        table.insert(state.visible_items, {
            item = active_items[i].item,
            original_index = active_items[i].original_index
        })
    end
    
    -- Update navigation arrows state
    state.nav_arrows.left.active = state.current_page > 1
    state.nav_arrows.right.active = state.current_page < state.total_pages
    
    -- Return if we should show pagination (4+ active items)
    return #active_items >= 4
end

-- Calculate layout for the menu and its items
function menu_template.calculate_layout(state, w, h)
    -- Menu box dimensions and position
    local box_w = state.config.box_w or menu_template.defaults.box_w
    local box_h = state.config.box_h or menu_template.defaults.box_h
    local box_x = (w - box_w) / 2
    local box_y = (h - box_h) / 2
    
    state.menu_box = {
        x = box_x, y = box_y, w = box_w, h = box_h,
        r = state.config.border_radius or menu_template.defaults.border_radius
    }
    
    -- Calculate item box positions (center with proper spacing)
    local item_box_w = state.config.item_box_w or menu_template.defaults.item_box_w
    local item_box_h = state.config.item_box_h or menu_template.defaults.item_box_h
    local padding = state.config.item_box_padding or menu_template.defaults.item_box_padding
    
    -- Calculate total width needed for all visible item boxes plus padding
    local items_per_page = state.config.items_per_page or menu_template.defaults.items_per_page
    local total_items_width = (item_box_w * #state.visible_items) + (padding * (#state.visible_items - 1))
    local start_x = box_x + (box_w - total_items_width) / 2
    
    state.item_boxes = {}
    for i = 1, #state.visible_items do
        local item_x = start_x + (i-1) * (item_box_w + padding)
        local item_y = box_y + (state.config.items_y_offset or menu_template.defaults.items_y_offset)
        
        state.item_boxes[i] = {
            x = item_x,
            y = item_y,
            w = item_box_w,
            h = item_box_h,
            r = state.config.item_border_radius or menu_template.defaults.item_border_radius
        }
    end
    
    -- Position navigation arrows
    local arrow_size = state.config.arrow_size or menu_template.defaults.arrow_size
    local arrow_y = box_y + (state.config.arrow_y_offset or menu_template.defaults.arrow_y_offset)
    
    state.nav_arrows.left.box = {
        x = box_x + 30,
        y = arrow_y,
        w = arrow_size,
        h = arrow_size
    }
    
    state.nav_arrows.right.box = {
        x = box_x + box_w - 30 - arrow_size,
        y = arrow_y,
        w = arrow_size,
        h = arrow_size
    }
    
    -- Setup buttons if provided
    if state.config.buttons then
        local button_y = box_y + box_h - 80
        local total_buttons_width = 0
        
        -- Calculate total width of buttons
        for _, button in ipairs(state.config.buttons) do
            total_buttons_width = total_buttons_width + (button.width or 160) + 20
        end
        
        -- Position buttons
        local button_x = box_x + (box_w - total_buttons_width) / 2
        state.button_boxes = {}
        
        for i, button in ipairs(state.config.buttons) do
            local width = button.width or 160
            local height = button.height or 50
            
            state.button_boxes[i] = {
                x = button_x,
                y = button_y,
                w = width,
                h = height,
                r = 10,
                button = button
            }
            
            button_x = button_x + width + 20
        end
    end
end

-- Check if a point is within a box
function menu_template.point_in_box(x, y, box)
    return x >= box.x and x <= box.x + box.w and y >= box.y and y <= box.y + box.h
end

-- Handle mouse movement to detect hovers
function menu_template.handle_mouse_move(state, x, y)
    -- Check item hovers
    state.hover_item = nil
    for i, box in ipairs(state.item_boxes) do
        if state.visible_items[i] and menu_template.point_in_box(x, y, box) then
            state.hover_item = i
            break
        end
    end
    
    -- Check button hovers
    state.hover_button = nil
    for i, box in ipairs(state.button_boxes) do
        if menu_template.point_in_box(x, y, box) then
            state.hover_button = i
            break
        end
    end
    
    -- Check navigation arrow hovers
    state.nav_arrows.left.hover = state.nav_arrows.left.active and menu_template.point_in_box(x, y, state.nav_arrows.left.box)
    state.nav_arrows.right.hover = state.nav_arrows.right.active and menu_template.point_in_box(x, y, state.nav_arrows.right.box)
    
    return state.hover_item, state.hover_button
end

-- Handle mouse click
function menu_template.handle_mouse_click(state, x, y)
    -- Check if an item was clicked
    for i, box in ipairs(state.item_boxes) do
        if state.visible_items[i] and menu_template.point_in_box(x, y, box) then
            -- Call the onItemSelected callback if it exists
            if state.config.callbacks and state.config.callbacks.onItemSelected then
                return state.config.callbacks.onItemSelected(state.visible_items[i].original_index, state.visible_items[i].item)
            end
            return true
        end
    end
    
    -- Check if a button was clicked
    for i, box in ipairs(state.button_boxes) do
        if menu_template.point_in_box(x, y, box) and box.button and box.button.callback then
            if box.button.enabled ~= false then
                return box.button.callback()
            end
        end
    end
    
    -- Check if left arrow was clicked
    if state.nav_arrows.left.active and menu_template.point_in_box(x, y, state.nav_arrows.left.box) then
        state.current_page = state.current_page - 1
        menu_template.update_state(state)
        return true
    end
    
    -- Check if right arrow was clicked
    if state.nav_arrows.right.active and menu_template.point_in_box(x, y, state.nav_arrows.right.box) then
        state.current_page = state.current_page + 1
        menu_template.update_state(state)
        return true
    end
    
    return false
end

-- Mark an item as removed (e.g. purchased)
function menu_template.remove_item(state, index)
    state.removed_indices[index] = true
    menu_template.update_state(state)
end

-- Draw the menu background and border
function menu_template.draw_background(state)
    local box = state.menu_box
    
    -- Background
    love.graphics.setColor(state.config.bg_color or {0.15, 0.15, 0.15, 0.95})
    love.graphics.rectangle("fill", box.x, box.y, box.w, box.h, box.r, box.r)
    
    -- Border
    love.graphics.setColor(state.config.border_color or {0.4, 0.6, 1, 1})
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", box.x, box.y, box.w, box.h, box.r, box.r)
    love.graphics.setLineWidth(1)
end

-- Draw the navigation arrows and page text if needed
function menu_template.draw_navigation(state, show_pagination)
    if not show_pagination then return end
    
    -- Left arrow
    local left = state.nav_arrows.left
    if left.active then
        love.graphics.setColor(left.hover and {1, 1, 1, 1} or {0.7, 0.7, 0.7, 0.7})
        love.graphics.polygon('fill', 
            left.box.x + left.box.w, left.box.y, 
            left.box.x + left.box.w, left.box.y + left.box.h, 
            left.box.x, left.box.y + left.box.h/2
        )
    else
        love.graphics.setColor(0.4, 0.4, 0.4, 0.4)
        love.graphics.polygon('fill', 
            left.box.x + left.box.w, left.box.y, 
            left.box.x + left.box.w, left.box.y + left.box.h, 
            left.box.x, left.box.y + left.box.h/2
        )
    end
    
    -- Right arrow
    local right = state.nav_arrows.right
    if right.active then
        love.graphics.setColor(right.hover and {1, 1, 1, 1} or {0.7, 0.7, 0.7, 0.7})
        love.graphics.polygon('fill', 
            right.box.x, right.box.y, 
            right.box.x, right.box.y + right.box.h, 
            right.box.x + right.box.w, right.box.y + right.box.h/2
        )
    else
        love.graphics.setColor(0.4, 0.4, 0.4, 0.4)
        love.graphics.polygon('fill', 
            right.box.x, right.box.y, 
            right.box.x, right.box.y + right.box.h, 
            right.box.x + right.box.w, right.box.y + right.box.h/2
        )
    end
    
    -- Page text
    love.graphics.setColor(0.7, 0.7, 0.7, 1)
    love.graphics.setFont(state.config.fonts.body)
    local page_text = "Page " .. state.current_page .. " of " .. state.total_pages
    love.graphics.printf(page_text, 
                        state.menu_box.x, 
                        state.menu_box.y + (state.config.page_text_y_offset or menu_template.defaults.page_text_y_offset), 
                        state.menu_box.w, 
                        "center")
end

-- Draw the menu title and subtitle
function menu_template.draw_title(state)
    -- Title
    love.graphics.setFont(state.config.fonts.header)
    love.graphics.setColor(state.config.title_color or {0.4, 0.6, 1, 1})
    love.graphics.printf(state.config.title or "MENU", 
                        state.menu_box.x, 
                        state.menu_box.y + (state.config.title_y_offset or menu_template.defaults.title_y_offset), 
                        state.menu_box.w, 
                        "center")
    
    -- Subtitle (if provided)
    if state.config.subtitle then
        love.graphics.setFont(state.config.fonts.body)
        love.graphics.setColor(state.config.subtitle_color or {0.8, 0.8, 0.8, 1})
        love.graphics.printf(state.config.subtitle, 
                            state.menu_box.x, 
                            state.menu_box.y + (state.config.subtitle_y_offset or menu_template.defaults.subtitle_y_offset), 
                            state.menu_box.w, 
                            "center")
    end
end

-- Draw the buttons
function menu_template.draw_buttons(state)
    if not state.config.buttons then return end
    
    for i, box in ipairs(state.button_boxes) do
        local button = box.button
        local enabled = button.enabled ~= false
        local hover = state.hover_button == i and enabled
        
        -- Button background
        love.graphics.setColor(button.bg_color or (enabled and (hover and {0.4, 0.6, 1, 0.8} or {0.3, 0.5, 0.9, 0.7}) or {0.5, 0.5, 0.5, 0.5}))
        love.graphics.rectangle("fill", box.x, box.y, box.w, box.h, box.r, box.r)
        
        -- Button border
        love.graphics.setColor(button.border_color or (enabled and {0.4, 0.6, 1, 1} or {0.5, 0.5, 0.5, 0.8}))
        love.graphics.setLineWidth(hover and 3 or 2)
        love.graphics.rectangle("line", box.x, box.y, box.w, box.h, box.r, box.r)
        love.graphics.setLineWidth(1)
        
        -- Button text
        love.graphics.setFont(state.config.fonts.body)
        love.graphics.setColor(button.text_color or (enabled and {1, 1, 1, 1} or {0.7, 0.7, 0.7, 0.7}))
        love.graphics.printf(button.text, box.x, box.y + box.h/2 - 10, box.w, "center")
        
        -- Price tag if applicable
        if button.price then
            love.graphics.setColor(1, 0.9, 0, 1)
            love.graphics.printf("$" .. button.price, box.x, box.y + box.h - 20, box.w, "center")
        end
    end
end

-- Main draw function
function menu_template.draw(state, w, h)
    -- Calculate layout first
    menu_template.calculate_layout(state, w, h)
    
    -- Update visible items and pagination
    local show_pagination = menu_template.update_state(state)
    
    -- Draw background and border
    menu_template.draw_background(state)
    
    -- Draw title and subtitle
    menu_template.draw_title(state)
    
    -- Draw items (using the provided drawItem callback)
    if state.config.callbacks and state.config.callbacks.drawItem then
        for i, item_data in ipairs(state.visible_items) do
            state.config.callbacks.drawItem(
                item_data.item,
                state.item_boxes[i],
                state.hover_item == i
            )
        end
    end
    
    -- Draw navigation (if needed)
    menu_template.draw_navigation(state, show_pagination)
    
    -- Draw buttons
    menu_template.draw_buttons(state)
end

return menu_template
