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
            coin = {
                "assets/sfx/coin1.ogg",
                "assets/sfx/coin2.ogg",
                "assets/sfx/coin3.ogg",
                "assets/sfx/coin4.ogg",
                "assets/sfx/coin5.ogg",
                "assets/sfx/coin6.ogg",
                "assets/sfx/coin7.ogg",
            },
            weapon = "assets/sfx/weapon.ogg",
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
            }
        },
        img = "assets/img/",
        hp = "assets/img/hp.png",
        music = "assets/music/"
    }
}
return paths
