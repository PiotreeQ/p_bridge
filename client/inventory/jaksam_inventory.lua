if (Config.Inventory == 'auto' and not checkResource('jaksam_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'jaksam_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: jaksam_inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.openInventory = function(invType, data)
    local invId = nil
    if type(data) == 'table' then
        if data.owner then
            invId = ('%s_%s'):format(data.id, data.owner)
        else
            invId = data.id
        end
    elseif type(data) == 'string' then
        invId = data
    end
    exports['jaksam_inventory']:openInventory(invId)
end

Bridge.Inventory.getItemCount = function(itemName)
    return exports['jaksam_inventory']:getTotalItemAmount(itemName)
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports['jaksam_inventory']:getStaticItem(itemName)
    return info and {name = itemName, label = info.label, description = info.description, image = ('https://cfx-nui-jaksam_inventory/_images/%s.png'):format(itemName)}
end

Bridge.Inventory.getPlayerItems = function()
    return exports['jaksam_inventory']:getInventory()?.items or {}
end