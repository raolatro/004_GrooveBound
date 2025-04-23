-- settings.lua
local settings = {
    main = {
        sfx = {
            volume = 0.25, -- global SFX volume (0-1)
            loot_enabled = true,
            weapon_enabled = true,
            projectile_enabled = true,
            dead_enabled = true,
        },
        scoring = {
            kill_point = 10,         -- points for normal kill
            groove_kill_point = 50, -- points for groove kill
        },
        auto_fire_angle = 0.15, -- radians, smaller = stricter auto-fire aim (default ~4.5 degrees)
        window_width = 1920,
        window_height = 1080,
        bpm = 32,
        beat_subdivisions = 2,
        camera_delay = 1,         -- seconds
        -- Beat checker (rhythm aim) settings
        beat_checker_scale_initial = 0.5, -- scale at the start of pulse
        beat_checker_scale_final = 8,   -- scale at the end of pulse
        beat_checker_ease = 0.25,         -- how quickly it shrinks to normal (seconds)
        beat_checker_pulse_duration = 1, -- seconds for a full pulse
        -- Beat checker visual/logic parameters
        beat_checker_base_radius = 64, -- base radius offset from player center
        beat_checker_full_outline_width = 1, -- px, full beat circle outline
        beat_checker_full_opacity = 1.0,    -- full beat circle opacity
        beat_checker_quarter_count = 3,     -- number of quarter beats (subdivisions minus one)
        beat_checker_quarter_outline_width = 0.25, -- px, quarter outline
        beat_checker_quarter_opacity = 0.5, -- opacity for quarter beats
        beat_checker_on_beat_buffer = 0.05, -- seconds, window for perfect on-beat
        beat_checker_on_beat_anim_time = 0.6, -- seconds, green fill anim duration
        on_beat_color = {0,1,0,1}, -- global on-beat color for all visuals
        on_beat_scale = 1.1, -- global on-beat scale for all visuals
        -- On-beat circle animation (player outline) settings
        on_beat_scale_initial = 1.2,      -- scale at the start of on-beat animation
        on_beat_scale_final = 1.0,        -- scale at the end of on-beat animation
        on_beat_ease = 0.18,              -- how quickly it animates
        beat_flash = 1,                -- seconds to flash outline on beat

        -- Centralized font settings for all UI
        fonts = {
            path = "assets/fonts/m6x11plus.ttf",
            header = 28,
            body = 18,
            button = 24
        }

    },

    player = {
        speed = 20,
        hp = 7,
    },
    projectile = {
        -- Damage values for different projectile types (scalable for future weapons)
        normal_damage = 1,
        on_beat_damage = 5,
        range = 1000,                -- how far the projectile can travel (pixels)
        speed = 800,                -- speed of the projectile (pixels/sec)
        fire_rate = 0.15,          -- seconds between shots
        -- on_beat_color and on_beat_scale are now set globally in settings.main
        normal_color = {1,1,1,1},   -- RGBA for normal projectile
        normal_scale = 0.7,         -- scale for normal projectile
    },
    -- Note: Most enemy settings are now handled directly by the wave system
    enemy = {
        flash_duration = 0.5,      -- seconds enemy flashes when hit
    },
    popup = {
        -- Default popup settings
        enable_groove_popup = false,  -- toggle player groove popup
        text = "Groove punch!",
        color = {0,1,0,1}, -- default color
        font_size = 20,         -- font size in px for popup text
        stay_duration = 3,      -- seconds popup stays before fading
        fade_duration = 0.3,    -- seconds to fade out
        y_offset = 10,
        box = false,
        box_color = {0,0,0,0.7},
        box_padding = 5,
        outline = false,
        outline_color = {1,1,1,1},
        outline_width = 2,
        shadow = false,
        shadow_color = {0,0,0,0.5},
        shadow_offset = {2,2},
        
        -- Popup for enemy killed by groove
        killed_text = "Killed by the groove!",
        killed_color = {1,0,0,1},
        
        -- Standardized popup styles
        styles = {
            -- Main popup style (for boss announcements, major events)
            main = {
                font_size = 64,
                fade_duration = 3.0,
                hold_time = 4.0,
                box = true,
                box_color = {0, 0, 0, 0.9},
                box_padding = 25,
                outline = true,
                outline_color = {1, 1, 0, 1}, -- Yellow outline
                outline_width = 6,           -- Thicker outline
                shadow = true,
                shadow_color = {0, 0, 0, 0.8},
                shadow_offset = {5, 5}
            },
            
            -- Subhead style (secondary information)
            subhead = {
                font_size = 42,
                fade_duration = 2.5,
                hold_time = 3.0,
                box = true,
                box_color = {0, 0, 0, 0.8},
                box_padding = 15,
                outline = false,
                shadow = true,
                shadow_color = {0, 0, 0, 0.8},
                shadow_offset = 3
            },
            
            -- Weapon style (for weapon pickups, level-ups)
            weapon = {
                font_size = 32,
                fade_duration = 2.0,
                hold_time = 2.5,
                box = true,
                box_color = {0.1, 0.1, 0.1, 0.8},
                box_padding = 12,
                outline = true,
                outline_width = 2,
                shadow = true,
                shadow_color = {0, 0, 0, 0.6},
                shadow_offset = 3
            }
        },
    },
    enemy_hp_display = {
        font_size = 12,           -- px
        color = {0,0,0,1},       -- black
        y_offset = -7,          -- pixels above enemy center
        font = nil,              -- can set a custom font path if needed
    },
    -- Load item drop settings
    item_data = require "data/items",
    loot = {
        attraction_enabled = true, -- coins chase player
        attraction_speed = 500,   -- px/sec
        attraction_radius_mult = 70, -- chase starts at outline_radius * this
        pickup_radius_mult = 0.8, -- now matches beat_checker_base_radius (which is 64px)
        show_pickup_radius = true, -- toggle visibility of pickup radius
    },
    weapon = {
        attraction_enabled = true,
        attraction_speed = 500, -- px/sec
        attraction_radius_mult = 70, -- chase starts at outline_radius * this
        pickup_radius_mult = 0.8, -- now matches beat_checker_base_radius (which is 64px)
    }
}

