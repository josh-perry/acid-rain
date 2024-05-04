local gameOver = class({
    name = "gameOver"
})

function gameOver:draw()
    love.graphics.printf("game over", 0, 96, love.graphics.getWidth(), "center")
    love.graphics.printf(("you failed to save %i people"):format(_G.states.game.deaths), 0, 128, love.graphics.getWidth(), "center")
end

function gameOver:update()
end

function gameOver:keypressed(key)
    if key == "space" then
        _G.currentState = _G.states.mainMenu
    end
end

return gameOver