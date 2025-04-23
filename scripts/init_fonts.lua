-- init_fonts.lua: Ensure all HUD/game fonts are loaded at game start
local hud = require "scripts/hud"
local level_stats = require "scripts/level_stats"
local settings = require "settings"

return function()
    hud.load_fonts()
    level_stats.load_font(settings.main.fonts.path, settings.main.fonts.body)
end
