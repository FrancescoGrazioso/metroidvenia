-- gamestate.lua
-- Sistema di gestione degli stati di gioco

local GameState = {
    current = nil,
    states = {},
    transitions = {
        fade_alpha = 0,
        fade_in = false,
        fade_out = false,
        fade_speed = 3,
        next_state = nil,
        transition_complete_callback = nil
    }
}

-- Registra un nuovo stato di gioco
function GameState:register(name, state)
    self.states[name] = state
    
    -- Metodi di default se non definiti
    if not state.enter then state.enter = function() end end
    if not state.exit then state.exit = function() end end
    if not state.update then state.update = function(dt) end end
    if not state.draw then state.draw = function() end end
end

-- Cambia stato corrente
function GameState:change(name, ...)
    assert(self.states[name], "Stato di gioco '" .. name .. "' non registrato")
    
    -- Esci dallo stato corrente se esiste
    if self.current then
        self.states[self.current]:exit()
    end
    
    -- Entra nel nuovo stato
    self.current = name
    self.states[name]:enter(...)
end

-- Cambia stato con transizione graduale
function GameState:change_with_transition(name, ...)
    assert(self.states[name], "Stato di gioco '" .. name .. "' non registrato")
    
    self.transitions.fade_out = true
    self.transitions.next_state = name
    self.transitions.next_state_args = {...}
end

-- Aggiorna lo stato corrente
function GameState:update(dt)
    -- Aggiorna transizioni se attive
    if self.transitions.fade_out then
        -- Effetto fadeout
        self.transitions.fade_alpha = self.transitions.fade_alpha + self.transitions.fade_speed * dt
        
        if self.transitions.fade_alpha >= 1 then
            -- Cambio stato
            self.transitions.fade_alpha = 1
            self.transitions.fade_out = false
            self.transitions.fade_in = true
            
            -- Cambia stato
            local next_state = self.transitions.next_state
            local args = self.transitions.next_state_args
            
            -- Esci dallo stato corrente
            if self.current then
                self.states[self.current]:exit()
            end
            
            -- Entra nel nuovo stato
            self.current = next_state
            self.states[next_state]:enter(unpack(args))
        end
    elseif self.transitions.fade_in then
        -- Effetto fadein
        self.transitions.fade_alpha = self.transitions.fade_alpha - self.transitions.fade_speed * dt
        
        if self.transitions.fade_alpha <= 0 then
            -- Fine transizione
            self.transitions.fade_alpha = 0
            self.transitions.fade_in = false
            
            -- Callback se presente
            if self.transitions.transition_complete_callback then
                self.transitions.transition_complete_callback()
                self.transitions.transition_complete_callback = nil
            end
        end
    end
    
    -- Aggiorna stato corrente
    if self.current then
        self.states[self.current]:update(dt)
    end
end

-- Disegna lo stato corrente
function GameState:draw()
    -- Disegna stato corrente
    if self.current then
        self.states[self.current]:draw()
    end
    
    -- Disegna overlay transizione se necessario
    if self.transitions.fade_alpha > 0 then
        love.graphics.setColor(0, 0, 0, self.transitions.fade_alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1, 1)
    end
end

-- Imposta la velocità di transizione
function GameState:set_transition_speed(speed)
    self.transitions.fade_speed = speed
end

-- Imposta callback per completamento transizione
function GameState:on_transition_complete(callback)
    self.transitions.transition_complete_callback = callback
end

-- Inizializza un template di stato di gioco
function GameState:create_state_template()
    return {
        enter = function(self, ...) end,
        exit = function(self) end,
        update = function(self, dt) end,
        draw = function(self) end
    }
end

return GameState