if (Config.Phone == 'auto' and not checkResource('npwd')) or (Config.Phone ~= 'auto' and Config.Phone ~= 'npwd') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Phone] Loaded: npwd')
end

Bridge.Phone = {}

Bridge.Phone.toggleDisabled = function(state) -- true = disable, false = enable
    exports['npwd']:setPhoneDisabled(state)
end