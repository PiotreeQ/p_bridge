if (Config.CarKeys == 'auto' and not checkResource('wasabi_carlock')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'wasabi_carlock') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: wasabi_carlock')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports['wasabi_carlock']:GiveKey(vehiclePlate)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    exports['wasabi_carlock']:RemoveKey(vehiclePlate)
end