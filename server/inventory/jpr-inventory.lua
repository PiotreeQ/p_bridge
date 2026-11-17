if (Config.Inventory == 'auto' and not checkResource('jpr-inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'jpr-inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: jpr-inventory')
end

Bridge.Inventory = {}

RegisterNetEvent('p_bridge/inventory/openInventory', function(invType, data)
    local _source = source
    if invType == 'shop' then
        exports['jpr-inventory']:OpenShop(_source, data.type)
    elseif invType == 'player' then
        exports['jpr-inventory']:OpenInventoryById(_source, tonumber(type(data) == 'table' and data.id or data))
    else
        -- OpenInventory(source, identifier, data): the id must be the stash
        -- STRING, the size goes in the data table (qb-inventory rewrite API)
        if type(data) ~= 'table' or not data.id then return end
        local stashId = data.owner and ('%s_%s'):format(data.id, data.owner) or data.id
        local reg = Bridge.Inventory.getStashInfo and Bridge.Inventory.getStashInfo(stashId) or {}
        local slots = math.max(tonumber(data.slots) or 0, reg.slots or 0)
        local maxWeight = math.max(tonumber(data.maxWeight) or 0, reg.weight or 0)
        exports['jpr-inventory']:OpenInventory(_source, stashId, {
            label = data.label or reg.label or stashId,
            slots = slots > 0 and slots or nil,
            maxweight = maxWeight > 0 and maxWeight or nil,
        })
    end
end)

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    -- jpr keeps player items on QBCore PlayerData (qb layout)
    local Player = QBCore and QBCore.Functions.GetPlayer(tonumber(playerId))
    if Player then
        local out = {}
        for _, item in pairs(Player.PlayerData.items or {}) do
            if item and item.name then out[#out + 1] = item end
        end
        return out
    end
    local ok, items = pcall(function() return exports["jpr-inventory"]:GetInventory(playerId) end)
    return ok and items or {}
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    lib.print.error('CustomDrop is not supported in jpr-inventory, please change type in config')
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['jpr-inventory']:AddItem(playerId, itemName, itemCount, itemSlot, itemMetadata)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to remove]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    local ok, result = pcall(function()
        return exports['jpr-inventory']:RemoveItem(playerId, itemName, itemCount, itemSlot, 'p_bridge:removeItem')
    end)
    return ok and result ~= false
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    if itemMetadata and QBCore then
        local Player = QBCore.Functions.GetPlayer(playerId)
        local items = Player.PlayerData.items
        for k, v in pairs(items) do
            if v.name == itemName and v.info and lib.table.matches(v.info, itemMetadata) then
                return v.amount
            end
        end
    else
        return exports['jpr-inventory']:GetItemCount(playerId, itemName)
    end

    return 0
end

--@param playerId: number [existing player id]
--@param slot: number [item slot]
--@return item: {name: string, label: string, amount: number, metadata: table}
Bridge.Inventory.getItemSlot = function(playerId, slot)
    local itemSlot = exports['jpr-inventory']:GetItemBySlot(playerId, slot)
    return itemSlot and {name = itemSlot.name, label = itemSlot.label, amount = itemSlot.amount, metadata = itemSlot.info or {}} or nil
end

---@param shopName: string [unique shop name]
---@param data: table [shop data]
Bridge.Inventory.createShop = function(shopName, data)
    for i = 1, #data.inventory, 1 do
        if not data.inventory[i].slot then
            data.inventory[i].slot = i
        end
        
        if not data.inventory[i].amount then
            data.inventory[i].amount = 1000
        end
    end
    exports['jpr-inventory']:CreateShop({
        name = shopName,
        label = data.label or shopName,
        slots = #data.inventory,
        items = data.inventory
    })
end

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    return QBCore and QBCore.Shared.Items[itemName] or nil
end

---@param invId: number|string [player id]
---@return inventory: table|nil [{ items = { [slot] = { name, amount, info, slot } } }]
Bridge.Inventory.getInventory = function(invId)
    if tonumber(invId) then
        return { items = Bridge.Inventory.getPlayerItems(invId) }
    end
    local ok, inv = pcall(function() return exports['jpr-inventory']:GetInventory(invId) end)
    if not ok or type(inv) ~= 'table' then return nil end
    return inv.items and inv or { items = inv }
end

---@param invId: number|string [player id]
Bridge.Inventory.clearInventory = function(invId)
    local playerId = tonumber(invId)
    if not playerId then
        lib.print.error('clearInventory only supports player ids in jpr-inventory')
        return
    end

    for _, item in pairs(Bridge.Inventory.getPlayerItems(playerId) or {}) do
        local amount = item.amount or item.count
        if item.name and amount and amount > 0 then
            Bridge.Inventory.removeItem(playerId, item.name, amount, nil, item.slot)
        end
    end
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
-- jpr-inventory mirrors the qb-inventory rewrite API: CreateInventory puts a
-- stash in memory so AddItem/RemoveItem/GetInventory reach it before anyone
-- opened it. An existing stash is resized by OpenInventory's data table, which
-- the open handler fills with the bigger of the caller's and registered size.
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    if Bridge.Inventory.getInventory(stashId) then return end
    InvUtils.call('jpr-inventory', 'CreateInventory', stashId, {
        label = label or stashId,
        slots = slots or 50,
        maxweight = weight or 500000,
    })
end

--@param stashId: string [stash id]
--@return items: table [{ name, count, metadata, slot }]
Bridge.Inventory.getStashItems = function(stashId)
    local inv = Bridge.Inventory.getInventory(stashId)
    return InvUtils.normalizeList(inv and inv.items or nil)
end

--@return success: boolean
Bridge.Inventory.addItemToStash = function(stashId, itemName, itemCount, itemMetadata, stashSlots, stashMaxWeight)
    if not Bridge.Inventory.getInventory(stashId) then
        Bridge.Inventory.registerStash(stashId, stashId, stashSlots, stashMaxWeight)
    end
    local ok, result = pcall(function()
        return exports['jpr-inventory']:AddItem(stashId, itemName, itemCount, false, itemMetadata or false, 'p_bridge:addItemToStash')
    end)
    return ok and result and true or false
end

--@return success: boolean
Bridge.Inventory.removeItemFromStash = function(stashId, itemName, itemCount, itemMetadata, itemSlot)
    -- RemoveItem ignores metadata, so remove slot by slot from the matching stacks
    local plan = InvUtils.planRemoval(Bridge.Inventory.getStashItems(stashId), itemName, itemCount, itemMetadata, itemSlot)
    if not plan then return false end
    for _, step in ipairs(plan) do
        local ok, result = pcall(function()
            return exports['jpr-inventory']:RemoveItem(stashId, itemName, step.count, step.slot or false, 'p_bridge:removeItemFromStash')
        end)
        if not ok or result == false then return false end
    end
    return true
end

--@return canCarry: boolean
Bridge.Inventory.canCarryItem = function(playerId, itemName, itemCount)
    local ok, result = InvUtils.call('jpr-inventory', 'CanAddItem', playerId, itemName, itemCount or 1)
    if not ok then return true end
    return result and true or false
end

---@param playerId: number|string [player id or stash id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    if not tonumber(playerId) then
        lib.print.error('setMetadata on a stash is not supported in jpr-inventory')
        return false
    end
    -- jpr documents editing PlayerData.items + SetPlayerData for item info
    return InvUtils.qbSetPlayerSlotInfo(playerId, slot, metadata or {})
end

---@param event: string [hook name]
---@param cb: function [hook callback]
---@param options: table|nil [hook options]
---@return nil [inventory hooks are ox_inventory only]
Bridge.Inventory.registerHook = function(event, cb, options)
    return nil
end