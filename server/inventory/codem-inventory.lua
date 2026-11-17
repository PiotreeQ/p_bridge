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
    local ok, result = pcall(function()
        return exports['codem-inventory']:RemoveItem(playerId, itemName, itemCount, itemSlot)
    end)
    return ok and result ~= false
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    if itemMetadata then
        local items = InvUtils.normalizeList(Bridge.Inventory.getPlayerItems(playerId))
        return InvUtils.countItems(items, itemName, itemMetadata)
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

---@param shopName: string [unique shop name]
---@param data: table [shop data]
Bridge.Inventory.createShop = function(shopName, data)
    lib.print.error(('createShop is not supported in codem-inventory, create the shop [%s] in codem-inventory config'):format(shopName))
end

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    local ok, items = pcall(function() return exports['codem-inventory']:GetItemList() end)
    local item = ok and items and items[itemName]
    if not item then return nil end
    item.name = item.name or itemName
    return item
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
-- codem-inventory creates stashes the first time they are opened and takes the
-- size from every open ('codem-inventory:server:openstash', stashId, slots,
-- weight, label); the client opens with the bigger of the caller's and the
-- registered size (guard.lua getStashInfo), which is how a stash grows.
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    return
end

-- Stash contents: GetStashItems(stashId) / UpdateStash(stashId, items) are the
-- documented pair; add/remove edit the slot table and write it back.
local function loadStash(stashId)
    local ok, items = pcall(function() return exports['codem-inventory']:GetStashItems(stashId) end)
    return InvUtils.rekeyBySlot(ok and type(items) == 'table' and items or {})
end

local function saveStash(stashId, items)
    local ok, result = pcall(function() return exports['codem-inventory']:UpdateStash(stashId, items) end)
    return ok and result ~= false
end

--@param stashId: string [stash id]
--@return items: table [{ name, count, metadata, slot }]
Bridge.Inventory.getStashItems = function(stashId)
    return InvUtils.normalizeList(loadStash(stashId))
end

--@return success: boolean
Bridge.Inventory.addItemToStash = function(stashId, itemName, itemCount, itemMetadata, stashSlots, stashMaxWeight)
    local def = Bridge.Inventory.getItemData(itemName)
    if not def then return false end
    local reg = Bridge.Inventory.getStashInfo and Bridge.Inventory.getStashInfo(stashId) or {}
    local items = loadStash(stashId)
    if not InvUtils.slotTableAdd(items, def, itemName, itemCount, itemMetadata, stashSlots or reg.slots or 100) then
        return false
    end
    return saveStash(stashId, items)
end

--@return success: boolean
Bridge.Inventory.removeItemFromStash = function(stashId, itemName, itemCount, itemMetadata, itemSlot)
    local items = loadStash(stashId)
    if not InvUtils.slotTableRemove(items, itemName, itemCount, itemMetadata, itemSlot) then return false end
    return saveStash(stashId, items)
end

---@param playerId: number|string [player id or stash id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    if tonumber(playerId) then
        local ok, result = pcall(function()
            return exports['codem-inventory']:SetItemMetadata(tonumber(playerId), slot, metadata or {})
        end)
        return ok and result ~= false
    end
    local items = loadStash(playerId)
    local item = items[tonumber(slot)]
    if not item then return false end
    item.info = metadata or {}
    return saveStash(playerId, items)
end

---@param invId: number|string [player id]
---@return inventory: table|nil [{ items = { [slot] = { name, amount, info, slot } } }]
Bridge.Inventory.getInventory = function(invId)
    return { items = Bridge.Inventory.getPlayerItems(invId) }
end

---@param invId: number|string [player id]
Bridge.Inventory.clearInventory = function(invId)
    local playerId = tonumber(invId)
    if not playerId then
        lib.print.error('clearInventory only supports player ids in codem-inventory')
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