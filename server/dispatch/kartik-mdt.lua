if (Config.Dispatch == 'auto' and not checkResource('kartik-mdt')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'kartik-mdt') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Dispatch] Loaded: kartik-mdt')
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
    local alertJobs = {}
    if data.job then
        if type(data.job) == 'string' then
            alertJobs[data.job] = true
        elseif type(data.job) == 'table' then
            for k, v in pairs(data.job) do
                if type(v) == 'string' then
                    alertJobs[v] = true
                elseif type(k) == 'string' and type(v) =='boolean' then
                    alertJobs[k] = v
                end
            end
        end
    end
    local dispatchData = {
        title = data.title,
        code = data.code,
        description = data.description or ('%s - %s'):format(data.code, data.title),
        sound = "dispatch", 
        x = plyCoords.x,
        y = plyCoords.y,
        z = plyCoords.z,
        type = "Alert", 
        blip = {
            sprite = data.blip?.sprite or 1,
            color = data.blip?.color or 1,
            scale = data.blip?.scale or 1.2,
            length = data.time
        },
        jobs = data.job and alertJobs or {['police'] = true}
    }
    TriggerEvent('kartik-mdt:server:sendDispatchNotification', dispatchData)
end

RegisterNetEvent('p_bridge/server/dispatch/sendAlert', function(data)
    Bridge.Dispatch.SendAlert(source, data)
end)