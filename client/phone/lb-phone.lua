if (Config.Phone == 'auto' and not checkResource('lb-phone')) or (Config.Phone ~= 'auto' and Config.Phone ~= 'lb-phone') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Phone] Loaded: lb-phone')
end

Bridge.Phone = {}

Bridge.Phone.toggleDisabled = function(state)
    exports['lb-phone']:ToggleDisabled(state)
end