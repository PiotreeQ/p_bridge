if (Config.CarKeys == 'auto' and not checkResource('cd_garage')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'cd_garage') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: cd_garage')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    TriggerEvent('cd_garage:AddKeys', exports['cd_garage']:GetPlate(vehicleEntity))
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
end