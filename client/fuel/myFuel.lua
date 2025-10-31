if (Config.Fuel == 'auto' and not checkResource('myFuel')) or (Config.Fuel ~= 'auto' and Config.Fuel ~= 'myFuel') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Fuel] Loaded: myFuel')
end

Bridge.Fuel = {}

Bridge.Fuel.SetFuel = function(vehicle, fuelLevel)
    exports['myFuel']:SetFuel(vehicle, fuelLevel)
end
