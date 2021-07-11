tickCount = 0

xml = require("scripts.lua-xml")
lbt = require("scripts.lbt")
serpent = require("scripts.serpent")
require("scripts.timer")
require("scripts.cutscenes")
require("scripts.sounds")
require("scripts.graphics")
require("scripts.functions")
require("scripts.animations")
require("scripts.world")

--executeCutscene("Fred rozmawia z FZB po raz drugi")

love.window.setMode(800, 600)

function love.draw()
    if love.keyboard.isDown("left") then
        setCameraPosition(getCameraPosition() + 3)
    end
    if love.keyboard.isDown("right") then
        setCameraPosition(getCameraPosition() - 3)
    end
    renderWorld()
end

function love.keypressed(key)
    if key == "c" then
        changeIdleAnimation("Swiadek_Jehowy", "swiadek_bierze_od_Freda_glejt")
    end
end

function love.update(dt)
    tickCount = tickCount + dt*1000
    updateCutscenes()
    updateSounds()
    updateTimers()
end