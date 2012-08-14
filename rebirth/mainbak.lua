require "hump.vector"
require "hump.camera"
Class = require 'hump.class'

-- convenience
local vector = hump.vector
local camera = hump.camera

-- "constants"
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
GRAVITY_FIELD_RESOLUTION = 100
PROJECTILE_FIRE_CONTROL = .5
PROJECTILE_SIZE = 25
TOTAL_PLANETS = 30
ARENA_WIDTH = TOTAL_PLANETS * 200
ARENA_HEIGHT = TOTAL_PLANETS * 200

Planet = Class{name = "Planet", function(self, size, xPos, yPos, gravMass, resourceRate, techRate, populationCap)
    self.size = size
    self.xPos = xPos
	self.yPos = yPos
	self.gravMass = size
	self.resourceRate = resourceRate
	self.techRate = techRate
	self.populationCap = size*10
	self.playerOwned = false
	self.currentPopulation = 0
	self.counter = 0
end}

function Planet:distanceTo(targetX, targetY)
    return math.sqrt((targetX-self.xPos)^2 + (targetY-self.yPos)^2)
end

function Planet:getResource(player)
	return populationTable[player] * self.resourceRate
end
	
function Planet:refreshPopulation()
	self.counter = self.counter + 1
	if self.counter == 5 then
		if self.playerOwned == true then
			self.currentPopulation = math.floor(self.currentPopulation + self.currentPopulation * self.populationCap/100000) + 1
			if self.currentPopulation > self.populationCap then
				self.currentPopulation = self.populationCap
			end

		end
		self.counter = 0
	end
end

Projectile = Class{name = "Projectile", function(self, position, vector)
	self.position = position
	self.vector = vector
end}

planets = {}
gravityField = {}
gravityFieldDraw = {}
projectiles = {}
projectilesIndex = 1
projectilesPending = {}
everyShape = {}
everyShapeIndex = 1

-- data about the boxes
boxes = {}

-- what state is the game in? (starting, playing, finished)
state = "starting"
prevMouseX = 0
prevMouseY = 0
zoomDistance = 1
planetSelection = {}
planetSelection["x"] = 0
planetSelection["y"] = 0
planetSelection["size"] = 0

function calculateGravity(projectile)
	totalField = vector(0,0)
	for k, v in pairs(planets) do
		magnitude = v.gravMass / v:distanceTo(testX, testY)^2
		vectorToPlanet = vector(v.xPos-testX, v.yPos-testY)
		gravityField[i*GRAVITY_FIELD_RESOLUTION+j] = gravityField[i*GRAVITY_FIELD_RESOLUTION+j] + (magnitude * vector(vectorToPlanet * vector(1, 0), vectorToPlanet * vector(0, 1)))
		--gravityField[i*GRAVITY_FIELD_RESOLUTION+j] = gravityField[i*GRAVITY_FIELD_RESOLUTION+j] + magnitude * vectorToPlanet
	end
end

function add(a, b, coll)
	p:setPosition(coll:getPosition())
	p:start()
	--[[
	if everyShape[a]["name"] == "Projectile" then
		aIndex = everyShape[a]["index"]
		if projectiles[aIndex]["shape"]~= nil then
			projectiles[aIndex]["shape"] = nil
			projectiles[aIndex]["body"] = nil
		end
	end

	if everyShape[b]["name"] == "Projectile" then
		bIndex = everyShape[b]["index"]
		if projectiles[bIndex]["shape"]~= nil then
			projectiles[bIndex]["shape"] = nil
			projectiles[bIndex]["body"] = nil
		end
	end
	]]--
	--[[
	if a~=nil then
		aBody = a:getData()
		if aBody:isBullet() == true then
			aBody = nil
		end
	end
	if b~=nil then
		bBody = b:getData()
		if bBody:isBullet() == true then
			bBody = nil
		end
	end
	]]--
end

