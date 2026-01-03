if (Config.Inventory == 'auto' and not checkResource('ps-inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'ps-inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: ps-inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.openInventory = function(invType, data)
    if invType == 'stash' then
        if data.owner then
            TriggerServerEvent("inventory:server:OpenInventory", "stash", data.id..'_'..data.owner, {
                maxweight = 250000,
                slots = 100,
            })
            TriggerEvent("inventory:client:SetCurrentStash", data.id..'_'..data.owner)
        else
            TriggerServerEvent('p_bridge/inventory/openInventory', invType, data)
        end
    elseif invType == 'shop' then
        TriggerServerEvent('p_bridge/inventory/openInventory', invType, data)
    elseif invType == 'player' then
        TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", data)
        TriggerEvent("inventory:client:SetCurrentStash", "otherplayer")
    end
end

Bridge.Inventory.getItemData = function(itemName)
    local info = QBCore.Shared.Items[itemName]
    return info and {name = itemName, label = info.label, description = info.description, image = ('https://cfx-nui-ps-inventory/html/images/%s.png'):format(itemName)}
end

Bridge.Inventory.getPlayerItems = function()
    return QBCore.PlayerData.items
end