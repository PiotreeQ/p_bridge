if (Config.Fuel == 'auto' and not checkResource('LegacyFuel')) or (Config.Fuel ~= 'auto' and Config.Fuel ~= 'LegacyFuel') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Fuel] Loaded: LegacyFuel')
end

Bridge.Fuel = {}

Bridge.Fuel.SetFuel = function(vehicle, fuelLevel)
    exports['LegacyFuel']:SetFuel(vehicle, fuelLevel)
end
