if (Config.CarKeys == 'auto' and not checkResource('tgiann-hotwire')) or (Config.CarKeys ~= 'auto' and Config.CarKeys ~= 'tgiann-hotwire') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[CarKeys] Loaded: tgiann-hotwire')
end

Bridge.CarKeys = {}

--@param vehiclePlate: string [the plate of the vehicle]
--@param vehicleEntity: number [the entity ID of the vehicle]
Bridge.CarKeys.CreateKeys = function(vehiclePlate, vehicleEntity)
    exports["tgiann-hotwire"]:GiveKeyPlate(vehiclePlate, true)
end

--@param vehiclePlate: string [the plate of the vehicle]
Bridge.CarKeys.RemoveKeys = function(vehiclePlate)
    -- empty function for compatibility, as tgiann-hotwire does not have a remove keys function
end