-- settings.lua: All designer-tunable variables
local settings = {
    main = {
        window_width = 1920,
        window_height = 1080,
        bpm = 32,
        beat_subdivisions = 4,
        camera_delay = 0.5,         -- seconds
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
    },

    player = {
        speed = 15,
        hp = 3,
    },
    projectile = {
        -- Damage values for different projectile types (scalable for future weapons)
        normal_damage = 1,
        on_beat_damage = 5,
        range = 800,                -- how far the projectile can travel (pixels)
        speed = 500,                -- speed of the projectile (pixels/sec)
        fire_rate = 0.2,           -- seconds between shots
        -- on_beat_color and on_beat_scale are now set globally in settings.main
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
}

return settings
