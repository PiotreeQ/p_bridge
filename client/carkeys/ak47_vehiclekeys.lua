if (Config.CarKeys == 'auto' and not checkResource('ak47_vehiclekeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'ak47_vehiclekeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: ak47_vehiclekeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports['ak47_vehiclekeys']:GiveKey(vehiclePlate, false)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    exports['ak47_vehiclekeys']:RemoveKey(vehiclePlate, false)
end