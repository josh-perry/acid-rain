local gameOver = class({
    name = "gameOver"
})

local randomTaunts = {
    "you can't save them all",
    "what's the point",
    "you failed",
    "there was nothing you could do",
    "why try?",
    "there was never any hope",
    "despair",
    "give up"
}

function gameOver:draw()
    if not self.taunt then
        self.taunt = tablex.pick_random(randomTaunts)
    end

    if _G.states.game.deaths == 0 then
        love.graphics.printf("how?", 0, 96, love.graphics.getWidth(), "center")
        love.graphics.printf("press space to return to menu", 0, 350, love.graphics.getWidth(), "center")
        return
    end

    for i = 0, love.graphics.getHeight(), 32 do
        love.graphics.setColor(1, 1, 1, 0.1)
        love.graphics.printf(self.taunt, 0, i, love.graphics.getWidth(), "center")
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("game over", 0, 96, love.graphics.getWidth(), "center")
    love.graphics.printf(("you failed to save %i people"):format(_G.states.game.deaths), 0, 128, love.graphics.getWidth(), "center")

    love.graphics.printf("press space to return to menu", 0, 350, love.graphics.getWidth(), "center")
end

local tauntTimer = 0
local maxTauntTimer = 0.1
function gameOver:update(dt)
    tauntTimer = tauntTimer + dt

    if tauntTimer >= maxTauntTimer then
        self.taunt = tablex.pick_random(randomTaunts)
        tauntTimer = 0
    end
end

function gameOver:keypressed(key)
    if key == "space" then
        _G.currentState = _G.states.mainMenu
    end
end

return gameOver