if (Config.CarKeys == 'auto' and not checkResource('is_carkeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'is_carkeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: is_carkeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports["is_vehiclekeys"]:GiveKey(vehiclePlate)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    exports["is_vehiclekeys"]:RemoveKey(vehiclePlate)
end