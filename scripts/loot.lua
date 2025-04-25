-- scripts/loot.lua: spawn and draw loot drops
local debug = require "scripts/debug"
local settings = require "settings"
local hud = require "scripts/hud"  -- Added missing import for hud module
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
        -- Check if this is any kind of cash drop (any of the coin types)
        local is_cash = d.id:match("coin") or d.id:match("gold") or d.id:match("treasure")
        local attr_enabled = is_cash and loot_settings.attraction_enabled or weapon_settings.attraction_enabled
        local attr_speed = is_cash and loot_settings.attraction_speed or weapon_settings.attraction_speed
        local attr_mult = is_cash and loot_settings.attraction_radius_mult or weapon_settings.attraction_radius_mult
        -- Attraction radius is based on outline_radius * attraction_radius_mult
        local attr_radius = outline_radius * (attr_mult or 2)
        -- Pickup radius is now outline_radius * loot.pickup_radius_mult (controllable in settings)
        local pickup_mult = is_cash and (loot_settings.pickup_radius_mult or 1.3) or 1.0
        local pickup_radius = outline_radius * pickup_mult
        -- Attraction: if within attraction radius but outside pickup radius
        d._attracting = d._attracting or false
        if attr_enabled and dist < attr_radius and dist > 1 then
            if not d._attracting then
                -- debug.log((is_money and 'Coin' or 'Weapon')..' attraction started!')
                d._attracting = true
            end
            -- Exponential ease-in: starts slow, accelerates as it approaches the player
            -- Calculate normalized distance - 0 when at pickup radius, 1 when at max attraction distance
            local normalized_dist = (dist - pickup_radius) / (attr_radius - pickup_radius)
            -- Clamp to 0-1 range
            normalized_dist = math.max(0, math.min(1, normalized_dist))
            -- Invert so it's 1 near player, 0 at edge
            local t = 1 - normalized_dist
            -- Exponential ease-in curve: t^3 accelerates dramatically as t increases
            local ease_factor = t * t * t -- cubic ease-in
            -- Apply easing to base speed
            local effective_speed = attr_speed * ease_factor * dt
            -- Calculate movement
            local angle = math.atan2(player_y - d.y, player_x - d.x)
            local move_dist = math.min(dist, effective_speed)
            d.x = d.x + math.cos(angle) * move_dist
            d.y = d.y + math.sin(angle) * move_dist
        else
            d._attracting = false
        end
        -- Pickup logic: if within pickup radius...
        if dist < pickup_radius then
            local data = settings.item_data
            local popup = require "scripts/popup"
            local sfx = require "scripts/sfx"
            
            -- Handle weapon pickups - this shouldn't happen anymore with updated system
            -- but keeping it for backward compatibility
            if not is_cash then
                local inventory = require "scripts/inventory"
                
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
                
                -- Show ONLY the color-coded weapon notification for new weapon, level up, or maxed out
                if maxed_out then
                    popup.create_notification(display_name .. " MAXED OUT!", popup.STYLES.WEAPON, {0.8, 0.8, 0.8, 1})
                elseif in_inventory then
                    popup.create_notification(display_name .. " LEVEL " .. tostring(inv_level), popup.STYLES.WEAPON, color)
                else
                    popup.create_notification("Got a new " .. display_name .. "!!", popup.STYLES.WEAPON, color)
                end
                -- No duplicate or extra popups
            end
            -- Handle cash pickups
            else
                -- Find the loot type by ID to get value, name, tint, and size
                local loot_value, loot_name, loot_tint, loot_size = 10, "Coin", {1,0.9,0,1}, 10
                for _, loot_type in ipairs(data.LootTypes) do
                    if loot_type.id == d.id then
                        loot_value = loot_type.value
                        loot_name = loot_type.name
                        loot_tint = loot_type.tint or loot_tint
                        loot_size = loot_type.size or loot_size
                        break
                    end
                end
                -- Always update drop's tint and size for consistency
                d.tint = loot_tint
                d.size = loot_size
                -- Add money to player cash
                if not hud.cash then hud.cash = 0 end
                hud.cash = hud.cash + loot_value
                -- Popup is now created in on_pickup function to avoid duplicates
                
                -- Play cash pickup sound
                if sfx.play then
                    sfx.play('coin')
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

