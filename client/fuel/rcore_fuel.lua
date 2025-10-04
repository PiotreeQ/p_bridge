if (Config.Fuel == 'auto' and not checkResource('rcore_fuel')) or (Config.Fuel ~= 'auto' and Config.Fuel ~= 'rcore_fuel') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Fuel] Loaded: rcore_fuel')
end

Bridge.Fuel = {}

Bridge.Fuel.SetFuel = function(vehicle, fuelLevel)
    exports['rcore_fuel']:SetVehicleFuel(vehicle, fuelLevel)
end
