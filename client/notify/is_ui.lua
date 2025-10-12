if (Config.Notify == 'auto' and not checkResource('is_ui')) or (Config.Notify ~= 'auto' and Config.Notify ~= 'is_ui') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: is_ui')
end

Bridge.Notify = {}

Bridge.Notify.showNotify = function(message, type)
    exports["is_ui"]:Notify(message, nil, 5000, type)
end