-- input.lua
-- Sistema di gestione dell'input

local input = {
    -- Tasti premuti
    keys_down = {},
    keys_pressed = {},
    keys_released = {},
    
    -- Controller
    gamepads = {},
    gamepad_buttons_pressed = {},
    gamepad_buttons_released = {},
    
    -- Mappatura tasti
    key_mapping = {
        left = {"left", "a"},
        right = {"right", "d"},
        jump = {"space", "w", "up"},
        attack = {"z", "j"},
        dash = {"lshift", "k"},
        pause = {"escape", "p"}
    },
    
    -- Mappatura gamepad
    gamepad_mapping = {
        left = {"dpleft"},
        right = {"dpright"},
        jump = {"a", "dpup"},
        attack = {"x"},
        dash = {"b"},
        pause = {"start"}
    },
    
    -- Assi analogici
    axes = {
        move_x = 0,
        move_y = 0
    }
}

-- Inizializza il sistema di input
function input:init()
    self.gamepads = love.joystick.getJoysticks()
end

-- Aggiorna lo stato dell'input
function input:update()
    -- Reset degli stati temporanei
    self.keys_pressed = {}
    self.keys_released = {}
    self.gamepad_buttons_pressed = {}
    self.gamepad_buttons_released = {}
    
    -- Aggiorna assi analogici
    self:update_axes()
end

-- Aggiorna gli assi analogici (gamepad)
function input:update_axes()
    self.axes.move_x = 0
    self.axes.move_y = 0
    
    -- Tastiera (emula assi)
    if self:is_down("left") then
        self.axes.move_x = self.axes.move_x - 1
    end
    if self:is_down("right") then
        self.axes.move_x = self.axes.move_x + 1
    end
    
    -- Gamepad
    if #self.gamepads > 0 then
        local gamepad = self.gamepads[1]
        
        -- Leggi assi analogici
        local left_x = gamepad:getAxis(1)
        local left_y = gamepad:getAxis(2)
        
        -- Deadzone
        if math.abs(left_x) > 0.2 then
            self.axes.move_x = left_x
        end
        
        if math.abs(left_y) > 0.2 then
            self.axes.move_y = left_y
        end
        
        -- D-pad (emula assi)
        if gamepad:isDown("dpleft") then
            self.axes.move_x = -1
        elseif gamepad:isDown("dpright") then
            self.axes.move_x = 1
        end
        
        if gamepad:isDown("dpup") then
            self.axes.move_y = -1
        elseif gamepad:isDown("dpdown") then
            self.axes.move_y = 1
        end
    end
end

-- Callback per tasto premuto
function input:keypressed(key)
    self.keys_down[key] = true
    self.keys_pressed[key] = true
end

-- Callback per tasto rilasciato
function input:keyreleased(key)
    self.keys_down[key] = nil
    self.keys_released[key] = true
end

-- Callback per pulsante gamepad premuto
function input:gamepadpressed(joystick, button)
    self.gamepad_buttons_pressed[button] = true
end

-- Callback per pulsante gamepad rilasciato
function input:gamepadreleased(joystick, button)
    self.gamepad_buttons_released[button] = true
end

-- Verifica se un'azione è correntemente premuta
function input:is_down(action)
    -- Controlla tastiera
    for _, key in ipairs(self.key_mapping[action] or {}) do
        if self.keys_down[key] then
            return true
        end
    end
    
    -- Controlla gamepad
    if #self.gamepads > 0 then
        local gamepad = self.gamepads[1]
        for _, button in ipairs(self.gamepad_mapping[action] or {}) do
            if gamepad:isDown(button) then
                return true
            end
        end
    end
    
    return false
end

-- Verifica se un'azione è stata appena premuta
function input:is_pressed(action)
    -- Controlla tastiera
    for _, key in ipairs(self.key_mapping[action] or {}) do
        if self.keys_pressed[key] then
            return true
        end
    end
    
    -- Controlla gamepad
    for _, button in ipairs(self.gamepad_mapping[action] or {}) do
        if self.gamepad_buttons_pressed[button] then
            return true
        end
    end
    
    return false
end

-- Verifica se un'azione è stata appena rilasciata
function input:is_released(action)
    -- Controlla tastiera
    for _, key in ipairs(self.key_mapping[action] or {}) do
        if self.keys_released[key] then
            return true
        end
    end
    
    -- Controlla gamepad
    for _, button in ipairs(self.gamepad_mapping[action] or {}) do
        if self.gamepad_buttons_released[button] then
            return true
        end
    end
    
    return false
end

-- Ottieni valore asse analogico
function input:get_axis(axis_name)
    return self.axes[axis_name] or 0
end

-- Configura una mappatura personalizzata per un'azione
function input:set_key_mapping(action, keys)
    self.key_mapping[action] = keys
end

-- Configura una mappatura gamepad personalizzata per un'azione
function input:set_gamepad_mapping(action, buttons)
    self.gamepad_mapping[action] = buttons
end

return input