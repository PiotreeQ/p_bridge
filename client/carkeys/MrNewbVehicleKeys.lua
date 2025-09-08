if (Config.CarKeys == 'auto' and not checkResource('MrNewbVehicleKeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'MrNewbVehicleKeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: MrNewbVehicleKeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports.MrNewbVehicleKeys:GiveKeysByPlate(vehiclePlate)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    exports.MrNewbVehicleKeys:RemoveKeysByPlate(vehiclePlate)
end