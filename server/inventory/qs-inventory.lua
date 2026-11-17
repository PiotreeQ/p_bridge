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
    local reg = Bridge.Inventory.getStashInfo and Bridge.Inventory.getStashInfo(stashId) or {}
    stashSlots = stashSlots or reg.slots or 50
    stashMaxWeight = stashMaxWeight or reg.weight or 500000
    local ok, result = pcall(function()
        return exports['qs-inventory']:AddItemIntoStash(stashId, itemName, itemCount, nil, itemMetadata or {}, stashSlots, stashMaxWeight)
    end)
    return ok and result ~= false
end

--@param stashId: string [stash id]
--@return items: table [{ name, count, metadata, slot }]
Bridge.Inventory.getStashItems = function(stashId)
    local ok, items = pcall(function() return exports['qs-inventory']:GetStashItems(stashId) end)
    return InvUtils.normalizeList(ok and items or nil)
end

--@param stashId: string [stash id]
--@param itemName: string [item name]
--@param itemCount: number [amount to remove]
--@param itemMetadata: table|nil [metadata filter]
--@param itemSlot: number|nil [slot]
--@return success: boolean
Bridge.Inventory.removeItemFromStash = function(stashId, itemName, itemCount, itemMetadata, itemSlot)
    local plan = InvUtils.planRemoval(Bridge.Inventory.getStashItems(stashId), itemName, itemCount, itemMetadata, itemSlot)
    if not plan then return false end
    local reg = Bridge.Inventory.getStashInfo and Bridge.Inventory.getStashInfo(stashId) or {}
    for _, step in ipairs(plan) do
        local ok, result = pcall(function()
            return exports['qs-inventory']:RemoveItemIntoStash(stashId, itemName, step.count, step.slot, reg.slots, reg.weight)
        end)
        if not ok or result == false then return false end
    end
    return true
end

--@param playerId: number [existing player id]
--@return canCarry: boolean
Bridge.Inventory.canCarryItem = function(playerId, itemName, itemCount)
    local ok, result = pcall(function()
        return exports['qs-inventory']:CanCarryItem(playerId, itemName, itemCount or 1)
    end)
    if not ok then return true end
    return result and true or false
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to remove]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    local ok, result = pcall(function()
        return exports['qs-inventory']:RemoveItem(playerId, itemName, itemCount, itemSlot, itemMetadata)
    end)
    return ok and result ~= false
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
    local ok, items = pcall(function() return exports['qs-inventory']:GetInventory(playerId) end)
    local itemData = ok and items and (items[slot] or items[tostring(slot)])
    if not itemData then return nil end
    local amount = itemData.amount or itemData.count or 0
    return {name = itemData.name, label = itemData.label, amount = amount, count = amount, slot = itemData.slot or slot, metadata = itemData.info or itemData.metadata or {}}
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
-- qs-inventory creates a stash the first time it is opened or touched by
-- AddItemIntoStash (which takes slots/weight); its server RegisterStash export
-- needs a player and opens the UI, so nothing is created here. The size kept by
-- guard.lua (getStashInfo) is passed on every open and AddItemIntoStash, which is
-- how a re-registered stash grows.
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    return
end

---@param playerId: number [existing player id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    local ok, result = pcall(function()
        return exports['qs-inventory']:SetItemMetadata(playerId, slot, metadata or {})
    end)
    return ok and result ~= false
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