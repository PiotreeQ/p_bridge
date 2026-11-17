if (Config.Dispatch == 'auto' and not checkResource('nn_dispatch')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'nn_dispatch') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Dispatch] Loaded: nn_dispatch')
end

Bridge.Dispatch = {}

-- nn_dispatch priority: 0 emergency ... 3 information
local priorities = { high = 1, medium = 2, low = 3 }

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
    local jobs = data.job or 'police'

    return exports['nn_dispatch']:SendAlert({
        title = data.title,
        message = data.message or data.street,
        code = data.code,
        priority = priorities[data.priority] or 2,
        jobs = type(jobs) == 'table' and jobs or { jobs },
        coords = data.coords and vector3(data.coords.x, data.coords.y, data.coords.z) or vector3(plyCoords.x, plyCoords.y, plyCoords.z),
        blip = {
            sprite = data.blip?.sprite or 1,
            colour = data.blip?.color or 1,
            flash = data.priority == 'high',
            time = (data.time or 5) * 60000
        }
    })
end

RegisterNetEvent('p_bridge/server/dispatch/sendAlert', function(data)
    Bridge.Dispatch.SendAlert(source, data)
end)
