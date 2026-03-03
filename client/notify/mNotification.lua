if (Config.Notify == 'auto' and not checkResource('mNotification')) or (Config.Notify ~= 'auto' and Config.Notify ~= 'mNotification') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: mNotification')
end

Bridge.Notify = {}

Bridge.Notify.showNotify = function(message, type)
    TriggerEvent('codem-notification:Create', message, type, nil, 5000)
end