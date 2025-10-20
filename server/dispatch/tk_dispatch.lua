if (Config.Dispatch == 'auto' and not checkResource('tk_dispatch')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'tk_dispatch') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Dispatch] Loaded: tk-dispatch')
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
    exports['tk_dispatch']:addCall({
        title = data.title,
        code = data.code,
        priority = data.priority or 'normal',
        coords = vector3(plyCoords.x, plyCoords.y, plyCoords.z),
        showTime = 5000,
        jobs = data.job,
        blip = {
            sprite = data.blip?.sprite or 1,
            scale = data.blip?.scale or 1.1,
            color = data.blip?.color or 1,
            flash = data.priority == 'high',
            shortRange = true
        }
    })
end

RegisterNetEvent('p_bridge/server/dispatch/sendAlert', function(data)
    local _source = source
    Bridge.Dispatch.SendAlert(_source, data)
end)