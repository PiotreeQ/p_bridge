if (Config.CarKeys == 'auto' and not checkResource('mm_carkeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'mm_carkeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: mm_carkeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports.mm_carkeys:GiveKeyItem(vehiclePlate, vehicleEntity)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    exports.mm_carkeys:RemoveKeyItem(vehiclePlate)
end