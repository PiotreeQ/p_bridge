if (Config.Inventory == 'auto' and not checkResource('core_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'core_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: core_inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.openInventory = function(invType, data)
    if invType == 'player' then
        TriggerServerEvent('core_inventory:server:openInventory', data, 'otherplayer', nil, nil, true)
    elseif invType == 'shop' then
        lib.print.error('core_inventory doesnt have export to open shop')
    elseif invType == 'stash' then
        TriggerServerEvent('core_inventory:server:openInventory', data.owner and ('%s_%s'):format(data.id, data.owner) or data.id, 'stash')
    end
end

Bridge.Inventory.getItemCount = function(itemName)
    return exports.core_inventory:getItemCount(itemName)
end

Bridge.Inventory.getItemData = function(itemName)
    lib.print.error('core_inventory doesnt have export to get item data')
    return nil
end

Bridge.Inventory.getPlayerItems = function()
    return exports.core_inventory:getInventory()
end