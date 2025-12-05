if (Config.Inventory == 'auto' and not checkResource('S-inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'S-inventory') then
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