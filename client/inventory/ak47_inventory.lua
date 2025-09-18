if (Config.Inventory == 'auto' and not checkResource('ak47_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'ak47_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: ak47_inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.openInventory = function(invType, data)
    exports['ak47_inventory']:OpenInventory(data)
end

Bridge.Inventory.getItemCount = function(itemName)
    return exports['ak47_inventory']:Search('amount', itemName)
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports['ak47_inventory']:Items(itemName)
    return info and {name = itemName, label = info.label, image = ('https://cfx-nui-ak47_inventory/web/images/%s.png'):format(itemName)} or nil
end