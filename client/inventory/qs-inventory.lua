if (Config.Inventory == 'auto' and not checkResource('qs-inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'qs-inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: qs-inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.getItemCount = function(itemName)
    return exports['qs-inventory']:Search(itemName)
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports['qs-inventory']:GetItemList()[itemName]
    return info and {name = itemName, label = info.label, image = ('https://cfx-nui-qs-inventory/htmk/images/%s.png'):format(itemName)}
end