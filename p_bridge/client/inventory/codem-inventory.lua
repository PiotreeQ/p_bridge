if (Config.Inventory == 'auto' and not checkResource('codem-inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'codem-inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: codem-inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.getItemCount = function(itemName)
    local items = exports['codem-inventory']:getUserInventory()
    for _, item in pairs(items) do
        if item.name == itemName then
            return item.amount
        end
    end
    return 0
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports['codem-inventory']:GetItemList()[itemName]
    return info and {name = itemName, label = info.label, image = ('https://cfx-nui-codem-inventory/html/itemimages/%s.png'):format(itemName)}
end