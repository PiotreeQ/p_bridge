while not Bridge do
    Citizen.Wait(0)
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

Bridge.Dispatch.SendAlert = function(data)
    if not data.coords then
        data.coords = GetEntityCoords(cache.ped)
    end

    data.street = GetStreetNameFromHashKey(GetStreetNameAtCoord(data.coords.x, data.coords.y, data.coords.z))
    TriggerServerEvent('p_bridge/server/dispatch/sendAlert', data)
end

-- Galaxis Dispatch relay - the glxs-dispatch server adapter routes alerts through
-- the alerting player so glxs can resolve name/gender/street from the event source.
RegisterNetEvent('p_bridge/client/dispatch/glxsRelay', function(alertType, coords, context)
    TriggerServerEvent('glxs-dispatch:server:SendAlert', alertType, coords, context)
end)