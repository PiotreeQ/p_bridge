if (Config.Inventory == 'auto' and not checkResource('tgiann-inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'tgiann-inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: tgiann-inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.getItemCount = function(itemName)
    return exports['tgiann-inventory']:Search('count', itemName)
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports["tgiann-inventory"]:Items(itemName)
    return info and {name = itemName, label = info.label, image = ('https://cfx-nui-tgiann-inventory/html/images/%s.png'):format(itemName)}
end