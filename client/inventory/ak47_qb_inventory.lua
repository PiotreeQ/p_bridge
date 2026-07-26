if (Config.Inventory == 'auto' and not checkResource('ak47_qb_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'ak47_qb_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: ak47_qb_inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.openInventory = function(invType, data)
    exports['ak47_qb_inventory']:OpenInventory(data)
end

Bridge.Inventory.getItemCount = function(itemName)
    return exports['ak47_qb_inventory']:Search('amount', itemName)
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports['ak47_qb_inventory']:Items(itemName)
    return info and {name = itemName, label = info.label, description = info.description, image = ('https://cfx-nui-ak47_qb_inventory/web/images/%s.png'):format(itemName)} or nil
end

Bridge.Inventory.getPlayerItems = function()
    return exports['ak47_qb_inventory']:GetPlayerItems()
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