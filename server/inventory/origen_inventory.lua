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

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    return exports['origen_inventory']:getInventoryItems(playerId)
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    lib.print.error('CustomDrop is not supported in origen_inventory, please change type in config')
end

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

Bridge.Inventory.createShop = function(shopName, data)
    while GetResourceState('origen_inventory') ~= 'started' do
        Citizen.Wait(100)
    end
    exports['origen_inventory']:createShop(shopName, {
        label = data.name or 'Shop',
        slots = #data.inventory,
        items = data.inventory,
        locations = data.locations,
    })
end