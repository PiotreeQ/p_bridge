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

Bridge.Notify.showNotify = function(message, type)
    exports.lation_ui:notify({
        message = message,
        type = type or 'inform'
    })
end