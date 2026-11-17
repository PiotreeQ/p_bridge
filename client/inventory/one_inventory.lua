if (Config.Inventory == 'auto' and not checkResource('one_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'one_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: one_inventory')
end

Bridge.Inventory = {}

Bridge.Inventory.openInventory = function(invType, data)
    if invType == 'stash' and type(data) == 'table' then
        -- opens the shared 'stash:<id>' inventory the server exports use, with
        -- the bigger of the caller's and the registered size
        local stashId, slots, maxWeight, label = Bridge.Utils.resolveStash(data)
        exports['one_inventory']:OpenInventory('stash', {
            id = stashId,
            label = label,
            slots = slots,
            maxWeight = maxWeight,
        })
        return
    end
    exports['one_inventory']:OpenInventory(invType, data)
end

Bridge.Inventory.getItemCount = function(itemName, metadata)
    return exports['one_inventory']:GetItemCount(itemName, metadata or nil)
end

Bridge.Inventory.getItemData = function(itemName)
    local info = exports['one_inventory']:GetItemDefinition(itemName)
    if not info then
        return
    end

    local image = info.image or ('%s.png'):format(itemName)
    if not image:find('^https?://') then
        if not image:find('%.') then
            image = ('%s.png'):format(image)
        end
        image = ('https://cfx-nui-one_inventory/web/images/%s'):format(image)
    end

    return {name = itemName, label = info.label, description = info.description, image = image}
end

Bridge.Inventory.getPlayerItems = function()
    return exports['one_inventory']:GetInventoryItems()
end

---@return weapon: table|nil [currently equipped weapon { name, label, metadata, slot, ... } or nil]
Bridge.Inventory.getCurrentWeapon = function()
    return exports['one_inventory']:GetEquippedWeapon()
end

---@param state: boolean [true to force-holster/disarm the equipped weapon]
Bridge.Inventory.disarm = function(state)
    exports['one_inventory']:DisarmPlayer()
end
