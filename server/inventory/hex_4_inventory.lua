if (Config.Inventory == 'auto' and not checkResource('hex_4_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'hex_4_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: hex_4_inventory')
end

Bridge.Inventory = {}

-- HEX Inventory v4 keeps player items inside the framework (xPlayer inventory on
-- ESX, PlayerData.items on QB/QBX) and only exposes exports for secondary
-- inventories (stashes/"fraction" storages, trunks, gloveboxes), clearing and
-- hooks. Player item operations therefore go through the framework object,
-- secondary inventories go through the hex_4_inventory exports.
-- Docs: https://docs.resync.me/docs/hexscripts/versionfour/inventory/exports

-- Custom inventory type used for every stash the bridge opens/clears. 'fraction'
-- is the persisted custom type documented by HEX; change it here if your build
-- uses a different name for job/custom storages.
local STASH_TYPE = 'fraction'

-- registerStash() metadata (label/weight) so openInventory can pass it along.
local registeredStashes = {}

local function getFramework()
    if ESX then return 'esx' end
    if QBCore then return 'qb' end
    if GetResourceState('qbx_core') == 'started' then return 'qbox' end
    return nil
end

local function getPlayer(playerId)
    playerId = tonumber(playerId)
    if not playerId then return nil end

    local fw = getFramework()
    if fw == 'esx' then
        return ESX.GetPlayerFromId(playerId)
    elseif fw == 'qb' then
        return QBCore.Functions.GetPlayer(playerId)
    elseif fw == 'qbox' then
        return exports.qbx_core:GetPlayer(playerId)
    end
    return nil
end

local function stashInventoryData(stashId)
    local meta = registeredStashes[stashId] or {}
    return {
        type = STASH_TYPE,
        id = stashId,
        title = meta.label or stashId,
        weight = meta.weight or false,
    }
end

RegisterNetEvent('p_bridge/inventory/openInventory', function(invType, data)
    local _source = source
    if invType == 'stash' then
        local stashId = data.owner and ('%s_%s'):format(data.id, data.owner) or data.id
        local invData = stashInventoryData(stashId)
        if data.label then invData.title = data.label end
        if data.maxWeight then invData.weight = data.maxWeight end
        exports['hex_4_inventory']:OpenInventory(_source, invData)
    elseif invType == 'player' then
        local targetId = tonumber(type(data) == 'table' and data.id or data)
        if not targetId then return end
        exports['hex_4_inventory']:OpenInventory(_source, { type = 'player', id = targetId })
    elseif invType == 'shop' then
        lib.print.error(('hex_4_inventory has no shop export, create the shop [%s] in hex_4_inventory config'):format(data and data.type or 'unknown'))
    end
end)

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, count: number, label: string, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    local player = getPlayer(playerId)
    if not player then return {} end

    local out = {}
    local fw = getFramework()
    if fw == 'esx' then
        for _, item in pairs(player.getInventory() or {}) do
            if item.name and (item.count or 0) > 0 then
                out[#out + 1] = {
                    name = item.name,
                    label = item.label,
                    amount = item.count,
                    count = item.count,
                    metadata = item.metadata or item.info or {},
                    slot = item.slot,
                }
            end
        end
    else
        for _, item in pairs(player.PlayerData and player.PlayerData.items or {}) do
            if item and item.name and (item.amount or item.count or 0) > 0 then
                out[#out + 1] = {
                    name = item.name,
                    label = item.label,
                    amount = item.amount or item.count,
                    count = item.amount or item.count,
                    metadata = item.info or item.metadata or {},
                    slot = item.slot,
                }
            end
        end
    end
    return out
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    lib.print.error('CustomDrop is not supported in hex_4_inventory, please change type in config')
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    local player = getPlayer(playerId)
    if not player then return false end

    if getFramework() == 'esx' then
        player.addInventoryItem(itemName, itemCount, itemMetadata)
        return true
    end
    return player.Functions.AddItem(itemName, itemCount, itemSlot, itemMetadata)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to remove]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    local player = getPlayer(playerId)
    if not player then return false end

    if getFramework() == 'esx' then
        player.removeInventoryItem(itemName, itemCount, itemMetadata)
        return true
    end
    return player.Functions.RemoveItem(itemName, itemCount, itemSlot)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    local count = 0
    for _, item in pairs(Bridge.Inventory.getPlayerItems(playerId)) do
        if item.name == itemName and (not itemMetadata or lib.table.matches(item.metadata or {}, itemMetadata)) then
            count = count + (item.amount or 0)
        end
    end
    return count
end

--@param playerId: number [existing player id]
--@param slot: number [item slot]
--@return item: {name: string, label: string, amount: number, metadata: table}
Bridge.Inventory.getItemSlot = function(playerId, slot)
    for _, item in pairs(Bridge.Inventory.getPlayerItems(playerId)) do
        if item.slot == slot then
            return { name = item.name, label = item.label, amount = item.amount, metadata = item.metadata or {} }
        end
    end
    return nil
end

---@param shopName: string [unique shop name]
---@param data: table [shop data]
Bridge.Inventory.createShop = function(shopName, data)
    lib.print.error(('createShop is not supported in hex_4_inventory, create the shop [%s] in hex_4_inventory config'):format(shopName))
end

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    local fw = getFramework()
    if fw == 'esx' then
        local item = ESX.Items and ESX.Items[itemName]
        return item and { name = itemName, label = item.label, description = item.description, weight = item.weight } or nil
    elseif fw == 'qb' then
        return QBCore.Shared.Items[itemName]
    elseif fw == 'qbox' then
        local items = exports.qbx_core:GetItems()
        return items and items[itemName] or nil
    end
    return nil
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
-- hex_4_inventory creates custom inventories lazily on first open; we only
-- remember the label/weight so openInventory can pass them to OpenInventory.
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    registeredStashes[stashId] = { label = label, slots = slots, weight = weight }
end

--@param stashId: string [stash id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@return success: boolean [whether the item landed in the stash]
-- AddItemToInventory is documented with a player id/object as the first two
-- arguments; server-side inserts have no player, so pass nil and let the
-- inventory decide. Wrapped in pcall so an unsupported call cannot crash callers.
Bridge.Inventory.addItemToStash = function(stashId, itemName, itemCount, itemMetadata)
    local ok, success = pcall(function()
        return exports['hex_4_inventory']:AddItemToInventory(nil, nil, { name = itemName, metadata = itemMetadata or {} }, itemCount, stashInventoryData(stashId))
    end)
    if not ok and Config.Debug then
        lib.print.warn(('[Inventory] AddItemToInventory to stash %s failed: %s'):format(stashId, tostring(success)))
    end
    return ok and success and true or false
end

---@param playerId: number|string [player id or stash id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    lib.print.error('setMetadata is not supported in hex_4_inventory, please change type in config')
end

---@param invId: number|string [player id or stash id]
---@return inventory: table|nil [{ items = { name, amount, metadata, slot } }]
Bridge.Inventory.getInventory = function(invId)
    if tonumber(invId) then
        return { items = Bridge.Inventory.getPlayerItems(invId) }
    end

    local ok, inventory = pcall(function()
        return exports['hex_4_inventory']:GetInventory(nil, stashInventoryData(invId))
    end)
    if not ok then
        if Config.Debug then
            lib.print.warn(('[Inventory] GetInventory for stash %s failed: %s'):format(invId, tostring(inventory)))
        end
        return nil
    end
    if type(inventory) == 'table' and not inventory.items then
        return { items = inventory }
    end
    return inventory
end

---@param invId: number|string [player id or stash id]
Bridge.Inventory.clearInventory = function(invId)
    local playerId = tonumber(invId)
    if not playerId then
        exports['hex_4_inventory']:ClearInventory(STASH_TYPE, invId)
        return
    end

    local player = getPlayer(playerId)
    if player and getFramework() ~= 'esx' and player.Functions.ClearInventory then
        player.Functions.ClearInventory()
        return
    end

    for _, item in pairs(Bridge.Inventory.getPlayerItems(playerId)) do
        if item.name and (item.amount or 0) > 0 then
            Bridge.Inventory.removeItem(playerId, item.name, item.amount, nil, item.slot)
        end
    end
end

---@param event: string [hook name, e.g. 'moveItemToOther' or 'hex_4_inventory:moveItemToOther']
---@param cb: function [hook callback, return false to block the action]
---@param options: table|nil [unused, kept for ox_inventory parity]
---@return id: string|nil [hook id]
-- Available hooks: giveInventoryItem, removeItem, moveItemToOther,
-- moveItemToPlayer, moveItemBetween, getOtherInventory.
Bridge.Inventory.registerHook = function(event, cb, options)
    if type(event) ~= 'string' or type(cb) ~= 'function' then return nil end
    if not event:find(':', 1, true) then
        event = 'hex_4_inventory:' .. event
    end
    return exports['hex_4_inventory']:AddHook(event, cb)
end

---@param hookId: string [hook id returned by registerHook]
---@return success: boolean
Bridge.Inventory.removeHook = function(hookId)
    if not hookId then return false end
    return exports['hex_4_inventory']:RemoveHook(hookId) and true or false
end

---@param oldPlate: string [previous vehicle plate]
---@param newPlate: string [new vehicle plate]
-- Moves trunk/glovebox contents when a vehicle plate changes.
Bridge.Inventory.changePlate = function(oldPlate, newPlate)
    exports['hex_4_inventory']:ChangeInventoryPlate(oldPlate, newPlate)
end
