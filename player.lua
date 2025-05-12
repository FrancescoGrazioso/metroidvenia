-- player.lua
-- Implementazione del giocatore che eredita da Entity

local Entity = require("entity")
local config = require("config")
local utils = require("utils")

-- Crea una classe Player che eredita da Entity
local Player = setmetatable({}, {__index = Entity})
Player.__index = Player

function Player:new(x, y)
    -- Chiama il costruttore della classe base
    local instance = Entity.new(self, x, y, 32, 64)
    
    -- Identifica questa entità come il giocatore
    instance.is_player = true
    
    -- Proprietà specifiche del giocatore
    instance.speed = config.PLAYER_SPEED
    instance.max_jumps = config.MAX_JUMPS
    instance.jumps_left = instance.max_jumps
    
    -- Stati
    instance.state = "idle"
    instance.previous_state = nil
    
    -- Attacco
    instance.is_attacking = false
    instance.attack_timer = 0
    
    -- Dash
    instance.is_dashing = false
    instance.dash_timer = 0
    instance.dash_duration = config.DASH_DURATION
    instance.dash_speed = config.DASH_SPEED
    instance.dash_cooldown = config.DASH_COOLDOWN
    instance.dash_cooldown_timer = 0
    
    -- Input
    instance.joystick = love.joystick.getJoysticks()[1]
    
    -- Carica animazioni
    instance:load_player_animations()
    
    return instance
end

function Player:load_player_animations()
    local animations_data = {
        idle = {
            frames = utils.load_frames("assets/Warrior/Individual_Sprite/idle/Warrior_Idle_%d.png", 6),
            duration = config.FRAME_DURATION,
            loop = true
        },
        jump = {
            frames = utils.load_frames("assets/Warrior/Individual_Sprite/Jump/Warrior_Jump_%d.png", 3),
            duration = config.FRAME_DURATION,
            loop = true
        },
        fall = {
            frames = utils.load_frames("assets/Warrior/Individual_Sprite/Fall/Warrior_Fall_%d.png", 3),
            duration = config.FRAME_DURATION,
            loop = true
        },
        run = {
            frames = utils.load_frames("assets/Warrior/Individual_Sprite/Run/Warrior_Run_%d.png", 8),
            duration = config.FRAME_DURATION,
            loop = true
        },
        attack = {
            frames = utils.load_frames("assets/Warrior/Individual_Sprite/Attack/Warrior_Attack_%d.png", 11),
            duration = config.FRAME_DURATION * config.ATTACK_SPEED_MULTIPLIER,
            loop = false
        },
        dash = {
            frames = utils.load_frames("assets/Warrior/Individual_Sprite/Dash/Warrior_Dash_%d.png", 7),
            duration = config.FRAME_DURATION,
            loop = false
        }
    }
    
    self:load_animations(animations_data)
    self.current_animation = "idle"
end

function Player:update(dt)
    -- Aggiorna timer cooldown dash
    if self.dash_cooldown_timer > 0 then
        self.dash_cooldown_timer = self.dash_cooldown_timer - dt
    end
    
    -- Gestione stati speciali
    if self.is_dashing then
        self:handle_dash_state(dt)
    elseif self.is_attacking then
        self:handle_attack_state(dt)
    else
        -- Gestione input normale
        local move_direction = self:get_movement_input()
        self:check_horizontal_movement(dt, move_direction, self.speed)
        
        -- Applica gravità (ereditato da Entity)
        Entity.update(self, dt)
        
        -- Aggiorna stato in base alla situazione
        self:update_state(move_direction)
    end
    
    -- Aggiorna animazione corrente in base allo stato
    self.current_animation = self.state
    
    -- Aggiorna animazione (ereditato da Entity)
    self:update_animation(dt)
end

function Player:handle_dash_state(dt)
    self.state = "dash"
    self.dash_timer = self.dash_timer + dt
    
    -- Movimento dash
    local direction = utils.direction_factor(self.facing_right)
    self.x = self.x + direction * self.dash_speed * dt
    
    -- Fine dash
    if self.dash_timer >= self.dash_duration then
        self.is_dashing = false
        self.dash_timer = 0
        
        -- Transizione dopo il dash
        if not self.on_ground then
            self.state = self.vy < 0 and "jump" or "fall"
        else
            self.state = math.abs(self.vx or 0) > 0.2 and "run" or "idle"
        end
    end
end

function Player:handle_attack_state(dt)
    self.state = "attack"
    self.attack_timer = self.attack_timer + dt
    
    -- Durata totale dell'attacco
    local attack_duration = #self.animations.attack.frames * self.animations.attack.duration
    
    -- Fine attacco
    if self.attack_timer >= attack_duration then
        self.is_attacking = false
        self.attack_timer = 0
        
        -- Transizione dopo l'attacco
        if not self.on_ground then
            self.state = self.vy < 0 and "jump" or "fall"
        else
            local moving = math.abs(self:get_movement_input()) > 0.2
            self.state = moving and "run" or "idle"
        end
    end
end

function Player:update_state(move_direction)
    -- Determinazione dello stato normale
    if not self.on_ground then
        self.state = self.vy < 0 and "jump" or "fall"
    elseif math.abs(move_direction) > 0.2 then
        self.state = "run"
    else
        self.state = "idle"
    end
end

function Player:get_movement_input()
    local move_input = 0
    
    -- Tastiera
    if love.keyboard.isDown("left") then 
        move_input = move_input - 1 
    end
    if love.keyboard.isDown("right") then 
        move_input = move_input + 1 
    end
    
    -- Gamepad
    if self.joystick then
        local axis = self.joystick:getAxis(1)
        if math.abs(axis) > 0.2 then 
            move_input = move_input + axis 
        end
    end
    
    return move_input
end

function Player:keypressed(key)
    if key == "space" or key == "up" or key == "w" then
        if self.jumps_left > 0 then
            self:jump()
        end
    elseif key == "z" or key == "j" or key == "x" then
        if not self.is_attacking then
            self:attack()
        end
    elseif key == "lshift" or key == "rshift" or key == "c" then
        if not self.is_dashing and self.dash_cooldown_timer <= 0 then
            self:dash()
        end
    end
end

function Player:keyreleased(key)
    if key == "space" and self.vy < 0 then
        self.vy = self.vy * 0.5 -- Piccolo salto
    end
end

function Player:gamepadpressed(joystick, button)
    if button == "a" and self.jumps_left > 0 then
        self:jump()
    elseif button == "x" and not self.is_attacking then
        self:attack()
    elseif button == "b" and not self.is_dashing and self.dash_cooldown_timer <= 0 then
        self:dash()
    end
end

function Player:gamepadreleased(joystick, button)
    if button == "a" and self.vy < 0 then
        self.vy = self.vy * 0.5 -- Piccolo salto come per il tasto space
    end
end

-- Azioni del player
function Player:jump()
    self.vy = config.JUMP_FORCE
    self.on_ground = false
    self.jumps_left = self.jumps_left - 1
    self.state = "jump"
end

function Player:attack()
    self.is_attacking = true
    self.attack_timer = 0
    self.current_frame = 1
    self.state = "attack"
end

function Player:dash()
    self.is_dashing = true
    self.dash_timer = 0
    self.dash_cooldown_timer = self.dash_cooldown
    self.state = "dash"
end

-- Override di apply_gravity per gestire i jumps_left
function Player:apply_gravity(dt)
    Entity.apply_gravity(self, dt)
    
    -- Reset jumps quando tocchiamo terra
    if self.on_ground then
        self.jumps_left = self.max_jumps
    end
end

-- Restituisce la classe Player
return Player
