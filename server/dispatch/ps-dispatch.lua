if (Config.Dispatch == 'auto' and not checkResource('ps-dispatch')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'ps-dispatch') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Dispatch] Loaded: ps-dispatch')
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
    TriggerEvent('ps-dispatch:server:notify', {
        message = data.title,
        codeName = 'NONE',
        code = data.code,
        icon = data.icon or 'fa-solid fa-bell',
        priority = data.priority == 'high' and 1 or 2,
        coords = vector3(plyCoords.x, plyCoords.y, plyCoords.z),
        alertTime = data.time * 60,
        alert = {
            radius = 0,
            sprite = data.blip?.sprite or 1,
            scale = data.blip?.scale or 1.1,
            color = data.blip?.color or 1,
            flash = data.priority == 'high',
        },
        jobs = data.job
    })
end

RegisterNetEvent('p_bridge/server/dispatch/sendAlert', function(data)
    Bridge.Dispatch.SendAlert(source, data)
end)