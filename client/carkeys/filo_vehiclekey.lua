if (Config.CarKeys == 'auto' and not checkResource('filo_vehiclekey')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'filo_vehiclekey') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: filo_vehiclekey')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports.filo_vehiclekey:GiveKeys(vehiclePlate)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    exports.filo_vehiclekey:RemoveKeys(vehiclePlate)
end