function love.load()
	-- convenience
	local gfx = love.graphics
	local phys = love.physics

	p = love.graphics.newParticleSystem( gfx.newImage("cloud.png"), 500 )
	p:setEmissionRate(100)
	p:setSpeed(300, 400)
	p:setGravity(0)
	p:setSize(2, 1)
	p:setColor(255, 255, 255, 255, 58, 128, 255, 0)
	p:setPosition(400, 300)
	p:setLifetime(1)
	p:setParticleLife(1)
	p:setDirection(0)
	p:setSpread(360)
	p:setRadialAcceleration(-2000)
	p:setTangentialAcceleration(1000)
	p:stop()
	
	f = love.graphics.newParticleSystem(gfx.newImage("part1.png"), 1000)
	f:setEmissionRate(1000)
	f:setSpeed(300, 400)
	f:setSize(2, 1)
	f:setColor(220, 105, 20, 255, 194, 30, 18, 0)
	f:setPosition(400, 300)
	f:setLifetime(0.1)
	f:setParticleLife(0.2)
	f:setDirection(0)
	f:setSpread(360)
	f:setTangentialAcceleration(1000)
	f:setRadialAcceleration(-2000)
	f:stop()
	
	-- set background color
	gfx.setBackgroundColor(150, 150, 150)
	
	-- create a new physics world
	world = phys.newWorld(0, 0, ARENA_WIDTH, ARENA_HEIGHT)

	-- Randomize the random function
	math.randomseed( os.time() )

	-- Insert the planets into the table
	for i=1,TOTAL_PLANETS do
		table.insert(planets, Planet(math.random(10, 150),
		 							math.random(100, ARENA_WIDTH-100),
									math.random(100, ARENA_HEIGHT-100), 
									math.random(),
									math.random(),
									math.random(),
									math.random(100, 1000)))
	end

	local startPlanet = planets[math.random(TOTAL_PLANETS)]
	startPlanet.playerOwned = true
	startPlanet.currentPopulation = 100
	
	-- camera
	cam = camera.new(vector.new(startPlanet.xPos, startPlanet.yPos))
	cam.moving = false
	cam.lastCoords = vector.new(-1, -1)
	
	for k, v in pairs(planets) do
		v.body = love.physics.newBody(world, v.xPos, v.yPos, 0, 0)
		v.shape = love.physics.newCircleShape(v.body, 0, 0, v.size)
		v.shape:setData(everyShapeIndex + 1)
		newShapeIndex = {}
		newShapeIndex["name"] = "Planet"
		newShapeIndex["index"] = 0
		table.insert(everyShape, newShapeIndex)
	end
	
    for i=1, GRAVITY_FIELD_RESOLUTION, 1 do
		for j=1, GRAVITY_FIELD_RESOLUTION, 1 do
			gravityField[i*GRAVITY_FIELD_RESOLUTION+j] = vector(0,0)
			testX = i*ARENA_WIDTH/GRAVITY_FIELD_RESOLUTION
			testY = j*ARENA_HEIGHT/GRAVITY_FIELD_RESOLUTION
			for k, v in pairs(planets) do
				magnitude = 10*(v.gravMass / (v:distanceTo(testX, testY))^2)^1.3
				if magnitude < 0.0001 then
					magnitude = 0
				end
				vectorToPlanet = vector(v.xPos-testX, v.yPos-testY)
				if magnitude < .005 then
					gravityFieldDraw[i*GRAVITY_FIELD_RESOLUTION+j] = false
				else
					gravityFieldDraw[i*GRAVITY_FIELD_RESOLUTION+j] = false
				end
				gravityField[i*GRAVITY_FIELD_RESOLUTION+j] = gravityField[i*GRAVITY_FIELD_RESOLUTION+j] + (magnitude * vectorToPlanet)
				--gravityField[i*GRAVITY_FIELD_RESOLUTION+j] = gravityField[i*GRAVITY_FIELD_RESOLUTION+j] + magnitude * vectorToPlanet
			end
		end
	end
			
	world:setCallbacks(add, persist, rem, result)
end


gravX = 0
gravY = 0

