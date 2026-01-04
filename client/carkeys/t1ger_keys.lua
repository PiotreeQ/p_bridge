if (Config.CarKeys == 'auto' and not checkResource('t1ger_keys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 't1ger_keys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: t1ger_keys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports['t1ger_keys']:GiveTemporaryKeys(vehiclePlate, GetDisplayNameFromVehicleModel(GetEntityModel(vehicleEntity)), 'type')
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
end