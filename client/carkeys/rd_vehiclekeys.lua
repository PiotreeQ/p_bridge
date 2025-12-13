if (Config.CarKeys == 'auto' and not checkResource('rd_vehiclekeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'rd_vehiclekeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: rd_vehiclekeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    TriggerServerEvent('rd_vehiclekeys:server:GiveKeys', vehiclePlate)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    TriggerServerEvent('rd_vehiclekeys:server:RemoveKeys', vehiclePlate)
end