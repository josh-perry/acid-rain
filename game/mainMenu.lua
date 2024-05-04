local mainMenu = class({
    name = "mainMenu"
})

function mainMenu:draw()
    love.graphics.printf("acid rain", 0, 96, love.graphics.getWidth(), "center")
    love.graphics.printf("everyday monotony of the end of the world", love.graphics.getWidth() / 2, 128, (love.graphics.getWidth() / 2) - 20, "left")

    love.graphics.printf("instructions: press a and d to protect what you can", 0, 240, love.graphics.getWidth(), "center")
    love.graphics.printf("press space to start", 0, 350, love.graphics.getWidth(), "center")
end

function mainMenu:update()
end

function mainMenu:keypressed(key)
    if key == "space" then
        _G.currentState = _G.states.game
        _G.currentState:initialize()
    end
end

return mainMenu