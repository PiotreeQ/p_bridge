-- Loaded after every framework and inventory adapter: makes removeMoney / removeItem report
-- honestly on all of them. Some frameworks always return true (ESX removeAccountMoney has no
-- result) and most inventory exports return nothing, so scripts could not tell a failed
-- charge from a paid one. Both now refuse what the player can't cover and return true only
-- when the balance or item count really went down.

local function badAmount(amount)
    return type(amount) ~= 'number' or amount ~= amount or amount < 0 or amount == math.huge
end

if Bridge.Framework and Bridge.Framework.removeMoney and Bridge.Framework.getMoney then
    local removeMoney, getMoney = Bridge.Framework.removeMoney, Bridge.Framework.getMoney
    -- account names callers use -> getMoney keys
    local keys = { money = 'money', cash = 'money', bank = 'bank', black_money = 'black_money', crypto = 'black_money' }

    local function balance(playerId, account)
        local key = keys[account]
        if not key then return nil end
        local ok, money = pcall(getMoney, playerId)
        return ok and type(money) == 'table' and tonumber(money[key]) or nil
    end

    Bridge.Framework.removeMoney = function(playerId, account, amount)
        if badAmount(amount) then return false end
        if amount == 0 then return true end
        local before = balance(playerId, account)
        if before and before < amount then return false end
        if removeMoney(playerId, account, amount) == false then return false end
        -- unknown account or offline player: the framework's own answer is all there is
        if not before then return true end
        local after = balance(playerId, account)
        return not after or after < before
    end
end

-- society accounts: never let a script overdraw the business (two withdrawals at once, NaN)
if Bridge.Society and Bridge.Society.removeMoney and Bridge.Society.getMoney then
    local removeMoney, getMoney = Bridge.Society.removeMoney, Bridge.Society.getMoney

    Bridge.Society.removeMoney = function(playerId, jobName, amount)
        if badAmount(amount) then return false end
        if amount == 0 then return true end
        local ok, money = pcall(getMoney, playerId, jobName)
        if ok and tonumber(money) and tonumber(money) < amount then return false end
        return removeMoney(playerId, jobName, amount) ~= false
    end
end

if Bridge.Inventory and Bridge.Inventory.removeItem and Bridge.Inventory.getItemCount then
    local removeItem, getItemCount = Bridge.Inventory.removeItem, Bridge.Inventory.getItemCount

    local function count(playerId, itemName, itemMetadata)
        local ok, n = pcall(getItemCount, playerId, itemName, itemMetadata)
        return ok and tonumber(n) or nil
    end

    Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
        itemCount = itemCount or 1
        if badAmount(itemCount) then return false end
        if type(playerId) == 'string' and tonumber(playerId) then
            playerId = tonumber(playerId)
        end
        -- stash ids: the stash path counts the stash itself (see removeItemFromStash below)
        if type(playerId) ~= 'number' then
            if Bridge.Inventory.removeItemFromStash then
                return Bridge.Inventory.removeItemFromStash(playerId, itemName, itemCount, itemMetadata, itemSlot)
            end
            local ok, result = pcall(removeItem, playerId, itemName, itemCount, itemMetadata, itemSlot)
            return ok and result ~= false and result ~= nil
        end
        local before = count(playerId, itemName, itemMetadata)
        if before and before < itemCount then return false end
        local ok, result = pcall(removeItem, playerId, itemName, itemCount, itemMetadata, itemSlot)
        if not ok or result == false then return false end
        if not before then return true end
        local after = count(playerId, itemName, itemMetadata)
        return not after or after < before
    end
end

