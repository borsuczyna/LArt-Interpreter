local sounds = require("data.Dialogi")
local allSounds = {}

function playSound(name)
    local location = "data/sounds/" .. name
    local sound = love.audio.newSource(location, "stream")
    sound:play()
    sound:seek(0.0001, "seconds")
    table.insert(allSounds, {sound=sound, name=name})
    return sound
end

function updateSounds()
    for k,v in pairs(allSounds) do
        if v.sound:tell("seconds") == 0 then
            v.sound:release()
            onSoundDone(v.name)
            table.remove(allSounds, k)
        end
    end
end

function getSoundByName(name)
    for k,v in pairs(sounds) do
        if type(v) == "table" then
            if v[2] == name then
                return k
            end
        else
            if v == name then
                return k
            end
        end
    end
end

function playSoundByName(name)
    local sound = getSoundByName(name)
    if not sound then return end
    local type = "sounds2.pac_00000000"
    if sound:find("sounds.pac") then
        type = "sounds.pac_00000000"
    end
    local sound = sound:gsub("sounds.pac_", ""):gsub("sounds2.pac_", "")

    local sound = playSound(type .. sound)
    return sound
end

function onSoundDone(name)
    print(name .. " done")
end