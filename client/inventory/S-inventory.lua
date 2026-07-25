if (Config.Inventory == 'auto' and not (checkResource('S-Inventory') or checkResource('S-inventory'))) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'S-Inventory' and Config.Inventory ~= 'S-inventory') then
    return
end

local ESX = exports['es_extended']:getSharedObject()

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: S-Inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.openInventory = function(invType, data)
    if invType == 'player' then
        TriggerEvent("SService:Server:SearchPlayer")
    elseif invType == 'stash' then
        exports["S-Inventory"]:OpenStashInventory(nil, data)
    elseif invType == 'shop' then
        lib.print.error('S-Inventory does not support external shops, create shop in inventory config')
    end
end

Bridge.Inventory.getItemCount = function(itemName)
    local items = ESX.GetPlayerData().inventory
    if items then
        for k, v in pairs(items) do
            if v.name == itemName then
                return v.count or 0
            end
        end
    end
end

Bridge.Inventory.getItemData = function(itemName)
    local info = GlobalState['p_bridge:itemsData'][itemName]
    return info and {name = itemName, label = info.label, description = info.description, image = ('https://cfx-nui-ox_inventory/web/images/%s.png'):format(itemName)}
end

Bridge.Inventory.getPlayerItems = function()
    return ESX.GetPlayerData().inventory
end

---@return weapon: table|nil [currently equipped weapon { name, label, metadata } or nil]
Bridge.Inventory.getCurrentWeapon = function()
    local weaponHash = GetSelectedPedWeapon(cache.ped)
    if not weaponHash or weaponHash == `WEAPON_UNARMED` then
        return nil
    end

    local loadout = ESX.GetPlayerData().loadout or {}
    for _, weapon in pairs(loadout) do
        if GetHashKey(weapon.name) == weaponHash then
            return {name = weapon.name, label = weapon.label, metadata = {ammo = weapon.ammo, components = weapon.components}}
        end
    end

    return nil
end

---@param state: boolean [true to force-holster/disarm the equipped weapon]
Bridge.Inventory.disarm = function(state)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
end