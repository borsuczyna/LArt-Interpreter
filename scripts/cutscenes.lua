local cutscenes = {
    prolog = require("lua.prolog"),
    akt = "prolog",
}

function getCutsceneByName()

end

function defaultCutsceneData()
    return {
        groupelem = nil
    }
end
local currentCutscene
local cutsceneData = defaultCutsceneData()

function deleteFirstIndex(t)
    local c = {}
    local i, id = 1, 1
    for k,v in ipairs(t) do
        if i > 1 then
            c[id] = v
            id = id + 1
        end
        i = i + 1
    end
    return c
end

function findCutsceneByName(name)
    for k,v in pairs(cutscenes) do
        if name == v.name then
            return v
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

function exec(data)
    if not data then return end
    if cutsceneData.groupelem then
        if cutsceneData.groupelem ~= removenumbers(tostring(data.groupelem)) then
            cutsceneData.groupelem = nil
            return false
        end
    end
    
    if data.groupelem and data.groupelem:len() > 0 then
        local time = removechars(data.groupelem)
        if time and time:len() > 0 then
            data.groupelem = false
            setTimer(exec, tonumber(time)*1000, data)
            return true
        end
    end

    if data.type == "ClipAction" then
        if data.name:find("podejsc do") then
            local x, y = loadstring("return " .. data.name:gsub("podejsc do ", ""))()
            print("Pominieto podejsc do bo nie wykonane")
            return true
        elseif data.name == "set visible" then
            print("Ustawiono " .. data.params)
            return true
        elseif data.name == "playsound" then
            print("Zagrano dzwiek " .. data.sfx)
            return true
        end
    elseif data.type == "ClipAnimation" then
        print(data.type)
        if data.groupelem then
            cutsceneData.groupelem = removenumbers(data.groupelem)
            print("Groupelem set to " .. removenumbers(data.groupelem))
            return true
        end
    end
    print(data.type)
    return false
end

function executeCutscene(name)
    currentCutscene = findCutsceneByName(name)
    nextCutscene()
end

function nextCutscene()
    if not currentCutscene[1] then cutsceneData = defaultCutsceneData(); return end
    local next = exec(currentCutscene[1])
    currentCutscene = deleteFirstIndex(currentCutscene)
    if next then
        nextCutscene()
    end
end

function updateCutscenes()

end

--fiXlly.#7312