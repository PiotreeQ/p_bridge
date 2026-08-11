if (Config.Inventory == 'auto' and not checkResource('ox_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'ox_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: ox_inventory')
end

Bridge.Inventory = {}

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    return exports['ox_inventory']:GetInventoryItems(playerId)
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    exports['ox_inventory']:CustomDrop(prefix, items, coords)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['ox_inventory']:AddItem(playerId, itemName, itemCount, itemMetadata, itemSlot)
end

--@param stashId: string [stash id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@return success: boolean [whether the item landed in the stash]
Bridge.Inventory.addItemToStash = function(stashId, itemName, itemCount, itemMetadata)
    local success = exports['ox_inventory']:AddItem(stashId, itemName, itemCount, itemMetadata)
    return success and true or false
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['ox_inventory']:RemoveItem(playerId, itemName, itemCount, itemMetadata, itemSlot)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    return exports['ox_inventory']:Search(playerId, 'count', itemName, itemMetadata)
end

---@param playerId: number [existing player id]
---@param slot: number [inventory slot]
Bridge.Inventory.getItemSlot = function(playerId, slot)
    return exports['ox_inventory']:GetSlot(playerId, slot)
end

---@param shopName: string [unique shop name]
---@param data: table
Bridge.Inventory.createShop = function(shopName, data)
    while GetResourceState('ox_inventory') ~= 'started' do
        Citizen.Wait(100)
    end

    Citizen.Wait(100)
    exports['ox_inventory']:RegisterShop(shopName, data)
end

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    return exports['ox_inventory']:Items(itemName)
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    while GetResourceState('ox_inventory') ~= 'started' do
        Citizen.Wait(100)
    end

    Citizen.Wait(100)
    exports['ox_inventory']:RegisterStash(stashId, label, slots, weight)
end

---@param playerId: number|string [player id or stash/inventory id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    exports['ox_inventory']:SetMetadata(playerId, slot, metadata)
end

---@param invId: number|string [player id or stash/inventory id]
---@return inventory: table|nil [{ items = { [slot] = { name, count, metadata, slot } } }]
Bridge.Inventory.getInventory = function(invId)
    return exports['ox_inventory']:GetInventory(invId)
end

---@param invId: number|string [player id or stash/inventory id]
Bridge.Inventory.clearInventory = function(invId)
    exports['ox_inventory']:ClearInventory(invId)
end

---@param event: string [ox_inventory hook name, e.g. 'swapItems']
---@param cb: function [hook callback]
---@param options: table|nil [ox hook options, e.g. { itemFilter = { body_cam = true } }]
---@return id: number|nil [hook id (ox_inventory only)]
Bridge.Inventory.registerHook = function(event, cb, options)
    return exports['ox_inventory']:registerHook(event, cb, options)
end