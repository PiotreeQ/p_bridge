if (Config.Fuel == 'auto' and not checkResource('lc_fuel')) or (Config.Fuel ~= 'auto' and Config.Fuel ~= 'lc_fuel') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Fuel] Loaded: lc_fuel')
end

Bridge.Fuel = {}

Bridge.Fuel.SetFuel = function(vehicle, fuelLevel)
    exports["lc_fuel"]:SetFuel(vehicle, fuelLevel)
end
