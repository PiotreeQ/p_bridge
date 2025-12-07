if (Config.CarKeys == 'auto' and not checkResource('brutal_carkeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'brutal_carkeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: brutal_carkeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports.brutal_keys:addVehicleKey(vehiclePlate, 'car')
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    exports.brutal_keys:removeKey(vehiclePlate, true)
end