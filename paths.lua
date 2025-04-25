-- paths.lua: Centralized path definitions for all assets, scripts, and future files
local paths = {
    -- Fixed (core) paths
    scripts = {
        player = "scripts/player.lua",
        enemy = "scripts/enemy.lua",
        weapon = "scripts/weapon.lua",
        beat = "scripts/beat.lua",
        debug = "scripts/debug.lua",
        camera = "scripts/camera.lua",
        gamepad = "scripts/gamepad.lua",
        collision = "scripts/collision.lua",
    },
    assets = {
        sfx = {
            base_path = "assets/sfx/",
            coin = {
                "assets/sfx/coin1.ogg",
                "assets/sfx/coin2.ogg",
                "assets/sfx/coin3.ogg",
                "assets/sfx/coin4.ogg",
                "assets/sfx/coin5.ogg",
                "assets/sfx/coin6.ogg",
                "assets/sfx/coin7.ogg",
            },
            projectile = {
                "assets/sfx/projectile1.ogg",
                "assets/sfx/projectile2.ogg",
                "assets/sfx/projectile3.ogg",
            },
            dead = {
                "assets/sfx/dead1.ogg",
                "assets/sfx/dead2.ogg",
                "assets/sfx/dead3.ogg",
                "assets/sfx/dead4.ogg",
            },
            -- New weapon sounds
            weapon_picked = {
                -- forward = "assets/sfx/weapon-pistol1-picked.ogg", -- Pistol (placeholder)
                cross = "assets/sfx/weapon-cross1-picked.ogg",    -- Blaster
                area = "assets/sfx/weapon-heavy1-picked.ogg",     -- Shotgun
                drones = "assets/sfx/weapon-drones1-picked.ogg",  -- Drones
            },
            weapon_levelup = {
                forward = "assets/sfx/weapon-pistol1-levelup.ogg", -- Pistol
                cross = "assets/sfx/weapon-cross1-levelup.ogg",  -- Blaster
                area = "assets/sfx/weapon-heavy1-levelup.ogg",     -- Shotgun
                drones = "assets/sfx/weapon-drones1-levelup.ogg",  -- Drones
            },
            levelup = "assets/sfx/levelup.ogg"
        },
        img = "assets/img/",
        hp = "assets/img/hp.png",
        music = "assets/music/"
    }
}
return paths
