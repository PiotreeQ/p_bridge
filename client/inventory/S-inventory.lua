if (Config.Inventory == 'auto' and not checkResource('S-Inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'S-Inventory') then
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
    local info = exports['ox_inventory']:Items(itemName)
    return info and {name = itemName, label = info.label, description = info.description, image = ('https://cfx-nui-ox_inventory/web/images/%s.png'):format(itemName)}
end