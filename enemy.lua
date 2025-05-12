-- enemy.lua
-- Implementazione di un nemico che eredita da Entity

local Entity = require("entity")
local config = require("config")
local utils = require("utils")

-- Crea una classe Enemy che eredita da Entity
local Enemy = setmetatable({}, {__index = Entity})
Enemy.__index = Enemy

function Enemy:new(x, y)
    local instance = Entity.new(self, x, y, 32, 64)
    instance.is_enemy = true

    -- Stati
    instance.state = "idle"
    instance.previous_state = nil

    -- Movimento base (velocità aumentata del 25%)
    instance.speed = config.PLAYER_SPEED
    instance.direction = 1 -- 1 = destra, -1 = sinistra

    -- Carica le stesse animazioni del player
    instance:load_enemy_animations()

    return instance
end

function Enemy:load_enemy_animations()
    local animations_data = {
        idle = {
            frames = utils.load_frames("assets/Slimes/SlimeGreen/SlimeBasic_0000%d.png", 9),
            duration = config.FRAME_DURATION,
            loop = true
        },
        jump = {
            frames = utils.load_frames("assets/Slimes/SlimeGreen/SlimeBasic_0000%d.png", 9),
            duration = config.FRAME_DURATION,
            loop = true
        },
        fall = {
            frames = utils.load_frames("assets/Slimes/SlimeGreen/SlimeBasic_0000%d.png", 9),
            duration = config.FRAME_DURATION,
            loop = true
        },
        run = {
            frames = utils.load_frames("assets/Slimes/SlimeGreen/SlimeBasic_0000%d.png", 9),
            duration = config.FRAME_DURATION,
            loop = true
        },
        attack = {
            frames = utils.load_frames("assets/Slimes/SlimeGreen/SlimeBasic_0000%d.png", 9),
            duration = config.FRAME_DURATION * config.ATTACK_SPEED_MULTIPLIER,
            loop = false
        },
        dash = {
            frames = utils.load_frames("assets/Slimes/SlimeGreen/SlimeBasic_0000%d.png", 9),
            duration = config.FRAME_DURATION,
            loop = false
        }
    }
    self:load_animations(animations_data)
    self.current_animation = "idle"
end

function Enemy:update(dt)
    -- Movimento base: cammina avanti e indietro
    local move_direction = self.direction

    -- Controllo bordo piattaforma: se non c'è piattaforma sotto il piede avanti, inverte direzione
    if not self.on_ground then
        move_direction = 0
    end
    if self.world and self.world.platforms and self.on_ground then
        local foot_x
        if self.direction > 0 then
            foot_x = self.x + self.width + self.speed * dt
        else
            foot_x = self.x - self.speed * dt
        end
        local foot_y = self.y + self.height + 1 -- appena sotto i piedi
        local on_platform = false
        for _, platform in ipairs(self.world.platforms) do
            if foot_x >= platform.x and foot_x <= platform.x + platform.w and
               foot_y >= platform.y and foot_y <= platform.y + platform.h then
                on_platform = true
                break
            end
        end
        if not on_platform then
            self.direction = -self.direction
            move_direction = self.direction
        end
    end

    self:check_horizontal_movement(dt, move_direction, self.speed)

    -- Applica gravità e aggiorna animazione
    Entity.update(self, dt)

    -- Aggiorna stato animazione
    if not self.on_ground then
        self.state = self.vy < 0 and "jump" or "fall"
    elseif math.abs(move_direction) > 0.2 then
        self.state = "run"
    else
        self.state = "idle"
    end
    self.current_animation = self.state
end

function Enemy:draw_animation()
    local anim = self.animations[self.current_animation]
    if not anim or not anim.frames[self.current_frame] then return end
    
    local sprite = anim.frames[self.current_frame]
    local spriteWidth = sprite:getWidth()
    local scaleX = self.facing_right and 1 or -1
    local offsetX = self.facing_right and 0 or spriteWidth * 0.1
    
    love.graphics.draw(
        sprite, 
        self.x + offsetX, 
        self.y + 40, 
        0, 
        scaleX * 0.1, 
        0.1
    )
end

return Enemy