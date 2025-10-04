if (Config.Fuel == 'auto' and not checkResource('ox_fuel')) or (Config.Fuel ~= 'auto' and Config.Fuel ~= 'ox_fuel') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Fuel] Loaded: OX')
end

Bridge.Fuel = {}

Bridge.Fuel.SetFuel = function(vehicle, fuelLevel)
    SetVehicleFuelLevel(vehicle, fuelLevel)
    Entity(vehicle).state.fuel = fuelLevel
end
