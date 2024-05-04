local batteries = require("lib.batteries")
batteries:export()

pubsub:new()

log = require("lib.log")

local peachy = require("lib.peachy")

local guys = {}

local Guy = require("guy")

love.graphics.setLineStyle("rough")

local buildingsImage = love.graphics.newImage("assets/buildings.png")

local deaths = 0

function love.load()
	pubsub:subscribe("guyDied", function(guy)
		deaths = deaths + 1
	end)
end

local umbrella = {
	position = vec2(love.graphics.getWidth() / 2 - 16, 32),
	sprite = love.graphics.newImage("assets/umbrella.png"),
	speed = 100
}

local guySpawningTimer = 0
local guyMaxSpawningTimer = 1

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

local rainDrops = {}

local rainImage = love.graphics.newImage("assets/rain.png")

for _ = 1, 100 do
	local raindrop = {
		position = vec2(love.math.random(0, love.graphics.getWidth()), love.math.random(0, love.graphics.getHeight())),
	}

	local sprite = peachy.new("assets/rain.json", rainImage, "Idle")
	sprite:onLoop(function()
		raindrop.position = vec2(love.math.random(0, love.graphics.getWidth()), love.math.random(0, love.graphics.getHeight()))
	end)

	raindrop.sprite = sprite
	table.insert(rainDrops, raindrop)
end

function love.update(dt)
	for _, guy in ipairs(guys) do
		guy:update(dt)

		local safe = false
		local guyInTheSky = vec2(guy.position.x, guy.position.y - 1000)

		for _, v in ipairs(safeZones) do
			if aabb(guy.position.x, guy.position.y, 32, 32, v.x, v.y, v.w, love.graphics.getHeight()) then
				safe = true
				break
			end
		end

		if not safe and intersect.line_line_collide(guy.position, guyInTheSky, 0, vec2(umbrella.position.x, umbrella.position.y), vec2(umbrella.position.x + 64, umbrella.position.y), 0) then
			if aabb(guy.position.x, guy.position.y, 32, 32, umbrella.position.x, umbrella.position.y + 64, 64, love.graphics.getHeight()) then
				safe = true
			end
		end

		if not safe then
			guy.health = guy.health - dt
		end

		guy.safe = safe
	end

	for _, rainDrop in ipairs(rainDrops) do
		rainDrop.sprite:update(dt)
	end

	guySpawningTimer = guySpawningTimer + dt

	if guySpawningTimer >= guyMaxSpawningTimer then
		local y = 310 - 32

		if love.math.random() < 0.5 then
			x = 0
		else
			x = 640 - 32
		end

		local guy = Guy(x, y)
		guy.destinationDoor = tablex.pick_random(doors)

		table.insert(guys, guy)
		guySpawningTimer = 0
	end

	if love.keyboard.isDown("a") then
		umbrella.position.x = umbrella.position.x - umbrella.speed * dt
	elseif love.keyboard.isDown("d") then
		umbrella.position.x = umbrella.position.x + umbrella.speed * dt
	end
end

local function rainStencil()
	love.graphics.setColorMask(false, false, false, false)

	for _, safeZone in ipairs(safeZones) do
		love.graphics.rectangle("fill", safeZone.x, safeZone.y, safeZone.w, love.graphics.getHeight())
	end

	love.graphics.rectangle("fill", umbrella.position.x, umbrella.position.y + 64, 64, love.graphics.getHeight())
	love.graphics.rectangle("fill", 0, 311, love.graphics.getWidth(), love.graphics.getHeight())

	love.graphics.setColorMask(true, true, true, true)
end

function love.draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.draw(buildingsImage, 0, 0)

	for _, guy in ipairs(guys) do
		if not guy.safe then
			love.graphics.setColor(1, 0, 0)
		else
			love.graphics.setColor(1, 1, 1)
		end

		guy:draw()
	end


	love.graphics.setColor(1, 1, 1)
	love.graphics.printf(deaths, 0, love.graphics.getHeight() - 100, love.graphics.getWidth(), "center")

	love.graphics.draw(umbrella.sprite, mathx.round(umbrella.position.x), mathx.round(umbrella.position.y))
	love.graphics.line(umbrella.position.x, umbrella.position.y + 36, umbrella.position.x, 311)
	love.graphics.line(umbrella.position.x + 64, umbrella.position.y + 36, umbrella.position.x + 64, 311)

	love.graphics.setStencilMode("increment", "always", 1)
	rainStencil()
	love.graphics.setStencilMode()

	love.graphics.setStencilMode("keep", "equal", 0)
	love.graphics.setColor(1, 1, 1)

	for _, rainDrop in ipairs(rainDrops) do
		rainDrop.sprite:draw(rainDrop.position.x, rainDrop.position.y)
	end

	--love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	love.graphics.setStencilMode()
end
