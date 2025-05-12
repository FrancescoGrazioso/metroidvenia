-- camera.lua
-- Sistema di camera con funzionalità avanzate

local camera = {
    x = 0,
    y = 0,
    scale = 1,
    rotation = 0,
    target = nil,
    
    -- Limiti della camera
    bounds = {
        x_min = nil,
        y_min = nil,
        x_max = nil,
        y_max = nil
    },
    
    -- Effetti e comportamenti
    smooth_factor = 5,  -- Fattore di smorzamento, più alto = più veloce
    shake_amount = 0,
    shake_duration = 0,
    shake_intensity = 0,
    
    -- Dimensioni viewport
    viewport_width = 800,
    viewport_height = 600
}

-- Inizializza la camera
function camera:init(width, height)
    self.viewport_width = width or love.graphics.getWidth()
    self.viewport_height = height or love.graphics.getHeight()
end

-- Imposta i limiti della camera
function camera:set_bounds(x_min, y_min, x_max, y_max)
    self.bounds.x_min = x_min
    self.bounds.y_min = y_min
    self.bounds.x_max = x_max
    self.bounds.y_max = y_max
end

-- Imposta target da seguire
function camera:follow(target)
    self.target = target
end

-- Aggiorna la posizione della camera
function camera:update(dt)
    -- Segui il target se presente
    if self.target then
        local target_x = self.target.x
        local target_y = self.target.y
        
        -- Applica smorzamento per movimento fluido
        self.x = self.x + (target_x - self.x) * self.smooth_factor * dt
        self.y = self.y + (target_y - self.y) * self.smooth_factor * dt
    end
    
    -- Aggiorna shake della camera
    if self.shake_duration > 0 then
        self.shake_duration = self.shake_duration - dt
        self.shake_amount = self.shake_intensity * (self.shake_duration / self.shake_intensity)
        
        if self.shake_duration <= 0 then
            self.shake_amount = 0
        end
    end
    
    -- Applica limiti della camera se presenti
    self:apply_bounds()
end

-- Applica i limiti alla camera
function camera:apply_bounds()
    if self.bounds.x_min and self.x < self.bounds.x_min + self.viewport_width/2/self.scale then
        self.x = self.bounds.x_min + self.viewport_width/2/self.scale
    end
    
    if self.bounds.x_max and self.x > self.bounds.x_max - self.viewport_width/2/self.scale then
        self.x = self.bounds.x_max - self.viewport_width/2/self.scale
    end
    
    if self.bounds.y_min and self.y < self.bounds.y_min + self.viewport_height/2/self.scale then
        self.y = self.bounds.y_min + self.viewport_height/2/self.scale
    end
    
    if self.bounds.y_max and self.y > self.bounds.y_max - self.viewport_height/2/self.scale then
        self.y = self.bounds.y_max - self.viewport_height/2/self.scale
    end
end

-- Applica la trasformazione della camera
function camera:apply()
    love.graphics.push()
    
    -- Centro dello schermo
    love.graphics.translate(self.viewport_width/2, self.viewport_height/2)
    
    -- Scala
    love.graphics.scale(self.scale, self.scale)
    
    -- Rotazione
    love.graphics.rotate(self.rotation)
    
    -- Applica effetto shake se attivo
    local shake_offset_x = 0
    local shake_offset_y = 0
    
    if self.shake_amount > 0 then
        shake_offset_x = love.math.random(-self.shake_amount, self.shake_amount)
        shake_offset_y = love.math.random(-self.shake_amount, self.shake_amount)
    end
    
    -- Trasla alla posizione della camera (invertita)
    love.graphics.translate(-self.x + shake_offset_x, -self.y + shake_offset_y)
end

-- Ripristina la trasformazione della camera
function camera:reset()
    love.graphics.pop()
end

-- Inizia un effetto di shake della camera
function camera:shake(duration, intensity)
    self.shake_duration = duration or 0.5
    self.shake_intensity = intensity or 5
    self.shake_amount = self.shake_intensity
end

-- Zoom della camera
function camera:zoom(factor)
    self.scale = self.scale * factor
end

-- Imposta lo zoom a un valore specifico
function camera:set_zoom(scale)
    self.scale = scale
end

-- Converti coordinate schermo in coordinate mondo
function camera:screen_to_world(x, y)
    -- Inverti la trasformazione della camera
    local world_x = (x - self.viewport_width/2) / self.scale + self.x
    local world_y = (y - self.viewport_height/2) / self.scale + self.y
    
    return world_x, world_y
end

-- Converti coordinate mondo in coordinate schermo
function camera:world_to_screen(x, y)
    -- Applica la trasformazione della camera
    local screen_x = (x - self.x) * self.scale + self.viewport_width/2
    local screen_y = (y - self.y) * self.scale + self.viewport_height/2
    
    return screen_x, screen_y
end

-- Verifica se un punto nel mondo è visibile a schermo
function camera:is_visible(x, y, width, height)
    local left = x - width/2
    local right = x + width/2
    local top = y - height/2
    local bottom = y + height/2
    
    local camera_left = self.x - self.viewport_width/2/self.scale
    local camera_right = self.x + self.viewport_width/2/self.scale
    local camera_top = self.y - self.viewport_height/2/self.scale
    local camera_bottom = self.y + self.viewport_height/2/self.scale
    
    return right > camera_left and left < camera_right and
           bottom > camera_top and top < camera_bottom
end

-- Aggiorna le dimensioni del viewport
function camera:resize(width, height)
    self.viewport_width = width
    self.viewport_height = height
end

return camera