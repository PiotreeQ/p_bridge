if (Config.Inventory == 'auto' and not (checkResource('S-Inventory') or checkResource('S-inventory'))) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'S-Inventory' and Config.Inventory ~= 'S-inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: S-inventory')
end

Bridge.Inventory = {}

local ESX = exports['es_extended']:getSharedObject()

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    return xPlayer.getInventory()
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    -- S-inventory does not support custom drops
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    xPlayer.addInventoryItem(itemName, itemCount)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    local ok = pcall(xPlayer.removeInventoryItem, itemName, itemCount, itemMetadata)
    return ok -- guard.lua confirms the count really went down
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    local item = xPlayer.getInventoryItem(itemName)
    return item and item.count or 0
end

Bridge.Inventory.getItemSlot = function(playerId, slot)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    local items = xPlayer.getInventory()
    return items[slot]
end

Bridge.Inventory.createShop = function(shopName, data)
    -- S-inventory does not support shops
end

Bridge.Inventory.itemsData = {}
GlobalState['p_bridge:itemsData'] = Bridge.Inventory.itemsData

Citizen.CreateThread(function()
    while not (MySQL and MySQL.ready) do
        Citizen.Wait(100)
    end

    local result = MySQL.query.await('SELECT * FROM items')
    for k, v in pairs(result) do
        Bridge.Inventory.itemsData[v.name] = {
            label = v.label,
            description = v.description or v.label,
            weight = tonumber(v.weight),
        }
    end
    GlobalState['p_bridge:itemsData'] = Bridge.Inventory.itemsData
end)

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    local info = Bridge.Inventory.itemsData[itemName]
    return info and {name = itemName, label = info.label, description = info.description, weight = info.weight} or nil
end

-- S-Inventory addresses a stash by (uniqueid, stashid group). The bridge uses the
-- stash id for both, so the client opens OpenStashInventory(id, id) and every
-- server export below targets the same stash.
local RES = GetResourceState('S-Inventory') ~= 'missing' and 'S-Inventory' or 'S-inventory'

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots, S-Inventory is weight based]
---@param weight: number [max weight]
-- RegisterStash(stashid, name, maxweight, uniqueid); calling it again with a
-- bigger weight is how the bridge grows an existing stash.
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    while GetResourceState(RES) ~= 'started' do
        Citizen.Wait(100)
    end
    InvUtils.call(RES, 'RegisterStash', stashId, label or stashId, weight or 100000, stashId)
end

--@param stashId: string [stash id]
--@return items: table [{ name, count, metadata, slot }]
Bridge.Inventory.getStashItems = function(stashId)
    local ok, rows = InvUtils.call(RES, 'GetDataFromStashItems', stashId, stashId)
    if not ok or type(rows) ~= 'table' then return {} end
    local items = {}
    for key, row in pairs(rows) do
        if type(row) == 'table' then
            items[key] = {
                name = row.name or row.itemname or row.item,
                count = row.count or row.amount or row.itemcount or row.anzahl,
                label = row.label or row.itemlabel,
                metadata = row.metadata,
                slot = row.slot,
            }
        end
    end
    return InvUtils.normalizeList(items)
end

--@return success: boolean
Bridge.Inventory.addItemToStash = function(stashId, itemName, itemCount, itemMetadata)
    local before = InvUtils.countItems(Bridge.Inventory.getStashItems(stashId), itemName)
    -- documented stash insert with stacking ("checks for double")
    TriggerEvent('SService:Server:InsertItemsIntoStash', { name = itemName, anzahl = itemCount }, stashId, stashId)
    if InvUtils.countItems(Bridge.Inventory.getStashItems(stashId), itemName) > before then
        return true
    end
    -- the event may depend on a player source; fall back to the raw insert export
    local label = (Bridge.Inventory.getItemData(itemName) or {}).label or itemName
    local typeOfData = itemName:upper():find('^WEAPON_') and 'weapon' or 'item'
    InvUtils.call(RES, 'InsertNewItemInStash', stashId, typeOfData, itemName, itemCount, label)
    return InvUtils.countItems(Bridge.Inventory.getStashItems(stashId), itemName) > before
end

--@return success: boolean
-- DeleteItem removes the whole entry of an item, so a partial removal deletes
-- it and puts the remainder back.
Bridge.Inventory.removeItemFromStash = function(stashId, itemName, itemCount, itemMetadata, itemSlot)
    local have = InvUtils.countItems(Bridge.Inventory.getStashItems(stashId), itemName)
    if have < itemCount then return false end
    local ok = InvUtils.call(RES, 'DeleteItem', stashId, stashId, itemName)
    if not ok then return false end
    local rest = have - itemCount
    if rest > 0 then
        local label = (Bridge.Inventory.getItemData(itemName) or {}).label or itemName
        local typeOfData = itemName:upper():find('^WEAPON_') and 'weapon' or 'item'
        InvUtils.call(RES, 'InsertNewItemInStash', stashId, typeOfData, itemName, rest, label)
    end
    return true
end

--@return canCarry: boolean
Bridge.Inventory.canCarryItem = function(playerId, itemName, itemCount)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer or not xPlayer.canCarryItem then return true end
    local ok, result = pcall(xPlayer.canCarryItem, itemName, itemCount or 1)
    if not ok then return true end
    return result and true or false
end

---@param playerId: number|string [player id or stash id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    lib.print.error('setMetadata is not supported in S-inventory, please change type in config')
end

---@param invId: number|string [player id]
---@return inventory: table|nil [{ items = { name, count, label } }]
Bridge.Inventory.getInventory = function(invId)
    return { items = Bridge.Inventory.getPlayerItems(invId) }
end

---@param invId: number|string [player id]
Bridge.Inventory.clearInventory = function(invId)
    local playerId = tonumber(invId)
    if not playerId then
        lib.print.error('clearInventory only supports player ids in S-inventory')
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