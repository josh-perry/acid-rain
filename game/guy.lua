local guy = class({
    name = "guy"
})

local peachy = require("lib.peachy")

local guyImage = love.graphics.newImage("assets/guy.png")

local function aabb(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and
           x2 < x1 + w1 and
           y1 < y2 + h2 and
           y2 < y1 + h1
end

function guy:new(x, y)
    self.position = vec2(x, y)
    self.sprite = peachy.new("assets/guy.json", guyImage, "Walk")
    self.speed = love.math.random(20, 60)
    self.health = 3
end

function guy:draw()
    if self.arrived or self.dead then
        return
    end

    self.sprite:draw(self.position.x, self.position.y)
end

function guy:update(dt)
    if self.arrived or self.dead then
        return
    end

    if self.health <= 0 then
        self.sprite:setTag("Die")
        self.sprite:onLoop(function()
            self.dead = true
            pubsub:publish("guyDied", self)
        end)
        self.sprite:update(dt)
        return
    end

    self.sprite:update(dt)

    if self.position.x < self.destinationDoor.x then
        self.position.x = self.position.x + self.speed * dt
    elseif self.position.x > self.destinationDoor.x then
        self.position.x = self.position.x - self.speed * dt
    end

    if aabb(self.position.x, self.position.y, 32, 32, self.destinationDoor.x, self.destinationDoor.y, self.destinationDoor.w, self.destinationDoor.h) then
        self.arrived = true
    end
end

return guy