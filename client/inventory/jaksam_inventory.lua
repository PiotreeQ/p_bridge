if (Config.Inventory == 'auto' and not checkResource('jaksam_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'jaksam_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: jaksam_inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.openInventory = function(invType, data)
    local invId = nil
    if type(data) == 'table' then
        if data.owner then
            invId = ('%s_%s'):format(data.id, data.owner)
        else
            invId = data.id
        end
    elseif type(data) == 'string' then
        invId = data
    end
    exports['jaksam_inventory']:openInventory(invId)
end

Bridge.Inventory.getItemCount = function(itemName)
    return exports['jaksam_inventory']:getTotalItemAmount(itemName)
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports['jaksam_inventory']:getStaticItem(itemName)
    return info and {name = itemName, label = info.label, description = info.description, image = ('https://cfx-nui-jaksam_inventory/_images/%s.png'):format(itemName)}
end

Bridge.Inventory.getPlayerItems = function()
    return exports['jaksam_inventory']:getInventory()?.items or {}
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