-- Spawn a single loot item of specified type with proper visual properties
function loot.spawn_item(x, y, offset_range, chosen_loot)
    local data = settings.item_data
    offset_range = offset_range or 30
    
    -- Add random offset so drops aren't exactly on the same position
    local offset_x = math.random(-offset_range, offset_range)
    local offset_y = math.random(-offset_range, offset_range)
    
    -- Ensure chosen_loot has all required properties
    if not chosen_loot.size then chosen_loot.size = 10 end
    if not chosen_loot.tint then chosen_loot.tint = {1, 0.9, 0, 1} end
    if not chosen_loot.value then chosen_loot.value = 10 end
    
    -- Slightly vary size and tint to make each loot item look unique
    local size_variation = math.random(90, 110) / 100  -- ±10% variation
    local tint_variation = {
        math.min(1, chosen_loot.tint[1] * math.random(95, 105) / 100),
        math.min(1, chosen_loot.tint[2] * math.random(95, 105) / 100),
        math.min(1, chosen_loot.tint[3] * math.random(95, 105) / 100),
        chosen_loot.tint[4] or 1
    }
    
    -- Create the drop with proper properties
    local new_loot = {
        id = chosen_loot.id,
        x = x + offset_x,
        y = y + offset_y,
        size = chosen_loot.size * size_variation,  -- Vary size slightly
        tint = tint_variation,  -- Vary color slightly
        value = chosen_loot.value,
        name = chosen_loot.name or "Coin"
    }
    
    table.insert(loot.drops, new_loot)
    return new_loot
end

-- Roll drop table to select a random loot type based on weights
function loot.roll_loot_type()
    local data = settings.item_data
    
    -- Roll drop table by weight to select a loot type
    local total_weight = 0
    for _, loot_type in ipairs(data.LootTypes) do
        total_weight = total_weight + (loot_type.weight or 1)
    end
    
    local roll = math.random() * total_weight
    local current_weight = 0
    local chosen_loot = nil
    
    -- Select a loot type based on weight
    for _, loot_type in ipairs(data.LootTypes) do
        current_weight = current_weight + (loot_type.weight or 1)
        if roll <= current_weight then
            chosen_loot = loot_type
            break
        end
    end
    
    -- Fallback to a basic coin if nothing was selected
    if not chosen_loot then
        for _, loot_type in ipairs(data.LootTypes) do
            if loot_type.id == "coin_medium" then
                chosen_loot = loot_type
                break
            end
        end
        -- Final fallback if coin_medium doesn't exist
        if not chosen_loot and #data.LootTypes > 0 then
            chosen_loot = data.LootTypes[1]
        else
            -- Emergency fallback if loot types table is empty
            chosen_loot = {
                id = "coin_medium",
                name = "Coin",
                size = 10,
                tint = {1, 0.9, 0, 1},
                value = 10
            }
        end
    end
    
    return chosen_loot
end

-- Spawn a new drop near (x,y) with random offset
function loot.spawn(x, y)
    -- For backward compatibility, spawn a single loot item
    local chosen_loot = loot.roll_loot_type()
    local new_loot = loot.spawn_item(x, y, 30, chosen_loot)
    debug.log("Spawned loot: " .. new_loot.id .. " with value $" .. new_loot.value)
    return new_loot
end

-- Spawn multiple loot items based on enemy type and wave
function loot.spawn_multiple(x, y, is_boss, killed_by_groove, wave_number)
    local settings = require "settings"
    local loot_settings = settings.loot
    local data = settings.item_data
    wave_number = wave_number or (_G.current_wave or 1)
    
    -- Calculate wave scaling factors for both drops and value
    local wave_drop_scaling = 1 + (loot_settings.wave_drop_scaling * wave_number)
    local wave_value_scaling = 1 + (loot_settings.wave_value_scaling * wave_number)
    
    -- Determine base min/max drops based on enemy type
    local min_drops = is_boss and loot_settings.boss_min_drops or loot_settings.min_drops
    local max_drops = is_boss and loot_settings.boss_max_drops or loot_settings.max_drops
    
    -- Add bonus for killing with rhythm/groove
    if killed_by_groove then
        min_drops = min_drops + loot_settings.groove_bonus
        max_drops = max_drops + loot_settings.groove_bonus
    end
    
    -- Apply wave scaling to min/max drops (with a floor function to ensure whole numbers)
    min_drops = math.floor(min_drops * wave_drop_scaling)
    max_drops = math.floor(max_drops * wave_drop_scaling)
    
    -- Calculate final number of drops, capped at max_drops
    local num_drops = math.min(math.random(min_drops, max_drops), max_drops)
    
    -- Log the drop calculations
    debug.log(string.format("Spawning %d loot items (min=%d, max=%d, wave=%d, drop_scaling=%.2f, value_scaling=%.2f)", 
        num_drops, min_drops, max_drops, wave_number, wave_drop_scaling, wave_value_scaling))
    
    -- Apply value multipliers for special conditions
    local value_multiplier = 1.0
    if is_boss then value_multiplier = value_multiplier * loot_settings.boss_value_multiplier end
    if killed_by_groove then value_multiplier = value_multiplier * loot_settings.groove_value_multiplier end
    
    -- Apply wave scaling to value multiplier
    value_multiplier = value_multiplier * wave_value_scaling
    
    debug.log(string.format("Loot value multiplier: %.2f (wave=%d, boss=%s, groove=%s)",
        value_multiplier, wave_number, tostring(is_boss), tostring(killed_by_groove)))
    
    -- Spawn the calculated number of loot items
    local total_value = 0
    local scattered_range = is_boss and 60 or 40  -- Wider scattering for boss loot
    
    for i = 1, num_drops do
        local chosen_loot = loot.roll_loot_type()
        local new_loot = loot.spawn_item(x, y, scattered_range, chosen_loot)
        -- Optionally scale value for groove/boss drops
        new_loot.value = math.floor(new_loot.value * value_multiplier)
        table.insert(loot.drops, new_loot)
        total_value = total_value + new_loot.value
    end
    
    -- Return total value of spawned loot
    return total_value
