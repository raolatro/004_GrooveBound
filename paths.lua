-- paths.lua: Centralized path definitions for all assets, scripts, and future files
local paths = {
    -- Fixed (core) paths
    scripts = {
        player = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/scripts/player.lua",
        enemy = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/scripts/enemy.lua",
        weapon = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/scripts/weapon.lua",
        beat = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/scripts/beat.lua",
        debug = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/scripts/debug.lua",
        camera = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/scripts/camera.lua",
        gamepad = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/scripts/gamepad.lua",
        collision = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/scripts/collision.lua",
    },
    assets = {
        img = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/assets/img/",
        sfx = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/assets/sfx/",
        music = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/assets/music/",
    },
    settings = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/settings.lua",
    conf = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/conf.lua",
    main = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/main.lua",
    -- Variable/future paths (add as needed)
    saves = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/saves/",
    localization = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/localization/",
    shaders = "/Users/raonilima/raolatro/GAMES/004_GrooveBound/shaders/",
    -- Add more as your project grows
}
return paths
