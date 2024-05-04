local batteries = require("lib.batteries")
batteries:export()

pubsub:new()

log = require("lib.log")

local peachy = require("lib.peachy")

local Guy = require("guy")

love.graphics.setLineStyle("rough")

local buildingsImage = love.graphics.newImage("assets/buildings.png")
local cloudImage = love.graphics.newImage("assets/cloud.png")

local game = class({
	name = "game"
})

function game:new()
end

local noiseSource = love.audio.newSource("assets/noise.wav", "stream")
local walkingSource = love.audio.newSource("assets/walk.wav", "static")

function game:initialize()
	self.music = love.audio.newSource("assets/music.wav", "stream")
	self.music:setLooping(true)
	self.music:setVolume(0.1)
	self.music:play()

	self.guys = {}
	self.deaths = 0
	self.maxTimeLimit = 120
	self.timeLimit = self.maxTimeLimit

	self.guySpawningTimer = 0
	self.guyMaxSpawningTimer = 1

	self.cloudSpawningTimer = 0
	self.maxCloudSpawningTimer = 2

	self.windDirectionTimer = 0
	self.windDirectionMaxTimer = 5

	self.windDirection = -1

	pubsub:subscribe("guyDied", function(guy)
		self.deaths = self.deaths + 1
	end)

	self.umbrella = {
		position = vec2(love.graphics.getWidth() / 2 - 16, 48),
		sprite = love.graphics.newImage("assets/umbrella.png"),
		speed = 100
	}
	
	self.clouds = {}
	self.rainDrops = {}

	local rainImage = love.graphics.newImage("assets/rain.png")
	for _ = 1, 100 do
		local raindrop = {
			position = vec2(-1000, -1000)
		}

		local sprite = peachy.new("assets/rain.json", rainImage, "Idle")
		sprite:onLoop(function()
			if self.maxCloudSpawningTimer then
				if #self.clouds == 0 then
					return
				end

				local cloud = tablex.pick_random(self.clouds)
				local raindropX = cloud.x + love.math.random(0, 64)
				local raindropY = love.math.random(96, love.graphics.getHeight())
				raindrop.position = vec2(raindropX, raindropY)
				return
			end

			raindrop.position = vec2(love.math.random(0, love.graphics.getWidth()),
				love.math.random(96, love.graphics.getHeight()))
		end)

		raindrop.sprite = sprite
		table.insert(self.rainDrops, raindrop)
	end
end

local doors = {
	{ x = 172, y = 161, w = 20, h = 1030},
	{ x = 275, y = 161, w = 20, h = 1030},
	{ x = 378, y = 161, w = 20, h = 1030},
	{ x = 485, y = 161, w = 20, h = 1030},
}

local safeZones = functional.map(doors, function(door)
	return {
		x = door.x - 6,
		y = door.y - 32,
		w = door.w + 12
	}
end)

