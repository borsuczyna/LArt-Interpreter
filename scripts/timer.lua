local timers = {}

function setTimer(handler, time, ...)
    table.insert(timers, {handler=handler, time=tickCount+time, args={...}})
end

function updateTimers()
    for k,v in pairs(timers) do
        if tickCount > v.time then
            v.handler(unpack(v.args))
            table.remove(timers, k)
        end
    end
end