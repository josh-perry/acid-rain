local mainMenu = class({
    name = "mainMenu"
})

function mainMenu:draw()
    love.graphics.printf("acid game or something", 0, 96, love.graphics.getWidth(), "center")
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