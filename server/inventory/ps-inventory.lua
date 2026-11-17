if (Config.Inventory == 'auto' and not checkResource('ps-inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'ps-inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: ps-inventory')
end

Bridge.Inventory = {}

RegisterNetEvent('p_bridge/inventory/openInventory', function(invType, data)
    if invType == 'shop' then
        exports['ps-inventory']:OpenShop(source, data.type)
    elseif invType == 'player' then
        exports['ps-inventory']:OpenInventoryById(source, data)
    else
        -- stashes are opened client-side through inventory:server:OpenInventory
        -- (see client/inventory/ps-inventory.lua); this path is only a fallback
        local _source = source
        local stashId = type(data) == 'table' and (data.owner and ('%s_%s'):format(data.id, data.owner) or data.id) or data
        if type(stashId) ~= 'string' then return end
        pcall(function()
            exports['ps-inventory']:OpenInventory(_source, stashId, type(data) == 'table' and {
                label = data.label, slots = data.slots, maxweight = data.maxWeight,
            } or nil)
        end)
    end
end)

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    -- ps-inventory keeps player items on PlayerData (legacy qb layout)
    local Player = QBCore and QBCore.Functions.GetPlayer(tonumber(playerId))
    if Player then
        local out = {}
        for _, item in pairs(Player.PlayerData.items or {}) do
            if item and item.name then out[#out + 1] = item end
        end
        return out
    end
    local ok, inv = pcall(function() return exports['ps-inventory']:GetInventory(playerId) end)
    return ok and inv and inv.items or {}
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    lib.print.error('CustomDrop is not supported in ps-inventory, please change type in config')
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['ps-inventory']:AddItem(playerId, itemName, itemCount, itemSlot, itemMetadata)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to remove]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    local ok, result = pcall(function()
        return exports['ps-inventory']:RemoveItem(playerId, itemName, itemCount, itemSlot)
    end)
    return ok and result ~= false
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    -- total over every stack (GetItemByName only returns the first one, and
    -- its quantity field is `amount`, not `count`)
    local items = InvUtils.normalizeList(Bridge.Inventory.getPlayerItems(playerId))
    return InvUtils.countItems(items, itemName, itemMetadata)
end

--@param playerId: number [existing player id]
--@param slot: number [item slot]
--@return item: {name: string, label: string, amount: number, metadata: table}
Bridge.Inventory.getItemSlot = function(playerId, slot)
    local itemSlot = exports['ps-inventory']:GetItemBySlot(playerId, slot)
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
    exports['ps-inventory']:CreateShop({
        name = shopName,
        label = data.label,
        slots = #data.inventory,
        items = data.inventory
    })
end

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    return QBCore and QBCore.Shared.Items[itemName] or nil
end

---@param invId: number|string [player id or stash id]
---@return inventory: table|nil [{ items = { [slot] = { name, amount, info, slot } } }]
Bridge.Inventory.getInventory = function(invId)
    return exports['ps-inventory']:GetInventory(invId)
end

---@param invId: number|string [player id]
Bridge.Inventory.clearInventory = function(invId)
    local playerId = tonumber(invId)
    if not playerId then
        lib.print.error('clearInventory only supports player ids in ps-inventory')
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
-- ps-inventory (lj/legacy qb layout) keeps each stash as one JSON row in
-- `stashitems` and takes the size from every open call, so there is nothing to
-- create; the client opens with the bigger of the caller's and the registered
-- size (guard.lua getStashInfo), which is how a re-registered stash grows.
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    return
end

-- Server-side stash access goes straight to the `stashitems` row, which is what
-- ps-inventory loads when the stash is opened. A stash that is open in someone's
-- UI at that moment is saved back from memory on close and would overwrite it.

--@param stashId: string [stash id]
--@return items: table [{ name, count, metadata, slot }]
Bridge.Inventory.getStashItems = function(stashId)
    return InvUtils.normalizeList(InvUtils.dbStashLoad(stashId))
end

--@return success: boolean
Bridge.Inventory.addItemToStash = function(stashId, itemName, itemCount, itemMetadata, stashSlots, stashMaxWeight)
    local reg = Bridge.Inventory.getStashInfo and Bridge.Inventory.getStashInfo(stashId) or {}
    local ok, result = pcall(InvUtils.dbStashAdd, stashId, itemName, itemCount, itemMetadata, stashSlots or reg.slots)
    return ok and result and true or false
end

--@return success: boolean
Bridge.Inventory.removeItemFromStash = function(stashId, itemName, itemCount, itemMetadata, itemSlot)
    local ok, result = pcall(InvUtils.dbStashRemove, stashId, itemName, itemCount, itemMetadata, itemSlot)
    return ok and result and true or false
end

--@return canCarry: boolean
Bridge.Inventory.canCarryItem = function(playerId, itemName, itemCount)
    -- no CanAddItem in the legacy layout: compare weights against qb's max
    local def = InvUtils.qbItemDef(itemName)
    local Player = QBCore and QBCore.Functions.GetPlayer(tonumber(playerId))
    if not def or not Player then return true end
    local ok, total = pcall(function()
        return exports['ps-inventory']:GetTotalWeight(Player.PlayerData.items)
    end)
    local maxWeight = (QBCore.Config and QBCore.Config.Player and QBCore.Config.Player.MaxWeight) or 120000
    if not ok or type(total) ~= 'number' then return true end
    return total + (def.weight or 0) * (itemCount or 1) <= maxWeight
end

---@param playerId: number|string [player id or stash id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    if tonumber(playerId) then
        return InvUtils.qbSetPlayerSlotInfo(playerId, slot, metadata or {})
    end
    local items = InvUtils.dbStashLoad(playerId)
    local item = items[tonumber(slot)]
    if not item then return false end
    item.info = metadata or {}
    return InvUtils.dbStashSave(playerId, items)
end

---@param event: string [hook name]
---@param cb: function [hook callback]
---@param options: table|nil [hook options]
---@return nil [inventory hooks are ox_inventory only]
Bridge.Inventory.registerHook = function(event, cb, options)
    return nil
end