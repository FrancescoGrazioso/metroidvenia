-- utils.lua
-- Funzioni di utilità generiche

local utils = {}

-- Funzione di collisione AABB
function utils.check_collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

-- Carica un insieme di frame di animazione da un pattern di percorso
function utils.load_frames(path_format, count)
    local frames = {}
    for i = 1, count do
        local path = string.format(path_format, i)
        table.insert(frames, love.graphics.newImage(path))
    end
    return frames
end

-- Verifica se un punto è all'interno di un rettangolo
function utils.point_in_rect(px, py, rx, ry, rw, rh)
    return px >= rx and px <= rx + rw and py >= ry and py <= ry + rh
end

-- Ottieni la direzione come fattore (1 o -1) da un booleano
function utils.direction_factor(is_right)
    return is_right and 1 or -1
end

-- Mantiene un valore all'interno di un range
function utils.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

return utils