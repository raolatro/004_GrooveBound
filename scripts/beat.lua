-- scripts/beat.lua: Handles beat timing and events
local paths = require "paths"
local paths = require "paths"
local settings = require "settings"
local beat = {}

beat.beat_length = 60 / settings.main.bpm
beat.current_beat_step = 0
beat.timer = 0
beat.listeners = {}

function beat.update(dt)
    beat.timer = beat.timer + dt
    local subdivision_time = beat.beat_length / settings.main.beat_subdivisions
    while beat.timer >= subdivision_time do
        beat.timer = beat.timer - subdivision_time
        beat.current_beat_step = (beat.current_beat_step + 1) % settings.main.beat_subdivisions
        for _, fn in ipairs(beat.listeners) do fn(beat.current_beat_step) end
        if beat.current_beat_step == 0 then
            print("Beat: " .. os.time())
        end
    end
end

function beat.on_beat(fn)
    table.insert(beat.listeners, fn)
end

return beat
