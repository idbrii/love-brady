-- Demonstration of Brady
-- Creates a world with a player who can walk around the world.

local Camera = require('camera')

local mobileCam, overviewCam
local layer = {}

local world_dimensions = {1600,1200}
local has_gravity = false
local show_world = true

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

local offset = 32
local W, H = love.graphics.getDimensions()

local function resizeCamera( self, w, h )
	local scaleW, scaleH = w / self.w, h / self.h
	local scale = math.min( scaleW, scaleH )
	self.w, self.h = scale * self.w, scale * self.h
	self.aspectRatio = self.w / w
	self.offsetX, self.offsetY = self.w / 2, self.h / 2
	offset = offset * scale
end

local function drawCameraBounds( cam, mode )
	love.graphics.rectangle( mode, cam.x, cam.y, cam.w, cam.h )
end

local squares = {}
local function newSquare( x, y, w, h )
	table.insert( squares, {
			x = x - w / 2, y = y - h / 2,
			w = w, h = h,
			draw = function( self )
				love.graphics.rectangle( 'fill', self.x, self.y, self.w, self.h )
			end,
		} )
end

local function drawSquares()
	for _, square in ipairs( squares ) do square:draw() end
end

local function setColor255(r,g,b,a)
    r = r or 255
    g = g or 255
    b = b or 255
    a = a or 255
    love.graphics.setColor(r/255, g/255, b/255, a/255)
end

function love.load()
    mobileCam = Camera( W / 2 - 2 * offset, H - 2 * offset, {
            x = offset,
            y = offset,
            resizable = true,
            maintainAspectRatio = true,
            resizingFunction = function( self, w, h )
                resizeCamera( self, w, h )
                --~ local W, H = love.graphics.getDimensions()
                self.x = offset
                self.y = offset
            end,
            getContainerDimensions = function()
                --~ local W, H = love.graphics.getDimensions()
                return W / 2 - 2 * offset, H - 2 * offset
            end,
        } )

    -- Moves at the same speed as the main layer
    layer.close = mobileCam:addLayer( 'close', 2, { relativeScale = .5 } )
    layer.far = mobileCam:addLayer( 'far', .5 )

    overviewCam = Camera( W / 2 - 2 * offset,
        H - 2 * offset,
        { x = W / 2 + offset,
            y = offset,
            resizable = true,
            maintainAspectRatio = true,
            resizingFunction = function( self, w, h )
                resizeCamera( self, w, h )
                local W, H = love.graphics.getDimensions()
                self.x = W / 2 + offset
                self.y = offset
            end,
            getContainerDimensions = function()
                local W, H = love.graphics.getDimensions()
                return W / 2 - 2 * offset, H - 2 * offset
            end
        } )
    -- Start at player position.
    overviewCam:setTranslation(player.x, player.y)
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
    elseif key == 'j' then
        -- Allow disabling the "world" to showcase the previous parallax demo.
        show_world = not show_world
    elseif key == 'n' then
        mobileCam:setScale(loop(mobileCam.scale + 1, 4))
    elseif key == 'm' then
        mobileCam:scaleBy(0.5)
	elseif key == 'k' then squares = {}
	elseif key == 'o' then
		mobileCam:setTranslation( 0, 0 )
		mobileCam:setRotation( 0, 0 )
		mobileCam:setScale( 1 )
	elseif key == 'r' then
		love.keyreleased( 'o' )
		love.keyreleased( 'c' )
    end
end

function love.wheelmoved( dx, dy )
	mobileCam:scaleToPoint( 1 + dy / 10 )
end

function love.update(dt)
	local moveSpeed = 300 / mobileCam.scale
    local tau = math.pi * 2
    local rotateSpeed = tau * 0.05
    
    if love.keyboard.isDown('a') then translate(-moveSpeed * dt, 0) end
    if love.keyboard.isDown('d') then translate(moveSpeed * dt, 0) end

    if love.keyboard.isDown('x') then mobileCam:increaseRotation(0 - rotateSpeed * dt) end
    if love.keyboard.isDown('c') then mobileCam:increaseRotation(0 + rotateSpeed * dt) end

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

	if love.mouse.isDown( 1 ) then
		local x, y = love.mouse.getPosition()
		if  x > mobileCam.x and x < mobileCam.x + mobileCam.w
			and y > mobileCam.y and y < mobileCam.y + mobileCam.h then
			local newX, newY = mobileCam:getWorldCoordinates( x, y )
			newSquare( newX, newY, offset / mobileCam.scale, offset / mobileCam.scale )
		end
		if  x > overviewCam.x and x < overviewCam.x + overviewCam.w
			and y > overviewCam.y and y < overviewCam.y + overviewCam.h then
			local newX, newY = overviewCam:getWorldCoordinates( x, y )
			newSquare( newX, newY, offset / mobileCam.scale, offset / mobileCam.scale )
		end
	end


    -- Chase the mouse to demonstrate converting mouse to world
    -- coordinates.
    local x,y = mobileCam:getMouseWorldCoordinates()
    chaser.x = lerp(chaser.x, x, 0.025)
    chaser.y = lerp(chaser.y, y, 0.025)

    -- ## Update the camera and the target position. ##
    mobileCam:setTranslation(player.x, player.y)
	mobileCam:update()
	overviewCam:update()
end

local function draw_game(cam)
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
    local x,y = cam:getMouseWorldCoordinates()
    love.graphics.circle('fill', x,y, 7,7)
    love.graphics.setColor(0.5, 1, 0, 1)
    love.graphics.circle('fill', chaser.x,chaser.y, 7,7)
end

function love.draw()
	drawCameraBounds( mobileCam, 'line' )
	drawCameraBounds( overviewCam, 'line' )

	-- Keep squares from bleeding
	love.graphics.stencil( function() drawCameraBounds( mobileCam, 'fill' ) end, 'replace', 1 )
	love.graphics.setStencilTest( 'greater', 0 )
	mobileCam:push() do
		layer.far:push() do
			setColor255( 255, 0, 0, 25 )
			drawSquares()
		end layer.far:pop()

		setColor255( 0, 255, 0, 255 )
		drawSquares()
        -- ## Draw the game here ##
        if show_world then
            draw_game(mobileCam)
        end

		-- Either method is acceptable
		mobileCam:push( 'close' ) do
			setColor255( 0, 0, 255, 25 )
			drawSquares()
		end mobileCam:pop( 'close' )
	end mobileCam:pop()

	setColor255(255,255,255)
    local x,y = mobileCam:getScreenCoordinates(world_dimensions[1]/2,world_dimensions[2]/2)
    love.graphics.circle("line", x,y, 5,5)
    love.graphics.printf("World Center", x,y, 100, 'center')

	love.graphics.setColor(1,1,1,1)
	love.graphics.stencil( function() drawCameraBounds( overviewCam, 'fill' ) end, 'replace', 1 )
	love.graphics.setStencilTest( 'greater', 0 )
	overviewCam:push() do
		drawSquares()
	end overviewCam:pop()

	love.graphics.setStencilTest()
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Physics: " .. (has_gravity and "Platformer" or "TopDown"), 0,0, 1000)
end

--~ require('parallax')
