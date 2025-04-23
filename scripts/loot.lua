-- scripts/loot.lua: spawn and draw loot drops
local debug = require "scripts/debug"
local settings = require "settings"
local loot = {}
loot.drops = {}

-- Update loot drops: attraction and pickup logic
function loot.update(dt, player_x, player_y, outline_radius)
    outline_radius = outline_radius or 16 -- Fallback to safe default if nil
    local loot_settings = settings.loot
    local weapon_settings = settings.weapon
    for i = #loot.drops, 1, -1 do
        local d = loot.drops[i]
        local dx, dy = d.x - player_x, d.y - player_y
        local dist = math.sqrt(dx*dx + dy*dy)
        local is_money = (d.id == "money")
        local attr_enabled = is_money and loot_settings.attraction_enabled or weapon_settings.attraction_enabled
        local attr_speed = is_money and loot_settings.attraction_speed or weapon_settings.attraction_speed
        local attr_mult = is_money and loot_settings.attraction_radius_mult or weapon_settings.attraction_radius_mult
        -- Attraction radius is based on outline_radius * attraction_radius_mult
        local attr_radius = outline_radius * (attr_mult or 2)
        -- Pickup radius is now outline_radius * loot.pickup_radius_mult (controllable in settings)
        local pickup_mult = is_money and (loot_settings.pickup_radius_mult or 1.3) or 1.0
        local pickup_radius = outline_radius * pickup_mult
        -- Attraction: if within attraction radius but outside pickup radius
        d._attracting = d._attracting or false
        if attr_enabled and dist < attr_radius and dist > 1 then
            if not d._attracting then
                -- debug.log((is_money and 'Coin' or 'Weapon')..' attraction started!')
                d._attracting = true
            end
            -- Ease-out (starts fast, finishes slow): use quadratic ease-out for lerp factor
            local t = 1 - (dist-pickup_radius)/(attr_radius-pickup_radius)
            local lerp_factor = math.min(0.15 + 0.6 * (1-(1-t)^2), 1) -- quadratic ease-out
            d.x = d.x + (player_x - d.x) * lerp_factor * dt * 2
            d.y = d.y + (player_y - d.y) * lerp_factor * dt * 2
        else
            d._attracting = false
        end
        -- Pickup logic: if within pickup radius and not money, add to inventory or level up
        if not is_money and dist < pickup_radius then
            local inventory = require "scripts/inventory"
            local popup = require "scripts/popup"
            local data = settings.item_data -- Fix: Add reference to item_data
            
            -- Get results from inventory.add - now returns status info
            local success, action, category, level = inventory.add(d.id)
            inventory.debug_print() -- Debug: print inventory after pickup
            
            -- Handle different outcomes with appropriate visual feedback
            if action == "level_up" then
                -- Get color from the data (defaults to white if not found)
                local item_color = {1, 1, 1, 1} -- Default white
                local data_item = data.Items[d.id]
                if data_item and data_item.color then
                    item_color = data_item.color
                end
                
                -- Spawn level up popup with special effect and weapon color as notification
                popup.spawn({
                    text = category:upper() .. " LEVEL UP TO " .. level,
                    color = item_color,
                    font_size = 30, -- Use font_size instead of font_scale for consistency
                    fade_duration = settings.popup.fade_duration or 0.5,
                    box = true,
                    box_color = {0.1, 0.1, 0.1, 0.8},
                    box_padding = 12,
                    outline = true,
                    outline_color = {1, 1, 1, 0.8},
                    outline_width = 2,
                    shadow = false,
                    shadow_color = {0, 0, 0, 0.6},
                    shadow_offset = 2,
                    popup_type = popup.TYPES.NOTIFICATION -- Use notification type for top-center display
                })
                
                -- Play a special sound effect for level up
                local sfx = require "scripts/sfx"
                if sfx.play then
                    sfx.play('levelup')
                end
            elseif action == "max_level" then
                -- Show max level notification at top center
                popup.spawn({
                    text = category:upper() .. " MAXED OUT",
                    color = {1, 0.8, 0, 1}, -- Gold color for max level
                    font_size = 32, -- Use font_size instead of font_scale
                    fade_duration = 1.0,
                    box = true,
                    box_color = {0.1, 0.1, 0.1, 0.8},
                    box_padding = 12,
                    outline = true,
                    outline_color = {1, 0.8, 0, 0.8}, -- Gold outline
                    outline_width = 2,
                    shadow = true,
                    shadow_color = {0, 0, 0, 0.6},
                    shadow_offset = 3,
                    popup_type = popup.TYPES.NOTIFICATION -- Use notification type for top-center display
                })
            elseif action == "added" then
                -- Check if weapon is already in inventory and what level it is
                local in_inventory = false
                local inv_level = 1
                local maxed_out = false
                
                for _, slot in ipairs(inventory.slots) do
                    if slot and slot.category == category then
                        in_inventory = true
                        inv_level = slot.level or 1
                        
                        -- Check if weapon is maxed out
                        local weapon_levels = settings.weapons[category]
                        if weapon_levels and inv_level >= #weapon_levels then
                            maxed_out = true
                        end
                        break
                    end
                end
                
                -- Get display name and color for the weapon
                local weapon_settings = settings.weapons[category]
                local display_name = weapon_settings and weapon_settings.display_name or category:upper()
                local color = (data_item and data_item.color) or {1, 1, 1, 1}
                
                -- Show appropriate popup based on weapon status
                if maxed_out then
                    -- Show maxed out notification
                    popup.create_notification(display_name .. " MAXED OUT!", popup.STYLES.WEAPON, {0.8, 0.8, 0.8, 1})
                elseif in_inventory then
                    -- Show level up notification
                    popup.create_notification(display_name .. " LEVEL " .. tostring(inv_level), popup.STYLES.WEAPON, color)
                else
                    -- Show new weapon notification
                    popup.create_notification("Got a new " .. display_name .. "!!", popup.STYLES.WEAPON, color)
                end
            end
            
            -- Remove the loot regardless of outcome
            table.remove(loot.drops, i)
        end
    end
