if (Config.Inventory == 'auto' and not checkResource('origen_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'origen_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: origen_inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.openInventory = function(invType, data)
    exports['origen_inventory']:openInventory(invType, data)
end

Bridge.Inventory.getItemCount = function(itemName)
    return exports['origen_inventory']:Search('count', itemName)
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports['ox_inventory']:Items(itemName)
    return info and {name = itemName, label = info.label, description = info.description, image = ('https://cfx-nui-origen_inventory/web/images/%s.png'):format(itemName)}
end