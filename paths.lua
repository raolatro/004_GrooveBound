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
        img = "assets/img/",
        hp = "assets/img/hp.png",
        sfx = "assets/sfx/",
        music = "assets/music/",
    },
    settings = "settings.lua",
    conf = "conf.lua",
    main = "main.lua",
    -- Variable/future paths (add as needed)
    saves = "saves/",
    localization = "localization/",
    shaders = "shaders/", 
    -- Add more as your project grows
}
return paths
