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

Bridge.Inventory.openInventory = function(invType, data)
    TriggerServerEvent('p_bridge/inventory/openInventory', invType, data)
end

Bridge.Inventory.getItemCount = function(itemName)
    return exports['tgiann-inventory']:Search('count', itemName)
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports["tgiann-inventory"]:Items(itemName)
    return info and {name = itemName, label = info.label, description = info.description, image = ('nui://inventory_images/images/%s.png'):format(itemName)}
end

Bridge.Inventory.getPlayerItems = function()
    return exports["tgiann-inventory"]:GetPlayerItems()
end