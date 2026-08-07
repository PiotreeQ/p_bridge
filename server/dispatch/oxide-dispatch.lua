if (Config.Dispatch == 'auto' and not checkResource('oxide-dispatch')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'oxide-dispatch') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Dispatch] Loaded: oxide-dispatch')
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

    local priority = 2
    if data.priority == 'high' then
        priority = 1
    elseif data.priority == 'low' then
        priority = 3
    end

    exports['oxide-dispatch']:CreateAlert({
        code = data.code,
        title = data.title,
        message = data.title,
        priority = priority,
        jobs = data.job,
        coords = vec3(plyCoords.x, plyCoords.y, plyCoords.z),
        icon = data.icon,
        blipData = {
            sprite = data.blip?.sprite or 1,
            color = data.blip?.color or 1,
            scale = data.blip?.scale or 1.0,
        },
        source_type = 'player',
        source_name = GetPlayerName(playerId),
        expireMinutes = data.time,
        street = data.street,
    })
end

RegisterNetEvent('p_bridge/server/dispatch/sendAlert', function(data)
    Bridge.Dispatch.SendAlert(source, data)
end)
