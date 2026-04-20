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
    itemName = tostring(itemName or ''):lower()
    if itemName == '' then return 0 end

    if GetResourceState('codem-inventory') == 'started' then
        local ok, result = pcall(function()
            return exports['codem-inventory']:GetItemsTotalAmount(itemName)
        end)

        if ok and result ~= nil then
            return tonumber(result) or 0
        end

        -- fallback (au cas où)
        local ok2, result2 = pcall(function()
            return exports['codem-inventory']:HasItem(itemName, 1)
        end)

        if ok2 then
            if type(result2) == 'number' then
                return tonumber(result2) or 0
            end
            if result2 == true then
                return 1
            end
        end

        return 0
    end

    if GetResourceState('es_extended') == 'started' then
        local ESX = exports['es_extended']:getSharedObject()
        local items = ESX.GetPlayerData().inventory

        if items then
            for _, v in pairs(items) do
                if v.name == itemName then
                    return v.count or 0
                end
            end
        end

        return 0
    end

    return 0
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports['codem-inventory']:GetItemList()[itemName]
    return info and {name = itemName, label = info.label, description = info.description, image = ('https://cfx-nui-codem-inventory/html/itemimages/%s.png'):format(itemName)}
end

Bridge.Inventory.getPlayerItems = function()
    local ok, inv = pcall(function()
        return exports['codem-inventory']:GetClientPlayerInventory()
    end)

    if not ok or not inv then return {} end

    local items = inv.items or inv.inventory or inv.slots or inv
    local formatted = {}

    for _, item in pairs(items) do
        if item and item.name and (item.amount or item.count or 0) > 0 then
            formatted[#formatted + 1] = {
                name = item.name,
                label = item.label or item.name,
                amount = item.amount or item.count or 0,
                count = item.amount or item.count or 0,
                metadata = item.info or item.metadata or {},
                slot = item.slot
            }
        end
    end

    return formatted
end
