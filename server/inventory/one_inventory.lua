if (Config.Inventory == 'auto' and not checkResource('one_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'one_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: one_inventory')
end

Bridge.Inventory = {}

--@param playerId: number [existing player id]
--@return items: table [{name: string, count: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    return exports['one_inventory']:GetInventoryItems(playerId)
end

--@param prefix: string [prefix for the drop, unused in one_inventory]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    exports['one_inventory']:CreateDrop(coords, InvUtils.dropEntries(items))
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['one_inventory']:AddItem(playerId, itemName, itemCount, itemMetadata, itemSlot)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to remove]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    local ok, result = pcall(function()
        return exports['one_inventory']:RemoveItem(playerId, itemName, itemCount, itemMetadata, itemSlot)
    end)
    return ok and result and true or false
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    return exports['one_inventory']:GetItemCount(playerId, itemName, itemMetadata)
end

---@param playerId: number [existing player id]
---@param slot: number [inventory slot]
Bridge.Inventory.getItemSlot = function(playerId, slot)
    return exports['one_inventory']:GetSlot(playerId, slot)
end

---@param shopName: string [unique shop name]
---@param data: table
Bridge.Inventory.createShop = function(shopName, data)
    while GetResourceState('one_inventory') ~= 'started' do
        Citizen.Wait(100)
    end

    Citizen.Wait(100)
    exports['one_inventory']:RegisterShop({
        name = shopName,
        label = data.name or data.label or 'Shop',
        coords = data.coords or data.locations,
        jobs = data.groups,
        inventory = data.inventory
    })
end

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    return exports['one_inventory']:GetItemDefinition(itemName)
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
-- one_inventory has no stash-creation export: 'stash:<name>' inventories are
-- created on first open (OpenInventory 'stash' with id/slots/maxWeight/label) or
-- on the first AddItem (defaults 50 slots / 50 kg). The client opens with the
-- bigger of the caller's and the registered size (guard.lua getStashInfo).
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    return
end

-- server-side id of a shared stash opened as { id = stashId }
local function stashInv(stashId)
    return ('stash:%s'):format(stashId)
end

--@param stashId: string [stash id]
--@return items: table [{ name, count, metadata, slot }]
Bridge.Inventory.getStashItems = function(stashId)
    local ok, items = pcall(function() return exports['one_inventory']:GetInventoryItems(stashInv(stashId)) end)
    return InvUtils.normalizeList(ok and items or nil)
end

--@return success: boolean
Bridge.Inventory.addItemToStash = function(stashId, itemName, itemCount, itemMetadata)
    local ok, result = pcall(function()
        return exports['one_inventory']:AddItem(stashInv(stashId), itemName, itemCount, itemMetadata)
    end)
    return ok and result and true or false
end

--@return success: boolean
Bridge.Inventory.removeItemFromStash = function(stashId, itemName, itemCount, itemMetadata, itemSlot)
    local ok, result = pcall(function()
        return exports['one_inventory']:RemoveItem(stashInv(stashId), itemName, itemCount, itemMetadata, itemSlot)
    end)
    return ok and result and true or false
end

--@return canCarry: boolean
Bridge.Inventory.canCarryItem = function(playerId, itemName, itemCount)
    local ok, result = pcall(function()
        return exports['one_inventory']:CanCarryItem(playerId, itemName, itemCount or 1)
    end)
    if not ok then return true end
    return result and true or false
end

---@param playerId: number|string [player id or stash/inventory id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    -- plain stash ids map to their 'stash:<id>' inventory
    local inv = tonumber(playerId) or (tostring(playerId):find(':', 1, true) and playerId or stashInv(playerId))
    local ok, result = pcall(function()
        return exports['one_inventory']:SetItemMetadata(inv, slot, metadata or {})
    end)
    return ok and result ~= false
end

---@param invId: number|string [player id or stash/inventory id]
---@return inventory: table|nil [{ slots, weight, maxWeight, ... }]
Bridge.Inventory.getInventory = function(invId)
    return exports['one_inventory']:GetInventory(invId)
end

---@param invId: number|string [player id or stash/inventory id]
Bridge.Inventory.clearInventory = function(invId)
    exports['one_inventory']:ClearInventory(invId)
end

---@param event: string [one_inventory hook name, e.g. 'beforeItemAdd']
---@param cb: function [hook callback, return false to cancel]
---@param options: table|nil [hook options, e.g. { itemFilter, inventoryFilter, typeFilter }]
---@return id: number|nil [hook id]
Bridge.Inventory.registerHook = function(event, cb, options)
    return exports['one_inventory']:RegisterHook(event, cb, options)
end
