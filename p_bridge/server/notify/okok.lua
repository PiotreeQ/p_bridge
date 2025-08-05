if (Config.Notify == 'auto' and not checkResource('okokNotify')) or (Config.Notify ~= 'auto' and Config.Notify ~= 'okok') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: okok')
end

Bridge.Notify = {}

Bridge.Notify.showNotify = function(playerId, message, type)
    TriggerClientEvent('okokNotify:Alert', playerId, 'okokNotify', message, 5000, type)
end
