-- scenario.lua
-- Handles the creation and management of game environments and scenery
-- This module manages floor tiles, backgrounds, and other scene elements

local settings = require "settings"

local scenario = {}

-- Current loaded floor configuration
scenario.current_floor = nil

-- Floor configurations that can be loaded
scenario.floors = {}

-- Scenario settings (will be added to settings.lua in the future if needed)
scenario.settings = {
    tile_size = 64,
    -- Balance the weights - first tile is more common but not dominant
    tile_weights = {3, 1, 1, 1, 1, 1, 1, 1},
    -- The margin for the arena (should match arena_margin in main.lua)
    arena_margin = 32
}

-- Initialize the scenario module
function scenario.init()
    -- Load floor tile image
    scenario.tile_image = love.graphics.newImage("assets/img/floor-tiles1.jpg")
    
    -- Create quads for each 64x64 tile in the 4x2 grid
    scenario.tile_quads = {}
    for y = 0, 1 do
        for x = 0, 3 do
            table.insert(scenario.tile_quads, love.graphics.newQuad(
                x * 64, y * 64, 64, 64, scenario.tile_image:getDimensions()
            ))
        end
    end
    
    -- Define the first level floor configuration
    scenario.floors["level1"] = {
        tile_size = scenario.settings.tile_size,
        -- Weights for each tile (indices correspond to tile_quads indices)
        -- First tile has higher weight but balanced to not be too dominant
        tile_weights = scenario.settings.tile_weights,
        -- Use window dimensions from settings
        width = settings.main.window_width,
        height = settings.main.window_height,
        margin = scenario.settings.arena_margin
    }
    
    -- Set the current floor to level1
    scenario.set_floor("level1")
end

-- Set the active floor configuration
function scenario.set_floor(floor_name)
    if scenario.floors[floor_name] then
        scenario.current_floor = scenario.floors[floor_name]
        -- Generate the tile map with weighted randomization
        scenario.generate_tile_map()
    else
        print("Error: Floor configuration '" .. floor_name .. "' not found.")
    end
end

-- Generate a tile map based on the current floor configuration
function scenario.generate_tile_map()
    if not scenario.current_floor then return end
    
    local floor = scenario.current_floor
    local tile_size = floor.tile_size
    
    -- Calculate number of tiles needed to cover the floor area
    local tiles_x = math.ceil(floor.width / tile_size)
    local tiles_y = math.ceil(floor.height / tile_size)
    
    -- Create tile map with weighted random selection
    floor.tile_map = {}
    
    -- Create a selection pool based on weights
    local selection_pool = {}
    for i, weight in ipairs(floor.tile_weights) do
        for j = 1, weight do
            table.insert(selection_pool, i)
        end
    end
    
    -- Generate the tile map
    for y = 1, tiles_y do
        floor.tile_map[y] = {}
        for x = 1, tiles_x do
            -- Select a random tile from the weighted pool
            local random_index = love.math.random(1, #selection_pool)
            local tile_index = selection_pool[random_index]
            floor.tile_map[y][x] = tile_index
        end
    end
end

-- Draw the current floor
function scenario.draw_floor()
    if not scenario.current_floor then return end
    
    local floor = scenario.current_floor
    local tile_size = floor.tile_size
    local margin = floor.margin
    
    -- Calculate visible area with margins
    local visible_width = floor.width - (margin * 2)
    local visible_height = floor.height - (margin * 2)
    
    -- Calculate number of visible tiles
    local tiles_x = math.ceil(visible_width / tile_size)
    local tiles_y = math.ceil(visible_height / tile_size)
    
    -- Draw all tiles
    for y = 1, tiles_y do
        for x = 1, tiles_x do
            -- Get the tile index from the map
            local tile_index = floor.tile_map[y] and floor.tile_map[y][x]
            
            if tile_index then
                -- Calculate position with margin offset
                local pos_x = margin + (x - 1) * tile_size
                local pos_y = margin + (y - 1) * tile_size
                
                -- Draw the tile
                love.graphics.setColor(1, 1, 1, 1)
                love.graphics.draw(
                    scenario.tile_image,
                    scenario.tile_quads[tile_index],
                    pos_x, pos_y
                )
            end
        end
    end
end

-- Resize floor to match window dimensions
function scenario.resize(width, height)
    if scenario.current_floor then
        -- Update settings when window resizes
        settings.main.window_width = width
        settings.main.window_height = height
        
        -- Update floor dimensions
        scenario.current_floor.width = width
        scenario.current_floor.height = height
        
        -- Regenerate the tile map for the new dimensions
        scenario.generate_tile_map()
    end
end

-- Debug: Draw floor grid lines
function scenario.draw_debug_grid()
    if not scenario.current_floor then return end
    
    local floor = scenario.current_floor
    local tile_size = floor.tile_size
    local margin = floor.margin or 0
    
    -- Calculate visible area with margins
    local visible_width = floor.width - (margin * 2)
    local visible_height = floor.height - (margin * 2)
    
    -- Draw grid lines
    love.graphics.setColor(0.5, 0.5, 0.5, 0.5)
    
    -- Vertical lines
    for x = 0, math.ceil(visible_width / tile_size) do
        local pos_x = margin + x * tile_size
        love.graphics.line(pos_x, margin, pos_x, margin + visible_height)
    end
    
    -- Horizontal lines
    for y = 0, math.ceil(visible_height / tile_size) do
        local pos_y = margin + y * tile_size
        love.graphics.line(margin, pos_y, margin + visible_width, pos_y)
    end
end

return scenario
