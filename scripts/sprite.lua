-- sprite.lua: Generic, scalable sprite and animation system for GrooveBound
-- Supports multiple entities, animation states, and frame timing
-- Usage: local sprite = require "scripts/sprite"; local spr = sprite.new(...)

local sprite = {}
sprite.__index = sprite

-- Sprite sheet loader and animator
function sprite.new(args)
    -- args: {image_path, frame_w, frame_h, states = {state={frames, fps, row}}, anchor = {x, y}}
    local self = setmetatable({}, sprite)
    self.image = love.graphics.newImage(args.image_path)
    self.frame_w = args.frame_w
    self.frame_h = args.frame_h
    self.states = args.states or {}
    self.anchor = args.anchor or {x=0.5, y=1.0}
    self.state = args.default_state or "idle"
    self.frame = 1
    self.timer = 0
    self.fps = (self.states[self.state] and self.states[self.state].fps) or 4
    self.row = (self.states[self.state] and self.states[self.state].row) or 1
    self.frames = (self.states[self.state] and self.states[self.state].frames) or 1
    self.playing = true
    self.flip = false
    return self
end

function sprite:set_state(state)
    if self.state ~= state then
        self.state = state
        self.frame = 1
        self.timer = 0
        self.fps = (self.states[state] and self.states[state].fps) or 4
        self.row = (self.states[state] and self.states[state].row) or 1
        self.frames = (self.states[state] and self.states[state].frames) or 1
    end
end

function sprite:update(dt)
    if not self.playing then return end
    self.timer = self.timer + dt
    local spf = 1/(self.fps or 4)
    if self.timer >= spf then
        self.timer = self.timer - spf
        self.frame = self.frame + 1
        if self.frame > self.frames then self.frame = 1 end
    end
end

-- Draws the sprite at (x, y) with optional scale, rotation (radians), and color (table)
function sprite:draw(x, y, scale, rotation, color)
    scale = scale or 1
    rotation = rotation or 0
    color = color or {1,1,1,1}
    local quad = love.graphics.newQuad(
        (self.frame-1)*self.frame_w,
        (self.row-1)*self.frame_h,
        self.frame_w, self.frame_h,
        self.image:getDimensions()
    )
    love.graphics.setColor(color)
    love.graphics.draw(
        self.image, quad,
        x, y,
        rotation,
        scale * (self.flip and -1 or 1), scale,
        self.frame_w * self.anchor.x,
        self.frame_h * self.anchor.y
    )
    love.graphics.setColor(1,1,1,1)
end

return sprite
