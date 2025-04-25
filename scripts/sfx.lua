-- sfx.lua: Enhanced sound effects system with weapon-specific sounds
-- Supports both random sound groups and specific event/category sounds
local paths = require "paths"
local settings = require "settings"
local debug = require "scripts/debug"

local sfx = {}
sfx.sounds = {}

-- Load either a single sound or an array of sounds
local function load_sound(path)
    if type(path) == "string" then
        return love.audio.newSource(path, "static")
    end
    return nil
end

-- Load a collection of sounds (array or table with category keys)
local function load_sounds(tbl)
    if type(tbl) == "string" then
        -- Single string path
        return { load_sound(tbl) }
    elseif type(tbl) == "table" then
        -- Check if it's an array or category map
        if #tbl > 0 then 
            -- Array of sounds for random selection
            local arr = {}
            for _, v in ipairs(tbl) do
                local sound = load_sound(v)
                if sound then table.insert(arr, sound) end
            end
            return arr
        else
            -- Category map (like weapon_picked[category])
            local map = {}
            for k, v in pairs(tbl) do
                if type(v) == "string" then
                    map[k] = load_sound(v)
                end
            end
            return map
        end
    end
    return {}
end

-- Load all sounds from paths
function sfx.init()
    local sfx_paths = paths.assets.sfx
    
    -- Load regular random sound groups
    sfx.sounds.coin = load_sounds(sfx_paths.coin)
    sfx.sounds.projectile = load_sounds(sfx_paths.projectile)
    sfx.sounds.dead = load_sounds(sfx_paths.dead)
    
    -- Load weapon category sounds
    sfx.sounds.weapon_picked = load_sounds(sfx_paths.weapon_picked)
    sfx.sounds.weapon_levelup = load_sounds(sfx_paths.weapon_levelup)
    
    -- Load individual sounds
    if sfx_paths.levelup then
        sfx.sounds.levelup = load_sound(sfx_paths.levelup)
    end
    
    debug.log("SFX: Sound system initialized")
end

-- Play a random sound from a group or specific category sound
-- Usage examples:
--   sfx.play("coin") - plays random coin sound
--   sfx.play("weapon_picked", "cross") - plays blaster pickup sound
function sfx.play(group, category)
    -- Handle volume - adjust for weapon-specific sounds
    local vol = settings.main.sfx.volume or 1
    
    -- Apply weapon-specific volume multiplier for weapon sounds
    if group == "weapon_picked" or group == "weapon_levelup" then
        local weapons_vol_mult = settings.main.sfx.weapons_volume or 1
        vol = vol * weapons_vol_mult
    end
    
    -- Check if enabled
    local enabled = settings.main.sfx[group.."_enabled"]
    
    -- Skip if explicitly disabled
    if enabled == false then return end
    
    -- Get the sound collection
    local sound_collection = sfx.sounds[group]
    if not sound_collection then 
        debug.log("SFX: Unknown sound group: " .. tostring(group))
        return 
    end
    
    -- Handle category-specific sounds
    if category and type(sound_collection) == "table" and not (#sound_collection > 0) then
        -- It's a category map
        local source = sound_collection[category]
        if source then
            source:setVolume(vol)
            source:stop() -- Stop any previous instance
            source:play()
            return
        else
            debug.log("SFX: Missing category sound: " .. group .. "[" .. category .. "]")
        end
    elseif type(sound_collection) == "userdata" then
        -- Single sound source
        sound_collection:setVolume(vol)
        sound_collection:stop()
        sound_collection:play()
    elseif #sound_collection > 0 then
        -- Random from array
        local idx = math.random(1, #sound_collection)
        sound_collection[idx]:setVolume(vol)
        sound_collection[idx]:stop()
        sound_collection[idx]:play()
    end
end

-- Initialize on require
sfx.init()

return sfx
