if (Config.CarKeys == 'auto' and not checkResource('p_carkeys')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'p_carkeys') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: p_carkeys')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    TriggerServerEvent('p_carkeys:CreateKeys', vehiclePlate)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    TriggerServerEvent('p_carkeys:RemoveKeys', vehiclePlate)
end