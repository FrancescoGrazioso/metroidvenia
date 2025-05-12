-- world.lua
-- Gestisce tutto ciò che riguarda il mondo di gioco: piattaforme, ostacoli, ecc.

local world = {
    debug = false,
    platforms = {},
    gravity = 900
}

function world.load()
    -- Definizione delle piattaforme
    world.platforms = {
        { x = 0, y = 500, w = 800, h = 50, type = "ground" },
        { x = 300, y = 400, w = 200, h = 20, type = "platform" },
        { x = 600, y = 350, w = 150, h = 20, type = "platform" },
        { x = 100, y = 300, w = 150, h = 20, type = "platform" },
    }
    
    -- Condividi le piattaforme con il modulo player
    -- In una implementazione più avanzata, si potrebbe usare un gestore di collisioni o un sistema ECS
    local player = require("player")
    player.platforms = world.platforms
    player.world = world
end

function world.update(dt)
    -- Aggiorna elementi dinamici del mondo
    -- Ad esempio, piattaforme mobili, nemici, ecc.
end

function world.draw()
    love.graphics.setColor(0.5, 0.5, 0.5)
    
    -- Disegna tutte le piattaforme
    for _, platform in ipairs(world.platforms) do
        if platform.type == "ground" then
            love.graphics.setColor(0.4, 0.4, 0.4)
        else
            love.graphics.setColor(0.6, 0.6, 0.6)
        end
        
        love.graphics.rectangle("fill", platform.x, platform.y, platform.w, platform.h)
    end
    
    -- Ripristina il colore
    love.graphics.setColor(1, 1, 1)
end

-- Funzioni di utility per collisioni (che potrebbero essere usate dal player)
function world.check_collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

return world