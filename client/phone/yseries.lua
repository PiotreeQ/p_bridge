if (Config.Phone == 'auto' and not checkResource('yseries')) or (Config.Phone ~= 'auto' and Config.Phone ~= 'yseries') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Phone] Loaded: yseries')
end

Bridge.Phone = {}

Bridge.Phone.toggleDisabled = function(state) -- true = disable, false = enable
    exports['yseries']:ToggleDisabled(state)
end