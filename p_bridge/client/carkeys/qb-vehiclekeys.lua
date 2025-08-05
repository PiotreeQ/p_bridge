if (Config.CarKeys == 'auto' and not checkResource('qb-vehiclekeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'qb-vehiclekeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: qb-vehiclekeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', vehiclePlate)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    -- empty function for compatibility, as qb-vehiclekeys does not have a remove keys function
end