-- config.lua
-- File di configurazione globale del gioco

local config = {
    -- Fisica
    GRAVITY = 900,
    
    -- Player
    PLAYER_SPEED = 200,
    JUMP_FORCE = -500,
    MAX_JUMPS = 2,
    
    -- Animazioni
    FRAME_DURATION = 0.2,
    ATTACK_SPEED_MULTIPLIER = 0.23,
    ENTITY_SCALE = 1.6,
    
    -- Dash
    DASH_DURATION = 0.28,
    DASH_SPEED = 600,
    DASH_COOLDOWN = 0.4,
    
    -- Debug
    DEBUG = false,
    
    -- Dimensioni schermo
    SCREEN_WIDTH = 1920,
    SCREEN_HEIGHT = 1080
}

return config