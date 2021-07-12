local cutscenes = {
    prolog = require("lua.prolog"),
    ["akt1"] = require("lua.akt1"),
    ["akt2"] = require("lua.akt2"),
    ["akt3"] = require("lua.akt3"),
    triggers = require("lua.triggers"),
    constraints = require("lua.constraints"),
    soundeffects = require("lua.soundeffects"),
    reactions = require("lua.reactions"),
    changelocations = require("lua.changelocations"),
    changelocationsclips = require("lua.changelocationsclips"),
    animationsid = require("lua.animationsid"),
    akt = "prolog",
}

function getCurrentAct()
    return cutscenes[cutscenes.akt]
end

function getTriggerValue(id)
    for k,v in pairs(cutscenes.triggers) do
        if tonumber(v.id) == tonumber(id) or v.name == id then
            return (v.state == "True"), v.name, v
        end
    end
end

function setTriggerValue(id, boolean)
    for k,v in pairs(cutscenes.triggers) do
        if tonumber(v.id) == tonumber(id) or v.name == id then
            v.state = (boolean and "True" or "False")
            break
        end
    end
end

function isConstraintMet(id)
    local found = false
    for k,v in pairs(cutscenes.constraints) do
        if tonumber(v.id) == tonumber(id) or v.name == id then
            found = v
            break
        end
    end
    if not found then return false end
    local expression = found.expression
    local expressions = {}
    if expression:find("%(") then
        for _,c in pairs(lbt.findall(expression, "%(")) do
            local _expression = expression:sub(c, expression:len())
            _expression = _expression:sub(2, _expression:find("%)")-1)
            table.insert(expressions, _expression)
        end
    else
        table.insert(expressions, expression)
    end

    local fulfith = true
    for k,v in pairs(expressions) do
        v = v:gsub("t%[", ""):gsub("%]", ""):gsub("=", ""):gsub(" ", "")
        local id = lbt.onlynumbers(v)
        local state = lbt.onlychars(v)
        local current_state = getTriggerValue(id)
        if current_state ~= state:tobool() then
            fulfith = false
            break
        end
    end
    return fulfith
end

function defaultCutsceneData()
    return {
        groupelem = nil,
        sounds = {},
        animations = {},
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

function exec(data)
    if not data then return end
    if cutsceneData.groupelem then
        if (cutsceneData.groupelem ~= removenumbers(tostring(data.groupelem))) or (tonumber(cutsceneData.groupelem) and tostring(data.groupelem) ~= "0") then
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
            local pos = data.params:find(",")
            local npc = data.params:sub(1, pos-1)
            local state = data.params:sub(pos+1, data.params:len())
            setCharacterVisible(npc, (state:lower() == "true"))
            setHotpointVisible(npc, (state:lower() == "true"))
            return true
        elseif data.name == "playsound" then
            playSoundByName(data.sfx .. ".OGG")
            return true
        elseif data.name == "setcurrentidleanimation" then
            local pos = data.params:find(",")
            local npc = data.params:sub(1, pos-1)
            local anim = data.params:sub(pos+1, data.params:len())
            changeIdleAnimation(npc, anim)
            return true
        end
    elseif data.type == "ClipAnimation" then
        playClipAnimation(data)
        if data.groupelem and data.groupelem:len() > 0 then
            cutsceneData.groupelem = removenumbers(data.groupelem)
            return true
        else
            currentCutscene = deleteFirstIndex(currentCutscene)
            return false
        end
    end
    print(data.type)
    return false
end

function getAnimationByID(id)
    for k,v in pairs(cutscenes.animationsid) do
        if tonumber(v.id) == tonumber(id) then
            return v.name
        end
    end
end

function playClipAnimation(v)
    print(v.animationID .. " anim")
    if v.animationID and v.animationID:len() > 0 then
        local animation = getAnimationByID(v.animationID)
        changeNpcAnimation(v.character, animation)
        changeIdleAnimation(v.character, animation)

        if not v.wavename or v.wavename:len() == 0 then
            table.insert(cutsceneData.animations, animation)
        end
    end
    if v.wavename and v.wavename:len() > 0 then
        local sound = playSoundByName(v.wavename)
        table.insert(cutsceneData.sounds, {sound=sound, character=v.character})
    end
end

function getCutsceneByReference(name)
    for k,v in pairs(cutscenes.changelocationsclips) do
        if name == v.name or v.id == name then
            return v
        end
    end
end

function findCutsceneByName(name)
    local cutscene = getCutsceneByReference(name)
    if cutscene then
        name = cutscene.clipId
    end
    
    for k,v in pairs(getCurrentAct()["Standard Clips"]) do
        if tostring(v.id):lower() == name:lower() then
            return v
        end
    end
    for k,v in pairs(getCurrentAct()["Boring Grucha Clips"]) do
        if tostring(v.id):lower() == name:lower() then
            return v
        end
    end
    for k,v in pairs(getCurrentAct()["Boring Fred Clips"]) do
        if tostring(v.id):lower() == name:lower() then
            return v
        end
    end
    for k,v in pairs(getCurrentAct().GruchaClips) do
        if tostring(v.id):lower() == name:lower() then
            return v
        end
    end
    for k,v in pairs(getCurrentAct().FredClips) do
        if tostring(v.id):lower() == name:lower() then
            return v
        end
    end
    for d,c in pairs(getCurrentAct().Acts) do
        if c["Location Clips"] then
            for k,v in pairs(c["Location Clips"]) do
                if tostring(v.id):lower() == name:lower() then
                    return v
                end
            end
        end
        for k,v in pairs(c.Hotpoints) do
            if tostring(v.id):lower() == name:lower() then
                return v
            end
        end
    end
end

function executeCutscene(name)
    currentCutscene = findCutsceneByName(name)
    nextCutscene()
end

function onWorldChangeCutscene(dest)
    for k,v in pairs(cutscenes.changelocations) do
        if dest:lower() == v.name:lower() then
            if isConstraintMet(tonumber(v.const_id)) then
                executeCutscene(v.clip_id)
            end
        end
    end
end

function nextCutscene()
    if not currentCutscene[1] then cutsceneData = defaultCutsceneData(); return end
    local next = exec(currentCutscene[1])
    if next then
        currentCutscene = deleteFirstIndex(currentCutscene)
        nextCutscene()
    end
end

function updateCutscenes()
    if #cutsceneData.sounds > 0 and currentCutscene then
        for k,v in pairs(cutsceneData.sounds) do
            if v.sound and not v.sound:isPlaying() then
                setIdleAnimationToEnd(v.character)
                changeNpcAnimationToEnd(v.character)

                v.sound:release()
                v.sound = nil
            end
        end
    end
end

function isWaitingTillEndAnimation()
    return (#cutsceneData.animations > 0)
end

function onAnimationEndCutscene(name)
    if not cutsceneData then return end

    if isWaitingTillEndAnimation() then
        local found = false
        for k,v in pairs(cutsceneData.animations) do
            if name:lower() == v:lower() then
                found = true
                break
            end
        end
        if found then
            nextCutscene()
            cutsceneData.animations = {}
            return
        end
    end

    local playing = false
    for k,v in pairs(cutsceneData.sounds) do
        if v.sound then
            playing = true
        end
    end
    if not playing then
        nextCutscene()
    end
end