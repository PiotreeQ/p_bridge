if (Config.Inventory == 'auto' and not checkResource('ak47_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'ak47_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: ak47_inventory')
end

Bridge.Inventory = {}

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    return exports['ak47_inventory']:GetInventoryItems(playerId)
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    lib.print.error('ak47_inventory does not support CustomDrop function, please change type in config')
end
--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['ak47_inventory']:AddItem(playerId, itemName, itemCount, itemSlot, itemMetadata)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to remove]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    local ok, result = pcall(function()
        return exports['ak47_inventory']:RemoveItem(playerId, itemName, itemCount, itemSlot)
    end)
    return ok and result and true or false
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    return exports['ak47_inventory']:GetAmount(playerId, itemName)
end

--@param playerId: number [existing player id]
--@param slot: number [item slot]
--@return item: {name: string, label: string, amount: number, metadata: table}
Bridge.Inventory.getItemSlot = function(playerId, slot)
    local ok, itemData = InvUtils.call('ak47_inventory', { 'GetSlot', 'getSlot' }, playerId, slot)
    if not ok or type(itemData) ~= 'table' or not itemData.name then return nil end
    local amount = itemData.amount or itemData.count or 0
    return {name = itemData.name, label = itemData.label, amount = amount, count = amount, slot = itemData.slot or slot, metadata = itemData.info or itemData.metadata or {}}
end

---@param shopName: string [unique shop name]
---@param data: table
Bridge.Inventory.createShop = function(shopName, data)
    while GetResourceState('ak47_inventory') ~= 'started' do
        Citizen.Wait(100)
    end

    Citizen.Wait(100)
    exports['ak47_inventory']:CreateShop(shopName, shopName, data, 'money')
end

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    return exports['ak47_inventory']:Items(itemName)
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    while GetResourceState('ak47_inventory') ~= 'started' do
        Citizen.Wait(100)
    end

    Citizen.Wait(100)
    -- CreateInventory loads the stash into memory (required before AddItem /
    -- RemoveItem / GetInventoryItems reach it). Called again with a bigger size
    -- for an existing stash; whether ak47 applies it to a loaded inventory is
    -- not documented.
    pcall(function()
        exports['ak47_inventory']:CreateInventory(stashId, {
            label = label,
            slots = slots,
            maxWeight = weight,
            type = 'stash'
        })
    end)
end

--@param stashId: string [stash id]
--@return items: table [{ name, count, metadata, slot }]
Bridge.Inventory.getStashItems = function(stashId)
    local ok, items = pcall(function() return exports['ak47_inventory']:GetInventoryItems(stashId) end)
    return InvUtils.normalizeList(ok and items or nil)
end

--@return success: boolean
Bridge.Inventory.addItemToStash = function(stashId, itemName, itemCount, itemMetadata)
    local ok, result = pcall(function()
        return exports['ak47_inventory']:AddItem(stashId, itemName, itemCount, nil, itemMetadata)
    end)
    return ok and result and true or false
end

--@return success: boolean
Bridge.Inventory.removeItemFromStash = function(stashId, itemName, itemCount, itemMetadata, itemSlot)
    -- RemoveItem has no metadata filter: remove from the matching stacks slot by slot
    local plan = InvUtils.planRemoval(Bridge.Inventory.getStashItems(stashId), itemName, itemCount, itemMetadata, itemSlot)
    if not plan then return false end
    for _, step in ipairs(plan) do
        local ok, result = pcall(function()
            return exports['ak47_inventory']:RemoveItem(stashId, itemName, step.count, step.slot)
        end)
        if not ok or not result then return false end
    end
    return true
end

--@return canCarry: boolean
Bridge.Inventory.canCarryItem = function(playerId, itemName, itemCount)
    local ok, result = pcall(function()
        return exports['ak47_inventory']:CanAddItem(playerId, itemName, itemCount or 1)
    end)
    if not ok then return true end
    return result and true or false
end

---@param playerId: number|string [player id or stash id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    local ok, result = pcall(function()
        return exports['ak47_inventory']:SetItemInfo(playerId, slot, metadata or {})
    end)
    return ok and result ~= false
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
        lib.print.error('clearInventory only supports player ids in ak47_inventory')
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