settings.waves = {
    { hp = 10, speed = 70, spawn_rate = 2.5, max_enemies = 8 }, -- Wave 1
    { hp = 12, speed = 80, spawn_rate = 2, max_enemies = 10 }, -- Wave 2
    { hp = 14, speed = 90, spawn_rate = 1.5, max_enemies = 15 }, -- Wave 3
    { hp = 20, speed = 100, spawn_rate = 1.5, max_enemies = 20 }, -- Wave 4
    { hp = 25, speed = 110, spawn_rate = 1.3, max_enemies = 25 }, -- Wave 5
    { hp = 30, speed = 120, spawn_rate = 1.1, max_enemies = 30 }, -- Wave 6
    { hp = 35, speed = 130, spawn_rate = 1.0, max_enemies = 35 }, -- Wave 7
    { hp = 40, speed = 140, spawn_rate = 0.9, max_enemies = 40 }, -- Wave 8
    { hp = 45, speed = 150, spawn_rate = 0.8, max_enemies = 45 }, -- Wave 9
    { hp = 50, speed = 160, spawn_rate = 0.7, max_enemies = 50 }, -- Wave 10
    { hp = 55, speed = 170, spawn_rate = 0.6, max_enemies = 55 }, -- Wave 11
    { hp = 60, speed = 180, spawn_rate = 0.5, max_enemies = 60 }, -- Wave 12
    { hp = 65, speed = 190, spawn_rate = 0.4, max_enemies = 65 }, -- Wave 13
    -- Add more for easy tuning
}
settings.boss = {
    hp = { 20, 40, 80, 120, 160, 200, 240, 280, 320, 360, 400 }, -- Boss HP per boss number
    speed = { 100, 120, 140, 160, 180, 200, 220, 240, 260, 280, 300 },
    radius = { 40, 60, 80, 100, 120, 140, 160, 180, 200, 220, 240 },
    color = { {1,0.2,0.2,1}, {0.4,0,1,1}, {1,0.6,0,1}, {0,0.8,0.8,1}, {0.2,0.2,1,1} },
    sfx = { 'boss1', 'boss2', 'boss3', 'boss4', 'boss5', 'boss6', 'boss7', 'boss8', 'boss9', 'boss10', 'boss11' },
}
settings.wave_duration = 10
settings.boss_duration = 30

