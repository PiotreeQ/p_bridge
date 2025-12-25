if (Config.Dispatch == 'auto' and not checkResource('core_dispatch')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'core_dispatch') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Dispatch] Loaded: core_dispatch')
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
    exports['core_dispatch']:addCall(
        data.code, 
        data.title,
        {},
        {
            data.coords or plyCoords
        },
        'police', 
        3000, 
        data.blip?.sprite or 1, 
        data.blip?.color or 3,
        false
    )
end

RegisterNetEvent('p_bridge/server/dispatch/sendAlert', function(data)
    Bridge.Dispatch.SendAlert(source, data)
end)