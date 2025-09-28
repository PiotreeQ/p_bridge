if (Config.Inventory == 'auto' and not checkResource('qb-inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'qb-inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: qb-inventory')
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
            TriggerServerEvent('p_policejob/inventory/openInventory', invType, data)
        end
    elseif invType == 'shop' then
        if data.items then
            for i = 1, #data.items, 1 do
                data.items[i].slot = i
                if not data.items[i].amount then
                    data.items[i].amount = 1000
                end
            end
        end
        TriggerServerEvent("inventory:server:OpenInventory", "shop", data.type..'_'..data.id, data)
    elseif invType == 'player' then
        TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", data)
        TriggerEvent("inventory:client:SetCurrentStash", "otherplayer")
    end
end

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
    return info and {name = itemName, label = info.label, description = info.description, image = ('https://cfx-nui-qb-inventory/html/images/%s.png'):format(itemName)}
end