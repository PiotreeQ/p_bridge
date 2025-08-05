if (Config.Dispatch == 'auto' and not checkResource('lb-tablet')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'lb-tablet') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: lb-tablet')
end

Bridge.Dispatch = {}

--@param data: table
--@param data.title: string
--@param data.code: string
--@param data.icon?: string
--@param data.blip?: [scale: number, sprite: number, category: number, color: number, hidden: boolean, priority: number, short: boolean, alpha: number, name: string]
--@param data.priority?: 'low' | 'medium' | 'high'
--@param data.maxOfficers?: number [maximum number of officers that can answer the alert]
--@param data.time?: number [time in minutes how long the alert should be active]
--@param data.notify?: number [notify time]

Bridge.Dispatch.SendAlert = function(playerId, data)
    local plyPed = GetPlayerPed(playerId)
    local plyCoords = GetEntityCoords(plyPed)
    exports["lb-tablet"]:AddDispatch({
        priority = data.priority or 'normal',
        code = data.code,
        title = data.title,
        description = ('%s - %s'):format(data.code, data.title),
        location = {coords = vec2(plyCoords.x, plyCoords.y)},
        time = data.time * 60,
        job = data.job,
        blip = {
            sprite = data.blip?.sprite or 1,
            size = data.blip?.scale or 1.2,
            color = data.blip?.color or 3,
            shortRange = true,
            label = data.title or 'No Title',
        }
    })
end