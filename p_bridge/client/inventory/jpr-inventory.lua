if (Config.Inventory == 'auto' and not checkResource('jpr-inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'jpr-inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: jpr-inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.getItemCount = function(itemName)
    local items = QBCore.PlayerData.items
    for _, item in pairs(items) do
        if item.name == itemName then
            return item.amount
        end
    end
    return 0
end

Bridge.Inventory.getItemData = function(itemName)
    local info = QBCore.Shared.Items[itemName]
    return info and {name = itemName, label = info.label, image = ('https://cfx-nui-jpr-inventory/html/images/%s.png'):format(itemName)}
end