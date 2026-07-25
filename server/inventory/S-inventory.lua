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
    xPlayer.removeInventoryItem(itemName, itemCount, itemMetadata)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    return xPlayer.getInventoryItem(itemName)?.count or 0
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
    while not MySQL?.ready do
        Citizen.Wait(100)
    end

    local result = MySQL.query.await('SELECT * FROM items')
    for k, v in pairs(result) do
        Bridge.Inventory.itemsData[v.name] = {
            label = v.label,
            description = v.description or v.label,
        }
    end
    GlobalState['p_bridge:itemsData'] = Bridge.Inventory.itemsData
end)

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    local info = Bridge.Inventory.itemsData[itemName]
    return info and {name = itemName, label = info.label, description = info.description} or nil
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
-- S-inventory stashes are opened client-side with their data, so nothing to
-- pre-register here; kept for interface parity with ox_inventory.
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    return
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