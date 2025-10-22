if (Config.Fuel == 'auto' and not checkResource('Renewed-Fuel')) or (Config.Fuel ~= 'auto' and Config.Fuel ~= 'Renewed-Fuel') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Fuel] Loaded: Renewed-Fuel')
end

Bridge.Fuel = {}

Bridge.Fuel.SetFuel = function(vehicle, fuelLevel)
    exports['Renewed-Fuel']:SetFuel(vehicle, fuelLevel)
end
