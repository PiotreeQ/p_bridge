if (Config.Fuel == 'auto' and not checkResource('lyre_fuel')) or (Config.Fuel ~= 'auto' and Config.Fuel ~= 'lyre_fuel') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Fuel] Loaded: lyre_fuel')
end

Bridge.Fuel = {}

Bridge.Fuel.SetFuel = function(vehicle, fuelLevel)
    exports["lyre_fuel"]:SetFuel(vehicle, fuelLevel)
end
