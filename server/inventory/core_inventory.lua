if (Config.Inventory == 'auto' and not checkResource('core_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'core_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: core_inventory')
end

Bridge.Inventory = {}
Bridge.Inventory.Items = {}

local function addItemData(name, data)
    Bridge.Inventory.Items[name] = {
        name = name,
        label = data.label,
        weight = data.weight,
        description = data.description,
        image = ('https://cfx-nui-core_inventory/html/img/%s.png'):format(name)
    }
end

local function isQBCore()
    if Config.Framework == 'auto' then
        return checkResource('qb-core') or checkResource('qbx_core')
    end
    return Config.Framework == 'qb' or Config.Framework == 'qbox'
end

local function loadItems()
    if isQBCore() then
        -- QBCore keeps items in shared config instead of the database
        local core = QBCore or exports['qb-core']:GetCoreObject()
        for name, data in pairs(core.Shared.Items or {}) do
            addItemData(name, data)
        end
        return
    end

    while not (MySQL and MySQL.ready) do
        Citizen.Wait(100)
    end

    local result = MySQL.query.await('SELECT * FROM items')
    for k, v in ipairs(result or {}) do
        addItemData(v.name, v)
    end
end

Citizen.CreateThread(loadItems)

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    local items = exports['core_inventory']:getItems(playerId)
    return items
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    lib.print.error('CustomDrop is not supported in core_inventory, please change type in config')
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['core_inventory']:addItem(playerId, itemName, itemCount, itemMetadata)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to remove]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    local ok, result = pcall(function()
        return exports['core_inventory']:removeItem(playerId, itemName, itemCount)
    end)
    return ok and result ~= false
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    return exports.core_inventory:getItemCount(playerId, itemName)
end

--@param playerId: number [existing player id]
--@param slot: number [item slot]
--@return item: {name: string, label: string, amount: number, metadata: table}
Bridge.Inventory.getItemSlot = function(playerId, slot)
    local ok, itemData = pcall(function() return exports.core_inventory:getItemBySlot(playerId, slot) end)
    if not ok or not itemData then return nil end
    local amount = itemData.amount or itemData.count or 0
    return {name = itemData.name, label = itemData.label, amount = amount, count = amount, slot = slot, metadata = itemData.metadata or itemData.info or {}}
end

---@param shopName: string [unique shop name]
---@param data: table [shop data]
Bridge.Inventory.createShop = function(shopName, data)
    lib.print.error(('createShop is not supported in core_inventory, create the shop [%s] in core_inventory config'):format(shopName))
end

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    return Bridge.Inventory.Items[itemName]
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
-- core_inventory names inventories freely ('<anything unique>') and sizes them
-- by type ('stash' in Config.Inventories). openInventory with a nil source only
-- creates/loads the inventory; updateInventorySize grows it when asked.
-- Grid inventory: there is no weight limit to apply.
local STASH_TYPE = 'stash'
local STASH_ROWS = 10 -- slots per row of the default 'stash' type

Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    while GetResourceState('core_inventory') ~= 'started' do
        Citizen.Wait(100)
    end
    pcall(function()
        exports['core_inventory']:openInventory(nil, stashId, STASH_TYPE, label)
    end)
    if tonumber(slots) then
        pcall(function()
            exports['core_inventory']:updateInventorySize(stashId, tonumber(slots), STASH_ROWS)
        end)
    end
end

RegisterNetEvent('p_bridge/inventory/openInventory', function(invType, data)
    local _source = source
    if invType ~= 'stash' or type(data) ~= 'table' or not data.id then return end
    local stashId = data.owner and ('%s_%s'):format(data.id, data.owner) or data.id
    local reg = Bridge.Inventory.getStashInfo and Bridge.Inventory.getStashInfo(stashId) or {}
    local slots = math.max(tonumber(data.slots) or 0, reg.slots or 0)
    if slots > 0 and slots > (reg.slots or 0) then
        pcall(function() exports['core_inventory']:updateInventorySize(stashId, slots, STASH_ROWS) end)
    end
    exports['core_inventory']:openInventory(_source, stashId, STASH_TYPE, data.label or reg.label, nil, true)
end)

--@param stashId: string [stash id]
--@return items: table [{ name, count, metadata, slot }]
Bridge.Inventory.getStashItems = function(stashId)
    local ok, inv = pcall(function() return exports['core_inventory']:getInventory(stashId) end)
    return InvUtils.normalizeList(ok and inv and (inv.content or inv.items) or nil)
end

--@return success: boolean
Bridge.Inventory.addItemToStash = function(stashId, itemName, itemCount, itemMetadata)
    local ok, result = pcall(function()
        return exports['core_inventory']:addItem(stashId, itemName, itemCount, itemMetadata or {}, STASH_TYPE)
    end)
    return ok and result ~= false
end

--@return success: boolean
Bridge.Inventory.removeItemFromStash = function(stashId, itemName, itemCount, itemMetadata, itemSlot)
    -- removeItem takes the first matching stack and ignores metadata; when a slot
    -- or metadata matters, remove each planned stack by its unique content id
    if not itemSlot and not itemMetadata then
        local ok, result = pcall(function()
            return exports['core_inventory']:removeItem(stashId, itemName, itemCount, STASH_TYPE)
        end)
        return ok and result ~= false
    end

    local plan = InvUtils.planRemoval(Bridge.Inventory.getStashItems(stashId), itemName, itemCount, itemMetadata, itemSlot)
    if not plan then return false end
    for _, step in ipairs(plan) do
        local okItem, item = pcall(function() return exports['core_inventory']:getItemBySlot(stashId, step.slot) end)
        local uid = okItem and item and item.id
        if not uid then return false end
        local ok, result = pcall(function()
            return exports['core_inventory']:removeItemExact(stashId, uid, step.count)
        end)
        if not ok or result == false then return false end
    end
    return true
end

--@return canCarry: boolean
Bridge.Inventory.canCarryItem = function(playerId, itemName, itemCount)
    local ok, result = pcall(function()
        return exports['core_inventory']:canCarry(playerId, itemName, itemCount or 1)
    end)
    if not ok then return true end
    return result and true or false
end

---@param playerId: number|string [player id or stash id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    local ok = pcall(function()
        exports['core_inventory']:updateMetadata(playerId, slot, metadata or {})
    end)
    return ok
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
        lib.print.error('clearInventory only supports player ids in core_inventory')
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

lib.callback.register('p_bridge/core_inventory/getItemsData', function()
    return Bridge.Inventory.Items
end)