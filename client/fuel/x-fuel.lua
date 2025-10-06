if (Config.Fuel == 'auto' and not checkResource('x-fuel')) or (Config.Fuel ~= 'auto' and Config.Fuel ~= 'x-fuel') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Fuel] Loaded: x-fuel')
end

Bridge.Fuel = {}

Bridge.Fuel.SetFuel = function(vehicle, fuelLevel)
    exports['x-fuel']:SetFuel(vehicle, fuelLevel)
end
