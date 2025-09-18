if (Config.CarKeys == 'auto' and not checkResource('ak47_qb_vehiclekeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'ak47_qb_vehiclekeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: ak47_qb_vehiclekeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports['ak47_qb_vehiclekeys']:GiveKey(vehiclePlate, not NetworkGetEntityIsNetworked(vehicleEntity))
end

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate, vehicleEntity)
    exports['ak47_qb_vehiclekeys']:RemoveKey(vehiclePlate, not NetworkGetEntityIsNetworked(vehicleEntity))
end