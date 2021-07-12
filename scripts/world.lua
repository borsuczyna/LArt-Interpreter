local locations = require("lua.locations")
local locationsPositions = require("lua.locationspositions")
local currentLocation = false
local characters = {
    ["Fred"] = {
        x = 0,
        y = 0,
        z = 0,
        animationOffset = {0, 0},
        visible = true,
        animation = "",
    },
}

function changeNpcAnimation(name, anim)
    if not characters[name] then return end
    
    local animation_old = getIdleAnimationData(characters[name].animation)
    local animation_new = getIdleAnimationData(anim)
    --local x, y = animation_new.attr.StartOffsetX, animation_new.attr.StartOffsetY
    local x, y = characters[name].animationOffset[1], characters[name].animationOffset[2]
    x, y = x + animation_new.attr.StartOffsetX, y + animation_new.attr.StartOffsetY
    if animation_old then
        x = x - animation_old.attr.EndOffsetX
        y = y - animation_old.attr.EndOffsetY
    end
    characters[name].animationOffset = {x, y}

    characters[name].animation = anim
end

function changeNpcAnimationToEnd(name)
    if not characters[name] then return end
    local animation = getIdleAnimationData(characters[name].animation)
    animation.Cycle.Current = 2
end

function findLocationByName(name)
    for k,v in pairs(locations) do
        if v.attr.name == name then
            return v
        end
    end
end

function setCharacterVisible(name, state)
    if characters[name] then
        characters[name].visible = state
        return true
    end
    return false
end

function getHotpointByName(name)
    for _,location in pairs(locations) do
        for _,hotpoint in pairs(location.Hotpoints.Hotpoint) do
            if (hotpoint.attr and hotpoint.attr.name:lower() == name:lower() and hotpoint.attr.id:lower():find(currentLocation.attr.name:lower())) or (hotpoint.attr and hotpoint.attr.id:lower() == name:lower()) then
                return hotpoint
            end
        end
    end
end

function getHotpointFromAct(name)
    if not currentLocation then return false end
    local currentWorld = currentLocation.attr.name:upper()
    for d,c in pairs(getCurrentAct().Acts) do
        if c.name:upper() == currentWorld:upper() then
            for k,v in pairs(c.Hotpoints) do
                if v.id:upper() == name:upper() then
                    return v
                end
            end
            break
        end
    end
end

function renderHotpoints(hotpoints)
    for k,c in pairs(hotpoints) do
        local v = c.attr

        local actdata = getHotpointFromAct(v.id)
        local visible = (actdata.display == "")
        if visible then
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
    return tonumber(g*255), (r>0.5)
end

function setWorld(name)
    local world = findLocationByName(name)
    if not world then return error("Lokacja nie istnieje!") end
    local prev = (currentLocation and currentLocation.attr.name)
    local change = findLocationChange(name, prev)
    currentLocation = world

    if change then
        characters.Fred.x = tonumber(change.fred_x)
        characters.Fred.y = tonumber(change.fred_y)
        local z, walkAble = getZFromWisMap(characters.Fred.x, characters.Fred.y)
        characters.Fred.z = z
    end

    onWorldChangeCutscene(name, prev)
end

function renderCharacters(c)
    for k,v in pairs(c) do
        if v.visible then
            local animation = v.animation
            if type(animation) == "string" then
                animation = getIdleAnimationData(animation)
            end

            local scale = v.z/255+0.02
            local x, y, z = v.x - v.animationOffset[1]*scale, v.y - v.animationOffset[2]*scale, v.z
            local w, h = getIdleAnimationSize(animation)
            w, h = w*scale, h*scale
            local x, y = getScreenFromWorldPosition(x, y)
            renderIdleAnimation(x, y, z, animation, w, h)
        end
    end
end

function setHotpointVisible(name, state)
    if not currentLocation then return end
    for k,v in pairs(currentLocation.Hotpoints.Hotpoint) do
        if v.attr.id == name then
            local actdata = getHotpointFromAct(v.attr.id)
            v.attr.Visible = (state and "1" or "0")
            actdata.display = (state and "" or "invisible")
        end
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