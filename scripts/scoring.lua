-- scripts/scoring.lua: Handles all scoring logic for GrooveBound
local settings = require "settings"
local settings_menu = require "scripts/settings_menu"

local scoring = {}

function scoring.add_kill(is_groove)
    settings_menu.kills = (settings_menu.kills or 0) + 1
    local pts = settings.main.scoring and (is_groove and settings.main.scoring.groove_kill_point or settings.main.scoring.kill_point) or (is_groove and 2 or 1)
    settings_menu.score = (settings_menu.score or 0) + pts
end

return scoring
