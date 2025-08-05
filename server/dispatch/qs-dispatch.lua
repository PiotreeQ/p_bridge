if (Config.Dispatch == 'auto' and not checkResource('qs-dispatch')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'qs-dispatch') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: qs-dispatch')
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
    TriggerEvent('qs-dispatch:server:CreateDispatchCall', {
        job = data.job,
        callLocation = vector3(plyCoords.x, plyCoords.y, plyCoords.z),
        callCode = { code = data.code, snippet = data.code },
        message = data.title,
        flashes = data.priority == 'high',
        blip = {
            sprite = data.blip?.sprite or 1,
            scale = data.blip?.scale or 1.5,
            colour = data.blip?.color or 1,
            flashes = data.priority == 'high',
            text = data.title,
            time = data.time * 60 * 1000,
        }
    })
end