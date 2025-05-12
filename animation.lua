-- animation.lua
-- Sistema di gestione delle animazioni

local animation = {}

-- Carica un insieme di animazioni
function animation.load_animation_set(animations_data)
    local animations = {}
    
    for name, data in pairs(animations_data) do
        animations[name] = {
            frames = data.frames,
            duration = data.duration,
            loop = data.loop ~= false  -- Di default, le animazioni sono in loop
        }
    end
    
    return animations
end

-- Ottieni il frame corrente di un'animazione
function animation.get_current_frame(animation_data, current_frame, total_frames)
    if not animation_data or not animation_data.frames then
        return nil
    end
    
    -- Limita il frame all'interno del range valido
    local frame_index = math.min(current_frame, #animation_data.frames)
    return animation_data.frames[frame_index]
end

-- Calcola il prossimo frame di un'animazione
function animation.next_frame(current_frame, total_frames, loop)
    if loop then
        return current_frame % total_frames + 1
    else
        return math.min(current_frame + 1, total_frames)
    end
end

-- Verifica se un'animazione è completata
function animation.is_complete(current_frame, total_frames, loop)
    return not loop and current_frame >= total_frames
end

return animation