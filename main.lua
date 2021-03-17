-- Demonstration of Brady
-- Creates a world with a player who can walk around the world.

local Camera = require('camera')

local camera
local world_dimensions = {1600,1200}
local has_gravity = false

local player = {
    x = world_dimensions[1] * 0.5,
    y = world_dimensions[2] * 0.5,
    velocity = {
        y = 0,
    },
    jump_height = -300,
    gravity = -500,
    width = 10,
}

local chaser = {
    x = 0,
    y = 0,
}

local function clamp(x, min, max)
    return math.min(math.max(x, min), max)
end
local function lerp(a,b,t)
    return a * (1-t) + b * t
end
local function loop(i, n)
    local z = i - 1
    return (z % n) + 1
end

local function translate(x,y)
    local half_width = player.width / 2
    player.x = clamp(player.x + x, half_width, world_dimensions[1] - half_width)
    player.y = clamp(player.y + y, half_width, world_dimensions[2] - half_width)
end

function love.load()
	camera = Camera(400, 300, { x = 32, y = 32, resizable = true, maintainAspectRatio = true })
end

function love.keyreleased(key)
    if key == 'escape' then
        love.event.quit()
    elseif key == 'p' then
        has_gravity = not has_gravity
        if has_gravity then
            player.velocity.y = 1
        else
            player.velocity.y = 0
        end
    elseif key == 'n' then
        camera:setScale(loop(camera.scale + 1, 4))
    elseif key == 'm' then
        camera:scaleBy(0.5)
    end
end

function love.update(dt)
    local moveSpeed = 300
    local tau = math.pi * 2
    local rotateSpeed = tau * 0.05
    
    if love.keyboard.isDown('a') then translate(-moveSpeed * dt, 0) end
    if love.keyboard.isDown('d') then translate(moveSpeed * dt, 0) end

    if love.keyboard.isDown('x') then camera:increaseRotation(0 - rotateSpeed * dt) end
    if love.keyboard.isDown('c') then camera:increaseRotation(0 + rotateSpeed * dt) end

    if has_gravity then
        -- See https://love2d.org/wiki/Tutorial:Baseline_2D_Platformer
        if love.keyboard.isDown('w') or love.keyboard.isDown('space') then
            -- infinite jumps
            player.velocity.y = player.jump_height
        end
        if player.velocity.y ~= 0 then
            player.y = player.y + player.velocity.y * dt
            player.velocity.y = player.velocity.y - player.gravity * dt
        end

        local half_width = player.width * 0.5
        local bottom = world_dimensions[2] - half_width
        if player.y > bottom then
            player.velocity.y = 0
            player.y = bottom
        end
    else
        if love.keyboard.isDown('w') then translate(0, -moveSpeed * dt) end
        if love.keyboard.isDown('s') then translate(0, moveSpeed * dt) end
    end

    -- Chase the mouse to demonstrate converting mouse to world
    -- coordinates.
    local x,y = camera:getMouseWorldCoordinates()
    chaser.x = lerp(chaser.x, x, 0.025)
    chaser.y = lerp(chaser.y, y, 0.025)

    -- ## Update the camera and the target position. ##
    camera:update()
    camera:setTranslation(player.x, player.y)
end

local function draw_game()
    -- ## Draw the game here ##
    -- Draw world bounds.
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle('line', 0, 0, world_dimensions[1], world_dimensions[2])
    -- Draw the player (position is their centre)
    love.graphics.setColor(0, 1, 1, 1)
    local half_width = player.width * 0.5
    love.graphics.rectangle('fill', player.x - half_width, player.y - half_width, player.width, player.width)
    -- Populate the world with something.
    love.graphics.setColor(1, 0, 1, 1)
    for y=0,world_dimensions[2]-1,10 do
        for x=0,world_dimensions[1]-1,10 do
            if love.math.noise(x,y) > 0.98 then
                love.graphics.rectangle('fill', x, y, 10, 10)
            end
        end
    end
    -- Draw mouse position
    love.graphics.setColor(1, 1, 0, 1)
    local x,y = camera:getMouseWorldCoordinates()
    love.graphics.circle('fill', x,y, 7,7)
    love.graphics.setColor(0.5, 1, 0, 1)
    love.graphics.circle('fill', chaser.x,chaser.y, 7,7)
end

function love.draw()
    love.graphics.clear()
    camera:push() do
        -- ## Draw the game here ##
        draw_game()
    end camera:pop()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Physics: " .. (has_gravity and "Platformer" or "TopDown"), 0,0, 1000)

    local x,y = camera:getScreenCoordinates(world_dimensions[1]/2,world_dimensions[2]/2)
    love.graphics.circle("line", x,y, 5,5)
    love.graphics.printf("World Center", x,y, 100, 'center')
end