end

-- Draw debug radius for attraction and pickup
-- Attraction debug overlay is now handled in player.draw for accuracy. This function is no longer needed.
function loot.draw_debug() end

-- Spawn a new drop near (x,y) with random offset
function loot.spawn(x, y)
    local data = settings.item_data
    local inventory = require "scripts/inventory"
    
    -- Check for maxed out weapons to skip
    local maxed_categories = {}
    for i, slot in ipairs(inventory.slots) do
        if slot then
            local category = slot.category
            local current_level = slot.level or 1
            local weapon_levels = settings.weapons[category]
            
            -- If weapon exists and is at max level, add to skip list
            if weapon_levels and current_level >= #weapon_levels then
                maxed_categories[category] = true
                debug.log("Skipping drops for maxed out category: " .. category)
            end
        end
    end
    
    -- Roll drop table by weight, potentially multiple times if we hit maxed weapons
    local max_attempts = 5  -- Avoid infinite loops
    local attempts = 0
    local chosen = nil
    
    repeat
        attempts = attempts + 1
        
        -- Standard drop roll
        local total = 0
        for _, entry in ipairs(data.DropTable) do total = total + entry.weight end
        local r = math.random() * total
        local acc = 0
        chosen = data.DropTable[1]
        
        for _, entry in ipairs(data.DropTable) do
            acc = acc + entry.weight
            if r <= acc then chosen = entry break end
        end
        
        -- Check if this is a maxed out weapon
        local chosen_item = data.Items[chosen.id]
        local skip_drop = false
        
        if chosen_item and chosen_item.type == "weapon" then
            if maxed_categories[chosen_item.category] then
                skip_drop = true
                debug.log("Rerolling drop: " .. chosen.id .. " (maxed out category)")
            end
        end
        
        -- Exit loop if we found a valid drop or hit max attempts
    until (not skip_drop) or (attempts >= max_attempts)
    
    -- Only spawn if we didn't skip the drop
    if attempts < max_attempts or not skip_drop then
        -- Offset spawn position
        local angle = math.random() * 2 * math.pi
        local dist = math.random(20, 40)
        local dropX = x + math.cos(angle) * dist
        local dropY = y + math.sin(angle) * dist
        table.insert(loot.drops, { x = dropX, y = dropY, id = chosen.id, rarity = chosen.rarity })
    end
end

-- Draw all loot drops
function loot.draw(player_x, player_y, outline_radius)
    local data = settings.item_data
    local loot_settings = settings.loot
    for _, d in ipairs(loot.drops) do
        local item = data.Items[d.id]
        local color = (item and item.color) or (data.Rarity[d.rarity] and data.Rarity[d.rarity].color) or {1,1,1,1}
        love.graphics.setColor(color)
        love.graphics.circle("fill", d.x, d.y, 6)
        -- Debug: draw pickup radius if enabled
        if loot.debug_draw_pickup_radius and player_x and outline_radius then
            local is_money = (d.id == "money")
            local pickup_mult = is_money and (loot_settings.pickup_radius_mult or 1.3) or 1.0
            local pickup_radius = outline_radius * pickup_mult
            love.graphics.setColor(0.5,0,1,0.1)
            love.graphics.circle("fill", player_x, player_y, pickup_radius)
        end
    end
    love.graphics.setColor(1,1,1,1)
end

-- Toggle for debug pickup radius
loot.debug_draw_pickup_radius = true

return loot
