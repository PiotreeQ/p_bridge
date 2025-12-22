if (Config.CarKeys == 'auto' and not checkResource('sna-vehiclekeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'sna-vehiclekeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: sna-vehiclekeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    TriggerEvent("vehiclekeys:client:SetOwner", vehiclePlate)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
        TriggerServerEvent('qb-vehiclekeys:server:RemoveKey', vehiclePlate)
end