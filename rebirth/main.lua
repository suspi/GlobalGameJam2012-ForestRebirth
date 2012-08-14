require "hump.vector"
require "hump.camera"
Class = require 'hump.class'

-- convenience
local vector = hump.vector
local camera = hump.camera

-- "constants"

SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
TOTAL_TREES = 1000
WIND_FIELD_RESOLUTION = TOTAL_TREES/40
TREE_FIELD_RESOLUTION = 200
TREE_PER_FIELD = 10
ARENA_WIDTH = TOTAL_TREES
ARENA_HEIGHT = TOTAL_TREES

Tree = Class{name = "Tree", function(self, size, xPos, yPos, flameHealth, particle)
    self.size = size
	self.xPos = math.min(math.max(10, xPos), ARENA_WIDTH-10)
	self.yPos = math.min(math.max(10, yPos), ARENA_HEIGHT-10)
	self.flameHealth = flameHealth
end}

function Tree:distanceTo(targetX, targetY)
    return math.sqrt((targetX-self.xPos)^2 + (targetY-self.yPos)^2)
end

function Tree:update()
	if self.flameHealth ~= 0 then
		self.flameHealth = self.flameHealth + 10
	elseif self.size <= 50 then
		if math.random(1, 10) == 1 then
			self.size = self.size + 1
		end
		if self.size > 17 and self.size < 50 and self.flameHealth == 0 and math.random(1,8) == 1 then
			newTree = Tree(1,		math.random(math.max(10, self.xPos-20), math.min(ARENA_WIDTH-10, self.xPos+20)),
									math.random(math.max(10, self.yPos-20), math.min(ARENA_HEIGHT-10, self.yPos+20)),
									0)
			if #newTree:getField() < WIND_FIELD_RESOLUTION/10 then
				table.insert(newTree:getField(), newTree)
			end
		end
	end
	if self.size >= 50 and math.random(1, 100) == 1 then
		self.flameHealth = 1
	end	
end

function Tree:getField()
	print(math.floor(self.xPos/WIND_FIELD_RESOLUTION))
	print(math.floor(self.yPos/WIND_FIELD_RESOLUTION))
	return treeField[math.floor(self.xPos/WIND_FIELD_RESOLUTION)][math.floor(self.yPos/WIND_FIELD_RESOLUTION)]
end

function Tree:getNearbyTrees()
	nearbyTrees = {}
	for k, v in pairs(self:getField()) do
		table.insert(nearbyTrees, v)
	end
	return nearbyTrees
end

function getRandomTree()
	--while randomTree = treeField[math.random(1, ARENA_WIDTH/WIND_FIELD_RESOLUTION)][math.random(1, ARENA_HEIGHT/WIND_FIELD_RESOLUTION)][0] ~= nil do

	--end
end

trees = {}
windField = {}
treeField = {}
score = 0
for i=0, ARENA_WIDTH/WIND_FIELD_RESOLUTION do
	treeField[i]={}
	for j=0, ARENA_HEIGHT/WIND_FIELD_RESOLUTION do
		treeField[i][j] = {}
	end
end


everyShape = {}
everyShapeIndex = 1
prevMouseX = 0
prevMouseY = 0
zoomDistance = 1
counter = 0
state = "starting"
tree_counter = 0

