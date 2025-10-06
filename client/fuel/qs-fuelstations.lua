if (Config.Fuel == 'auto' and not checkResource('qs-fuelstations')) or (Config.Fuel ~= 'auto' and Config.Fuel ~= 'qs-fuelstations') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Fuel] Loaded: qs-fuelstations')
end

Bridge.Fuel = {}

Bridge.Fuel.SetFuel = function(vehicle, fuelLevel)
    exports['qs-fuelstations']:SetFuel(vehicle, fuelLevel)
end