local function aabb(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

function game:addCloud(x)
	local cloud = {
		sprite = peachy.new("assets/cloud.json", cloudImage, "Idle"),
		x = x,
		y = love.math.random(0, 32),
		source = noiseSource:clone()
	}

	cloud.source:setLooping(true)
	cloud.source:setPosition(cloud.x, cloud.y, 0)
	cloud.source:play()

	table.insert(self.clouds, cloud)
end

function game:update(dt)
	love.audio.setPosition(self.umbrella.position.x, self.umbrella.position.y, 0)
	--love.audio.setPosition(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2, 0)
	self.timeLimit = self.timeLimit - dt
	
	if self.timeLimit <= 0 then
		_G.currentState = _G.states.gameOver
		self.music:stop()
		return
	end

	if #self.guys > 0 then
		walkingSource:setPosition(self.umbrella.position.x, self.umbrella.position.y, 0)
		walkingSource:setLooping(true)
		walkingSource:setVolume(0.1)
		walkingSource:play()
	end

	for _, guy in ipairs(self.guys) do
		guy:update(dt)

		local safe = true
		local guyInTheSky = vec2(guy.position.x, guy.position.y - 1000)

		if self.maxCloudSpawningTimer then
			for _, cloud in ipairs(self.clouds) do
				if intersect.line_line_collide(guy.position, guyInTheSky, 0, vec2(cloud.x, cloud.y), vec2(cloud.x + 64, cloud.y), 0) then
					safe = false
					break
				end
			end

			if safe then
				goto continue
			end
		else
			safe = false
		end

		for _, v in ipairs(safeZones) do
			if aabb(guy.position.x, guy.position.y, 32, 32, v.x, v.y, v.w, love.graphics.getHeight()) then
				safe = true
				break
			end
		end

		if not safe and intersect.line_line_collide(guy.position, guyInTheSky, 0, vec2(self.umbrella.position.x, self.umbrella.position.y), vec2(self.umbrella.position.x + 64, self.umbrella.position.y), 0) then
			if aabb(guy.position.x, guy.position.y, 32, 32, self.umbrella.position.x, self.umbrella.position.y + 64, 64, love.graphics.getHeight()) then
				safe = true
			end
		end

		if not safe then
			guy.health = guy.health - dt
		end

		::continue::
		guy.safe = safe
	end

	for _, rainDrop in ipairs(self.rainDrops) do
		rainDrop.sprite:update(dt)
	end

	self.guySpawningTimer = self.guySpawningTimer + dt

	if self.guySpawningTimer >= self.guyMaxSpawningTimer then
		local y = 310 - 32

		if love.math.random() < 0.5 then
			x = 0
		else
			x = 640 - 32
		end

		local guy = Guy(x, y)
		guy.destinationDoor = tablex.pick_random(doors)
		--guy.source = walkingSource:clone()
		--guy.source:setLooping(true)
		--guy.source:play()

		table.insert(self.guys, guy)
		self.guySpawningTimer = 0
	end

	self.cloudSpawningTimer = self.cloudSpawningTimer + dt

	if self.maxCloudSpawningTimer then
		if self.cloudSpawningTimer >= self.maxCloudSpawningTimer then
			if self.maxCloudSpawningTimer <= 1 then
				self.maxCloudSpawningTimer = nil
			end

			if self.windDirection > 0 then
				x = 0
			else
				x = 640 - 64
			end

			self:addCloud(x)
			self.cloudSpawningTimer = 0

			if self.maxCloudSpawningTimer then
				self.maxCloudSpawningTimer = self.maxCloudSpawningTimer - 0.1
			end
		end
	end

	self.windDirectionTimer = self.windDirectionTimer + dt

	if self.windDirectionTimer >= self.windDirectionMaxTimer then
		self.windDirection = -self.windDirection
		self.windDirectionTimer = 0
	end

	for _, cloud in ipairs(self.clouds) do
		cloud.x = cloud.x + self.windDirection * 50 * dt

		cloud.source:setPosition(cloud.x, cloud.y, 0)
	end

	if love.keyboard.isDown("a") then
		self.umbrella.position.x = self.umbrella.position.x - self.umbrella.speed * dt
	elseif love.keyboard.isDown("d") then
		self.umbrella.position.x = self.umbrella.position.x + self.umbrella.speed * dt
	end
end

function game:rainStencil()
	love.graphics.setColorMask(false, false, false, false)

	for _, safeZone in ipairs(safeZones) do
		love.graphics.rectangle("fill", safeZone.x, safeZone.y, safeZone.w, love.graphics.getHeight())
	end

	love.graphics.rectangle("fill", self.umbrella.position.x, self.umbrella.position.y + 64, 64, love.graphics.getHeight())
	love.graphics.rectangle("fill", 0, 311, love.graphics.getWidth(), love.graphics.getHeight())

	love.graphics.setColorMask(true, true, true, true)
end

function game:draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(buildingsImage, 0, 0)

	for _, guy in ipairs(self.guys) do
		if not guy.safe then
			love.graphics.setColor(1, 0, 0)
		else
			love.graphics.setColor(1, 1, 1)
		end

		guy:draw()
	end

	love.graphics.setColor(1, 1, 1)
	for _, cloud in ipairs(self.clouds) do
		cloud.sprite:draw(cloud.x, cloud.y)
	end

	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(self.deaths, 0, love.graphics.getHeight() - 100, love.graphics.getWidth(), "center")

	love.graphics.rectangle("fill", 0, 0, (self.timeLimit / self.maxTimeLimit) * love.graphics.getWidth(), 8)

	love.graphics.draw(self.umbrella.sprite, mathx.round(self.umbrella.position.x), mathx.round(self.umbrella.position.y))
	love.graphics.line(self.umbrella.position.x, self.umbrella.position.y + 36, self.umbrella.position.x, 311)
	love.graphics.line(self.umbrella.position.x + 64, self.umbrella.position.y + 36, self.umbrella.position.x + 64, 311)

	love.graphics.setStencilMode("increment", "always", 1)
	self:rainStencil()
	love.graphics.setStencilMode()

	love.graphics.setStencilMode("keep", "equal", 0)
	love.graphics.setColor(1, 1, 1)

	for _, rainDrop in ipairs(self.rainDrops) do
		rainDrop.sprite:draw(rainDrop.position.x, rainDrop.position.y)
	end

	--love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	love.graphics.setStencilMode()
end

return game