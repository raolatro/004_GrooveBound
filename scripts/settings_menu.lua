-- settings_menu.lua: In-game settings menu UI for GrooveBound
-- Draws a hamburger icon, menu popup, and lets user adjust main settings in real time
-- Start with only the main settings group (bpm, beat_subdivisions, etc)

local settings = require "settings"
local inventory = require "scripts/inventory"
local settings_menu = {}
settings_menu.score = 0
settings_menu.kills = 0
settings_menu.money = 0

-- Font system: load all fonts up front for use throughout the UI
-- Helper to reload fonts whenever a size or path changes
function settings_menu.reload_fonts()
    settings_menu._fonts = {
        header = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.header),
        body = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.body),
        button = love.graphics.newFont(settings.main.fonts.path, settings.main.fonts.button)
    }
end
settings_menu.reload_fonts()

-- Font settings controls for the menu (for extensibility)
settings_menu.fonts_settings = {
    { key = "header", label = "Header Font Size", min = 10, max = 64, step = 1 },
    { key = "body", label = "Body Font Size", min = 8, max = 32, step = 1 },
    { key = "button", label = "Button Font Size", min = 8, max = 48, step = 1 }
}

settings_menu.active = false
settings_menu.page = 1
settings_menu.pages = {"main"}
settings_menu.icon_size = 36
settings_menu.icon_margin = 12
settings_menu.selected = 1 -- selected row in menu
settings_menu.auto_fire_enabled = false
settings_menu.aim_line_enabled = true -- Auto-Fire toggle
settings_menu.score = 0 -- Total score
settings_menu.kills = 0 -- Total kills
settings_menu.money = 0 -- Total money
settings_menu.player_hp = nil -- Player current HP (set at game start)
settings_menu.player_max_hp = nil -- Player max HP (set at game start)

-- Heart sprite
local paths = require "paths"
settings_menu.hp_img = settings_menu.hp_img or love.graphics.newImage(paths.assets.hp)
settings_menu.hp_full_quad = love.graphics.newQuad(0,0,64,56,settings_menu.hp_img:getDimensions())
settings_menu.hp_empty_quad = love.graphics.newQuad(64,0,64,56,settings_menu.hp_img:getDimensions())

-- List of settings to show on the first page (main)
settings_menu.main_settings = {
    { key = "bpm", label = "Beats Per Minute", min = 16, max = 240, step = 1 },
    { key = "beat_subdivisions", label = "Beat Subdivisions", min = 1, max = 16, step = 1 },
    { key = "beat_checker_base_radius", label = "Checker Radius", min = 8, max = 256, step = 1 },
    { key = "on_beat_scale", label = "On-Beat Scale", min = 0.5, max = 3, step = 0.05 },
    { key = "beat_checker_on_beat_buffer", label = "On-Beat Buffer", min = 0.01, max = 0.5, step = 0.01 },
    -- Loot attraction controls
    { key = "loot_attraction_enabled", label = "Loot Attraction", type = "bool" },
    { key = "loot_attraction_speed", label = "Loot Attraction Speed", min = 10, max = 500, step = 5 },
    { key = "loot_attraction_radius_mult", label = "Loot Attraction Radius x", min = 1, max = 5, step = 0.1 },
    -- Weapon attraction controls
    { key = "weapon_attraction_enabled", label = "Weapon Attraction", type = "bool" },
    { key = "weapon_attraction_speed", label = "Weapon Attraction Speed", min = 10, max = 500, step = 5 },
    { key = "weapon_attraction_radius_mult", label = "Weapon Attraction Radius x", min = 1, max = 5, step = 0.1 },
}

function settings_menu.toggle()
    settings_menu.active = not settings_menu.active
    if settings_menu.active then
        settings_menu.init_attraction_settings()
    end
end

