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
    -- ox-compatible builds expose CustomDrop; older ones have no server drop export
    local ok = InvUtils.call('origen_inventory', { 'CustomDrop', 'customDrop' }, prefix, InvUtils.dropEntries(items), coords)
    if not ok then
        lib.print.error('CustomDrop is not supported in origen_inventory, please change type in config')
    end
end

Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['origen_inventory']:addItem(playerId, itemName, itemCount, itemMetadata, itemSlot)
end

Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    local ok, result = InvUtils.call('origen_inventory', { 'removeItem', 'RemoveItem' }, playerId, itemName, itemCount, itemMetadata, itemSlot)
    return ok and result ~= false
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

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    return exports['origen_inventory']:Items(itemName)
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
-- origen_inventory follows the ox_inventory API (lowercase names, ox signatures),
-- so stashes are registered the ox way; re-registering updates the size like ox.
-- Every call tries the lowercase name first, then the ox-cased alias.
Bridge.Inventory.registerStash = function(stashId, label, slots, weight, owner, groups, coords)
    while GetResourceState('origen_inventory') ~= 'started' do
        Citizen.Wait(100)
    end
    InvUtils.call('origen_inventory', { 'registerStash', 'RegisterStash' }, stashId, label or stashId, slots or 50, weight or 100000, owner, groups, coords)
end

--@param stashId: string [stash id]
--@return items: table [{ name, count, metadata, slot }]
Bridge.Inventory.getStashItems = function(stashId)
    local ok, items = InvUtils.call('origen_inventory', { 'getInventoryItems', 'GetInventoryItems' }, stashId)
    return InvUtils.normalizeList(ok and items or nil)
end

--@return success: boolean
Bridge.Inventory.addItemToStash = function(stashId, itemName, itemCount, itemMetadata)
    local ok, result = InvUtils.call('origen_inventory', { 'addItem', 'AddItem' }, stashId, itemName, itemCount, itemMetadata)
    return ok and result and true or false
end

--@return success: boolean
Bridge.Inventory.removeItemFromStash = function(stashId, itemName, itemCount, itemMetadata, itemSlot)
    local ok, result = InvUtils.call('origen_inventory', { 'removeItem', 'RemoveItem' }, stashId, itemName, itemCount, itemMetadata, itemSlot)
    return ok and result ~= false
end

--@return canCarry: boolean
Bridge.Inventory.canCarryItem = function(playerId, itemName, itemCount)
    local ok, result = InvUtils.call('origen_inventory', { 'canCarryItem', 'CanCarryItem' }, playerId, itemName, itemCount or 1)
    if not ok then return true end
    return result and true or false
end

---@param playerId: number|string [player id or stash id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    local ok = InvUtils.call('origen_inventory', { 'setMetadata', 'SetMetadata' }, playerId, slot, metadata or {})
    return ok and true or false
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
        lib.print.error('clearInventory only supports player ids in origen_inventory')
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