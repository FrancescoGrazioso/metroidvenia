-- world.lua
-- Gestisce il mondo di gioco, piattaforme, entità e collisioni

local config = require("config")
local utils = require("utils")
local PlatformModule = require("platform")
local Platform = PlatformModule.Platform
local PlatformFactory = PlatformModule.PlatformFactory

local world = {
    platforms = {},
    entities = {},
    player = nil,
    enemies = {},
    gravity = config.GRAVITY,
    debug = config.DEBUG,
    camera = {
        x = 0,
        y = 0,
        target = nil,
        width = config.SCREEN_WIDTH,
        height = config.SCREEN_HEIGHT,
        scale = 1
    }
}

function world:load()
    -- Carica piattaforme
    self:load_platforms()
    
    -- Inizializza camera
    self.camera.width = love.graphics.getWidth()
    self.camera.height = love.graphics.getHeight()
end

function world:load_platforms()
    -- Crea piattaforme di base
    local platforms = {
        PlatformFactory.create_platform(0, 500, 800, 50, "ground"),
        PlatformFactory.create_platform(300, 400, 200, 20, "platform"),
        PlatformFactory.create_platform(600, 350, 150, 20, "platform"),
        PlatformFactory.create_platform(100, 300, 150, 20, "platform")
    }
    
    -- Aggiungi una piattaforma mobile
    local moving_platform = PlatformFactory.create_moving_platform(
        400, 250, 100, 20, 
        {{x = 400, y = 250}, {x = 600, y = 250}, {x = 600, y = 200}, {x = 400, y = 200}},
        70
    )
    
    table.insert(platforms, moving_platform)
    
    -- Imposta le piattaforme
    self.platforms = platforms
end

function world:update(dt)
    -- Aggiorna tutte le piattaforme
    for _, platform in ipairs(self.platforms) do
        platform:update(dt)
    end
    
    -- Aggiorna tutte le entità
    for _, entity in ipairs(self.entities) do
        if entity.is_alive then
            entity:update(dt)
        end
    end
    
    -- Gestisci collisioni tra entità
    self:check_entity_collisions()
    
    -- Aggiorna camera
    self:update_camera(dt)
end

function world:draw()
    -- Applica trasformazione camera
    self:apply_camera_transform()
    
    -- Disegna sfondo (potrebbe essere un livello separato)
    self:draw_background()
    
    -- Disegna tutte le piattaforme
    for _, platform in ipairs(self.platforms) do
        platform:draw()
    end
    
    -- Disegna tutte le entità
    for _, entity in ipairs(self.entities) do
        if entity.is_alive then
            entity:draw()
        end
    end
    
    -- Ripristina trasformazione camera
    love.graphics.pop()
    
    -- Debug info
    if self.debug then
        self:draw_debug_info()
    end
end

function world:draw_background()
    -- Disegna un semplice sfondo gradiente
    love.graphics.setColor(0.4, 0.6, 0.8, 1)
    love.graphics.rectangle("fill", 0, 0, self.camera.width, self.camera.height)
end

function world:apply_camera_transform()
    love.graphics.push()
    
    -- Calcola offset camera
    local offset_x = -self.camera.x + self.camera.width / 2
    local offset_y = -self.camera.y + self.camera.height / 2
    
    -- Applica trasformazione
    love.graphics.translate(offset_x, offset_y)
    love.graphics.scale(self.camera.scale, self.camera.scale)
end

function world:update_camera(dt)
    if not self.camera.target then return end
    
    -- Segui il target con smorzamento
    local target_x = self.camera.target.x
    local target_y = self.camera.target.y
    
    -- Effetto di smorzamento per movimento fluido
    local smooth_factor = 5
    self.camera.x = self.camera.x + (target_x - self.camera.x) * smooth_factor * dt
    self.camera.y = self.camera.y + (target_y - self.camera.y) * smooth_factor * dt
end

function world:set_camera_target(entity)
    self.camera.target = entity
end

function world:draw_debug_info()
    love.graphics.setColor(1, 1, 0)
    
    -- FPS e memoria
    love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 10)
    love.graphics.print("Memory: " .. math.floor(collectgarbage("count")) .. " KB", 10, 30)
    
    -- Numero di entità
    love.graphics.print("Entities: " .. #self.entities, 10, 50)
    
    -- Camera info
    love.graphics.print("Camera: " .. math.floor(self.camera.x) .. ", " .. math.floor(self.camera.y), 10, 70)
    
    -- Player info se esiste
    if self.player then
        love.graphics.print("Player: " .. math.floor(self.player.x) .. ", " .. math.floor(self.player.y), 10, 90)
        love.graphics.print("State: " .. self.player.state, 10, 110)
        love.graphics.print("On ground: " .. tostring(self.player.on_ground), 10, 130)
    end
end

function world:check_entity_collisions()
    -- Semplice controllo collisioni tra entità
    local entities = self.entities
    local entities_count = #entities
    
    for i = 1, entities_count - 1 do
        for j = i + 1, entities_count do
            local entity1 = entities[i]
            local entity2 = entities[j]
            
            if entity1.is_alive and entity2.is_alive and entity1:collides_with(entity2) then
                -- Chiamiamo l'handler di collisione per entrambe le entità
                if entity1.on_collision then
                    entity1:on_collision(entity2)
                end
                
                if entity2.on_collision then
                    entity2:on_collision(entity1)
                end
            end
        end
    end
end

function world:add_entity(entity)
    table.insert(self.entities, entity)
    entity:set_world(self)
    
    -- Imposta come player o nemico se applicabile
    if entity.is_player then
        self.player = entity
        self:set_camera_target(entity)
    elseif entity.is_enemy then
        table.insert(self.enemies, entity)
    end
end

function world:remove_entity(entity)
    -- Rimuovi da entità generiche
    for i, e in ipairs(self.entities) do
        if e == entity then
            table.remove(self.entities, i)
            break
        end
    end
    
    -- Rimuovi da nemici se applicabile
    if entity.is_enemy then
        for i, e in ipairs(self.enemies) do
            if e == entity then
                table.remove(self.enemies, i)
                break
            end
        end
    end
    
    -- Reset player se applicabile
    if entity == self.player then
        self.player = nil
    end
end

function world:get_platforms()
    return self.platforms
end

return world