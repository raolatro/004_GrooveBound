-- settings.lua: All designer-tunable variables
local settings = {
    main = {
        sfx = {
            volume = 0.8, -- global SFX volume (0-1)
            loot_enabled = true,
            weapon_enabled = true,
            projectile_enabled = true,
            dead_enabled = true,
        },
        scoring = {
            kill_point = 10,         -- points for normal kill
            groove_kill_point = 50, -- points for groove kill
        },
        auto_fire_angle = 0.3, -- radians, smaller = stricter auto-fire aim (default ~4.5 degrees)
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
        on_beat_scale = 1.2, -- global on-beat scale for all visuals
        -- On-beat circle animation (player outline) settings
        on_beat_scale_initial = 1.7,      -- scale at the start of on-beat animation
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
        speed = 25,
        hp = 5,
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
    enemy = {
        speed = 70,
        hp = 10,
        radius = 30,                -- radius of enemy (for drawing and collision)
        spawn_rate = 2.5,           -- seconds between spawns
        max_enemies = 10,            -- max enemies on screen
        flash_duration = 0.5,      -- seconds
    },
    popup = {
        enable_groove_popup = false,  -- toggle player groove popup
        text = "Groove punch!",
        color = {0,1,0,1}, -- default color
        font_size = 20,         -- font size in px for popup text
        stay_duration = 0.75,   -- seconds popup stays before fading
        fade_duration = 1,    -- seconds to fade out
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
        attraction_speed = 1200,   -- px/sec
        attraction_radius_mult = 15.0, -- chase starts at outline_radius * this
        pickup_radius_mult = 4, -- pickup area = outline_radius * this
    },
    weapon = {
        attraction_enabled = true,
        attraction_speed = 1200,
        attraction_radius_mult = 15.0,
    }
}

settings.waves = {
    { hp = 10, speed = 70, spawn_rate = 2.5, max_enemies = 8 }, -- Wave 1
    { hp = 10, speed = 80, spawn_rate = 2.2, max_enemies = 10 }, -- Wave 2
    { hp = 10, speed = 90, spawn_rate = 2.0, max_enemies = 13 }, -- Wave 3
    { hp = 10, speed = 100, spawn_rate = 1.8, max_enemies = 16 } -- Wave 4
    -- Add more for easy tuning
}
settings.boss = {
    hp = { 20, 50, 100, 150 }, -- Boss HP per boss number
    speed = { 100, 120, 140, 160 },
    radius = { 40, 60, 80, 100 },
    color = { {1,0.2,0.2,1}, {0.4,0,1,1}, {1,0.6,0,1}, {0,0.8,0.8,1} },
    sfx = { 'boss1', 'boss2', 'boss3', 'boss4' },
}
settings.wave_duration = 10
settings.boss_duration = 30

return settings