function love.update(dt)
	if state == "reload" then
		love.load()
	end
    -- update based on the state
    if state == "playing" then
        
        -- apply 1000 units/sec force in the x direction

		local i = 1
		local j = 1
	--[[	
		while i*ARENA_WIDTH/GRAVITY_FIELD_RESOLUTION-1<ball.body:getX() do
			i = i+1
		end
		while j*ARENA_HEIGHT/GRAVITY_FIELD_RESOLUTION-1<ball.body:getY() do
			j = j+1
		end
		
		interpX = (ball.body:getX()-i*ARENA_WIDTH/GRAVITY_FIELD_RESOLUTION)/GRAVITY_FIELD_RESOLUTION
		interpY = (ball.body:getY()-j*ARENA_HEIGHT/GRAVITY_FIELD_RESOLUTION)/GRAVITY_FIELD_RESOLUTION
		topLeft = gravityField[i*GRAVITY_FIELD_RESOLUTION+j]		
		topRight = gravityField[(i+1)*GRAVITY_FIELD_RESOLUTION+j]
		bottomLeft = gravityField[i*GRAVITY_FIELD_RESOLUTION+j+1]
		bottomRight = gravityField[(i+1)*GRAVITY_FIELD_RESOLUTION+j+1]
		topGravity = topLeft + interpX * (topRight - topLeft)
		bottomGravity = bottomLeft + interpX * (bottomRight - bottomLeft)
		totalGravity = topGravity + interpY * (topGravity - bottomGravity)
		gravX, gravY = totalGravity:unpack()
		ball.body:applyForce(totalGravity:unpack())
]]--
		for i=1, #projectilesPending, 1 do
			if projectilesPending[i]["size"] > 0 then
				local newParticle = {}
				newParticle["body"] = love.physics.newBody(world, projectilesPending[i]["newParticlePosX"], projectilesPending[i]["newParticlePosY"], 5, 0 )
				newParticle["body"]:setBullet(true)
				newParticle["body"]:applyImpulse((PROJECTILE_FIRE_CONTROL*projectilesPending[i]["newParticleVector"]):unpack())
				newParticle["shape"] = love.physics.newCircleShape(newParticle["body"], 0, 0, 5)
				newParticle["shape"]:setData(#everyShape + 1)
				newParticle["size"] = math.floor(projectilesPending[i]["newParticleVector"]:len())
				table.insert(projectiles, newParticle)
				newShapeIndex["name"] = "Projectile"
				newShapeIndex["index"] = #projectiles
				table.insert(everyShape, newShapeIndex)
				if projectilesPending[i]["size"] - PROJECTILE_SIZE <= 0 then
					table.remove(projectilesPending, i)
				else
					projectilesPending[i]["size"] = projectilesPending[i]["size"] - PROJECTILE_SIZE
				end
			end
		end

		for i=1, #projectiles, 1 do
			local projectileX, projectileY = projectiles[i]["body"]:getPosition()
			if projectiles[i]["shape"] ~= nil then
				local projectileX, projectileY = projectiles[i]["body"]:getPosition()
				for k,v in pairs(planets) do
					if v:distanceTo(projectileX, projectileY) <= v.size+10 then
						projectiles[i]["shape"] = nil
						if v.playerOwned == false then
							v.playerOwned = true
						end
						v.currentPopulation = math.ceil(v.currentPopulation + PROJECTILE_SIZE/10)
					end
				end
			end
			if projectiles[i]["shape"] ~= nil then
				if projectileX <= 10 or projectileX >= ARENA_WIDTH - 10 or
					projectileY <= 10 or projectileY >= ARENA_HEIGHT - 10 then
					projectiles[i]["shape"]=nil
				else
					local k = 2
					j = 2
					while k*ARENA_WIDTH/GRAVITY_FIELD_RESOLUTION<projectiles[i]["body"]:getX() do
						k = k+1
					end	
					while j*ARENA_HEIGHT/GRAVITY_FIELD_RESOLUTION<projectiles[i]["body"]:getY() do
						j = j+1
					end
			
					k=k-1
					j=j-1
			
					interpX = (projectiles[i]["body"]:getX()-k*ARENA_WIDTH/GRAVITY_FIELD_RESOLUTION)/GRAVITY_FIELD_RESOLUTION
					interpY = (projectiles[i]["body"]:getY()-j*ARENA_HEIGHT/GRAVITY_FIELD_RESOLUTION)/GRAVITY_FIELD_RESOLUTION
					topLeft = gravityField[k*GRAVITY_FIELD_RESOLUTION+j]		
					topRight = gravityField[(k+1)*GRAVITY_FIELD_RESOLUTION+j]
					bottomLeft = gravityField[k*GRAVITY_FIELD_RESOLUTION+j+1]
					bottomRight = gravityField[(k+1)*GRAVITY_FIELD_RESOLUTION+j+1]
					topGravity = topLeft + interpX * (topRight - topLeft)
					bottomGravity = bottomLeft + interpX * (bottomRight - bottomLeft)
					projectileGravity = topGravity + interpY * (topGravity - bottomGravity)
			
					projectiles[i]["body"]:applyForce((100*projectileGravity):unpack())
				--	projectiles[i]["body"]:applyImpulse((math.random()-.5)*10, (math.random()-.5)*10)
				end
			end
		end

		for k, v in pairs(planets) do
			v:refreshPopulation()
		end

		
        -- ball.body:applyForce(1000 * dt, 0)
		p:update(dt)
		f:update(dt)
        -- update the physics world
        world:update(dt)
        
    	elseif state == "finished" then
        
        -- update the physics world
        world:update(dt)
        
    end
    
	if love.mouse.isDown("l") then
		if planetSelected == false then
			cam:translate(vector(
							(prevMouseX - love.mouse.getX()) * 1/cam.zoom, 
							(prevMouseY - love.mouse.getY()) * 1/cam.zoom))
			prevMouseX = love.mouse.getX()
			prevMouseY = love.mouse.getY()
		end
	end
    
end

function drawPlanet(planet)
	if planet.playerOwned == false then
		love.graphics.setColor(255, 0, 255)
	else
		love.graphics.setColor(255, 0, 0)
	end
	love.graphics.circle("fill", planet.xPos, planet.yPos, planet.size)
	if planet.playerOwned == true then
		love.graphics.setColor(255,255,255)
		love.graphics.print(planet.currentPopulation,planet.xPos,planet.yPos,0,5)
	end
end

function love.draw()
	-- convenience
	local gfx = love.graphics

	-- draw the world
	cam:predraw()

	-- draw arena
	gfx.setColor(0, 0, 0)
	gfx.rectangle("fill", 0, 0, ARENA_WIDTH, ARENA_HEIGHT)

	love.graphics.setColor(0, 255, 0)
	
	for i=1, GRAVITY_FIELD_RESOLUTION, 1 do
		for j=1, GRAVITY_FIELD_RESOLUTION, 1 do
			testX = i*ARENA_WIDTH/GRAVITY_FIELD_RESOLUTION
			testY = j*ARENA_HEIGHT/GRAVITY_FIELD_RESOLUTION
			if gravityFieldDraw[i*GRAVITY_FIELD_RESOLUTION+j] == true then
				gravXoutput, gravYoutput = gravityField[i*GRAVITY_FIELD_RESOLUTION+j]:unpack()
				love.graphics.line(testX, testY, testX+100*gravXoutput, testY+100*gravYoutput)
			end
		end
	end
	
	local totalInvaders = 0
	local totalPlanetsCaptured = 0
	local totalPlanetsRemaining = 0
	for k, v in pairs(planets) do
		drawPlanet(planets[k])
		if v.playerOwned == true then
			totalInvaders = totalInvaders + v.currentPopulation
			totalPlanetsCaptured = totalPlanetsCaptured + 1
		else
			totalPlanetsRemaining = totalPlanetsRemaining + 1
		end
	end
	
	love.graphics.draw(p, 0, 0)
	love.graphics.draw(f, 0, 0)
	if planetSelected == true then
		local currentMousePosX, currentMousePosY = cam:mousepos():unpack()
		
		gfx.setColor(0,255,0)
		gfx.rectangle("line", planetSelection["x"]-planetSelection["size"], planetSelection["y"]-planetSelection["size"], planetSelection["size"]*2, planetSelection["size"]*2)
		
		if love.mouse.isDown( "r") then 
		
			gfx.setColor(0, 255, 255)
			gfx.line(planets[planetSelection["key"]].xPos, planets[planetSelection["key"]].yPos, currentMousePosX, currentMousePosY)
		
			local newParticleVector = vector(currentMousePosX - planets[planetSelection["key"]].xPos, currentMousePosY - planets[planetSelection["key"]].yPos) * PROJECTILE_FIRE_CONTROL
		
			love.graphics.print(math.floor(newParticleVector:len()),currentMousePosX-10,currentMousePosY-10,0,5)
		end
	end

	gfx.setColor(0, 255, 255)
	for i=1, #projectiles, 1 do
		if projectiles[i]["shape"] ~= nil then
			love.graphics.circle("fill", projectiles[i]["body"]:getX(), projectiles[i]["body"]:getY(), 5)
		end
	end
	

	
	-- done drawing the world
	cam:postdraw()
    gfx.setColor(255,255,255)
	gfx.print("Invaders: "..totalInvaders, 0,0, 0, 1)
    gfx.print("Planets Captured: "..totalPlanetsCaptured, 0,10, 0, 1)
	gfx.print("Planets Remaining: "..totalPlanetsRemaining, 0,20, 0, 1)
	if totalPlanetsRemaining == 0 then
		state = "finished"
	end
	if state == "starting" then
        gfx.setColor(255, 255, 255)
        gfx.print("Click to start playing!", 300, 250, 0, 3, 3)
gfx.print("Red planets are infected. Purple are targets", 300, 300, 0, 1, 1)
gfx.print("Drag with right click to launch your invaders", 300, 320, 0,1, 1)
    end
	if state == "finished" then
        gfx.setColor(255, 255, 255)
        gfx.print("YOU WIN!", 300, 250, 0, 3, 3)
    end

end

--[[
function love.keypressed(key, unicode)
    if key == " " and ball.body:getY() > ARENA_HEIGHT - ball.RADIUS - 20 then
        ball.body:applyImpulse(0, -280)
    end
	if key == "a" then
		ball.body:applyForce(-280, 0)
	end
	if key == "d" then
		ball.body:applyForce(280, 0)
	end
	if key == "w" then
		ball.body:applyForce(0, -280)
	end
	if key == "s" then
		ball.body:applyForce(0, 280)
	end
end
]]--
function love.mousepressed(x, y, button)
    if state == "starting" then
    
        if button == "l" then
            -- start the game!
            state = "playing"
        end
    else
		if button == "l" or button == "r" then
			planetSelected = false
			for k, v in pairs(planets) do
				if v:distanceTo(cam:mousepos():unpack()) <= v.size then
					planetSelected = true
					planetSelection["key"] = k
					planetSelection["x"] = v.xPos
					planetSelection["y"] = v.yPos
					planetSelection["size"] = v.size
				end
			end
			prevMouseX = love.mouse.getX()
			prevMouseY = love.mouse.getY()
		end
		if button == "wd" then
			--zoom out
			--cam = camera.new(vector.new(SCREEN_WIDTH / 4, ARENA_HEIGHT / 2))
			zoomDistance = zoomDistance - .05
			if zoomDistance <= 0 then
				zoomDistance = .05
			end
			cam.zoom = zoomDistance
		end
		if button == "wu" then
			--zoom in
			zoomDistance = zoomDistance + .05
			cam.zoom = zoomDistance
		end
    end
end

function love.mousereleased( x, y, button )
	if planetSelected == true then
		if planets[planetSelection["key"]].currentPopulation ~= 0 and planets[planetSelection["key"]].playerOwned == true and button == "r" then
			local newParticle = {}
			local currentMousePosX, currentMousePosY = cam:mousepos():unpack()
			local newParticlePosition = vector(currentMousePosX - planets[planetSelection["key"]].xPos, currentMousePosY - planets[planetSelection["key"]].yPos):normalized()
			newParticlePosition = (planetSelection["size"]+20) * newParticlePosition
			newParticlePosition = newParticlePosition + vector(planets[planetSelection["key"]].xPos, planets[planetSelection["key"]].yPos)
			local newParticleVector = vector(currentMousePosX - planets[planetSelection["key"]].xPos, currentMousePosY - planets[planetSelection["key"]].yPos) * PROJECTILE_FIRE_CONTROL
			if math.floor(newParticleVector:len()) > planets[planetSelection["key"]].currentPopulation then
				newParticleVector = newParticleVector:normalized() * (planets[planetSelection["key"]].currentPopulation)
			end
			planets[planetSelection["key"]].currentPopulation = planets[planetSelection["key"]].currentPopulation - math.ceil(newParticleVector:len())
			newParticlePosX, newParticlePosY = newParticlePosition:unpack()
			
			newParticleData = {}
			newParticleData["newParticlePosX"] = newParticlePosX
			newParticleData["newParticlePosY"] = newParticlePosY
			newParticleData["newParticleVector"] = newParticleVector
			newParticleData["size"] = math.floor(newParticleVector:len())
			table.insert(projectilesPending, newParticleData)

			if planets[planetSelection["key"]].currentPopulation <= 0 then
				planets[planetSelection["key"]].playerOwned = false
				planets[planetSelection["key"]].currentPopulation = 0
			end
			planetSelected = false
		end
	end
end