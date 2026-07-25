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

Bridge.Inventory.openInventory = function(invType, data)
    if invType == 'player' then
        TriggerServerEvent('core_inventory:server:openInventory', data, 'otherplayer', nil, nil, true)
    elseif invType == 'shop' then
        lib.print.error('core_inventory doesnt have export to open shop')
    elseif invType == 'stash' then
        TriggerServerEvent('core_inventory:server:openInventory', data.owner and ('%s_%s'):format(data.id, data.owner) or data.id, 'stash')
    end
end

Bridge.Inventory.getItemCount = function(itemName)
    return exports.core_inventory:getItemCount(itemName)
end

Bridge.Inventory.getItemData = function(itemName)
    local Items = lib.callback.await('p_bridge/core_inventory/getItemsData', false)
    if Items[itemName] then
        return Items[itemName]
    end
    
    return nil
end

Bridge.Inventory.getPlayerItems = function()
    return exports.core_inventory:getInventory()
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