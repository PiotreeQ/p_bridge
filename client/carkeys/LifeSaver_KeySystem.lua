if (Config.CarKeys == 'auto' and not checkResource('LifeSaver_KeySystem')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'LifeSaver_KeySystem') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: LifeSaver_KeySystem')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports['LifeSaver_KeySystem']:AddCarkey(vehiclePlate, GetDisplayNameFromVehicleModel(GetEntityModel(vehicleEntity)))
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate, vehicleEntity)
    exports['LifeSaver_KeySystem']:RemoveCarkey(vehiclePlate, GetDisplayNameFromVehicleModel(GetEntityModel(vehicleEntity)))
end