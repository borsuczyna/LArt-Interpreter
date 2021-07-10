local locations = require("lua.locations")
local locationsPositions = require("lua.locationspositions")
local currentLocation = false
local characters = {
    ["fred"] = {
        x = 0,
        y = 0,
        z = 0,
        animation = "fred_wychodzi_z_grobu",
    },
}

function findLocationByName(name)
    for k,v in pairs(locations) do
        if v.attr.name == name then
            return v
        end
    end
end

function getHotpointByName(name)
    for _,location in pairs(locations) do
        for _,hotpoint in pairs(location.Hotpoints.Hotpoint) do
            if hotpoint.attr and hotpoint.attr.name == name then
                return hotpoint
            end
        end
    end
end

function renderHotpoints(hotpoints)
    for k,c in pairs(hotpoints) do
        local v = c.attr

        if v.Visible == "1" then
            local x, y = getScreenFromWorldPosition(v.x, v.y)
            local z = tonumber(v.z)

            if v.bitmap then
                local image = getImageByName(v.bitmap)
                dxDrawAbsoluteImage3D(x, y, 1, z, ('data/graphics/%08d.png'):format(image))
            elseif v.idle_animation then
                renderIdleAnimation(x, y, z, v.idle_animation)
            end
        end
    end
end

-- tymczasowe
local file = io.open("xml/prolog.xml", "rb")
local xs = file:read("*all")
file:close()

--local data = xml.parse(xs)

local file = io.open("output.lua", "wb")
file:write(serpent.dump(data))
file:close()

function renderLayers(layers)
    for k,v in pairs(layers) do
        local x, y = getScreenFromWorldPosition(v.Position.attr.x, v.Position.attr.y)
        local z = tonumber(v.Depth.attr.z)

        local image = getImageByName(v.attr.name)
        dxDrawAbsoluteImage3D(x, y, 1, z, ('data/graphics/%08d.png'):format(image))
    end
end

function renderBackgroundAnimations(layers)
    for k,v in pairs(layers) do
        local x, y = getScreenFromWorldPosition(v.attr.x, v.attr.y)
        local z = tonumber(v.attr.z)

        renderIdleAnimation(x, y, z, v.Animation)
    end
end

function findLocationChange(source, dest)
    for k,v in pairs(locationsPositions) do
        if v.source == source:upper() and v.dest == (dest or "NULL"):upper() then
            return v
        end
    end
end

function getZFromWisMap(x, y)
    local image = getImageByName(currentLocation.attr.GameLogicMap)
    image = ('data/graphics/%08d.png'):format(image)
    local r, g, b = getImagePixelColor(x, y, image)
    return g*255, (r>0.5)
end

function setWorld(name)
    local world = findLocationByName(name)
    if not world then return error("Lokacja nie istnieje!") end
    local change = findLocationChange(name, (currentLocation and currentLocation.attr.name))
    currentLocation = world

    if change then
        characters.fred.x = tonumber(change.fred_x)
        characters.fred.y = tonumber(change.fred_y)
        local z, walkAble = getZFromWisMap(characters.fred.x, characters.fred.y)
        characters.fred.z = z
    end
end

function renderCharacters(c)
    for k,v in pairs(c) do
        local animation = v.animation
        if type(animation) == "string" then
            animation = getIdleAnimationData(animation)
        end

        local scale = v.z/255+0.02
        local x, y, z = v.x - animation.attr.StartOffsetX*scale, v.y - animation.attr.StartOffsetY*scale, v.z
        local w, h = getIdleAnimationSize(animation)
        w, h = w*scale, h*scale
        renderIdleAnimation(x, y, z, animation, w, h)
    end
end

function renderWorld()
    if not currentLocation then return end
    renderHotpoints(currentLocation.Hotpoints.Hotpoint)
    renderLayers(currentLocation.Layers.Layer)
    renderBackgroundAnimations(currentLocation.BackgroundAnimations.BackgroundAnimation)
    renderCharacters(characters)
    
    draw3DElements()
end

setWorld("Polana z grobem")