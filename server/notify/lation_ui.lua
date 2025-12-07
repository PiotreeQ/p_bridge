if (Config.Notify == 'auto' and not checkResource('lation_ui')) or (Config.Notify ~= 'auto' and Config.Notify ~= 'lation_ui') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: lation_ui')
end

Bridge.Notify = {}

Bridge.Notify.showNotify = function(playerId, message, type)
    TriggerClientEvent('lation_ui:notify', playerId, {
        message = message,
        type = type or 'info',
    })
end
