_G.states = {
    game = require("game")(),
    mainMenu = require("mainMenu")(),
    gameOver = require("gameOver")()
}

_G.currentState = states.mainMenu

function love.load()
end

function love.update(dt)
    currentState:update(dt)
end

function love.draw()
    currentState:draw()
end

function love.keypressed(key)
    if currentState.keypressed then
        currentState:keypressed(key)
    end
end