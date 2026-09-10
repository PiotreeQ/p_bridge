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

Bridge.Inventory.openInventory = function(invType, data)
    if invType == 'stash' then
        if data.owner then
            data.slots = data.slots or 100
            data.maxWeight = data.maxWeight or 250000
        end
        TriggerServerEvent('p_bridge/inventory/openInventory', invType, data)
    elseif invType == 'shop' then
        if not data.label then
            data.label = data.type
        end
        
        if data.items then
            for i = 1, #data.items, 1 do
                data.items[i].slot = i
                if not data.items[i].amount then
                    data.items[i].amount = 1000
                end
                if not data.items[i].price then
                    data.items[i].price = 0
                end
            end
        end
        TriggerServerEvent('p_bridge/inventory/openInventory', invType, data)
    elseif invType == 'player' then
        TriggerServerEvent('p_bridge/inventory/openInventory', invType, data)
    end
end

-- qb-inventory 2.0 no longer syncs item changes into the client's PlayerData,
-- so the copy held by this resource goes stale after the first read. Items are
-- fetched from the server instead: synchronously the first time, afterwards
-- refreshed in the background once the cache is older than CACHE_TTL or the
-- inventory reports a change, so per-frame callers never block.
local itemsCache = nil
local itemsCacheTime = 0
local itemsRefreshing = false
local CACHE_TTL = 1000

local function fetchItems()
    if itemsRefreshing then return end
    itemsRefreshing = true
    local items = lib.callback.await('p_bridge/inventory/getPlayerItems', false)
    if items then
        itemsCache = items
        itemsCacheTime = GetGameTimer()
    end
    itemsRefreshing = false
end

Bridge.Inventory.getPlayerItems = function()
    if not itemsCache then
        fetchItems()
        return itemsCache or QBCore.PlayerData.items or {}
    end
    if GetGameTimer() - itemsCacheTime > CACHE_TTL and not itemsRefreshing then
        Citizen.CreateThread(fetchItems)
    end
    return itemsCache
end

Bridge.Inventory.getItemCount = function(itemName)
    local count = 0
    for _, item in pairs(Bridge.Inventory.getPlayerItems() or {}) do
        if item.name == itemName then
            count = count + (item.amount or item.count or 0)
        end
    end
    return count
end

-- qb-inventory 2.0 announces changes here; legacy builds still deliver items
-- through SetPlayerData, which feeds the cache without a round trip
RegisterNetEvent('qb-inventory:client:updateInventory', function()
    itemsCacheTime = 0
    Citizen.CreateThread(fetchItems)
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(playerData)
    if playerData and playerData.items then
        itemsCache = playerData.items
        itemsCacheTime = GetGameTimer()
    end
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    itemsCache = nil
    itemsCacheTime = 0
end)

Bridge.Inventory.getItemData = function(itemName)
    local info = QBCore.Shared.Items[itemName]
    return info and {name = itemName, label = info.label, description = info.description, image = ('https://cfx-nui-qb-inventory/html/images/%s.png'):format(itemName)}
end

---@return weapon: table|nil [currently equipped weapon { name, label, metadata, slot } or nil]
Bridge.Inventory.getCurrentWeapon = function()
    local weaponHash = GetSelectedPedWeapon(cache.ped)
    if not weaponHash or weaponHash == `WEAPON_UNARMED` then
        return nil
    end

    for _, item in pairs(Bridge.Inventory.getPlayerItems() or {}) do
        if item.name and GetHashKey(item.name) == weaponHash then
            return {name = item.name, label = item.label, metadata = item.metadata or item.info or {}, slot = item.slot}
        end
    end

    return nil
end

---@param state: boolean [true to force-holster/disarm the equipped weapon]
Bridge.Inventory.disarm = function(state)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
end