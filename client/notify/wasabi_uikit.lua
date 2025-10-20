if (Config.Notify == 'auto' and not checkResource('wasabi_uikit')) or (Config.Notify ~= 'auto' and Config.Notify ~= 'wasabi_uikit') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: wasabi_uikit')
end

Bridge.Notify = {}

Bridge.Notify.showNotify = function(message, type)
    if type == 'inform' then
        type = 'info'
    end
    
    exports.wasabi_uikit:Notification({
        title = message,
        type = type,
    })
end