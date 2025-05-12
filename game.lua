-- game.lua
-- Implementazione dello stato di gioco principale

local config = require("config")
local Player = require("player")
local Enemy = require("enemy")
local world = require("world")
local camera = require("camera")
local input = require("input")

local Game = {}

function Game:enter()
    -- Inizializza camera
    camera:init(love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Carica mondo
    world:load()
    
    -- Crea player
    local player = Player:new(100, 100)
    world:add_entity(player)
    
    -- Imposta la camera per seguire il player
    camera:follow(player)
    camera:set_bounds(0, 0, 2000, 600)  -- Imposta limiti del livello
    
    -- Crea alcuni nemici di esempio
    local enemy1 = Enemy:new(400, 400, "base")
    enemy1:set_patrol_points({300, 500})
    enemy1:set_target(player)
    world:add_entity(enemy1)
    
    local enemy2 = Enemy:new(700, 300, "base")
    enemy2:set_patrol_points({600, 800})
    enemy2:set_target(player)
    world:add_entity(enemy2)
    
    -- Flag di pausa
    self.paused = false
end

function Game:update(dt)
    -- Gestione pausa
    if input:is_pressed("pause") then
        self.paused = not self.paused
        return
    end
    
    -- Salta update se in pausa
    if self.paused then return end
    
    -- Aggiorna mondo
    world:update(dt)
    
    -- Aggiorna camera
    camera:update(dt)
    
    -- Controllo game over
    if world.player and not world.player.is_alive then
        -- Qui si può richiamare un cambio di stato con GameState:change("game_over")
    end
end

function Game:draw()
    -- Applica trasformazione camera
    camera:apply()
    
    -- Disegna mondo
    world:draw()
    
    -- Ripristina trasformazione camera
    camera:reset()
    
    -- Disegna UI
    self:draw_ui()
    
    -- Disegna menu pausa
    if self.paused then
        self:draw_pause_menu()
    end
end

function Game:draw_ui()
    -- Disegna HUD del player
    if world.player then
        -- Barra salute
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 20, 20, 210, 30)
        
        local health_percent = world.player.health / world.player.max_health
        love.graphics.setColor(1 - health_percent, health_percent, 0, 0.8)
        love.graphics.rectangle("fill", 25, 25, 200 * health_percent, 20)
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Health: " .. world.player.health .. "/" .. world.player.max_health, 30, 27)
    end
    
    -- Debug info
    if config.DEBUG then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 60)
        
        if world.player then
            love.graphics.print("Player: " .. math.floor(world.player.x) .. ", " .. math.floor(world.player.y), 10, 80)
            love.graphics.print("State: " .. world.player.state, 10, 100)
        end
    end
end

function Game:draw_pause_menu()
    -- Overlay semitrasparente
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Testo pausa
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, 150, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("Press ESC to resume", 0, 250, love.graphics.getWidth(), "center")
    love.graphics.printf("Press Q to quit", 0, 280, love.graphics.getWidth(), "center")
    
    -- Gestione input menu pausa
    if input:is_pressed("q") then
        -- Esci al menu principale o chiudi il gioco
        -- GameState:change("menu")
    end
end

function Game:exit()
    -- Cleanup risorse se necessario
end

function Game:keypressed(key)
    -- Passa l'input al player se esiste
    if world.player and world.player.keypressed then
        world.player:keypressed(key)
    end
end

function Game:keyreleased(key)
    -- Passa l'input al player se esiste
    if world.player and world.player.keyreleased then
        world.player:keyreleased(key)
    end
end

return Game