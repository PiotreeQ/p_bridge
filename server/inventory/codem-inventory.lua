if (Config.Inventory == 'auto' and not checkResource('codem-inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'codem-inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: codem-inventory')
end

Bridge.Inventory = {}

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    local identifier = Bridge.Framework.getUniqueId(playerId)
    return exports['codem-inventory']:GetInventory(identifier, playerId)
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    lib.print.error('CustomDrop is not supported in codem-inventory, please change type in config')
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['codem-inventory']:AddItem(playerId, itemName, itemCount, itemSlot, itemMetadata)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to remove]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['codem-inventory']:RemoveItem(playerId, itemName, itemCount, itemSlot)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    if itemMetadata then
        local items = exports['codem-inventory']:GetInventory(playerId)
        for k, v in pairs(items) do
            if v.name == itemName and v.info and lib.table.matches(v.info, itemMetadata) then
                return v.amount
            end
        end
    else
        return exports['codem-inventory']:GetItemsTotalAmount(playerId, itemName)
    end

    return 0
end

--@param playerId: number [existing player id]
--@param slot: number [item slot]
--@return item: {name: string, label: string, amount: number, metadata: table}
Bridge.Inventory.getItemSlot = function(playerId, slot)
    local itemData = exports['codem-inventory']:GetItemBySlot(playerId, slot)
    return itemData and {name = itemData.name, label = itemData.label, amount = itemData.amount, metadata = itemData.info or {}} or nil
end