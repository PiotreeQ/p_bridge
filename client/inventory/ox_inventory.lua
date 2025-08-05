if (Config.Inventory == 'auto' and not checkResource('ox_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'ox_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: ox_inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.getItemCount = function(itemName)
    return exports['ox_inventory']:Search('count', itemName)
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports['ox_inventory']:Items(itemName)
    return info and {name = itemName, label = info.label, image = ('https://cfx-nui-ox_inventory/web/images/%s.png'):format(itemName)}
end