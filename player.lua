-- Modulo player refactored
local player = {}

-- Configurazione costanti
local CONSTANTS = {
    GRAVITY = 900,
    JUMP_FORCE = -500,
    PLAYER_SPEED = 200,
    FRAME_DURATION = 0.1,
    ATTACK_SPEED_MULTIPLIER = 0.47,
    SCALE = 1.6
}

-- Sistema di animazioni
local animations = {}

function animations.load()
    animations.data = {
        idle = {
            frames = animations.load_frames("assets/Warrior/Individual_Sprite/idle/Warrior_Idle_%d.png", 6),
            duration = CONSTANTS.FRAME_DURATION
        },
        jump = {
            frames = animations.load_frames("assets/Warrior/Individual_Sprite/Jump/Warrior_Jump_%d.png", 3),
            duration = CONSTANTS.FRAME_DURATION
        },
        fall = {
            frames = animations.load_frames("assets/Warrior/Individual_Sprite/Fall/Warrior_Fall_%d.png", 3),
            duration = CONSTANTS.FRAME_DURATION
        },
        run = {
            frames = animations.load_frames("assets/Warrior/Individual_Sprite/Run/Warrior_Run_%d.png", 8),
            duration = CONSTANTS.FRAME_DURATION
        },
        attack = {
            frames = animations.load_frames("assets/Warrior/Individual_Sprite/Attack/Warrior_Attack_%d.png", 11),
            duration = CONSTANTS.FRAME_DURATION * CONSTANTS.ATTACK_SPEED_MULTIPLIER
        },
        dash = {
            frames = animations.load_frames("assets/Warrior/Individual_Sprite/Dash/Warrior_Dash_%d.png", 7),
            duration = CONSTANTS.FRAME_DURATION
        }
    }
end

function animations.load_frames(path_format, count)
    local frames = {}
    for i = 1, count do
        local path = string.format(path_format, i)
        table.insert(frames, love.graphics.newImage(path))
    end
    return frames
end

function animations.update(dt)
    if player.state ~= player.previous_state then
        player.current_frame = 1
        player.frame_timer = 0
        player.previous_state = player.state
    end

    -- Avanza frame dell'animazione corrente
    player.frame_timer = player.frame_timer + dt
    local current_anim = animations.data[player.state]
    
    if current_anim then
        local frame_duration = current_anim.duration
        if player.frame_timer >= frame_duration then
            player.frame_timer = player.frame_timer - frame_duration
            player.current_frame = player.current_frame % #current_anim.frames + 1
        end
    end
end

function animations.draw()
    if not animations.data[player.state] then return end
    
    local sprite = animations.data[player.state].frames[player.current_frame]
    if sprite then
        local spriteWidth = sprite:getWidth()
        local scaleX = player.facing_right and 1 or -1
        local offsetX = player.facing_right and 0 or spriteWidth
        love.graphics.draw(sprite, player.x + offsetX, player.y, 0, scaleX * CONSTANTS.SCALE, CONSTANTS.SCALE)
    end
end

-- Sistema di fisica e collisioni
local physics = {}

function physics.apply_gravity(dt)
    player.vy = player.vy + CONSTANTS.GRAVITY * dt
    return player.y + player.vy * dt
end

function physics.check_platform_collisions(newY)
    player.on_ground = false
    local landed = false
    
    for _, platform in ipairs(player.platforms) do
        -- Collisione orizzontale
        local hits_horizontally = player.x + player.w > platform.x and 
                                  player.x < platform.x + platform.w
        
        -- Collisione verticale (atterraggio)
        local prev_bottom = player.y + player.h
        local next_bottom = newY + player.h
        local falling = player.vy > 0
        local will_land = prev_bottom <= platform.y and next_bottom >= platform.y
        
        if hits_horizontally and falling and will_land then
            player.y = platform.y - player.h
            player.vy = 0
            player.on_ground = true
            player.jumps_left = player.max_jumps
            landed = true
            break
        end
    end
    
    if not landed then 
        player.y = newY 
    end
    
    return landed
end

function physics.check_horizontal_movement(dt, move_input)
    if math.abs(move_input) <= 0.2 then return end
    
    local new_x = player.x + move_input * player.speed * dt
    local collided = false
    
    for _, platform in ipairs(player.platforms) do
        local vertical_overlap = player.y + player.h > platform.y and 
                                player.y < platform.y + platform.h
        local horizontal_overlap = new_x + player.w > platform.x and 
                                  new_x < platform.x + platform.w
        
        if vertical_overlap and horizontal_overlap then
            if math.abs((player.y + player.h) - platform.y) > 1 then
                collided = true
                break
            end
        end
    end
    
    if not collided then
        player.x = new_x
        player.facing_right = move_input > 0
    end
end

-- Input controller
local input = {}

function input.get_movement()
    local move_input = 0
    
    if love.keyboard.isDown("left") then 
        move_input = move_input - 1 
    end
    if love.keyboard.isDown("right") then 
        move_input = move_input + 1 
    end
    
    if player.joystick then
        local axis = player.joystick:getAxis(1)
        if math.abs(axis) > 0.2 then 
            move_input = move_input + axis 
        end
    end
    
    return move_input
