local graphics = require("data.Animacje")
local cache = {}
local cameraPosition = 0

function lastWord(str)
    local c = {}
    for k in str:gmatch('%S+') do
        table.insert(c, k)
    end
    return c[#c]
end

function getImageByName(name)
    name = lastWord(name):gsub(".png",""):gsub(".jpg",""):upper()
    if cache[name] then return cache[name] end
    for k,v in pairs(graphics) do
        if v == name then
            cache[name] = k-1
            return k-1
        end
    end
end

function getCameraPosition()
    return cameraPosition
end

function setCameraPosition(pos)
    cameraPosition = pos
end

function getScreenFromWorldPosition(x, y)
    return x + cameraPosition, y
end

function getSize(w, h)
    return w, h
end