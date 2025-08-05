if (Config.Notify == 'auto' and not checkResource('brutal_notify')) or (Config.Notify ~= 'auto' and Config.Notify ~= 'brutal') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: brutal_notify')
end

Bridge.Notify = {}

Bridge.Notify.showNotify = function(playerId, message, type)
    TriggerClientEvent('brutal_notify:SendAlert', playerId, 'Brutal Notify', message, 5000, type)
end
