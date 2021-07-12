local cache = {}

timers = {}
gameSpeed = 1

function findFreeValue(t)
    for i = 1, 1000 do
        if not t[i] then
            return i
        end
    end
end

function removenumbers(str)
    local c = ""
    for k in str:gmatch(".") do
        if not tonumber(k) and k ~= "." then
            c = c .. k
        end
    end
    return c
end

function removechars(str)
    local c = ""
    for k in str:gmatch(".") do
        if tonumber(k) or k == "." then
            c = c .. k
        end
    end
    return c
end

function getTimers()
    return timers
end

function loadTimers(dataToLoad)
    timers = dataToLoad
end

function setTimer(func, time, ...)
    local free = findFreeValue(timers)
    timers[free] = {func=func, time_end=tonumber(tickCount+(time/gameSpeed)), args={...}}
    return free
end

function setTimerEndtime(id, endtime)
    if not timers[id] then return end
    timers[id].time_end = endtime
end

function getDistanceBetweenPoints1D(x1,x2)
    return math.sqrt((x2 - x1) ^ 2)
end

function getDistanceBetweenPoints2D(x1,y1,x2,y2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
end

function getDistanceBetweenPoints3D(x1,y1,z1,x2,y2,z2)
    return math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2 + (z2 - z1) ^ 2)
end

function calcScreenX(value)
    local cx = sy * 1.33
    return (sx/2 - cx/2) + (value/2000)*cx
end

function calcWidth(value)
    local cx = sy * 1.33
    return (value/2000)*cx
end

function wordWrap(text, maxwidth)
    local lines = {}
    local actualLine = 1
    for word in text:gmatch("%S+") do
        if not lines[actualLine] then
            lines[actualLine] = ""
        end
        if dxGetTextWidth(lines[actualLine]) > maxwidth then
            actualLine = actualLine + 1
        end
        if not lines[actualLine] then
            lines[actualLine] = ""
        end
        lines[actualLine] = lines[actualLine] .. word .. " "
    end
    return lines
end

function updateTimers()
    for k = #timers, 1, -1 do
        v = timers[k]
        if v then
            if tickCount >= v.time_end then
                v.func(unpack(v.args))
                table.remove(timers, k)
                v = false
            end
        end
    end
end

function clearCache()
    for k,v in pairs(cache) do
        if v.lastUse + 4000 < tickCount then
            cache[k] = nil
            v = nil
        end
    end
end

