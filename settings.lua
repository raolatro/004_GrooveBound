-- settings.lua: All designer-tunable variables
local settings = {
    main = {
        window_width = 1920,
        window_height = 1080,
        bpm = 60,
        beat_subdivisions = 4,
        camera_delay = 0.5,         -- seconds
        -- Beat checker (rhythm aim) settings
        beat_checker_scale_initial = 2.5, -- scale at the start of pulse
        beat_checker_scale_final = 1.0,   -- scale at the end of pulse
        beat_checker_ease = 0.25,         -- how quickly it shrinks to normal (seconds)
        beat_checker_pulse_duration = 0.4, -- seconds for a full pulse
        -- On-beat circle animation (player outline) settings
        on_beat_scale_initial = 1.7,      -- scale at the start of on-beat animation
        on_beat_scale_final = 1.0,        -- scale at the end of on-beat animation
        on_beat_ease = 0.18,              -- how quickly it animates
        beat_flash = 0.25,                -- seconds to flash outline on beat
    },

    player = {
        speed = 7,
        hp = 3,
    },
    projectile = {
        -- Damage values for different projectile types (scalable for future weapons)
        normal_damage = 1,
        on_beat_damage = 5,
        range = 500,                -- how far the projectile can travel (pixels)
        speed = 500,                -- speed of the projectile (pixels/sec)
        fire_rate = 0.1,           -- seconds between shots
        on_beat_color = {0,1,0,1},  -- RGBA for on-beat projectile
        on_beat_scale = 2,        -- scale for on-beat projectile
        normal_color = {1,1,1,1},   -- RGBA for normal projectile
        normal_scale = 0.7,         -- scale for normal projectile
    },
    enemy = {
        speed = 20,
        hp = 5,
        radius = 20,                -- radius of enemy (for drawing and collision)
        spawn_rate = 3.0,           -- seconds between spawns
        max_enemies = 6,            -- max enemies on screen
        flash_duration = 0.15,      -- seconds
    },
    popup = {
        text = "Groove punch!",
        color = {0,1,0,1}, -- default color
        font_size = 28,         -- font size in px for popup text
        stay_duration = 0.65,   -- seconds popup stays before fading
        fade_duration = 0.7,    -- seconds to fade out
        y_offset = 40,
        box = false,
        box_color = {0,0,0,0.7},
        box_padding = 16,
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
}

return settings
