if (Config.Notify == 'auto' and not checkResource('g-notifications')) or (Config.Notify ~= 'auto' and Config.Notify ~= 'g-notifications') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: g-notifications')
end

Bridge.Notify = {}

Bridge.Notify.showNotify = function(message, type)
    if type == 'inform' then
        type = 'info'
    end

    exports["g-notifications"]:Notify({
	    title = "Notification",
	    description = message,
	    type = type or "info",
    })
end