function settings_menu.update(dt)
    -- Sync settings_menu values to settings.loot/weapon
    local settings = require "settings"
    -- Loot
    if settings_menu.loot_attraction_enabled ~= nil then settings.loot.attraction_enabled = settings_menu.loot_attraction_enabled end
    if settings_menu.loot_attraction_speed ~= nil then settings.loot.attraction_speed = settings_menu.loot_attraction_speed end
    if settings_menu.loot_attraction_radius_mult ~= nil then settings.loot.attraction_radius_mult = settings_menu.loot_attraction_radius_mult end
    -- Weapon
    if settings_menu.weapon_attraction_enabled ~= nil then settings.weapon.attraction_enabled = settings_menu.weapon_attraction_enabled end
    if settings_menu.weapon_attraction_speed ~= nil then settings.weapon.attraction_speed = settings_menu.weapon_attraction_speed end
    if settings_menu.weapon_attraction_radius_mult ~= nil then settings.weapon.attraction_radius_mult = settings_menu.weapon_attraction_radius_mult end
end

-- On load, copy settings into settings_menu
function settings_menu.init_attraction_settings()
    local settings = require "settings"
    settings_menu.loot_attraction_enabled = settings.loot.attraction_enabled
    settings_menu.loot_attraction_speed = settings.loot.attraction_speed
    settings_menu.loot_attraction_radius_mult = settings.loot.attraction_radius_mult
    settings_menu.weapon_attraction_enabled = settings.weapon.attraction_enabled
    settings_menu.weapon_attraction_speed = settings.weapon.attraction_speed
    settings_menu.weapon_attraction_radius_mult = settings.weapon.attraction_radius_mult
end

