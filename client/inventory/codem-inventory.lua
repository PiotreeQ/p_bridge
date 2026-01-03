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

Bridge.Inventory.openInventory = function(invType, data)
    if invType == 'stash' then
        if data.owner then
            TriggerServerEvent("inventory:server:OpenInventory", "stash", data.id..'_'..data.owner, {
                maxweight = 250000,
                slots = 100,
            })
        else
            TriggerServerEvent("inventory:server:OpenInventory", "stash", data, {
                maxweight = 250000,
                slots = 100,
            })
        end
    elseif invType == 'player' then
        TriggerEvent('codem-inventory:client:openplayerinventory', data)
    elseif invType == 'shop' then
        TriggerEvent('codem-inventory:openshop', data.type)
    end
end

Bridge.Inventory.getItemCount = function(itemName)
    if GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        local items = ESX.GetPlayerData().inventory
        if items then
            for k, v in pairs(items) do
                if v.name == itemName then
                    return v.count or 0
                end
            end
        end

        return 0
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports['qb-core']:GetCoreObject()
        local items = QBCore.Functions.GetPlayerData().items
        for _, item in pairs(items) do
            if item.name == itemName then
                return item.amount
            end
        end

        return 0
    elseif GetResourceState('qbx_core') == 'started' then
        local items = exports['qbx_core']:GetPlayerData().items
        for _, item in pairs(items) do
            if item.name == itemName then
                return item.amount
            end
        end

        return 0
    end
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports['codem-inventory']:GetItemList()[itemName]
    return info and {name = itemName, label = info.label, description = info.description, image = ('https://cfx-nui-codem-inventory/html/itemimages/%s.png'):format(itemName)}
end

Bridge.Inventory.getPlayerItems = function()
    return exports['codem-inventory']:GetClientPlayerInventory()
end