end

function input.handle_key_press(key)
    if key == "space" and player.jumps_left > 0 then
        player.jump()
    elseif key == "z" and not player.is_attacking then
        player.attack()
    elseif key == "lshift" and not player.is_dashing and player.dash_cooldown_timer <= 0 then
        player.dash()
    end
end

function input.handle_key_release(key)
    if key == "space" and player.vy < 0 then
        player.vy = player.vy * 0.5
    end
end

function input.handle_gamepad_press(joystick, button)
    if button == "a" and player.jumps_left > 0 then
        player.jump()
    elseif button == "x" and not player.is_attacking then
        player.attack()
    elseif button == "b" and not player.is_dashing and player.dash_cooldown_timer <= 0 then
        player.dash()
    end
end

-- Player state machine
local states = {}

function states.update(dt, move_input)
    -- Gestione stati speciali
    if player.is_dashing then
        states.handle_dash_state(dt)
        return
    end
    
    if player.is_attacking then
        states.handle_attack_state(dt)
        return
    end
    
    -- Determinazione dello stato normale
    if not player.on_ground then
        if player.vy < 0 then
            player.state = "jump"
        else
            player.state = "fall"
        end
    elseif math.abs(move_input) > 0.2 then
        player.state = "run"
    else
        player.state = "idle"
    end
end

function states.handle_dash_state(dt)
    player.state = "dash"
    player.dash_timer = player.dash_timer + dt
    
    local direction = player.facing_right and 1 or -1
    player.x = player.x + direction * player.dash_speed * dt
    
    if player.dash_timer >= player.dash_duration then
        player.is_dashing = false
        player.dash_timer = 0
        
        -- Transizione dopo il dash
        if not player.on_ground then
            player.state = player.vy < 0 and "jump" or "fall"
        else
            player.state = math.abs(player.vx or 0) > 0.2 and "run" or "idle"
        end
    end
end

function states.handle_attack_state(dt)
    player.state = "attack"
    player.attack_timer = player.attack_timer + dt
    
    if player.attack_timer >= #animations.data.attack.frames * animations.data.attack.duration then
        player.is_attacking = false
        player.attack_timer = 0
        player.current_frame = 1
        player.frame_timer = 0
        
        -- Transizione dopo l'attacco
        if not player.on_ground then
            player.state = player.vy < 0 and "jump" or "fall"
        else
            local moving = math.abs(input.get_movement()) > 0.2
            player.state = moving and "run" or "idle"
        end
    end
end

-- Player API pubblica
function player.load()
    -- Proprietà base
    player.x = 100
    player.y = 100
    player.w = 32
    player.h = 64
    player.speed = CONSTANTS.PLAYER_SPEED
    player.vy = 0
    player.vx = 0
    player.on_ground = false
    player.max_jumps = 2
    player.jumps_left = player.max_jumps
    
    -- Stati e animazioni
    player.state = "idle"
    player.previous_state = "idle"
    player.facing_right = true
    player.current_frame = 1
    player.frame_timer = 0
    
    -- Attacco
    player.is_attacking = false
    player.attack_timer = 0
    
    -- Dash
    player.is_dashing = false
    player.dash_timer = 0
    player.dash_duration = 0.18
    player.dash_speed = 600
    player.dash_cooldown = 0.4
    player.dash_cooldown_timer = 0
    
    -- Input
    player.joystick = love.joystick.getJoysticks()[1]
    
    -- Piattaforme (temporaneamente qui, idealmente in un modulo world)
    player.platforms = {
        { x = 0, y = 500, w = 800, h = 50 },
        { x = 300, y = 400, w = 200, h = 20 },
    }
    
    -- Carica animazioni
    animations.load()
end

function player.update(dt)
    -- Aggiorna timer cooldown dash
    if player.dash_cooldown_timer > 0 then
        player.dash_cooldown_timer = player.dash_cooldown_timer - dt
    end
    
    -- Ottiene input movimento
    local move_input = input.get_movement()
    player.vx = move_input * player.speed
    
    -- Esegue fisica
    local newY = physics.apply_gravity(dt)
    physics.check_horizontal_movement(dt, move_input)
    physics.check_platform_collisions(newY)
    
    -- Aggiorna macchina a stati
    states.update(dt, move_input)
    
    -- Aggiorna animazioni
    animations.update(dt)
end

function player.draw()
    love.graphics.setColor(1, 1, 1)
    animations.draw()
end

function player.keypressed(key)
    input.handle_key_press(key)
end

function player.keyreleased(key)
    input.handle_key_release(key)
end

function player.gamepadpressed(joystick, button)
    input.handle_gamepad_press(joystick, button)
end

-- Azioni del player
function player.jump()
    player.vy = CONSTANTS.JUMP_FORCE
    player.on_ground = false
    player.jumps_left = player.jumps_left - 1
end

function player.attack()
    player.is_attacking = true
    player.attack_timer = 0
    player.current_frame = 1
end

function player.dash()
    player.is_dashing = true
    player.dash_timer = 0
    player.dash_cooldown_timer = player.dash_cooldown
    player.state = "dash"
end

return player