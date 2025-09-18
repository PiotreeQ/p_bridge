if (Config.Notify == 'auto' and not checkResource('ox_lib')) or (Config.Notify ~= 'auto' and Config.Notify ~= 'ox_lib') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: ox_lib')
end

Bridge.Notify = {}

Bridge.Notify.showNotify = function(message, type)
    lib.notify({
        description = message,
        type = type or 'inform'
    })
end