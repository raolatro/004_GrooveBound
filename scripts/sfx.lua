-- sfx.lua: Handles all sound effects loading and playback
-- Loads all SFX listed in paths and provides randomization for variations
local paths = require "paths"
local settings = require "settings"
local sfx = {}

local function load_sounds(tbl)
    if type(tbl) == "string" then
        return { love.audio.newSource(tbl, "static") }
    elseif type(tbl) == "table" then
        local arr = {}
        for _, v in ipairs(tbl) do
            table.insert(arr, love.audio.newSource(v, "static"))
        end
        return arr
    end
end

local sfx_paths = paths.assets.sfx
sfx.coin = load_sounds(sfx_paths.coin)
sfx.weapon = load_sounds(sfx_paths.weapon)
sfx.projectile = load_sounds(sfx_paths.projectile)
sfx.dead = load_sounds(sfx_paths.dead)

-- Play a random sound from a group
function sfx.play(group)
    local group_tbl = sfx[group]
    if not group_tbl then return end
    local enabled = settings.main.sfx[group.."_enabled"]
    if enabled == false then return end
    local vol = settings.main.sfx.volume or 1
    if #group_tbl > 0 then
        local idx = math.random(1, #group_tbl)
        group_tbl[idx]:setVolume(vol)
        group_tbl[idx]:stop()
        group_tbl[idx]:play()
    end
end

return sfx
