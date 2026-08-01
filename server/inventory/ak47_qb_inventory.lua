if (Config.Inventory == 'auto' and not checkResource('ak47_qb_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'ak47_qb_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: ak47_qb_inventory')
end

Bridge.Inventory = {}

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    return exports['ak47_qb_inventory']:GetInventoryItems(playerId)
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    lib.print.error('ak47_qb_inventory does not support CustomDrop function, please change type in config')
end
--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['ak47_qb_inventory']:AddItem(playerId, itemName, itemCount, itemSlot, itemMetadata)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to remove]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['ak47_qb_inventory']:RemoveItem(playerId, itemName, itemCount, itemSlot)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    return exports['ak47_qb_inventory']:getItemCount(playerId, 'count', itemName, itemMetadata)
end

--@param playerId: number [existing player id]
--@param slot: number [item slot]
--@return item: {name: string, label: string, amount: number, metadata: table}
Bridge.Inventory.getItemSlot = function(playerId, slot)
    local itemData = exports['ak47_qb_inventory']:getSlot(playerId, slot)
    return itemData and {name = itemData.name, label = itemData.label, amount = itemData.amount, metadata = itemData.info or {}} or nil
end

---@param shopName: string [unique shop name]
---@param data: table
Bridge.Inventory.createShop = function(shopName, data)
    while GetResourceState('ak47_qb_inventory') ~= 'started' do
        Citizen.Wait(100)
    end

    Citizen.Wait(100)
    exports['ak47_qb_inventory']:CreateShop(shopName, shopName, data, 'money')
end

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    return exports['ak47_qb_inventory']:Items(itemName)
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    while GetResourceState('ak47_qb_inventory') ~= 'started' do
        Citizen.Wait(100)
    end

    Citizen.Wait(100)
    exports['ak47_qb_inventory']:CreateInventory(stashId, {
        label = label,
        slots = slots,
        maxWeight = weight,
        type = 'stash'
    })
end

---@param playerId: number|string [player id or stash id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    lib.print.error('setMetadata is not supported in ak47_qb_inventory, please change type in config')
end

---@param invId: number|string [player id]
---@return inventory: table|nil [{ items = { name, amount, metadata, slot } }]
Bridge.Inventory.getInventory = function(invId)
    return { items = Bridge.Inventory.getPlayerItems(invId) }
end

---@param invId: number|string [player id]
Bridge.Inventory.clearInventory = function(invId)
    local playerId = tonumber(invId)
    if not playerId then
        lib.print.error('clearInventory only supports player ids in ak47_qb_inventory')
        return
    end

    for _, item in pairs(Bridge.Inventory.getPlayerItems(playerId) or {}) do
        local amount = item.amount or item.count
        if item.name and amount and amount > 0 then
            Bridge.Inventory.removeItem(playerId, item.name, amount, nil, item.slot)
        end
    end
end

---@param event: string [hook name]
---@param cb: function [hook callback]
---@param options: table|nil [hook options]
---@return nil [inventory hooks are ox_inventory only]
Bridge.Inventory.registerHook = function(event, cb, options)
    return nil
end