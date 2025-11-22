if (Config.CarKeys == 'auto' and not checkResource('Renewed-Vehiclekeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'Renewed-Vehiclekeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: Renewed-Vehiclekeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports['Renewed-Vehiclekeys']:addKey(vehiclePlate)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    exports['Renewed-Vehiclekeys']:removeKey(vehiclePlate)
end