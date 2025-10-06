if (Config.CarKeys == 'auto' and not checkResource('vehicles_keys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'vehicles_keys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: vehicles_keys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    TriggerServerEvent("vehicles_keys:selfGiveVehicleKeys", vehiclePlate)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    TriggerServerEvent("vehicles_keys:selfRemoveKeys", vehiclePlate)
end