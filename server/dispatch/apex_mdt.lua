if (Config.Dispatch == 'auto' and not checkResource('apex_mdt')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'apex_mdt') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Dispatch] Loaded: apex_mdt')
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
    local coords = data.coords
    if not coords then
        local plyPed = GetPlayerPed(playerId)
        coords = GetEntityCoords(plyPed)
    end

    local mode = 'police'
    if data.job then
        local jobs = type(data.job) == 'table' and data.job or { data.job }
        for k, v in pairs(jobs) do
            local jobName = type(v) == 'string' and v or k
            if jobName == 'ambulance' or jobName == 'ems' or jobName == 'doctor' then
                mode = 'ems'
                break
            end
        end
    end

    exports['apex_mdt']:CreateCall({
        mode = mode,
        code = data.code,
        label = data.title,
        priority = data.priority or 'medium',
        desc = data.description or ('%s - %s'):format(data.code or '10-71', data.title or 'Alert'),
        location = data.street,
        coords = vec3(coords.x, coords.y, coords.z),
    })
end

RegisterNetEvent('p_bridge/server/dispatch/sendAlert', function(data)
    Bridge.Dispatch.SendAlert(source, data)
end)
