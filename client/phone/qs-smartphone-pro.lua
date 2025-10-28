if (Config.Phone == 'auto' and not checkResource('qs-smartphone-pro')) or (Config.Phone ~= 'auto' and Config.Phone ~= 'qs-smartphone-pro') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Phone] Loaded: qs-smartphone-pro')
end

Bridge.Phone = {}

Bridge.Phone.toggleDisabled = function(state) -- true = disable, false = enable
    exports['qs-smartphone-pro']:SetCanOpenPhone(not state)
end