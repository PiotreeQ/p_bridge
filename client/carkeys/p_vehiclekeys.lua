if (Config.CarKeys == 'auto' and not checkResource('p_vehiclekeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'p_vehiclekeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: p_vehiclekeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports['p_vehiclekeys']:createKey(vehiclePlate, vehicleEntity)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate, vehicleEntity)
    exports['p_vehiclekeys']:removeKey(vehiclePlate, vehicleEntity, true)
end