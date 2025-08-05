if (Config.CarKeys == 'auto' and not checkResource('qbx_vehiclekeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'qbx_vehiclekeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: qbx_vehiclekeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    TriggerServerEvent('qbx_vehiclekeys:server:hotwiredVehicle', Bridge.Utils.getNetIdFromEntity(vehicleEntity))
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    -- empty function for compatibility, as qb-vehiclekeys does not have a remove keys function
end