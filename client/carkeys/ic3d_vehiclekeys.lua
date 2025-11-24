if (Config.CarKeys == 'auto' and not checkResource('ic3d_vehiclekeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'ic3d_vehiclekeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: ic3d_vehiclekeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports.ic3d_vehiclekeys:ClientInventoryKeys('add', vehiclePlate)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    exports.ic3d_vehiclekeys:ClientInventoryKeys('remove', vehiclePlate)
end