end

-- Draw loot drops with appropriate size and color for each type
function loot.draw()
    local camera = require "scripts/camera"
    local data = settings.item_data
    
    for _, d in ipairs(loot.drops) do
        -- Draw cash with appropriate size and color
        love.graphics.setColor(d.tint or {1, 0.9, 0, 1}) -- Golden yellow default
        love.graphics.circle("fill", d.x, d.y, d.size or 10)
        love.graphics.setColor(1, 1, 1, 0.8) -- White outline
        love.graphics.circle("line", d.x, d.y, (d.size or 10) + 1)
    end
    
    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

-- Handle loot pickup when player touches it
function loot.on_pickup(index, player_x, player_y)
    -- Get the drop being picked up
    local drop = loot.drops[index]
    if not drop then return end  -- Safety check
    
    -- Setup required modules
    local data = settings.item_data
    local hud = require "scripts/hud"
    local popup = require "scripts/popup"
    local sfx = require "scripts/sfx"
    
    -- Debug log
    debug.log("Loot picked up: " .. drop.id .. " at position " .. drop.x .. ", " .. drop.y)
    
    -- Check if it's a cash/coin type
    local is_cash = drop.id:match("coin") or drop.id:match("gold") or drop.id:match("treasure") or drop.id == "money"
    
    if is_cash then
        -- Find the loot type to get name, value, tint, and size
        local loot_value, loot_name, loot_tint, loot_size = 10, "Coin", {1,0.9,0,1}, 10
        
        -- Get correct loot info from LootTypes in item_data
        for _, loot_type in ipairs(data.LootTypes) do
            if loot_type.id == drop.id then
                loot_value = loot_type.value
                loot_name = loot_type.name
                loot_tint = loot_type.tint or loot_tint
                loot_size = loot_type.size or loot_size
                break
            end
        end
        
        -- Play pickup sound
        if sfx.play then sfx.play('coin') end
        
        -- Add value to player cash
        if not hud.cash then hud.cash = 0 end
        hud.cash = hud.cash + loot_value
        
        -- Create the popup with loot name and value
        popup.spawn({
            x = drop.x,
            y = drop.y - 20,
            text = loot_name .. " +$" .. loot_value,
            color = loot_tint,
            font_size = 16,
            fade_duration = 0.5,
            stay_duration = 0.3,
        })
    else
        -- Handle legacy weapon pickups - this should rarely happen with updated system
        local inventory = require "scripts/inventory"
        
        -- Add to inventory and get result info
        local success, action, category, level = inventory.add(drop.id)
        
        -- Play weapon pickup sound
        if sfx.play then sfx.play('weapon') end
        
        -- Create appropriate notification
        if action == "level_up" then
            popup.create_notification(category:upper() .. " upgraded to LVL " .. level, popup.STYLES.WEAPON, drop.color or {1,1,1,1})
        elseif action == "added" then
            popup.create_notification("Picked up " .. category:upper(), popup.STYLES.WEAPON, drop.color or {1,1,1,1})
        end
    end
    
    -- Remove the loot from the drops array
    table.remove(loot.drops, index)
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
    end
    
    -- Draw pickup radius if enabled (moved outside the loop to avoid drawing multiple circles)
    if settings.loot.show_pickup_radius and player_x and outline_radius then
        -- Draw money pickup radius
        local money_pickup_mult = loot_settings.pickup_radius_mult or 1.3
        local money_pickup_radius = outline_radius * money_pickup_mult
        love.graphics.setColor(0.2, 0.8, 0.2, 0.15) -- Green for money
        love.graphics.circle("fill", player_x, player_y, money_pickup_radius)
        
        -- Draw weapon pickup radius
        local weapon_pickup_mult = settings.weapon.pickup_radius_mult or 1.0
        local weapon_pickup_radius = outline_radius * weapon_pickup_mult
        love.graphics.setColor(0.5, 0, 1, 0.15) -- Purple for weapons
        love.graphics.circle("line", player_x, player_y, weapon_pickup_radius)
        love.graphics.setColor(0.5, 0, 1, 0.05) -- Lighter fill
        love.graphics.circle("fill", player_x, player_y, weapon_pickup_radius)
    end
    love.graphics.setColor(1,1,1,1)
end

-- Note: Debug toggle replaced by settings.loot.show_pickup_radius

return loot
