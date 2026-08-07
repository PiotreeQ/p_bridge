if (Config.Dispatch == 'auto' and not checkResource('glxs-dispatch')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'glxs-dispatch') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Dispatch] Loaded: glxs-dispatch')
end

Bridge.Dispatch = {}

-- Galaxis Dispatch has no generic custom-alert export - every alert must reference
-- an alert type defined in glxs-dispatch/cfg_alerts.lua. Add this entry to
-- Config.AlertTypes there (adjust code/blip/jobs to taste):
--
--     ['p_bridge_alert'] = {
--         code = '10-31',
--         title = 'Police Alert',
--         message = 'Requires attention',
--         icon = 'fas fa-bell',
--         priority = 2,
--         soundFile = 'dp_generic.ogg',
--         fields = { 'location', 'message' },
--         targetJobs = { 'police' },
--         blip = { sprite = 161, color = 1, duration = 60000 },
--     },
--
local ALERT_TYPE = 'p_bridge_alert'

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
    local coords = vec3(plyCoords.x, plyCoords.y, plyCoords.z)

    -- glxs-dispatch resolves name/gender/street from the event source, so the alert
    -- is relayed through the alerting player's client instead of being sent from here.
    TriggerClientEvent('p_bridge/client/dispatch/glxsRelay', playerId, ALERT_TYPE, coords, {
        coords = coords,
        message = ('%s - %s'):format(data.code, data.title),
    })
end

RegisterNetEvent('p_bridge/server/dispatch/sendAlert', function(data)
    Bridge.Dispatch.SendAlert(source, data)
end)
