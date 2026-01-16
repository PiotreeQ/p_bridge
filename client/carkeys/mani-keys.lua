if (Config.CarKeys == 'auto' and not checkResource('mani-keys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'mani-keys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: mani-keys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    export['mani-keys']:GiveKeyServerId(vehicleEntity, cache.serverId)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    export['mani-keys']:RemoveKeyServerId(vehicleEntity, cache.serverId)
end