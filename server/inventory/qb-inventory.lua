if (Config.Inventory == 'auto' and not checkResource('qb-inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'qb-inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: qb-inventory')
end

Bridge.Inventory = {}

-- qb-inventory exists in two very different generations: the rewrite exposes
-- GetInventory/OpenInventoryById/CreateInventory and identifier-routed AddItem,
-- the legacy build has none of those (player-only exports + event-based UI).
-- Detect once and pick the matching code path everywhere below.
local hasNewApi
local function newApi()
    if hasNewApi == nil then
        hasNewApi = pcall(function()
            return exports['qb-inventory']:GetInventory('__p_bridge_probe')
        end)
        if Config.Debug then
            lib.print.info(('[Inventory] qb-inventory API generation: %s'):format(hasNewApi and 'rewrite' or 'legacy'))
        end
    end
    return hasNewApi
end

RegisterNetEvent('p_bridge/inventory/openInventory', function(invType, data)
    local _source = source
    if invType == 'shop' then
        exports['qb-inventory']:OpenShop(_source, data.type)
    elseif invType == 'player' then
        if newApi() then
            exports['qb-inventory']:OpenInventoryById(_source, tonumber(data))
        else
            -- legacy build: event-based, uses the handler's source
            TriggerEvent('inventory:server:OpenInventory', 'otherplayer', tostring(data))
        end
    else
        -- The inventory id must be a STRING; passing the data table creates a
        -- broken in-memory inventory that never persists.
        local stashId = data.owner and ('%s_%s'):format(data.id, data.owner) or data.id
        local stashData = nil
        if data.slots or data.maxWeight or data.label then
            stashData = { slots = data.slots, maxweight = data.maxWeight, label = data.label }
        end

        if newApi() then
            exports['qb-inventory']:OpenInventory(_source, stashId, stashData)
        else
            TriggerClientEvent('inventory:client:SetCurrentStash', _source, stashId)
            TriggerEvent('inventory:server:OpenInventory', 'stash', stashId, stashData or { maxweight = 4000000, slots = 50 })
        end
    end
end)

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    if newApi() then
        return exports['qb-inventory']:GetInventory(playerId)?.items or {}
    end
    local Player = QBCore and QBCore.Functions.GetPlayer(tonumber(playerId))
    return Player and Player.PlayerData.items or {}
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    lib.print.error('CustomDrop is not supported in qb-inventory, please change type in config')
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['qb-inventory']:AddItem(playerId, itemName, itemCount, itemSlot, itemMetadata)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to remove]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['qb-inventory']:RemoveItem(playerId, itemName, itemCount, itemSlot)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    if itemMetadata and QBCore then
        local Player = QBCore.Functions.GetPlayer(playerId)
        local items = Player and Player.PlayerData.items or {}
        for k, v in pairs(items) do
            if v.name == itemName and v.info and lib.table.matches(v.info, itemMetadata) then
                return v.amount
            end
        end
        return 0
    end

    if newApi() then
        return exports['qb-inventory']:GetItemCount(playerId, itemName)
    end

    -- legacy build has no GetItemCount export
    local count = 0
    local Player = QBCore and QBCore.Functions.GetPlayer(tonumber(playerId))
    for _, item in pairs(Player and Player.PlayerData.items or {}) do
        if item.name == itemName then
            count = count + (item.amount or item.count or 0)
        end
    end
    return count
end

--@param playerId: number [existing player id]
--@param slot: number [item slot]
--@return item: {name: string, label: string, amount: number, metadata: table}
Bridge.Inventory.getItemSlot = function(playerId, slot)
    local itemSlot = exports['qb-inventory']:GetItemBySlot(playerId, slot)
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
    local ok = pcall(function()
        exports['qb-inventory']:CreateShop({
            name = shopName,
            label = data.label,
            slots = #data.inventory,
            items = data.inventory
        })
    end)
    if not ok then
        lib.print.error('CreateShop is not available in this qb-inventory build - update qb-inventory to use shops')
    end
end

---@param invId: number|string [player id or stash id]
---@return inventory: table|nil [{ items = { [slot] = { name, amount, info, slot } } }]
Bridge.Inventory.getInventory = function(invId)
    if newApi() then
        return exports['qb-inventory']:GetInventory(invId)
    end
    return { items = Bridge.Inventory.getPlayerItems(invId) }
end

---@param invId: number|string [player id or stash id]
Bridge.Inventory.clearInventory = function(invId)
    if newApi() then
        exports['qb-inventory']:ClearInventory(invId)
        return
    end
    local Player = QBCore and QBCore.Functions.GetPlayer(tonumber(invId))
    if Player then
        Player.Functions.ClearInventory()
    end
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
-- qb-inventory creates stashes lazily when they are first opened, so nothing to
-- pre-register here; kept for interface parity with ox_inventory.
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    return
end

-- Legacy qb-inventory keeps stash contents in the `stashitems` table (one JSON
-- blob per stash); writing the item straight into it is the only server-side
-- insertion path that build offers.
local function legacyStashAdd(stashId, itemName, itemCount, itemMetadata, stashSlots)
    if not QBCore then return false end
    local itemInfo = QBCore.Shared.Items[itemName:lower()]
    if not itemInfo then return false end

    local raw = MySQL.scalar.await('SELECT items FROM stashitems WHERE stash = ?', { stashId })
    local items = {}
    if raw then
        for _, item in pairs(json.decode(raw) or {}) do
            if item and item.slot then items[item.slot] = item end
        end
    end

    local maxSlots = stashSlots or 50
    local slotToUse

    if not itemInfo.unique then
        for slot, item in pairs(items) do
            if item.name == itemName and lib.table.matches(item.info or {}, itemMetadata or {}) then
                item.amount = (item.amount or 0) + itemCount
                slotToUse = slot
                break
            end
        end
    end

    if not slotToUse then
        for slot = 1, maxSlots do
            if not items[slot] then
                items[slot] = {
                    name = itemInfo.name,
                    amount = itemCount,
                    info = itemMetadata or {},
                    label = itemInfo.label,
                    description = itemInfo.description or '',
                    weight = itemInfo.weight,
                    type = itemInfo.type,
                    unique = itemInfo.unique,
                    useable = itemInfo.useable,
                    image = itemInfo.image,
                    shouldClose = itemInfo.shouldClose,
                    combinable = itemInfo.combinable,
                    slot = slot,
                }
                slotToUse = slot
                break
            end
        end
    end

    if not slotToUse then return false end

    MySQL.query.await('INSERT INTO stashitems (stash, items) VALUES (?, ?) ON DUPLICATE KEY UPDATE items = VALUES(items)', {
        stashId, json.encode(items)
    })
    return true
end

--@param stashId: string [stash id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param stashSlots: number [stash slot count, used if the stash must be created]
--@param stashMaxWeight: number [stash max weight, used if the stash must be created]
--@return success: boolean [whether the item landed in the stash]
Bridge.Inventory.addItemToStash = function(stashId, itemName, itemCount, itemMetadata, stashSlots, stashMaxWeight)
    if not newApi() then
        local ok, result = pcall(legacyStashAdd, stashId, itemName, itemCount, itemMetadata, stashSlots)
        return ok and result or false
    end

    -- Rewrite build: AddItem only reaches stashes that already exist in memory,
    -- so try the plain add first and only CreateInventory when the stash is
    -- unknown (creating unconditionally could shadow a DB-persisted stash).
    local function tryAdd()
        local ok, success = pcall(function()
            return exports['qb-inventory']:AddItem(stashId, itemName, itemCount, false, itemMetadata or false, 'p_bridge:addItemToStash')
        end)
        return ok and success and true or false
    end

    if tryAdd() then return true end

    pcall(function()
        exports['qb-inventory']:CreateInventory(stashId, {
            label = stashId,
            slots = stashSlots or 50,
            maxweight = stashMaxWeight or 500000,
        })
    end)
    return tryAdd()
end

---@param playerId: number|string [player id or stash id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    -- qb-inventory has no framework-agnostic per-slot metadata setter; use
    -- ox_inventory if you rely on evidence analysis persisting to the item.
    lib.print.error('setMetadata is not supported in qb-inventory, please change type in config')
end

---@param event: string [hook name]
---@param cb: function [hook callback]
---@param options: table|nil [hook options]
---@return nil [inventory hooks are ox_inventory only]
Bridge.Inventory.registerHook = function(event, cb, options)
    return nil
end

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    return QBCore and QBCore.Shared.Items[itemName] or nil
end
