if (Config.Dispatch == 'auto' and not checkResource('rcore_dispatch')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'rcore_dispatch') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: rcore_dispatch')
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
    TriggerEvent('rcore_dispatch:server:sendAlert', {
        code = data.code,
        default_priority = data.priority or 'normal',
        coords = vec3(plyCoords.x, plyCoords.y, plyCoords.z),
        job = data.job,
        text = data.title,
        type = 'alerts',
        blip_time = data.time or 10,
        blip = {
            sprite = data.blip?.sprite or 1,
            scale = data.blip?.scale or 1.1,
            colour = data.blip?.color or 1,
            text = data.title or 'No Title',
        }
    })
end