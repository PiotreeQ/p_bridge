if (Config.CarKeys == 'auto' and not checkResource('qs-vehiclekeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'qs-vehiclekeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: qs-vehiclekeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicleEntity))
    exports['qs-vehiclekeys']:GiveKeys(vehiclePlate, model, true)
end

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate, vehicleEntity)
    local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicleEntity))
    exports['qs-vehiclekeys']:RemoveKeys(vehiclePlate, model)
end