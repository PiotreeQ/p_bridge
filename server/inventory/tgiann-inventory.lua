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

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    return exports['tgiann-inventory']:GetPlayerItems(playerId)
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
    exports['tgiann-inventory']:CustomDrop(prefix, items, coords)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['tgiann-inventory']:AddItem(playerId, itemName, itemCount, itemSlot, itemMetadata)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to remove]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['tgiann-inventory']:RemoveItem(playerId, itemName, itemCount, itemSlot, itemMetadata)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    if itemMetadata then
        local items = exports['tgiann-inventory']:GetPlayerItems(playerId)
        for k, v in pairs(items) do
            if v.name == itemName and v.info and lib.table.matches(v.info, itemMetadata) then
                return v.amount
            end
        end
    else
        return exports['tgiann-inventory']:GetItemCount(playerId, itemName)
    end

    return 0
end

--@param playerId: number [existing player id]
--@param slot: number [item slot]
--@return item: {name: string, label: string, amount: number, metadata: table}
Bridge.Inventory.getItemSlot = function(playerId, slot)
    local items = exports['tgiann-inventory']:GetPlayerItems(playerId)
    local itemData = nil
    for k, v in pairs(items) do
        if v.slot == slot then
            itemData = v
            break
        end
    end
    return itemData and {name = itemData.name, label = itemData.label, amount = itemData.amount, metadata = itemData.info or {}} or nil
end

Bridge.Inventory.createShop = function(shopName, data)
    while GetResourceState('tgiann-inventory') ~= 'started' do
        Citizen.Wait(100)
    end
    
    for i = 1, #data.inventory, 1 do
        if not data.inventory[i].amount then
            data.inventory[i].amount = 9999
        end
        
        if not data.inventory[i].slot then
            data.inventory[i].slot = i
        end
        if data.inventory[i].name:find('WEAPON_') then
            data.inventory[i].type = 'weapon'
        else
            data.inventory[i].type = 'item'
        end
    end
    exports["tgiann-inventory"]:RegisterShop(shopName, data.inventory)
end

RegisterNetEvent('p_bridge/inventory/openInventory', function(invType, data)
    if invType == 'stash' then
        if data.owner then
            exports['tgiann-inventory']:OpenInventory(source, "stash", data.id..'_'..data.owner)
        else
            exports['tgiann-inventory']:OpenInventory(source, "stash", data)
        end
    elseif invType == 'player' then
        exports["tgiann-inventory"]:OpenInventoryById(source, data)
    elseif invType == 'shop' then
        exports["tgiann-inventory"]:OpenShop(source, data.type)
    end
end)