-- Stash / slot contract shared by every inventory adapter. Adapters implement the
-- inventory-specific calls; this layer fills gaps with safe defaults, normalises
-- what comes back ({ name, count, amount, metadata = {}, slot }) and makes the
-- stash removal honest by counting the stash before and after.
if Bridge.Inventory then
    local Inv = Bridge.Inventory
    local name = Config.Inventory ~= 'auto' and Config.Inventory or 'inventory'

    local function warnMissing(fn)
        lib.print.error(('[Inventory] %s is not supported by the active inventory (%s)'):format(fn, name))
    end

    -- registerStash: remember the biggest size asked for each stash. Adapters
    -- whose inventory takes the size at open time read it back through
    -- getStashInfo (server) or the 'p_bridge/inventory/getStashInfo' callback
    -- (client), so re-registering with more slots/weight grows the stash, and a
    -- smaller re-registration never shrinks one that may already be full.
    local stashInfo = {}
    local registerStash = Inv.registerStash

    Inv.getStashInfo = function(stashId)
        return stashInfo[stashId]
    end

    Inv.registerStash = function(stashId, label, slots, weight, owner, groups, coords)
        if type(stashId) ~= 'string' and type(stashId) ~= 'number' then return end
        local cur = stashInfo[stashId] or {}
        slots = tonumber(slots)
        weight = tonumber(weight)
        if cur.slots and (not slots or cur.slots > slots) then slots = cur.slots end
        if cur.weight and (not weight or cur.weight > weight) then weight = cur.weight end
        stashInfo[stashId] = { label = label or cur.label, slots = slots, weight = weight }
        if registerStash then
            local ok, err = pcall(registerStash, stashId, label or cur.label, slots, weight, owner, groups, coords)
            if not ok then
                lib.print.error(('[Inventory] registerStash(%s) failed: %s'):format(tostring(stashId), tostring(err)))
            end
        end
    end

    lib.callback.register('p_bridge/inventory/getStashInfo', function(_, stashId)
        return stashInfo[stashId]
    end)

    -- getStashItems: always an array of normalised items
    local getStashItems = Inv.getStashItems
    Inv.getStashItems = function(stashId)
        if not getStashItems then return {} end
        local ok, items = pcall(getStashItems, stashId)
        if not ok then
            lib.print.error(('[Inventory] getStashItems(%s) failed: %s'):format(tostring(stashId), tostring(items)))
            return {}
        end
        return InvUtils.normalizeList(items)
    end

    -- addItemToStash: boolean, never throws
    local addItemToStash = Inv.addItemToStash
    Inv.addItemToStash = function(stashId, itemName, itemCount, itemMetadata, stashSlots, stashMaxWeight)
        itemCount = itemCount or 1
        if badAmount(itemCount) or type(itemName) ~= 'string' then return false end
        if itemCount == 0 then return true end
        if not addItemToStash then
            warnMissing('addItemToStash')
            return false
        end
        local info = stashInfo[stashId] or {}
        local ok, result = pcall(addItemToStash, stashId, itemName, itemCount, itemMetadata,
            stashSlots or info.slots, stashMaxWeight or info.weight)
        return ok and result == true
    end

    -- removeItemFromStash: refuses what the stash can't cover and returns true
    -- only when that many really left (stash counted before and after, so an
    -- export that reports nothing still gets an honest answer).
    local removeItemFromStash = Inv.removeItemFromStash
    Inv.removeItemFromStash = function(stashId, itemName, itemCount, itemMetadata, itemSlot)
        itemCount = itemCount or 1
        if badAmount(itemCount) or type(itemName) ~= 'string' then return false end
        if itemCount == 0 then return true end
        if not removeItemFromStash then
            warnMissing('removeItemFromStash')
            return false
        end
        local before = InvUtils.countItems(Inv.getStashItems(stashId), itemName, itemMetadata, itemSlot)
        if before < itemCount then return false end
        local ok, result = pcall(removeItemFromStash, stashId, itemName, itemCount, itemMetadata, itemSlot)
        if not ok then
            lib.print.error(('[Inventory] removeItemFromStash(%s) failed: %s'):format(tostring(stashId), tostring(result)))
        end
        local after = InvUtils.countItems(Inv.getStashItems(stashId), itemName, itemMetadata, itemSlot)
        if after < before - itemCount then
            lib.print.warn(('[Inventory] removeItemFromStash(%s) removed %s x %s, asked for %s'):format(
                tostring(stashId), before - after, itemName, itemCount))
        end
        return after <= before - itemCount
    end

    -- canCarryItem: true when the inventory has no check
    local canCarryItem = Inv.canCarryItem
    Inv.canCarryItem = function(playerId, itemName, itemCount)
        if not canCarryItem then return true end
        local ok, result = pcall(canCarryItem, playerId, itemName, itemCount or 1)
        if not ok then return true end
        return result and true or false
    end

    -- searchPlayerItems: adapter export, else built from getPlayerItems
    local searchPlayerItems = Inv.searchPlayerItems
    Inv.searchPlayerItems = function(playerId, itemName)
        local items
        if searchPlayerItems then
            local ok, result = pcall(searchPlayerItems, playerId, itemName)
            items = ok and result or nil
        end
        if not items and Inv.getPlayerItems then
            local ok, result = pcall(Inv.getPlayerItems, playerId)
            items = ok and result or nil
        end
        return InvUtils.filterByName(InvUtils.normalizeList(items), itemName)
    end

    -- getItemSlot: keep the adapter's fields, guarantee count/amount/slot/metadata
    local getItemSlot = Inv.getItemSlot
    if getItemSlot then
        Inv.getItemSlot = function(playerId, slot)
            local ok, item = pcall(getItemSlot, playerId, slot)
            if not ok or type(item) ~= 'table' or not item.name then return nil end
            local count = tonumber(item.count or item.amount) or 0
            local metadata = item.metadata
            if type(metadata) ~= 'table' then metadata = item.info end
            if type(metadata) ~= 'table' then metadata = {} end
            local out = table.clone(item)
            out.count, out.amount = count, count
            out.slot = tonumber(item.slot) or slot
            out.metadata = metadata
            return out
        end
    end

    -- setMetadata: boolean, never throws
    local setMetadata = Inv.setMetadata
    if setMetadata then
        Inv.setMetadata = function(playerId, slot, metadata)
            local ok, result = pcall(setMetadata, playerId, slot, metadata or {})
            return ok and result ~= false
        end
    end

    -- getItemData: at least { name, label, weight? } or nil
    local getItemData = Inv.getItemData
    if getItemData then
        Inv.getItemData = function(itemName)
            local ok, item = pcall(getItemData, itemName)
            if not ok or type(item) ~= 'table' then return nil end
            local out = table.clone(item)
            out.name = out.name or itemName
            out.label = out.label or itemName
            return out
        end
    end

    -- CustomDrop: entries readable both positionally and by key
    local customDrop = Inv.CustomDrop
    if customDrop then
        Inv.CustomDrop = function(prefix, items, coords)
            return customDrop(prefix, InvUtils.dropEntries(items), coords)
        end
    end
end
