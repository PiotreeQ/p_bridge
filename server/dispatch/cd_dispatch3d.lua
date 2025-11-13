if (Config.Dispatch == 'auto' and not checkResource('cd_dispatch3d')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'cd_dispatch3d') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Dispatch] Loaded: cd_dispatch3d')
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
    TriggerClientEvent('cd_dispatch:AddNotification', -1, {
        job_table = data.job,
        coords = vec3(plyCoords.x, plyCoords.y, plyCoords.z),
        title = data.code,
        message = data.title,
        unique_id = tostring(math.random(0000000,9999999)),
        sound = 1,
        blip = {
            sprite = data.blip?.sprite or 1,
            scale = data.blip?.scale or 1.2,
            colour = data.blip?.color or 3,
            flashes = data.priority == 'high',
            text = ('%s - %s'):format(data.code, data.title),
            time = data.time,
            radius = 0,
        }
    })
end

RegisterNetEvent('p_bridge/server/dispatch/sendAlert', function(data)
    Bridge.Dispatch.SendAlert(source, data)
end)