if (Config.CarKeys == 'auto' and not checkResource('mk_vehiclekeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'mk_vehiclekeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: mk_vehiclekeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    if NetworkGetEntityIsNetworked(vehicleEntity) then
        exports['mk_vehiclekeys']:AddKey(vehicleEntity)
    else
        Entity(vehicleEntity).state:set('Keys', {LocalPlayer.state.mk_identifier}, true)
    end
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate, vehicleEntity)
    if NetworkGetEntityIsNetworked(vehicleEntity) then
        exports['mk_vehiclekeys']:RemoveKey(vehicleEntity)
    else
            Entity(vehicleEntity).state:set('Keys', {}, true)
    end
end