-- settings.lua
-- Ensure item data is always loaded for inventory operations
local item_data = require "data/items"

local settings = {
    main = {
        sfx = {
            volume = 0.25, -- global SFX volume (0-1)
            weapons_volume = 2, -- weapon sounds relative volume (multiplied by global volume)
            loot_enabled = true,
            weapon_enabled = true,
            projectile_enabled = true,
            dead_enabled = true,
        },
        scoring = {
            kill_point = 10,         -- points for normal kill
            groove_kill_point = 50, -- points for groove kill
        },
        auto_fire_angle = 0.25, -- radians, smaller = stricter auto-fire aim (default ~4.5 degrees)
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

    floor = {
        image_path = "assets/img/floor-tiles1.jpg",
        tile_size = 128,
        tile_grid_width = 4,   -- number of tiles horizontally in the tileset
        tile_grid_height = 2,  -- number of tiles vertically in the tileset
        tile_weights = {3, 1, 1, 1, 1, 1, 1, 1},
        arena_margin = 32
    },

    -- Enemy 1 sprite and animation settings
    enemy1 = {
        walk_sprite = "assets/img/enemy1/walk/enemy1_walk.png", -- Walk animation sprite sheet
        walk_grid = {cols = 6, rows = 4}, -- 6 frames per direction, 4 directions
        walk_frame_size = {w = 64, h = 64},
        walk_fps = 16, -- Default fast animation speed (frames per second)
        death_sprite = "assets/img/enemy1/death/enemy1_death.png", -- Death animation sprite sheet
        death_grid = {cols = 11, rows = 4}, -- 11 frames per direction, 4 directions
        death_frame_size = {w = 64, h = 64},
        death_fps = 16, -- Death animation speed (frames per second)
        directions = {down = 1, up = 2, left = 3, right = 4},
    },

    -- Player 1 sprite and animation settings (modular, scalable)
    player1 = {
        states = {
            idle = {
                sprite = "assets/img/player1/armed_idle/player1-armed_idle.png",
                shadow = "assets/img/player1/armed_idle/shadow.png",
                grid = {cols = 4, rows = 4}, -- 6 frames per direction, 4 directions
                frame_size = {w = 64, h = 64},
                fps = 10,
            },
            run = {
                sprite = "assets/img/player1/armed_run/player1-armed_run.png",
                shadow = "assets/img/player1/armed_run/shadow.png",
                grid = {cols = 8, rows = 4},
                frame_size = {w = 64, h = 64},
                fps = 16,
            },
            attack = {
                -- TODO: Replace with real attack sprite and shadow if available
                sprite = "assets/img/player1/armed_run/player1-armed_run.png",
                shadow = "assets/img/player1/armed_run/shadow.png",
                grid = {cols = 6, rows = 4},
                frame_size = {w = 64, h = 64},
                fps = 18,
            },
            death = {
                sprite = "assets/img/player1/armed_death/player1-armed_death.png",
                shadow = "assets/img/player1/armed_death/shadow.png",
                grid = {cols = 11, rows = 4}, -- 11 frames per direction, 4 directions
                frame_size = {w = 64, h = 64},
                fps = 16,
            },
        },
        directions = {down = 1, up = 2, left = 3, right = 4},
        default_state = "idle"
    },

    player = {
        speed = 8,
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
        y_offset = -25,         -- pixels above enemy center
        box = false,
        box_color = {0,0,0,0.7},
        
        -- XP popup settings
        xp_text = "+%d XP",    -- XP popup text format (will be formatted with amount)
        xp_color = {0.4, 0.6, 1, 1}, -- blue color for XP popups
        box_padding = 8,
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
        y_offset = -7,          -- pixels above enemy center (if needed for bar positioning)
    },
    -- Load item drop settings
    item_data = require "data/items",
    
    -- Power-up system settings
    powerups = {
        -- Configuration for the power-up system
        level_up_count = 3,        -- Number of options presented in level-up menu
        shop_count = 4,            -- Number of options presented in shop menu
        always_include_ultimate = true, -- Always include ultimate upgrade in post-boss shop
        
        -- Rarity weights for level-up menu
        level_up_weights = {
            common = 10,
            uncommon = 8,
            rare = 5,
            epic = 3,
            legendary = 1,
            extremely_legendary = 0, -- Never in level-up menu
        },
        
        -- Rarity weights for shop menu (higher = more likely)
        shop_weights = {
            common = 1,
            uncommon = 2,
            rare = 3,
            epic = 4,
            legendary = 5,
            extremely_legendary = 10, -- Special handling for extremely legendary
        },
        
        -- Rarity colors for UI
        colors = {
            common = {0.7, 0.7, 0.7, 1},       -- Gray
            uncommon = {0.0, 0.7, 0.0, 1},     -- Green
            rare = {0.0, 0.4, 0.9, 1},         -- Blue
            epic = {0.7, 0.2, 0.9, 1},         -- Purple
            legendary = {1.0, 0.6, 0.0, 1},    -- Orange
            extremely_legendary = {1.0, 0.1, 0.1, 1}, -- Red
        },
    },
    loot = {
        attraction_enabled = true, -- coins chase player
        attraction_speed = 500,   -- px/sec
        attraction_radius_mult = 70, -- chase starts at outline_radius * this
        pickup_radius_mult = 0.8, -- now matches beat_checker_base_radius (which is 64px)
        show_pickup_radius = true, -- toggle visibility of pickup radius
        
        -- Multiple loot drop settings
        min_drops = 1,       -- Minimum number of loot items per kill
        max_drops = 5,       -- Maximum number of loot items per kill (cap)
        boss_min_drops = 3,  -- Minimum number of loot items per boss kill
        boss_max_drops = 12, -- Maximum number of loot items per boss kill
        
        -- Wave scaling settings
        wave_scaling = 0.5,  -- How much to increase loot per wave (0.5 = +50% per 10 waves)
        groove_bonus = 1,    -- Extra loot for killing with groove/on-beat
    },
    weapon = {
        attraction_enabled = true,
        attraction_speed = 500, -- px/sec
        attraction_radius_mult = 70, -- chase starts at outline_radius * this
        pickup_radius_mult = 0.8, -- now matches beat_checker_base_radius (which is 64px)
    },
    
    -- XP system settings
    xp = {
        color = {0.4, 0.6, 1, 1}, -- Blue color for XP bar
        empty_color = {0.5, 0.5, 0.5, 0.8}, -- Gray color for empty XP bar
        bar_height = 10, -- Height of XP progress bar
        text_offset = 5, -- Space between bar and text
        
        -- Level thresholds (total XP needed to reach each level)
        difficulty = 1,
        levels = {
            {level = 1, threshold = 0}, -- Starting level
            {level = 2, threshold = 100}, 
            {level = 3, threshold = 300}, 
            {level = 4, threshold = 600}, 
            {level = 5, threshold = 1000},
            {level = 6, threshold = 1500},
            {level = 7, threshold = 2100},
            {level = 8, threshold = 2800}, 
            {level = 9, threshold = 4000}, 
            {level = 10, threshold = 6000},
            {level = 11, threshold = 8500},
            {level = 12, threshold = 11000},
            {level = 13, threshold = 13500},
            {level = 14, threshold = 16000},
            {level = 15, threshold = 18500},
            {level = 16, threshold = 21000},
            {level = 17, threshold = 23500},
            {level = 18, threshold = 26000},
            {level = 19, threshold = 28500},
            {level = 20, threshold = 31000},
            {level = 21, threshold = 33500},
            {level = 22, threshold = 36000},
            {level = 23, threshold = 38500},
            {level = 24, threshold = 41000},
            {level = 25, threshold = 43500},
            {level = 26, threshold = 46000},
            {level = 27, threshold = 48500},
            {level = 28, threshold = 51000},
            {level = 29, threshold = 53500},
            {level = 30, threshold = 56000},
        }
    }
}

-- Attach item data to settings for global access
-- Expose both Items and LootTypes for compatibility with inventory and loot systems
settings.item_data = {
    Items = item_data,
    LootTypes = require("data/items").LootTypes,
    Rarity = require("data/items").Rarity
}

-- Loot drop settings
settings.loot = {
    -- Base drop rates and settings
    min_drops = 1,               -- Minimum number of drops for regular enemies
    max_drops = 3,               -- Maximum number of drops for regular enemies
    boss_min_drops = 5,          -- Minimum number of drops for bosses
    boss_max_drops = 10,         -- Maximum number of drops for bosses
    groove_bonus = 1,            -- Extra drops for groove/rhythm kills
    wave_scaling = 0.15,         -- +15% per 10 waves by default (multiply by wave/10)
    
    -- Wave-based loot scaling parameters
    wave_value_scaling = 0.1,    -- Increase drop value by 10% per wave
    wave_drop_scaling = 0.05,    -- Increase drop count by 5% per wave
    
    -- Value scaling for different enemy types
    boss_value_multiplier = 2.0, -- Bosses drop items worth 2x more
    groove_value_multiplier = 1.5 -- Groove kills drop items worth 1.5x more
}

settings.waves = {
    { hp = 10, speed = 70, spawn_rate = 2.5, max_enemies = 8 }, -- Wave 1
    { hp = 12, speed = 70, spawn_rate = 2.3, max_enemies = 10 }, -- Wave 2
    { hp = 15, speed = 70, spawn_rate = 2.1, max_enemies = 12 }, -- Wave 3
    { hp = 20, speed = 70, spawn_rate = 1.9, max_enemies = 15 }, -- Wave 4
    { hp = 25, speed = 70, spawn_rate = 1.7, max_enemies = 20 }, -- Wave 5
    { hp = 30, speed = 70, spawn_rate = 1.5, max_enemies = 25 }, -- Wave 6
    { hp = 30, speed = 70, spawn_rate = 1.3, max_enemies = 30 }, -- Wave 7
    { hp = 30, speed = 70, spawn_rate = 1.1, max_enemies = 35 }, -- Wave 8
    { hp = 30, speed = 70, spawn_rate = 0.9, max_enemies = 45 }, -- Wave 9
    { hp = 30, speed = 70, spawn_rate = 0.7, max_enemies = 50 }, -- Wave 10
    { hp = 30, speed = 70, spawn_rate = 0.6, max_enemies = 55 }, -- Wave 11
    { hp = 30, speed = 70, spawn_rate = 0.5, max_enemies = 60 }, -- Wave 12
    { hp = 30, speed = 70, spawn_rate = 0.4, max_enemies = 65 }, -- Wave 13
    -- Add more for easy tuning
}
settings.boss = {
    -- Steady linear HP increase instead of exponential
    hp = { 50, 100, 150, 200, 250, 300, 350, 400, 450, 500 }, -- Boss HP for 10 bosses
    -- Speed increases gradually for all 10 bosses
    speed = { 100, 110, 120, 130, 140, 150, 160, 170, 180, 190 },
    -- Radius increases gradually for all 10 bosses
    radius = { 40, 45, 50, 55, 60, 65, 70, 75, 80, 85 },
    -- 10 unique colors for each boss
    color = {
        {1.0, 0.2, 0.2, 1.0}, -- Red (Boss 1)
        {0.4, 0.0, 1.0, 1.0}, -- Purple (Boss 2)
        {1.0, 0.6, 0.0, 1.0}, -- Orange (Boss 3)
        {0.0, 0.8, 0.8, 1.0}, -- Cyan (Boss 4)
        {0.2, 0.2, 1.0, 1.0}, -- Blue (Boss 5)
        {0.0, 0.8, 0.2, 1.0}, -- Green (Boss 6)
        {1.0, 0.8, 0.0, 1.0}, -- Gold (Boss 7)
        {0.8, 0.0, 0.6, 1.0}, -- Magenta (Boss 8)
        {0.5, 0.5, 0.5, 1.0}, -- Silver (Boss 9)
        {0.9, 0.1, 0.5, 1.0}, -- Pink (Boss 10)
    },
    -- 10 sound effects, one for each boss
    sfx = { 'boss1', 'boss2', 'boss3', 'boss4', 'boss5', 'boss6', 'boss7', 'boss8', 'boss9', 'boss10' },
}
settings.wave_duration = 15
settings.boss_duration = 45

-- Weapon categories and levels
settings.weapons = {
    forward = {
        display_name = "Pistol",
        projectile_image = "assets/img/projectile1.png",
        color = {1, 1, 1, 1}, -- White for pistol/forward gun
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
        color = {0, 1, 0, 1}, -- Green for cross/blaster
        -- Fires in 4 or more directions
        { damage = 1, fire_rate = 0.5, pierce = false, radius = 10, directions = 2 },
        { damage = 2, fire_rate = 0.7, pierce = true, radius = 10, directions = 4 },
        { damage = 3, fire_rate = 0.9, pierce = true, radius = 10, directions = 6 },
        { damage = 4, fire_rate = 1.1, pierce = true, radius = 10, directions = 8 },
        { damage = 5, fire_rate = 1.5, pierce = true, radius = 10, directions = 10 },
        { damage = 6, fire_rate = 1.7, pierce = true, radius = 10, directions = 12 },
        { damage = 7, fire_rate = 2.0, pierce = true, radius = 10, directions = 14 },
        { damage = 8, fire_rate = 2.2, pierce = true, radius = 10, directions = 16 },
        { damage = 9, fire_rate = 2.4, pierce = true, radius = 10, directions = 18 },
        { damage = 10, fire_rate = 2.6, pierce = true, radius = 10, directions = 20 },
        { damage = 10, fire_rate = 2.8, pierce = true, radius = 10, directions = 22 },
        { damage = 10, fire_rate = 3.0, pierce = true, radius = 10, directions = 24 },
    },
    drones = {
        display_name = "Drones",
        color = {0, 1, 1, 1}, -- Cyan for drones
        -- Sprite settings for drones
        sprite_path = "assets/img/drone1-sprite.png",
        sprite_frames = 4,        -- Total frames in spritesheet
        sprite_rows = 2,          -- Number of rows in spritesheet
        sprite_cols = 2,          -- Number of columns in spritesheet
        sprite_frame_width = 64,  -- Width of each frame
        sprite_frame_height = 64, -- Height of each frame
        sprite_anim_speed = 8,    -- Frames per second for animation
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
        color = {1, 0.5, 0, 1}, -- Orange for shotgun/area weapon
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
