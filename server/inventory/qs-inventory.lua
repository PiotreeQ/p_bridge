if (Config.Inventory == 'auto' and not checkResource('qs-inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'qs-inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: qs-inventory')
end

Bridge.Inventory = {}

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    return exports['qs-inventory']:GetInventory(playerId) or {}
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    lib.print.error('CustomDrop is not supported in qs-inventory, please change type in config')
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['qs-inventory']:AddItem(playerId, itemName, itemCount, itemSlot, itemMetadata)
end

--@param stashId: string [stash id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param stashSlots: number [stash slot count, optional]
--@param stashMaxWeight: number [stash max weight, optional]
--@return success: boolean [whether the item landed in the stash]
-- qs-inventory's AddItem is player-only; stashes have a dedicated export.
Bridge.Inventory.addItemToStash = function(stashId, itemName, itemCount, itemMetadata, stashSlots, stashMaxWeight)
    local ok = pcall(function()
        exports['qs-inventory']:AddItemIntoStash(stashId, itemName, itemCount, nil, itemMetadata or {}, stashSlots, stashMaxWeight)
    end)
    return ok
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to remove]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['qs-inventory']:RemoveItem(playerId, itemName, itemCount, itemSlot, itemMetadata)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    if itemMetadata then
        local items = exports['qs-inventory']:GetInventory(playerId)
        for k, v in pairs(items) do
            if v.name == itemName and v.info and lib.table.matches(v.info, itemMetadata) then
                return v.amount
            end
        end
    else
        return exports['qs-inventory']:GetItemTotalAmount(playerId, itemName)
    end

    return 0
end

--@param playerId: number [existing player id]
--@param slot: number [item slot]
--@return item: {name: string, label: string, amount: number, metadata: table}
Bridge.Inventory.getItemSlot = function(playerId, slot)
    local items = exports['qs-inventory']:GetInventory(playerId)
    local itemData = items[slot]
    return itemData and {name = itemData.name, label = itemData.label, amount = itemData.amount, metadata = itemData.info or {}} or nil
end

---@param shopName: string [unique shop name]
---@param data: table [shop data]
-- qs-inventory shops are opened client-side with their items passed inline
-- (see client/inventory/qs-inventory.lua), so nothing to register here.
Bridge.Inventory.createShop = function(shopName, data)
    return
end

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    local items = exports['qs-inventory']:GetItemList()
    return items and items[itemName] or nil
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
-- qs-inventory creates stashes lazily when they are first opened, so nothing to
-- pre-register here; kept for interface parity with ox_inventory.
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    return
end

---@param playerId: number [existing player id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    exports['qs-inventory']:SetItemMetadata(playerId, slot, metadata)
end

---@param invId: number|string [player id]
---@return inventory: table|nil [{ items = { [slot] = { name, amount, info, slot } } }]
Bridge.Inventory.getInventory = function(invId)
    return { items = exports['qs-inventory']:GetInventory(invId) }
end

---@param invId: number|string [player id]
Bridge.Inventory.clearInventory = function(invId)
    exports['qs-inventory']:ClearInventory(invId)
end

---@param event: string [hook name]
---@param cb: function [hook callback]
---@param options: table|nil [hook options]
---@return nil [inventory hooks are ox_inventory only]
Bridge.Inventory.registerHook = function(event, cb, options)
    return nil
end