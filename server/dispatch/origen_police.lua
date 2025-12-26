if (Config.Dispatch == 'auto' and not checkResource('origen_police')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'origen_police') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Dispatch] Loaded: origen_police')
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
    if type(data.jobs) == 'table' then
        for k, v in pairs(data.jobs) do
            exports['origen_police']:SendAlert({
                coords = vec3(plyCoords.x, plyCoords.y, plyCoords.z),
                title = data.title,
                type = 'GENERAL',
                message = data.code,
                job = v,
            })
        end
    else
        exports['origen_police']:SendAlert({
            coords = vec3(plyCoords.x, plyCoords.y, plyCoords.z),
            title = data.title,
            type = 'GENERAL',
            message = data.code,
            job = data.job or 'police',
        })
    end
end

RegisterNetEvent('p_bridge/server/dispatch/sendAlert', function(data)
    Bridge.Dispatch.SendAlert(source, data)
end)