function settings_menu.keypressed(key)
    if not settings_menu.active then return end
    if key == "escape" then settings_menu.active = false end
    if key == "down" then settings_menu.selected = math.min(settings_menu.selected+1, #settings_menu.main_settings) end
    if key == "up" then settings_menu.selected = math.max(settings_menu.selected-1, 1) end
    local sel = settings_menu.main_settings[settings_menu.selected]
    if key == "+" or key == "right" then
        local v = settings.main[sel.key]
        settings.main[sel.key] = math.min(sel.max, v + sel.step)
    elseif key == "-" or key == "left" then
        local v = settings.main[sel.key]
        settings.main[sel.key] = math.max(sel.min, v - sel.step)
    end
end

function settings_menu.mousepressed(x, y, button)
    print('DEBUG: mousepressed called, active='..tostring(settings_menu.active)..', x='..x..', y='..y..', button='..tostring(button))
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local margin = 16
    local bar_height = 38
    local heart_w = 32
    local n_hearts = tonumber(settings_menu.player_max_hp) or 5
    local bar_x = margin
    local bar_y = margin
    local after_hearts_x = bar_x + n_hearts*heart_w + 24 + (28*3 + 8*2)
    local after_money_x = after_hearts_x + 100 + 12
    local after_score_x = after_money_x + 100 + 12
    local after_kills_x = after_score_x + 80 + 12
    local af_width = 160
    -- Check Auto-Fire toggle button (always clickable)
    if button == 1 and x >= after_kills_x and x <= after_kills_x+af_width and y >= bar_y and y <= bar_y+bar_height then
        settings_menu.auto_fire_enabled = not settings_menu.auto_fire_enabled
        print('DEBUG: Auto-Fire toggled to', tostring(settings_menu.auto_fire_enabled))
        return
    end
    if not settings_menu.active then
        -- Check if hamburger icon clicked (only left mouse button)
        local ix, iy = w - settings_menu.icon_size - settings_menu.icon_margin, settings_menu.icon_margin
        if button == 1 then
            print('DEBUG: Left mouse button pressed')
            if x >= ix and x <= ix+settings_menu.icon_size and y >= iy and y <= iy+settings_menu.icon_size then
                print('DEBUG: Hamburger icon clicked! Activating menu.')
                settings_menu.active = true
            end
        end
    else
        -- Implement mouse interaction for +/- font controls
        if settings_menu.active then
            local w, h = love.graphics.getWidth(), love.graphics.getHeight()
            local font_section_y = h/2 + 80
            for j, font_entry in ipairs(settings_menu.fonts_settings) do
                local fy = font_section_y + 24 + (j-1)*38
                -- Minus button
                if button == 1 and x >= w/2+60 and x <= w/2+88 and y >= fy and y <= fy+28 then
                    local key = font_entry.key
                    local cur = settings.main.fonts[key]
                    local new_val = math.max(font_entry.min, cur - font_entry.step)
                    settings.main.fonts[key] = new_val
                    settings_menu.reload_fonts()
                    return
                end
                -- Plus button
                if button == 1 and x >= w/2+100 and x <= w/2+128 and y >= fy and y <= fy+28 then
                    local key = font_entry.key
                    local cur = settings.main.fonts[key]
                    local new_val = math.min(font_entry.max, cur + font_entry.step)
                    settings.main.fonts[key] = new_val
                    settings_menu.reload_fonts()
                    return
                end
            end
        end
    end
end

function settings_menu.draw()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    -- Draw hamburger icon (top right)
    local ix, iy = w - settings_menu.icon_size - settings_menu.icon_margin, settings_menu.icon_margin
    print('DEBUG: draw() called, drawing hamburger icon at', ix, iy)
    love.graphics.setColor(1,1,1,0.8)
    love.graphics.rectangle("fill", ix, iy, settings_menu.icon_size, settings_menu.icon_size, 8, 8)
    love.graphics.setColor(0,0,0,1)
    for i=1,3 do
        love.graphics.rectangle("fill", ix+8, iy+8*i, settings_menu.icon_size-16, 4, 2, 2)
    end
    love.graphics.setColor(1,1,1,1)
    -- Draw top bar: hearts, score, kills, auto-fire toggle all in one row
    local bar_height = 38
    local margin = 16
    local heart_w, heart_h = 32, 28
    local n_hearts = tonumber(settings_menu.player_max_hp) or 3
    local bar_x = margin
    local bar_y = margin
    -- Draw hearts as sprites
    for i=1,n_hearts do
        local x = bar_x + (i-1)*heart_w
        local quad = (i <= (settings_menu.player_hp or 0)) and settings_menu.hp_full_quad or settings_menu.hp_empty_quad
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(settings_menu.hp_img, quad, x, bar_y, 0, heart_w/64, heart_h/56)
    end
    -- Weapons slots HUD
    do
        local slots = {"forward","cross","drone"}
        local slot_size = 28
        local slot_spacing = 8
        local slot_start_x = bar_x + n_hearts*heart_w + 24
        for idx, cat in ipairs(slots) do
            local x0 = slot_start_x + (idx-1)*(slot_size + slot_spacing)
            local y0 = bar_y + (bar_height - slot_size)/2
            love.graphics.setColor(1,1,1,1)
            love.graphics.rectangle("line", x0, y0, slot_size, slot_size, 6,6)
            local s = inventory.slots[cat]
            if s then
                love.graphics.setColor(s.color)
                love.graphics.circle("fill", x0 + slot_size/2, y0 + slot_size/2, slot_size/2 - 4)
            end
        end
    end
    local after_hearts_x = bar_x + n_hearts*heart_w + 24 + (28*3 + 8*2)
    -- Money HUD color matches popup text
    local money_color = settings.item_data.Rarity.Common.color
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", after_hearts_x, bar_y, 100, bar_height, 10, 10)
    love.graphics.setColor(money_color)
    love.graphics.printf("Money: "..tostring(settings_menu.money), after_hearts_x, bar_y+8, 100, "center")
    love.graphics.setColor(1,1,1,1)
    local after_money_x = after_hearts_x + 100 + 12
    -- Score
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", after_money_x, bar_y, 100, bar_height, 10, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Score: "..tostring(settings_menu.score), after_money_x, bar_y+8, 100, "center")
    local after_score_x = after_money_x + 100 + 12
    -- Kills
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", after_score_x, bar_y, 80, bar_height, 10, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Kills: "..tostring(settings_menu.kills), after_score_x, bar_y+8, 80, "center")
    local after_kills_x = after_score_x + 80 + 12
    -- Auto-Fire toggle
    local af_width = 160
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", after_kills_x, bar_y, af_width, bar_height, 10, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Auto-Fire", after_kills_x+0, bar_y+8, af_width-36, "right")
    love.graphics.setColor(settings_menu.auto_fire_enabled and {0,1,0,1} or {1,0,0,1})
    love.graphics.circle("fill", after_kills_x+af_width-20, bar_y+bar_height/2, 12)
    love.graphics.setColor(1,1,1,1)
    -- Aim Line toggle
    local aim_width = 160
    local aim_x = after_kills_x + af_width + 12
    love.graphics.setColor(0.12,0.12,0.12,0.92)
    love.graphics.rectangle("fill", aim_x, bar_y, aim_width, bar_height, 10, 10)
    love.graphics.setColor(1,1,1,1)
    love.graphics.printf("Aim Line", aim_x, bar_y+8, aim_width-36, "right")
    love.graphics.setColor(settings_menu.aim_line_enabled and {0.9,0.9,0,1} or {0.5,0.5,0.2,1})
    love.graphics.circle("fill", aim_x+aim_width-20, bar_y+bar_height/2, 12)
    love.graphics.setColor(1,1,1,1)
    -- Draw popup menu if active
    if settings_menu.active then
        print('DEBUG: settings_menu.active, drawing popup menu')
        love.graphics.setColor(0,0,0,0.92)
        love.graphics.rectangle("fill", w/2-180, h/2-140, 360, 280, 16, 16)
        love.graphics.setColor(1,1,1,1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", w/2-180, h/2-140, 360, 280, 16, 16)
        love.graphics.setLineWidth(1)
        love.graphics.printf("SETTINGS", w/2-180, h/2-132, 360, "center")
        for i, entry in ipairs(settings_menu.main_settings) do
            local y = h/2-100 + (i-1)*38
            local v = settings.main[entry.key]
            if i == settings_menu.selected then
                love.graphics.setColor(0.2,0.8,1,1)
            else
                love.graphics.setColor(1,1,1,1)
            end
            love.graphics.printf(entry.label .. ": ", w/2-150, y, 140, "right")
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf(string.format("%.2f", v), w/2-10, y, 60, "left")
            -- Draw +/- buttons
            love.graphics.setColor(0.7,0.7,0.7,1)
            love.graphics.rectangle("fill", w/2+60, y, 28, 28, 6, 6)
            love.graphics.rectangle("fill", w/2+100, y, 28, 28, 6, 6)
            love.graphics.setColor(0,0,0,1)
            love.graphics.printf("-", w/2+60, y+4, 28, "center")
            love.graphics.printf("+", w/2+100, y+4, 28, "center")
        end
        love.graphics.setColor(1,1,1,1)

        -- Font Settings Section
        local font_section_y = h/2 + 80
        love.graphics.setFont(settings_menu._fonts.body)
        love.graphics.setColor(1,1,1,1)
        love.graphics.printf("FONTS", w/2-180, font_section_y, 360, "center")
        for j, font_entry in ipairs(settings_menu.fonts_settings) do
            local fy = font_section_y + 24 + (j-1)*38
            local fsize = settings.main.fonts[font_entry.key]
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf(font_entry.label .. ": ", w/2-150, fy, 140, "right")
            love.graphics.setColor(1,1,1,1)
            love.graphics.printf(tostring(fsize), w/2-10, fy, 60, "left")
            -- Draw +/- buttons for font size
            love.graphics.setColor(0.7,0.7,0.7,1)
            love.graphics.rectangle("fill", w/2+60, fy, 28, 28, 6, 6)
            love.graphics.rectangle("fill", w/2+100, fy, 28, 28, 6, 6)
            love.graphics.setColor(0,0,0,1)
            love.graphics.printf("-", w/2+60, fy+4, 28, "center")
            love.graphics.printf("+", w/2+100, fy+4, 28, "center")
        end
    end
    -- Draw bottom-center instruction (always visible)
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle("fill", w/2-230, h-54, 460, 36, 10, 10)
    love.graphics.setColor(1,1,1,1)
    local old_font = love.graphics.getFont()
    local instr_font = settings_menu._fonts.body
    love.graphics.setFont(instr_font)
    love.graphics.printf("Move: WASD   |   Aim: Mouse   |   Shoot: Left Click or Auto-Fire", w/2-220, h-48, 440, "center")
    love.graphics.setFont(old_font)
end

-- Draw the game over screen centered
-- (game over UI moved to scripts/game_over.lua)

    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local box_w, box_h = 400, 320
    local box_x, box_y = (w-box_w)/2, (h-box_h)/2
    love.graphics.setColor(0,0,0,0.92)
    love.graphics.rectangle("fill", box_x, box_y, box_w, box_h, 18, 18)
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(3)
    love.graphics.rectangle("line", box_x, box_y, box_w, box_h, 18, 18)
    love.graphics.setLineWidth(1)
    -- GAME OVER Title
    love.graphics.setFont(settings_menu._fonts.header)
    love.graphics.printf("GAME OVER", box_x, box_y+28, box_w, "center")
    -- Final Score label
    love.graphics.setFont(settings_menu._fonts.body)
    love.graphics.printf("Final Score", box_x, box_y+90, box_w, "center")
    -- Final Score value
    love.graphics.setFont(settings_menu._fonts.body)
    love.graphics.printf(tostring(settings_menu.score), box_x, box_y+120, box_w, "center")
    -- Kills label
    love.graphics.setFont(settings_menu._fonts.body)
    love.graphics.printf("Kills", box_x, box_y+170, box_w, "center")
    -- Kills value
    love.graphics.setFont(settings_menu._fonts.body)
    love.graphics.printf(tostring(settings_menu.kills), box_x, box_y+200, box_w, "center")
    -- Restart button
    local btn_w, btn_h = 180, 48
    local btn_x, btn_y = w/2-btn_w/2, box_y+box_h-80
    settings_menu._restart_btn = {x=btn_x, y=btn_y, w=btn_w, h=btn_h}
    love.graphics.setColor(0.15,0.7,1,1)
    love.graphics.rectangle("fill", btn_x, btn_y, btn_w, btn_h, 12, 12)
    love.graphics.setColor(1,1,1,1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", btn_x, btn_y, btn_w, btn_h, 12, 12)
    love.graphics.setLineWidth(1)
    -- Set font for RESTART button
    love.graphics.setFont(settings_menu._fonts.body)
    love.graphics.printf("RESTART", btn_x, btn_y+10, btn_w, "center")
-- Helper to check if mouse is inside a box
local function mouse_in_box(x, y, box)
    return x >= box.x and x <= box.x+box.w and y >= box.y and y <= box.y+box.h
end

-- Patch mousepressed to handle game over restart
function settings_menu.mousepressed(x, y, button)
    -- Block all UI if game over
    if require("scripts/game_over").active then return end
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local margin = 16
    local bar_height = 38
    local heart_w = 32
    local n_hearts = tonumber(settings_menu.player_max_hp) or 5
    local bar_x = margin
    local bar_y = margin
    local after_hearts_x = bar_x + n_hearts*heart_w + 24 + (28*3 + 8*2)
    local after_money_x = after_hearts_x + 100 + 12
    local after_score_x = after_money_x + 100 + 12
    local after_kills_x = after_score_x + 80 + 12
    local af_width = 160
    -- Auto-Fire toggle
    if button == 1 and x >= after_kills_x and x <= after_kills_x+af_width and y >= bar_y and y <= bar_y+bar_height then
        settings_menu.auto_fire_enabled = not settings_menu.auto_fire_enabled
        return
    end
    -- Aim line toggle (next to auto-fire)
    local aim_width = 160
    local aim_x = after_kills_x + af_width + 12
    if button == 1 and x >= aim_x and x <= aim_x+aim_width and y >= bar_y and y <= bar_y+bar_height then
        settings_menu.aim_line_enabled = not settings_menu.aim_line_enabled
        return
    end
    -- Hamburger icon
    if not settings_menu.active then
        local ix, iy = w - settings_menu.icon_size - settings_menu.icon_margin, settings_menu.icon_margin
        if button == 1 then
            if x >= ix and x <= ix+settings_menu.icon_size and y >= iy and y <= iy+settings_menu.icon_size then
                settings_menu.active = true
            end
        end
    end
end

settings_menu.init_attraction_settings()
return settings_menu
