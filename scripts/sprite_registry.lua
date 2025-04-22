-- sprite_registry.lua: Central place to register all game sprites and their animation states
-- Add new sprites here for easy management and scalability

local sprite = require "scripts/sprite"

local registry = {}

-- Main player sprite (man1)
registry.player = sprite.new({
    image_path = "assets/img/man1-sprite.png",
    frame_w = 64,
    frame_h = 128,
    anchor = {x=0.5, y=0.5}, -- center anchor for true centering
    default_state = "idle",
    states = {
        walk = {frames=4, fps=8, row=1}, -- top row (1-based), 4 frames
        idle = {frames=2, fps=2, row=2}, -- bottom row, first 2 frames
    },
})

return registry
