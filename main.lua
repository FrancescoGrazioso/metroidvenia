-- main.lua
-- Entry point principale del gioco

local config = require("config")
local input = require("input")
local world = require("world")
local Player = require("player")
local Enemy = require("enemy")

-- Gestori di stato gioco
local game_state = {
    current = "menu",
    states = {
        menu = {},
        playing = {},
        paused = {},
        game_over = {}
    }
}

-- Inizializzazione
function love.load()
    -- Imposta dimensioni finestra
    local screen_width = config.SCREEN_WIDTH or 800
    local screen_height = config.SCREEN_HEIGHT or 600
    love.window.setMode(
        screen_width, 
        screen_height, 
        { 
            resizable = true,
            vsync = true,
            minwidth = 400,
            minheight = 300
        }
    )
    
    -- Imposta titolo
    love.window.setTitle("Warrior Platform Game")
    
    -- Inizializza input
    input:init()
    
    -- Inizializza mondo
    world:load()
    
    -- Crea player
    local player = Player:new(100, 100)
    world:add_entity(player)

    -- Crea nemici
    for i = 1, 1 do
        local enemy = Enemy:new(200 + i * 100, 100)
        world:add_entity(enemy)
    end
    
    -- Imposta inizialmente lo stato di gioco
    change_game_state("playing")
end

-- Update loop
function love.update(dt)
    -- Aggiorna input
    input:update()
    
    -- Controlla cambio stato (es. pausa)
    if input:is_pressed("pause") then
        if game_state.current == "playing" then
            change_game_state("paused")
        elseif game_state.current == "paused" then
            change_game_state("playing")
        end
    end
    
    -- Esegui update in base allo stato
    if game_state.current == "playing" then
        world:update(dt)
    elseif game_state.current == "menu" then
        update_menu(dt)
    elseif game_state.current == "paused" then
        update_pause_menu(dt)
    elseif game_state.current == "game_over" then
        update_game_over(dt)
    end
end

-- Drawing loop
function love.draw()
    if game_state.current == "playing" or game_state.current == "paused" then
        world:draw()
        
        -- Overlay di pausa
        if game_state.current == "paused" then
            draw_pause_menu()
        end
    elseif game_state.current == "menu" then
        draw_menu()
    elseif game_state.current == "game_over" then
        draw_game_over()
    end
end

-- Cambio stato di gioco
function change_game_state(new_state)
    -- Esci se lo stato non esiste
    if not game_state.states[new_state] then return end
    
    -- Gestisci uscita dallo stato corrente
    if game_state.current == "menu" then
        -- Cleanup menu
    elseif game_state.current == "playing" then
        -- Nulla da fare
    elseif game_state.current == "paused" then
        -- Nulla da fare
    elseif game_state.current == "game_over" then
        -- Cleanup game over
    end
    
    -- Cambia stato
    game_state.current = new_state
    
    -- Gestisci inizializzazione nuovo stato
    if new_state == "menu" then
        -- Init menu
    elseif new_state == "playing" then
        -- Nulla da fare
    elseif new_state == "paused" then
        -- Nulla da fare
    elseif new_state == "game_over" then
        -- Init game over
    end
end

-- Menu principale
function update_menu(dt)
    -- Logica menu
    if input:is_pressed("jump") or input:is_pressed("attack") then
        change_game_state("playing")
    end
end

function draw_menu()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("WARRIOR PLATFORM GAME", 0, 150, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("Press SPACE or Z to start", 0, 250, love.graphics.getWidth(), "center")
end

-- Menu pausa
function update_pause_menu(dt)
    -- Controlli menu pausa
end

function draw_pause_menu()
    -- Overlay semitrasparente
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("PAUSED", 0, 150, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("Press ESC to resume", 0, 250, love.graphics.getWidth(), "center")
end

-- Game over
function update_game_over(dt)
    if input:is_pressed("jump") or input:is_pressed("attack") then
        -- Restart
        love.load()
        change_game_state("playing")
    end
end

function draw_game_over()
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.setColor(1, 0.3, 0.3)
    love.graphics.printf("GAME OVER", 0, 150, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.printf("Press SPACE or Z to restart", 0, 250, love.graphics.getWidth(), "center")
end

-- Callbacks LÖVE per l'input
function love.keypressed(key)
-- Passa l'input al modulo input
    input:keypressed(key)
    
    -- Altri gestori di input
    if game_state.current == "playing" then
        if world.player then
            world.player:keypressed(key)
        end
    end
end

function love.keyreleased(key)
    input:keyreleased(key)
    
    -- Passa l'input al player
    if game_state.current == "playing" then
        if world.player then
            world.player:keyreleased(key)
        end
    end
end

function love.gamepadpressed(joystick, button)
    input:gamepadpressed(joystick, button)
    
    -- Passa l'input al player
    if game_state.current == "playing" then
        if world.player then
            world.player:gamepadpressed(joystick, button)
        end
    end
end

function love.gamepadreleased(joystick, button)
    input:gamepadreleased(joystick, button)
    
    -- Passa l'input al player
    if game_state.current == "playing" then
        if world.player then
            world.player:gamepadreleased(joystick, button)
        end
    end
end

-- Callback per eventi della finestra
function love.resize(width, height)
    -- Aggiorna dimensione viewport
    world.camera.width = width
    world.camera.height = height
end
