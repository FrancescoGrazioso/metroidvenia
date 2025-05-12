-- entity.lua
-- Classe base per tutte le entità di gioco

local config = require("config")
local utils = require("utils")

-- Classe base Entity
local Entity = {}
Entity.__index = Entity

-- Costruttore della classe base
function Entity:new(x, y, width, height)
    local instance = setmetatable({}, self)
    
    -- Proprietà fisiche
    instance.x = x or 0
    instance.y = y or 0
    instance.width = width or 32
    instance.height = height or 32
    instance.vx = 0
    instance.vy = 0
    instance.facing_right = true
    instance.on_ground = false
    
    -- Proprietà di salute
    instance.max_health = 100
    instance.health = instance.max_health
    instance.is_alive = true
    
    -- Proprietà di animazione
    instance.animations = {}
    instance.current_animation = "idle"
    instance.current_frame = 1
    instance.frame_timer = 0
    
    -- Riferimento al mondo
    instance.world = nil
    
    return instance
end

-- Metodi comuni a tutte le entità
function Entity:update(dt)
    self:apply_gravity(dt)
    self:update_animation(dt)
end

function Entity:draw()
    love.graphics.setColor(1, 1, 1)
    self:draw_animation()
    
    -- Debug collider
    if config.DEBUG then
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    end
end

function Entity:apply_gravity(dt)
    if not self.world then return end
    
    self.vy = self.vy + config.GRAVITY * dt
    local new_y = self.y + self.vy * dt
    
    -- Controlla collisioni con piattaforme
    local landed = false
    for _, platform in ipairs(self.world.platforms) do
        -- Verifica collisione orizzontale
        local hits_horizontally = self.x + self.width > platform.x and 
                                  self.x < platform.x + platform.w
        
        -- Verifica atterraggio
        local prev_bottom = self.y + self.height
        local next_bottom = new_y + self.height
        local falling = self.vy > 0
        local will_land = prev_bottom <= platform.y and next_bottom >= platform.y
        
        if hits_horizontally and falling and will_land then
            self.y = platform.y - self.height
            self.vy = 0
            self.on_ground = true
            landed = true
            break
        end
    end
    
    if not landed then
        self.y = new_y
        self.on_ground = false
    end
end

function Entity:check_horizontal_movement(dt, move_direction, speed)
    if not move_direction or not speed then return false end
    
    local new_x = self.x + move_direction * speed * dt
    
    -- Controllo collisioni con muri
    local collided = false
    for _, platform in ipairs(self.world.platforms) do
        -- Verifica solo collisioni con i lati delle piattaforme, non con la parte superiore
        local vertical_overlap = self.y + self.height > platform.y and 
                                self.y < platform.y + platform.h
        local horizontal_overlap = new_x + self.width > platform.x and 
                                  new_x < platform.x + platform.w
        
        if vertical_overlap and horizontal_overlap then
            -- Se non stiamo atterrando sulla piattaforma, è una collisione laterale
            if math.abs((self.y + self.height) - platform.y) > 1 then
                collided = true
                break
            end
        end
    end
    
    if not collided then
        self.x = new_x
        self.facing_right = move_direction > 0
        return true
    end
    
    return false
end

function Entity:update_animation(dt)
    -- Cambiamento di animazione
    if self.current_animation ~= self.previous_animation then
        self.current_frame = 1
        self.frame_timer = 0
        self.previous_animation = self.current_animation
    end
    
    -- Aggiornamento frame dell'animazione
    if self.animations[self.current_animation] then
        local anim = self.animations[self.current_animation]
        self.frame_timer = self.frame_timer + dt
        
        if self.frame_timer >= anim.duration then
            self.frame_timer = self.frame_timer - anim.duration
            if anim.loop ~= false or self.current_frame < #anim.frames then
                self.current_frame = self.current_frame % #anim.frames + 1
            end
        end
    end
end

function Entity:draw_animation()
    local anim = self.animations[self.current_animation]
    if not anim or not anim.frames[self.current_frame] then return end
    
    local sprite = anim.frames[self.current_frame]
    local spriteWidth = sprite:getWidth()
    local scaleX = self.facing_right and 1 or -1
    local offsetX = self.facing_right and 0 or spriteWidth * config.ENTITY_SCALE
    
    love.graphics.draw(
        sprite, 
        self.x + offsetX, 
        self.y, 
        0, 
        scaleX * config.ENTITY_SCALE, 
        config.ENTITY_SCALE
    )
end

function Entity:take_damage(amount)
    self.health = math.max(0, self.health - amount)
    self.is_alive = self.health > 0
    return self.is_alive
end

function Entity:heal(amount)
    self.health = math.min(self.max_health, self.health + amount)
end

function Entity:set_world(world)
    self.world = world
end

function Entity:collides_with(entity)
    return utils.check_collision(
        self.x, self.y, self.width, self.height,
        entity.x, entity.y, entity.width, entity.height
    )
end

function Entity:load_animations(animations_data)
    self.animations = animations_data
end

return Entity