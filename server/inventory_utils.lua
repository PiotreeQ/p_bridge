-- Shared helpers for the server inventory adapters (loaded before server/inventory/*.lua).
-- Only one adapter runs, so everything here is plain functions on a global table.

InvUtils = {}

-- Calls the first export of `names` that exists on `resource`.
-- A missing export ("No such export") falls through to the next name; any other
-- error stops (the export exists but failed, retrying an alias could act twice).
---@return boolean ok, any ...
function InvUtils.call(resource, names, ...)
    if type(names) ~= 'table' then names = { names } end
    local args = table.pack(...)
    local lastErr
    for _, name in ipairs(names) do
        local res = table.pack(pcall(function()
            local ex = exports[resource]
            return ex[name](ex, table.unpack(args, 1, args.n))
        end))
        if res[1] then
            return table.unpack(res, 1, res.n)
        end
        lastErr = tostring(res[2])
        if not lastErr:find('No such export', 1, true) and not lastErr:find('does not exist', 1, true) then
            break
        end
    end
    if Config.Debug then
        lib.print.warn(('[Inventory] %s:%s failed: %s'):format(resource, table.concat(names, '/'), lastErr))
    end
    return false, lastErr
end

-- Subset match: every key of `filter` must equal the same key in `metadata`.
function InvUtils.metaMatches(metadata, filter)
    if filter == nil then return true end
    if type(filter) ~= 'table' then return false end
    if type(metadata) ~= 'table' then return next(filter) == nil end
    for k, v in pairs(filter) do
        local m = metadata[k]
        if type(v) == 'table' then
            if type(m) ~= 'table' or not lib.table.matches(m, v) then return false end
        elseif m ~= v then
            return false
        end
    end
    return true
end

local function toSlot(item, key)
    local slot = tonumber(item.slot)
    if slot then return slot end
    if type(key) == 'number' then return key end
    if type(key) == 'string' then return tonumber(key:match('(%d+)$')) end
    return nil
end

-- { name, label, count, amount, metadata (never nil), slot } from any inventory's item shape.
function InvUtils.normalizeItem(item, key)
    if type(item) ~= 'table' or type(item.name) ~= 'string' then return nil end
    local count = tonumber(item.count or item.amount or item.anzahl or item.itemcount or item.quantity) or 0
    local metadata = item.metadata
    if type(metadata) ~= 'table' then metadata = item.info end
    if type(metadata) ~= 'table' then metadata = {} end
    return {
        name = item.name,
        label = item.label,
        count = count,
        amount = count,
        metadata = metadata,
        slot = toSlot(item, key),
    }
end

-- Array of normalised items (count > 0), sorted by slot.
function InvUtils.normalizeList(items)
    local out = {}
    if type(items) ~= 'table' then return out end
    for key, item in pairs(items) do
        local n = InvUtils.normalizeItem(item, key)
        if n and n.count > 0 then out[#out + 1] = n end
    end
    table.sort(out, function(a, b) return (a.slot or math.huge) < (b.slot or math.huge) end)
    return out
end

function InvUtils.countItems(list, name, metadata, slot)
    local n = 0
    for _, item in ipairs(list or {}) do
        if item.name == name and (not slot or item.slot == slot) and InvUtils.metaMatches(item.metadata, metadata) then
            n = n + (item.count or 0)
        end
    end
    return n
end

-- Splits a removal of `count` over the matching slots of a normalised list.
-- Returns { { slot, count, metadata }, ... } or nil when there is not enough.
function InvUtils.planRemoval(list, name, count, metadata, slot)
    local plan, left = {}, count
    for _, item in ipairs(list or {}) do
        if left <= 0 then break end
        if item.name == name and (not slot or item.slot == slot) and InvUtils.metaMatches(item.metadata, metadata) then
            local take = math.min(item.count, left)
            plan[#plan + 1] = { slot = item.slot, count = take, metadata = item.metadata }
            left = left - take
        end
    end
    if left > 0 then return nil end
    return plan
end

function InvUtils.filterByName(list, name)
    local out = {}
    for _, item in ipairs(list or {}) do
        if item.name == name then out[#out + 1] = item end
    end
    return out
end

-- Grams (ox convention used by callers) to the kilogram scale some inventories use.
function InvUtils.gramsToKg(weight)
    weight = tonumber(weight)
    if not weight then return nil end
    return weight > 1000 and weight / 1000 or weight
end

---------------------------------------------------------------------------
-- qb-style slot tables ({ [slot] = { name, amount, info, ... } }), used by the
-- DB-backed legacy stashes (qb legacy / ps-inventory) and codem's UpdateStash.
---------------------------------------------------------------------------

-- Re-key a decoded item list by its slot field (json round trips lose numeric keys).
function InvUtils.rekeyBySlot(raw)
    local items = {}
    for key, item in pairs(raw or {}) do
        if type(item) == 'table' and item.name then
            local slot = toSlot(item, key)
            if slot then
                item.slot = slot
                items[slot] = item
            end
        end
    end
    return items
end

local function slotAmount(item)
    return tonumber(item.amount or item.count) or 0
end

local function setSlotAmount(item, amount)
    if item.count ~= nil and item.amount == nil then
        item.count = amount
    else
        item.amount = amount
        if item.count ~= nil then item.count = amount end
    end
end

-- Adds `count` of `name` to a slot table. `def` is the item definition (label,
-- weight, unique, ...). Mutates only on success.
function InvUtils.slotTableAdd(items, def, name, count, metadata, maxSlots)
    def = def or {}
    metadata = metadata or {}
    if not def.unique then
        for _, item in pairs(items) do
            if item.name == name and lib.table.matches(item.info or item.metadata or {}, metadata) then
                setSlotAmount(item, slotAmount(item) + count)
                return true
            end
        end
    end

    for slot = 1, tonumber(maxSlots) or 50 do
        if not items[slot] then
            items[slot] = {
                name = def.name or name,
                amount = count,
                info = metadata,
                label = def.label or name,
                description = def.description or '',
                weight = def.weight or 0,
                type = def.type or 'item',
                unique = def.unique,
                useable = def.useable,
                image = def.image,
                shouldClose = def.shouldClose,
                combinable = def.combinable,
                slot = slot,
            }
            return true
        end
    end
    return false
end

-- Removes exactly `count` of `name` (optionally only matching metadata / slot).
-- Refuses (no mutation) when there is not enough.
function InvUtils.slotTableRemove(items, name, count, metadata, slot)
    local matching, total = {}, 0
    for s, item in pairs(items) do
        if item.name == name and (not slot or s == slot)
            and InvUtils.metaMatches(item.info or item.metadata, metadata) then
            matching[#matching + 1] = s
            total = total + slotAmount(item)
        end
    end
    if total < count then return false end

    table.sort(matching)
    local left = count
    for _, s in ipairs(matching) do
        if left <= 0 then break end
        local item = items[s]
        local have = slotAmount(item)
        local take = math.min(have, left)
        if have - take <= 0 then
            items[s] = nil
        else
            setSlotAmount(item, have - take)
        end
        left = left - take
    end
    return true
end

---------------------------------------------------------------------------
-- legacy `stashitems` table (qb-inventory legacy, ps-inventory, lj forks)
---------------------------------------------------------------------------

function InvUtils.dbStashLoad(stashId)
    local ok, raw = pcall(MySQL.scalar.await, 'SELECT items FROM stashitems WHERE stash = ?', { stashId })
    if not ok or not raw then return {} end
    local decoded = json.decode(raw)
    return InvUtils.rekeyBySlot(decoded)
end

function InvUtils.dbStashSave(stashId, items)
    local ok = pcall(MySQL.query.await,
        'INSERT INTO stashitems (stash, items) VALUES (?, ?) ON DUPLICATE KEY UPDATE items = VALUES(items)',
        { stashId, json.encode(items) })
    return ok
end

function InvUtils.qbItemDef(name)
    local core = QBCore
    if not core and GetResourceState('qb-core') == 'started' then
        local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
        core = ok and obj or nil
    end
    return core and core.Shared and core.Shared.Items and core.Shared.Items[name:lower()] or nil
end

function InvUtils.dbStashAdd(stashId, name, count, metadata, maxSlots)
    local def = InvUtils.qbItemDef(name)
    if not def then return false end
    local items = InvUtils.dbStashLoad(stashId)
    if not InvUtils.slotTableAdd(items, def, name, count, metadata, maxSlots) then return false end
    return InvUtils.dbStashSave(stashId, items)
end

function InvUtils.dbStashRemove(stashId, name, count, metadata, slot)
    local items = InvUtils.dbStashLoad(stashId)
    if not InvUtils.slotTableRemove(items, name, count, metadata, slot) then return false end
    return InvUtils.dbStashSave(stashId, items)
end

---------------------------------------------------------------------------
-- QBCore-family player helpers (PlayerData.items based inventories)
---------------------------------------------------------------------------

-- Writes metadata into PlayerData.items[slot].info through qb-core's setter.
function InvUtils.qbSetPlayerSlotInfo(playerId, slot, metadata)
    local Player = QBCore and QBCore.Functions.GetPlayer(tonumber(playerId))
    if not Player then return false end
    local items = Player.PlayerData.items or {}
    slot = tonumber(slot)
    local item = items[slot]
    if not item then
        for _, v in pairs(items) do
            if v and v.slot == slot then item = v break end
        end
    end
    if not item then return false end
    item.info = metadata or {}
    items[item.slot or slot] = item
    Player.Functions.SetPlayerData('items', items)
    return true
end

-- Positional + keyed item entries for CustomDrop ({ name, count, metadata } and
-- { name = , count = , metadata = }), so every drop export reads what it expects.
function InvUtils.dropEntries(items)
    local out = {}
    for _, entry in pairs(items or {}) do
        if type(entry) == 'table' then
            local name = entry.name or entry[1]
            local count = tonumber(entry.count or entry.amount or entry[2]) or 1
            local metadata = entry.metadata or entry.info or entry[3]
            if type(name) == 'string' then
                out[#out + 1] = {
                    name, count, metadata,
                    name = name, count = count, amount = count, metadata = metadata, info = metadata,
                }
            end
        end
    end
    return out
end
