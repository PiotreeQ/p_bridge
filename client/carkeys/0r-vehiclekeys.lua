if (Config.CarKeys == 'auto' and not checkResource('0r-vehiclekeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= '0r-vehiclekeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: 0r-vehiclekeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports['0r-vehiclekeys']:GiveKeys(vehiclePlate)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    exports['0r-vehiclekeys']:RemoveKeys(vehiclePlate)
end