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
        rotation = "A",
    },
    ["Grucha"] = {
        x = 0,
        y = 0,
        z = 0,
        animationOffset = {0, 0},
        visible = false,
        animation = "",
        rotation = "A",
    },
}

function getCharacterDirection(name)
    return characters[name].rotation
end

function restoreNpcPrevAnimation(anim)
    for k,v in pairs(characters) do
        if v.animation:lower() == anim:lower() then
            changeNpcAnimation(k, k .. "_stoi_" .. v.rotation)
        end
    end
end

function changeNpcAnimation(name, anim)
    if not characters[name] then return end

    local animation_old = getIdleAnimationData(characters[name].animation, name)
    local animation_new = getIdleAnimationData(anim, name)
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
    local animation = getIdleAnimationData(characters[name].animation, name)
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

function isInvertCloser(source, dest)
    if source == "A" and (dest == "H" or dest == "G" or dest == "F") then
        return true
    elseif source == "B" and (dest == "A" or dest == "H" or dest == "G") then
        return true
    elseif source == "C" and (dest == "B" or dest == "A" or dest == "H") then
        return true
    elseif source == "D" and (dest == "C" or dest == "B" or dest == "A") then
        return true
    elseif source == "E" and (dest == "D" or dest == "C" or dest == "B") then
        return true
    elseif source == "F" and (dest == "E" or dest == "D" or dest == "C") then
        return true
    elseif source == "G" and (dest == "F" or dest == "E" or dest == "D") then
        return true
    elseif source == "H" and (dest == "G" or dest == "F" or dest == "E") then
        return true
    end
    return false
end

function rotateNpc(name, dest)
    if characters[name].rotation == dest then
        print(characters[name].rotation .. " , " .. dest)
        return true
    end
    characters[name].rotateDest = dest
    local frame = getFrameByRotation(characters[name].rotation)
    assert(frame, "Zbugowałeś gre! (brak rotacji dla " .. name .. ")")
    local invert = isInvertCloser(characters[name].rotation, dest)
    if invert then
        frame = 23 - frame
    end
    if frame then
        setIdleAnimationFrame(name .. "_obrot" .. (invert and "_invert" or ""), frame)
    end
    changeNpcAnimation(name, name .. "_obrot" .. (invert and "_invert" or ""))
    return false
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
        characters.Fred.rotation = change.fred_direction
    end

    onWorldChangeCutscene(name, prev)
end

local rotations = {
    [0] = "A",
    [3] = "B",
    [6] = "C",
    [9] = "D",
    [12] = "E",
    [15] = "F",
    [18] = "G",
    [21] = "H"
}

function getRotationByFrame(id)
    local id = tonumber(id)
    return rotations[id]
end

function getFrameByRotation(rot)
    for k,v in pairs(rotations) do
        if v == rot then
            return k
        end
    end
    return false
end

function renderCharacters(c)
    for k,v in pairs(c) do
        if v.visible then
            local animation = v.animation
            if type(animation) == "string" then
                animation = getIdleAnimationData(animation, k)
            end

            if v.animation:lower():find("_obrot") and v.rotateDest then
                local current = (animation.Cycle.Current or 1)
                local Cycle = stringToTable(animation.Cycle[current].attr.frames)
                local rotation = getRotationByFrame(Cycle[animation.Cycle[current].Current])
                if rotation then
                    v.rotation = rotation
                end
                if rotation == v.rotateDest then
                    changeNpcAnimation(k, k .. "_stoi_" .. rotation)
                    v.rotateDest = false
                    onEndRotating()
                end
            end

            local scale = v.z/255+0.02
            local x, y, z = v.x - v.animationOffset[1]*scale, v.y - v.animationOffset[2]*scale, v.z
            local w, h = getIdleAnimationSize(animation, k)
            w, h = w*scale, h*scale
            local x, y = getScreenFromWorldPosition(x, y)
            renderIdleAnimation(x, y, z, animation, w, h)
        end
    end
end

function setHotpointVisible(name, state)
    if not currentLocation then return end
    for k,v in pairs(currentLocation.Hotpoints.Hotpoint) do
        if v.attr.id:lower() == name:lower() then
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