if (Config.Fuel == 'auto' and not checkResource('codem-fuel')) or (Config.Fuel ~= 'auto' and Config.Fuel ~= 'codem-fuel') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Fuel] Loaded: codem-fuel')
end

Bridge.Fuel = {}

Bridge.Fuel.SetFuel = function(vehicle, fuelLevel)
    exports['codem-fuel']:SetFuel(vehicle, fuelLevel)
end
