if (Config.Dispatch == 'auto' and not checkResource('tgiann-policealert')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'tgiann-policealert') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Dispatch] Loaded: tgiann-policealert')
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
    
    if data.priority == 'normal' then data.priority = 'low' end
    if data.priority == 'risk' then data.priority = 'high' end
    if data.priority ~= 'low' and data.priority ~= 'medium' and data.priority ~= 'high' then
        data.priority = 'low'
    end

    exports["tgiann-policealert"]:Alert(src, {
        jobs = data.jobs or {'police'},
        label = data.title,
        coords = plyCoords,
        code = data.code,
        policeCount = data.maxOfficers,
        icon = data.icon,
        iconColor = '#FF0000',
        bgAnimate = false,
        gender = true,
        blip = data.blip?.sprite or 280,
})
end

RegisterNetEvent('p_bridge/server/dispatch/sendAlert', function(data)
    Bridge.Dispatch.SendAlert(source, data)
end)