function love.load()
	-- convenience
	local gfx = love.graphics
	local phys = love.physics

	p = love.graphics.newParticleSystem( gfx.newImage("cloud.png"), 500 )
	p:setEmissionRate(100)
	p:setSpeed(300, 400)
	p:setGravity(0)
	p:setSize(2, 1)
	p:setColor(255, 0, 0, 255, 58, 128, 255, 0)
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
	for i=1,TOTAL_TREES/10 do
		newTree = Tree(math.random(1, 10),
		 							math.random(10, ARENA_WIDTH-10),
									math.random(10, ARENA_HEIGHT-10),
									0
									)
		table.insert(trees, newTree)
		table.insert(newTree:getField(), newTree)
	end

	--local startFire = trees[math.random(TOTAL_TREES)]
	--startFire.fireHealth = 1
	
	-- camera
	cam = camera.new(vector.new(ARENA_WIDTH/2, ARENA_HEIGHT/2))
	cam.moving = false
	cam.lastCoords = vector.new(-1, -1)
	
	for i=0, ARENA_WIDTH/WIND_FIELD_RESOLUTION do
		for j=0, ARENA_HEIGHT/WIND_FIELD_RESOLUTION do
			for k, v in pairs(treeField[i][j]) do
				--v.body = love.physics.newBody(world, v.xPos, v.yPos, 0, 0)
				--v.shape = love.physics.newCircleShape(v.body, 0, 0, v.size)
				--v.shape:setData(everyShapeIndex + 1)
				--newShapeIndex = {}
				--newShapeIndex["name"] = "Tree"
				--newShapeIndex["index"] = 0
				--table.insert(everyShape, newShapeIndex)
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
		
		counter = (counter + 1) % 3
		local i = 1
		local j = 1
		if counter == 0 then
			tree_counter = 0
			for i=0, ARENA_WIDTH/WIND_FIELD_RESOLUTION do
				for j=0, ARENA_HEIGHT/WIND_FIELD_RESOLUTION do
					for k, v in pairs(treeField[i][j]) do
						if v.flameHealth == 0 and v.size < 50 then
							tree_counter = tree_counter + 1
							score = score + (v.size * #treeField[i][j] * tree_counter)
						end
						if v.flameHealth > 0 and v.size < 17 then
							score = score - 1000
						end
						if v.flameHealth > 80 then
							for k, v in pairs(treeField[i][j]) do
								if treeField[i][j][k].size > 3 and math.random(1,treeField[i][j][k].size) == 1 then
									treeField[i][j][k].flameHealth = treeField[i][j][k].flameHealth + 1
								end
							end
							if i-1 ~= -1 then
								for k, v in pairs(treeField[i-1][j]) do
									if treeField[i-1][j][k].size > 3 and math.random(1,treeField[i-1][j][k].size) == 1 then
										treeField[i-1][j][k].flameHealth = treeField[i-1][j][k].flameHealth + 1
									end
								end
							end
							if i+1 ~= ARENA_WIDTH/WIND_FIELD_RESOLUTION +1 then
								for k, v in pairs(treeField[i+1][j]) do
									if treeField[i+1][j][k].size > 3 and math.random(1,treeField[i+1][j][k].size) == 1 then
										treeField[i+1][j][k].flameHealth = treeField[i+1][j][k].flameHealth + 1
									end
								end
							end
							if j-1 ~= -1 then
								for k, v in pairs(treeField[i][j-1]) do
									if treeField[i][j-1][k].size > 3 and math.random(1,treeField[i][j-1][k].size) == 1 then
										treeField[i][j-1][k].flameHealth = treeField[i][j-1][k].flameHealth + 1
									end
								end
							end
							if j+1 ~= ARENA_HEIGHT/WIND_FIELD_RESOLUTION +1 then
								for k, v in pairs(treeField[i][j+1]) do
									if treeField[i][j+1][k].size > 3 and math.random(1,treeField[i][j+1][k].size) == 1 then
										treeField[i][j+1][k].flameHealth = treeField[i][j+1][k].flameHealth + 1
									end
								end
							end
								
							if v.flameHealth > 90 then
								table.remove(treeField[i][j], k)
							end
						else
							v:update()
						end
					end
				end
			end
		end

		if love.mouse.isDown("l") and score > 10000000 then
			score = score - 10000000
			prevMouseX, prevMouseY = cam:mousepos():unpack()
			i = math.floor(prevMouseX/WIND_FIELD_RESOLUTION)
			j = math.floor(prevMouseY/WIND_FIELD_RESOLUTION)
			i = math.min(math.max(0, i), ARENA_WIDTH/WIND_FIELD_RESOLUTION)
			j = math.min(math.max(0, j), ARENA_HEIGHT/WIND_FIELD_RESOLUTION)
			
			newTree = Tree(1,		math.random(prevMouseX-20,prevMouseX+20),
									math.random(prevMouseY-20,prevMouseY+20),
									0)
			if #newTree:getField() < WIND_FIELD_RESOLUTION/10 then
				table.insert(newTree:getField(), newTree)
			end
			
			for k, v in pairs(treeField[i][j]) do
				if treeField[i][j][k].flameHealth > 0 then
					treeField[i][j][k].flameHealth = 0
					treeField[i][j][k].size = 1
					--treeField[i][j][k].size = math.min(treeField[i][j][k].size, 30)
				end
			end
			if i-1 ~= -1 then
				for k, v in pairs(treeField[i-1][j]) do
					if treeField[i-1][j][k].flameHealth > 0 then
						treeField[i-1][j][k].flameHealth = 0
						treeField[i-1][j][k].size = 1
						--treeField[i-1][j][k].size = math.min(treeField[i-1][j][k].size, 30)
					end
				end
			end
			if i+1 ~= ARENA_WIDTH/WIND_FIELD_RESOLUTION +1 then
				for k, v in pairs(treeField[i+1][j]) do
					if treeField[i+1][j][k].flameHealth > 0 then
						treeField[i+1][j][k].flameHealth = 0
						treeField[i+1][j][k].size = 1
						--treeField[i+1][j][k].size = math.min(treeField[i+1][j][k].size, 30)
					end
				end
			end
			if j-1 ~= -1 then
				for k, v in pairs(treeField[i][j-1]) do
					if treeField[i][j-1][k].flameHealth > 0 then
						treeField[i][j-1][k].flameHealth = 0
						treeField[i][j-1][k].size = 1
						--treeField[i][j-1][k].size = math.min(treeField[i][j-1][k].size, 30)
					end
				end
			end
			if j+1 ~= ARENA_HEIGHT/WIND_FIELD_RESOLUTION +1 then
				for k, v in pairs(treeField[i][j+1]) do
					if treeField[i][j+1][k].flameHealth > 0 then
						treeField[i][j+1][k].flameHealth = 0
						treeField[i][j+1][k].size = 1
						--treeField[i][j+1][k].size = math.min(treeField[i][j+1][k].size, 30)
					end
				end
			end
		end
	
			        -- ball.body:applyForce(1000 * dt, 0)
		p:update(dt)
		f:update(dt)
        -- update the physics world
        world:update(dt)
	end
    
	if love.mouse.isDown("r") then
		cam:translate(vector(
						(prevMouseX - love.mouse.getX()) * 1/cam.zoom, 
						(prevMouseY - love.mouse.getY()) * 1/cam.zoom))
		prevMouseX = love.mouse.getX()
		prevMouseY = love.mouse.getY()
	end

	
	

end

function drawTree(tree)
	if tree.flameHealth > 0 then
		love.graphics.setColor(math.min(tree.flameHealth+200,255), 50, 50)
	elseif tree.size > 30 then
		love.graphics.setColor(128,128,128)
	else
		love.graphics.setColor(128, 255, 128)
	end
	
	love.graphics.circle("fill", tree.xPos, tree.yPos, math.min(tree.size, 15))
	
	if tree.size < 30 and tree.flameHealth == 0 then
		love.graphics.setColor(0, 255, 0)
		love.graphics.circle("line", tree.xPos, tree.yPos, math.min(tree.size, 15))
	end
	--if tree.flameHealth > 0 then
	--	love.graphics.setColor(tree.flameHealth+128,128,128)
	--	love.graphics.print(tree.flameHealth,tree.xPos,tree.yPos,0,5)
	--end
end

function love.draw()
	-- convenience
	local gfx = love.graphics

	-- draw the world
	cam:predraw()

	-- draw arena
	
	gfx.setColor(76, 31, 7)
	gfx.rectangle("fill", 0, 0, ARENA_WIDTH, ARENA_HEIGHT)

	love.graphics.setColor(0, 255, 0)
	
	for i=0, ARENA_WIDTH/WIND_FIELD_RESOLUTION do
		for j=0, ARENA_HEIGHT/WIND_FIELD_RESOLUTION do
			for k, v in pairs(treeField[i][j]) do
				drawTree(treeField[i][j][k])
			end
		end
	end
	
	love.graphics.draw(p, 0, 0)
	love.graphics.draw(f, 0, 0)

	if love.mouse.isDown("l") then
		love.graphics.setColor(0, 0, 255)
		circleX, circleY = cam:mousepos():unpack()
		love.graphics.circle("line", circleX, circleY, WIND_FIELD_RESOLUTION * 1.5)	
	end
	
	-- done drawing the world
	cam:postdraw()
    gfx.setColor(255,255,255)
	gfx.print("Score: "..math.floor(score/100000000), 0,0, 0, 1)
	gfx.print("Combo: "..tree_counter, 0, 10, 0, 1)
	
	if state == "starting" then
        gfx.setColor(255, 255, 255)
        gfx.print("Click to start playing!", 300, 250, 0, 3, 3)
--gfx.print("Red planets are infected. Purple are targets", 300, 300, 0, 1, 1)
--gfx.print("Drag with right click to launch your invaders", 300, 320, 0,1, 1)
    end
	if state == "finished" then
        gfx.setColor(255, 255, 255)
        gfx.print("YOU WIN!", 300, 250, 0, 3, 3)
    end
end

function love.mousepressed(x, y, button)
    if state == "starting" then
        if button == "l" then
            -- start the game!
            state = "playing"
        end
    else
		if button == "r" then
			prevMouseX = love.mouse.getX()
			prevMouseY = love.mouse.getY()
		end
		if button == "l" then
			prevMouseX, prevMouseY = cam:mousepos():unpack()
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