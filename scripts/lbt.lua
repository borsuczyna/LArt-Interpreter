local lbt = {}
lbt.findall = function(code, find)
    local found = {}
    local lastPos = 0
    while code:find(find, lastPos) do
        local pos = code:find(find, lastPos)
        table.insert(found, pos)
        lastPos = pos + find:len()
    end
    return found
end

lbt.gsub = function(start_string, old, new)
    local end_string = tostring(start_string)
    local _old = tostring(old)
    local pos = 0
    local args = {}

    for _,v in pairs(lbt.findall(old, "*s")) do
        local footer = _old:sub(v+2, _old:len())
        if footer:find("*s") then
            footer = footer:sub(1, footer:find("*s")-1)
        end
        local value = end_string:sub(v+pos, end_string:len())
        local _pos = value:find(footer)-1
        value = value:sub(1, _pos)
        pos = pos + value:len()-2
        table.insert(args, value)
    end

    return new(unpack(args))
end

lbt.onlychars = function(str)
    local c = ""
    for k in str:gmatch(".") do
        if not tonumber(k) then
            c = c .. k
        end
    end
    return c
end

function string:tobool()
    return (self == "true")
end

lbt.onlynumbers = function(str)
    local c = ""
    for k in str:gmatch(".") do
        if tonumber(k) then
            c = c .. k
        end
    end
    return c
end

return lbt