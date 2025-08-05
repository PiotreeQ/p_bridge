if (Config.Inventory == 'auto' and not checkResource('origen_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'origen_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: origen_inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['origen_inventory']:addItem(playerId, itemName, itemCount, itemMetadata, itemSlot)
end

Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['origen_inventory']:removeItem(playerId, itemName, itemCount, itemMetadata, itemSlot)
end

Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    return exports['origen_inventory']:getItemCount(playerId, itemName, itemMetadata)
end

Bridge.Inventory.getItemSlot = function(playerId, slot)
    return exports['origen_inventory']:getSlot(playerId, slot)
end