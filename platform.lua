-- platform.lua
-- Gestione delle piattaforme di gioco

local Platform = {}
Platform.__index = Platform

function Platform:new(x, y, width, height, platform_type)
    local instance = setmetatable({}, self)
    
    instance.x = x
    instance.y = y
    instance.w = width
    instance.h = height
    instance.type = platform_type or "platform"  -- platform, ground, moving
    
    -- Proprietà per piattaforme mobili
    instance.is_moving = platform_type == "moving"
    instance.movement_points = {}
    instance.current_point_index = 1
    instance.move_speed = 50
    instance.wait_time = 0
    instance.wait_duration = 1
    instance.is_waiting = false
    
    -- Proprietà visive
    instance.color = {0.6, 0.6, 0.6}
    if platform_type == "ground" then
        instance.color = {0.4, 0.4, 0.4}
    elseif platform_type == "moving" then
        instance.color = {0.7, 0.5, 0.3}
    end
    
    -- Entità sopra la piattaforma
    instance.entities_on_platform = {}
    
    return instance
end

function Platform:update(dt)
    if not self.is_moving then return end
    
    -- Gestione logica piattaforme mobili
    if self.is_waiting then
        self.wait_time = self.wait_time + dt
        if self.wait_time >= self.wait_duration then
            self.wait_time = 0
            self.is_waiting = false
            
            -- Passa al prossimo punto
            self.current_point_index = (self.current_point_index % #self.movement_points) + 1
        end
        return
    end
    
    -- Nessun punto di movimento definito
    if #self.movement_points == 0 then return end
    
    -- Movimento verso il punto corrente
    local target = self.movement_points[self.current_point_index]
    local dx = target.x - self.x
    local dy = target.y - self.y
    local distance = math.sqrt(dx*dx + dy*dy)
    
    if distance < 5 then
        -- Punto raggiunto, attendi
        self.is_waiting = true
        return
    end
    
    -- Movimento verso il punto
    local angle = math.atan2(dy, dx)
    local vx = math.cos(angle) * self.move_speed * dt
    local vy = math.sin(angle) * self.move_speed * dt
    
    -- Applica movimento
    self.x = self.x + vx
    self.y = self.y + vy
    
    -- Aggiorna entità sopra la piattaforma
    for entity, _ in pairs(self.entities_on_platform) do
        entity.x = entity.x + vx
        entity.y = entity.y + vy
    end
end

function Platform:draw()
    love.graphics.setColor(unpack(self.color))
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    
    -- Effetto piattaforma
    love.graphics.setColor(self.color[1] * 1.2, self.color[2] * 1.2, self.color[3] * 1.2)
    love.graphics.rectangle("fill", self.x, self.y, self.w, 5)
end

function Platform:set_movement_points(points)
    self.movement_points = points
    self.is_moving = #points > 0
end

function Platform:add_entity_on_platform(entity)
    self.entities_on_platform[entity] = true
end

function Platform:remove_entity_from_platform(entity)
    self.entities_on_platform[entity] = nil
end

-- Crea una factory di piattaforme
local PlatformFactory = {}

function PlatformFactory.create_platform(x, y, width, height, type)
    return Platform:new(x, y, width, height, type)
end

function PlatformFactory.create_moving_platform(x, y, width, height, points, speed)
    local platform = Platform:new(x, y, width, height, "moving")
    platform:set_movement_points(points)
    if speed then platform.move_speed = speed end
    return platform
end

return {
    Platform = Platform,
    PlatformFactory = PlatformFactory
}