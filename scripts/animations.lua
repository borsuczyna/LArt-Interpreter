local animations = require("lua.animations")
local cache = {}

function stringToTable(str)
    local t = {}
    for k in str:gmatch("%S+") do
        table.insert(t, k)
    end
    return t
end

function getAnimationByName(name)
    if cache[name] then return cache[name] end
    for k,v in pairs(animations) do
        if v.attr.name:lower() == name:lower() then
            cache[name] = k
            return k
        end
    end
end

function getIdleAnimationData(name)
    local animation = getAnimationByName(name)
    if not animation then return end
    return animations[animation]
end

--[[function nextCycle(data)
    local current = (data.Cycle.Current or 1)

    data.Cycle[current].Current = 1
    data.Cycle.Current = (data.Cycle.Current or 1) + 1

    if not data.Cycle[data.Cycle.Current] then
        data.Cycle.Current = 1
    end

    while data.Cycle[data.Cycle.Current].attr.frames:len() < 1 do
        data.Cycle.Current = (data.Cycle.Current or 1) + 1
        if not data.Cycle[data.Cycle.Current] then
            data.Cycle.Current = 1
        end
    end

    return data
end]]

function nextCycle(data)
    local current = (data.Cycle.Current or 1)
    print(current .. ", " .. data.attr.name)

    data.Cycle[current].Current = 1
    
    if current == 1 then
        if data.Cycle[3] then
            data.Cycle.Current = 3
        elseif data.Cycle[2] and data.Cycle[2].attr.frames:len() > 0 then
            data.Cycle.Current = 2
        end
    elseif current >= 3 then
        if data.Cycle[current + 1] and data.Cycle[current + 1].attr.frames:len() > 0 then
            data.Cycle.Current = current + 1
        elseif data.Cycle[2] and data.Cycle[2].attr.frames:len() > 0 then
            data.Cycle.Current = 3 -- bylo 2
            if isWaitingTillEndThisAnimation(data.attr.name) then
                data.Cycle.Current = 2
            end
        else
            for i = 3, 15 do
                if data.Cycle[i] and data.Cycle[i].attr.frames:len() > 0 then
                    data.Cycle.Current = i
                    break
                end
            end
        end
    elseif current == 2 then
        if data.Cycle[1].attr.frames:len() > 0 then
            data.Cycle.Current = 1
        end
        onAnimationEnd(data.attr.name)
    end

    return data
end

function onAnimationEnd(name)
    onAnimationEndCutscene(name)
end

function updateIdleAnimation(data)
    local current = (data.Cycle.Current or 1)

    local Cycle = stringToTable(data.Cycle[current].attr.frames)
    local _current = (data.Cycle[current].Current or 1)
    local frame = Cycle[_current]

    local _change = 1000/data.attr.fps

    if (data.Cycle.LastChange or 0) + _change < tickCount then
        data.Cycle.LastChange = tickCount
        data.Cycle[current].Current = (data.Cycle[current].Current or 1) + 1
        if not Cycle[data.Cycle[current].Current] then
            data.Cycle[current].Current = 1
            data.Cycle[current].Repeats = (data.Cycle[current].Repeats or 1) + 1

            if data.Cycle[current].Repeats > tonumber(data.Cycle[current].attr["repeat"]) then
                data.Cycle[current].Repeats = 1
                data = nextCycle(data)
            end
        end
    end

    return frame or 0
end

function changeIdleAnimation(name, new)
    local hotpoint = getHotpointByName(name)
    if not hotpoint then return end

    if hotpoint.attr.idle_animation then
        local animation = getIdleAnimationData(hotpoint.attr.idle_animation)
        local new_animation = getIdleAnimationData(new)
        hotpoint.attr.x = hotpoint.attr.x - new_animation.attr.EndOffsetX + animation.attr.StartOffsetX
        hotpoint.attr.y = hotpoint.attr.y - new_animation.attr.EndOffsetY + animation.attr.StartOffsetY
    else
        local new_animation = getIdleAnimationData(new)
        hotpoint.attr.x = hotpoint.attr.x - new_animation.attr.EndOffsetX
        hotpoint.attr.y = hotpoint.attr.y - new_animation.attr.EndOffsetY
    end
    --hotpoint.attr.y = hotpoint.attr.y - new_animation.attr.EndTop + animation.attr.StartTop

    hotpoint.attr.idle_animation = new
end

function setIdleAnimationToEnd(name)
    local hotpoint = getHotpointByName(name)
    if not hotpoint then return end

    local data = getIdleAnimationData(hotpoint.attr.idle_animation)
    local current = (data.Cycle.Current or 1)
    data.Cycle.Current = 2
end

function getIdleAnimationFrame(animation)
    local prev = tostring(animation)
    if type(animation) == "string" then
        animation = getIdleAnimationData(animation)
    end
    assert(type(animation) == "table", "Nie znaleziono animacji.")

    local frame = updateIdleAnimation(animation)
    if frame then
        local name = ('%s_%02d'):format(animation.attr.name:upper(), frame+1)
        local image = getImageByName(name)
        assert(image, "Nie znaleziono klatki animacji.")
        return ('data/graphics/%08d.png'):format(image)
    end
end

function getIdleAnimationSize(animation)
    local image = getIdleAnimationFrame(animation)
    return getImageSize(image)
end

function renderIdleAnimation(x, y, z, animation, w, h)
    local image = getIdleAnimationFrame(animation)

    if not w then
        dxDrawAbsoluteImage3D(x, y, 1, z, image)
    else
        dxDrawImage3D(x, y, w, h, z, image)
    end
end