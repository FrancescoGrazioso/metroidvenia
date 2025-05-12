-- main.lua
local player = require("player")
local world = require("world") -- Nuovo modulo per gestire il mondo di gioco

function love.load()
    local screen_width, screen_height = love.window.getDesktopDimensions()
    love.window.setMode(screen_width, screen_height, { resizable = true })
    
    world.load()
    player.load()
end

function love.update(dt)
    world.update(dt)
    player.update(dt)
end

function love.draw()
    -- Disegna il mondo prima del player (per il layer di profondità)
    world.draw()
    player.draw()
    
    -- Debug info (opzionale)
    if world.debug then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("State: " .. player.state, 10, 10)
        love.graphics.print("On ground: " .. tostring(player.on_ground), 10, 30)
        love.graphics.print("FPS: " .. love.timer.getFPS(), 10, 50)
    end
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    elseif key == "f1" then
        world.debug = not world.debug
    end
    
    player.keypressed(key)
end

function love.keyreleased(key)
    player.keyreleased(key)
end

function love.gamepadpressed(joystick, button)
    player.gamepadpressed(joystick, button)
end