function deepcopy(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            copies[orig] = copy
            for orig_key, orig_value in next, orig, nil do
                copy[deepcopy(orig_key, copies)] = deepcopy(orig_value, copies)
            end
            setmetatable(copy, deepcopy(getmetatable(orig), copies))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

allSounds = {}

function playSound(q, w, e)
    src1 = love.audio.newSource(q, "static")
    src1:play()
    return src1
end

function stopAllSounds()
    for k,v in pairs(allSounds) do
        v:setPitch(0.0000001)
    end
end

function playAllSounds()
    for k,v in pairs(allSounds) do
        v:setPitch(1)
    end
end

function setColor(color)
    if color then
        love.graphics.setColor(color[1]/255, color[2]/255, color[3]/255, (tonumber(color[4])) and (color[4]/255) or 1)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function dxDrawText(text, x, y, w, h, color, scale, fontSet, alignX, alignY)
    setColor(color)
    if fontSet then
        love.graphics.setFont(fontSet)
    end
    local _, wt = love.graphics.getFont():getWrap(text,tonumber(w) or 9999)
    local height = #wt * font:getHeight()
    if alignY and alignY == "center" then
        y = y + (h/2) - (height/2)
    end
    love.graphics.printf(text, x, y, (tonumber(w)) and w or 9999, (tostring(alignX) == alignX) and alignX or "left")
end

function getImageFromCache(image)
    if not cache["image_" .. image] then
        local info = love.filesystem.getInfo(image)
        --addToDebug(image .. " size " .. info.size)
        cache["image_" .. image] = {data=love.graphics.newImage(image, love.image_optimize), lastUse=tonumber(tickCount), imageData=love.image.newImageData(image), size=info.size*2, name=image}
    else
        cache["image_" .. image].lastUse = tonumber(tickCount)
    end
    return cache["image_" .. image]
end

function reloadImageFromCache(image)
    cache["image_" .. image] = nil
end

function getMemoryUsage()
    local memory = 0
    for k,v in pairs(cache) do
        memory = memory + v.size
    end
    if memory/1024/1024 > 50 then
        for k,v in pairs(cache) do
            cache[k] = nil
        end
    end
    return memory
end

function getTexturesUsage()
    local textures = {}
    for k,v in pairs(cache) do
        table.insert(textures, v.name)
    end
    return textures
end

function dxDrawRectangle(x, y, w, h, color, type)
    setColor(color)
    if not type then type = "fill" end
    love.graphics.rectangle(type, x, y, w, h)
end

function dxDrawImage(x, y, w, h, image, center, rotation, color)
    if not center then center = {0, 0} end
    setColor(color)
    local image = getImageFromCache(image)
    local width, height = image.data:getWidth(), image.data:getHeight()
    love.graphics.draw(image.data, x, y, (rotation or 0)/20/2.8647889756541, (w/width), (h/height), center[1], center[2])
end

function dxDrawAbsoluteImage(x, y, scale, image)
    setColor(color)
    local image = getImageFromCache(image)
    love.graphics.draw(image.data, x, y, 0, scale, scale)
end

function getImagePixelColor(x, y, image)
    local image = getImageFromCache(image)
    local r, g, b, a = image.imageData:getPixel(x, y)
    return r, g, b, a
end

function getImageSize(image)
    local image = getImageFromCache(image)
    return image.data:getWidth(), image.data:getHeight()
end

function dxDrawImageSection(x, y, w, h, u, v, usize, vsize, image, color)
    setColor(color)
    local image = getImageFromCache(image)
    local width, height = image.data:getWidth(), image.data:getHeight()
    local quad = love.graphics.newQuad(u, v, usize, vsize, width, height)
    image.data:setWrap("repeat", "repeat")
    love.graphics.draw(image.data, quad, x, y, 0, ((w/usize)), ((h/vsize)))
end

local elements3D = {}
local absoluteElements3D = {}

function dxDrawImage3D(x, y, w, h, z, image, color)
    table.insert(elements3D, {x=x, y=y, w=w, h=h, z=z, image=image, color=color})
end

function dxDrawAbsoluteImage3D(x, y, scale, z, image)
    table.insert(absoluteElements3D, {x=x, y=y, scale=scale, z=z, image=image, absolute=true})
end

local getSortedOptions = function(tabela)
    local tabela = {}
    for k,v in pairs(elements3D) do
        table.insert(tabela, v)
    end
    for k,v in pairs(absoluteElements3D) do
        table.insert(tabela, v)
    end
    local currentOptionsSorted = {}
    for k,v in pairs(tabela) do
        table.insert(currentOptionsSorted, {key=k, value=v})
    end
    table.sort(currentOptionsSorted, function(a, b) return a.value.z < b.value.z end)
    return currentOptionsSorted
end

function dxGetTextWidth(text)
    return font:getWidth(text)
end

function isMouseOverImage(x, y, w, h, image, adetect)
    local image = getImageFromCache(image)
    local width, height = image.data:getWidth(), image.data:getHeight()
    local cx, cy = love.mouse.getPosition()
    local wpos = (w-(x + w - cx)) / (w/width)
    local ypos = (h-(y + h - cy)) / (h/height)
    if wpos < 1 or wpos > width - 1 or ypos < 1 or ypos > height - 1 then
        return false
    end
    local _, _, _, a = image.imageData:getPixel(wpos, ypos)
    if a <= (adetect or 0)/255 then
        return false
    else
        return true
    end
end

function draw3DElements()
    elements3D2 = getSortedOptions()
    for k,v in ipairs(elements3D2) do
        local v = v.value
        if not v.absolute then
            dxDrawImage(v.x, v.y, v.w, v.h, v.image, v.color)
        else
            dxDrawAbsoluteImage(v.x, v.y, v.scale, v.image)
        end
        --dxDrawImage(v.x, v.y, v.w, v.h, v.image, {255, 0, 0, 155}) -- debug
    end
    elements3D = {}
    absoluteElements3D = {}
end

function isPositionInRectangle(x, y, dx, dy, w, h)
    return ( ( x >= dx and x <= dx + w ) and ( y >= dy and y <= dy + h ) )
end

function isMouseInPosition ( x, y, width, height )
    local cx, cy = love.mouse.getPosition(  )
    
    return ( ( cx >= x and cx <= x + width ) and ( cy >= y and cy <= y + height ) )
end

function dxDrawImageWithHover( x, y, w, h, image, color, adetect )
    if isMouseOverImage( x, y, w, h, image, adetect and adetect or 100 ) then
        if love.mouse.isDown(1) then
            dxDrawImage( x, y, w, h, image:gsub(".png", "Click.png"), color )
        else
            dxDrawImage( x, y, w, h, image:gsub(".png", "Hover.png"), color )
        end
	else
		dxDrawImage( x, y, w, h, image, color )
	end
end

function varToString(var)
	if type(var) == "string" then
		return "\"" .. var .. "\""
	elseif type(var) ~= "table" then
		return tostring(var)
	else
		local ret = "{ "
		local ts = {}
		local ti = {}
		for i, v in pairs(var) do
			if type(i) == "string" then
				table.insert(ts, i)
			else
				table.insert(ti, i)
			end
		end
		
		local comma = ""
		if #ti >= 1 then
			for i, v in ipairs(ti) do
				ret = ret .. comma .. varToString(var[v])
				comma = ", "
			end
		end
		
		if #ts >= 1 then
			for i, v in ipairs(ts) do
				ret = ret .. comma .. "[\"" .. v .. "\"] = " .. varToString(var[v])
				comma = ", "
			end
		end
		
		return ret .. "}"
	end
end

function table_to_string(tbl)
    local result = "{"
    for k, v in pairs(tbl) do
        -- Check the key type (ignore any numerical keys - assume its an array)
        if type(k) == "string" then
            result = result.."[\""..k.."\"]".."="
        end

        -- Check the value type
        if type(v) == "table" then
            result = result..table_to_string(v)
        elseif type(v) == "boolean" then
            result = result..tostring(v)
        else
            result = result.."\""..v.."\""
        end
        result = result..","
    end
    -- Remove leading commas from the result
    if result ~= "" then
        result = result:sub(1, result:len()-1)
    end
    return result.."}"
end