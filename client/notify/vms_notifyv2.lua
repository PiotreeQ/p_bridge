if (Config.Notify == 'auto' and not checkResource('vms_notifyv2')) or (Config.Notify ~= 'auto' and Config.Notify ~= 'vms_notifyv2') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: vms_notifyv2')
end

Bridge.Notify = {}

Bridge.Notify.showNotify = function(message, type)
    exports['vms_notifyv2']:Notification({
        description = message,
    })
end