-- Weapon categories and levels
settings.weapons = {
    forward = {
        display_name = "Pistol",
        -- Main gun, fires forward
        { damage = 1, fire_rate = 1.0, pierce = false, radius = 10 },
        { damage = 1, fire_rate = 1.2, pierce = true, radius = 10 },
        { damage = 2, fire_rate = 1.4, pierce = true, radius = 10 },
        { damage = 2, fire_rate = 1.6, pierce = true, radius = 10 },
        { damage = 5, fire_rate = 1.8, pierce = true, radius = 10 },
        { damage = 5, fire_rate = 2.0, pierce = true, radius = 10 },
        { damage = 5, fire_rate = 2.2, pierce = true, radius = 10 },
        { damage = 5, fire_rate = 2.4, pierce = true, radius = 10 },
        { damage = 5, fire_rate = 2.6, pierce = true, radius = 10 },
        { damage = 5, fire_rate = 2.8, pierce = true, radius = 10 },
        { damage = 5, fire_rate = 3.0, pierce = true, radius = 10 },
    },
    cross = {
        display_name = "Blaster",
        -- Fires in 4 or more directions
        { damage = 1, fire_rate = 0.5, pierce = false, radius = 10, directions = 2 },
        { damage = 2, fire_rate = 0.7, pierce = true, radius = 10, directions = 4 },
        { damage = 2, fire_rate = 0.9, pierce = true, radius = 10, directions = 6 },
        { damage = 4, fire_rate = 1.1, pierce = true, radius = 10, directions = 8 },
        { damage = 4, fire_rate = 1.5, pierce = true, radius = 10, directions = 10 },
        { damage = 6, fire_rate = 1.7, pierce = true, radius = 10, directions = 12 },
        { damage = 8, fire_rate = 2.0, pierce = true, radius = 10, directions = 14 },
        { damage = 10, fire_rate = 2.2, pierce = true, radius = 10, directions = 16 },
        { damage = 10, fire_rate = 2.4, pierce = true, radius = 10, directions = 18 },
        { damage = 10, fire_rate = 2.6, pierce = true, radius = 10, directions = 20 },
        { damage = 10, fire_rate = 2.8, pierce = true, radius = 10, directions = 22 },
        { damage = 10, fire_rate = 3.0, pierce = true, radius = 10, directions = 24 },
    },
    drones = {
        display_name = "Drones",
        -- Orbiting drones, auto-fire at enemies
        { count = 1, damage = 1, fire_rate = 2, range = 80, orbit_radius = 100, drone_radius = 15, orbit_speed = 0.6, engaged_orbit_speed = 0.3 }, -- Level 1
        { count = 2, damage = 1, fire_rate = 4, range = 100, orbit_radius = 120, drone_radius = 17, orbit_speed = 0.5, engaged_orbit_speed = 0.15 }, -- Level 2
        { count = 3, damage = 2, fire_rate = 6, range = 120, orbit_radius = 140, drone_radius = 20, orbit_speed = 0.4, engaged_orbit_speed = 0.1 }, -- Level 3
        { count = 4, damage = 2, fire_rate = 8, range = 140, orbit_radius = 160, drone_radius = 20, orbit_speed = 0.4, engaged_orbit_speed = 0.1 }, -- Level 4
        { count = 5, damage = 3, fire_rate = 10, range = 160, orbit_radius = 180, drone_radius = 20, orbit_speed = 0.4, engaged_orbit_speed = 0.1 }, -- Level 5
        { count = 6, damage = 3, fire_rate = 12, range = 180, orbit_radius = 200, drone_radius = 20, orbit_speed = 0.4, engaged_orbit_speed = 0.1 }, -- Level 6
        { count = 7, damage = 4, fire_rate = 14, range = 200, orbit_radius = 220, drone_radius = 20, orbit_speed = 0.4, engaged_orbit_speed = 0.1 }, -- Level 7
    },
    area = {
        display_name = "Shotgun",
        -- Shotgun-like, fires multiple projectiles in a spread
        { pellets = 2, damage = 3, spread = 10, fire_rate = 1, color = {1,0.5,0,1} }, -- Orange
        { pellets = 3, damage = 3, spread = 20, fire_rate = 1, color = {1,0.5,0,1} }, -- Orange
        { pellets = 4, damage = 4, spread = 30, fire_rate = 1.2, color = {1,0.5,0,1} }, -- Orange
        { pellets = 5, damage = 4, spread = 40, fire_rate = 1.2, color = {1,0.5,0,1} }, -- Orange
        { pellets = 6, damage = 5, spread = 50, fire_rate = 1.4, color = {1,0.5,0,1} }, -- Orange
        { pellets = 7, damage = 5, spread = 60, fire_rate = 1.6, color = {1,0.5,0,1} }, -- Orange
        { pellets = 8, damage = 6, spread = 70, fire_rate = 1.8, color = {1,0.5,0,1} }, -- Orange
        { pellets = 9, damage = 6, spread = 80, fire_rate = 2, color = {1,0.5,0,1} }, -- Orange
    },
}

settings.inventory = {
    max_slots = 4, -- Default slots, can be changed for upgrades
    allowed_categories = {"forward", "cross", "drones", "area"},
}

return settings
