if (Config.Appearance == 'auto' and not checkResource('rcore_clothing')) or (Config.Appearance ~= 'auto' and Config.Appearance ~= 'rcore_clothing') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Appearance] Loaded: rcore_clothing')
end

Bridge.Appearance = {}

local persistGeneration = 0

local function queuePersistCurrentSkin()
    persistGeneration = persistGeneration + 1
    local generation = persistGeneration

    CreateThread(function()
        Wait(1500)
        if generation ~= persistGeneration then
            return
        end

        if GetResourceState('rcore_clothing') ~= 'started' then
            return
        end

        TriggerEvent('rcore_clothing:saveCurrentSkin')

        if Config.Debug then
            lib.print.info('[Appearance] Persisted current RCore skin after wardrobe finished')
        end
    end)
end

local function decodeIfNeeded(data)
    if type(data) == 'string' then
        local ok, decoded = pcall(json.decode, data)

        if ok then
            return decoded
        end

        lib.print.error('[Appearance] Failed to decode skin/clothing JSON')
        return nil
    end

    return data
end

local function isNonEmptyTable(data)
    return type(data) == 'table' and next(data) ~= nil
end

local function unwrapSkin(data)
    data = decodeIfNeeded(data)

    if type(data) ~= 'table' then
        return data
    end

    if data.skin ~= nil and (data.ped_model ~= nil or data.model ~= nil) then
        local skin = decodeIfNeeded(data.skin)

        if type(skin) == 'table' then
            return skin
        end
    end

    return data
end

local function isNativeRcoreClothing(data)
    data = unwrapSkin(data)

    if type(data) ~= 'table' then
        return false
    end

    if type(data.components) ~= 'table' and type(data.props) ~= 'table' then
        return false
    end

    return true
end

local function getNativeCurrentClothing()

    local ok, skin = pcall(function()
        return exports['rcore_clothing']:getPlayerSkin(false)
    end)

    skin = unwrapSkin(skin)

    if ok and isNonEmptyTable(skin) then
        if Config.Debug then
            lib.print.info('[Appearance] RCore getPlayerSkin(false):', skin)
        end

        return skin
    end

    ok, skin = pcall(function()
        return exports['rcore_clothing']:getPlayerClothing()
    end)

    skin = unwrapSkin(skin)

    if ok and isNonEmptyTable(skin) then
        if Config.Debug then
            lib.print.info('[Appearance] RCore getPlayerClothing():', skin)
        end

        return skin
    end

    lib.print.error('[Appearance] rcore_clothing returned no native clothing data. Outfit was NOT captured.')
    return nil
end

local function applyNativeRcoreClothing(clothingData)
    clothingData = unwrapSkin(clothingData)

    if not isNonEmptyTable(clothingData) then
        lib.print.error('[Appearance] Native RCore clothing payload is empty')
        return false
    end

    local ped = PlayerPedId()

    local ok, err = pcall(function()
        exports['rcore_clothing']:setPedSkin(ped, clothingData)
    end)

    if not ok then
        lib.print.error(('[Appearance] rcore_clothing:setPedSkin failed: %s'):format(tostring(err)))
        return false
    end

    pcall(function()
        exports['rcore_clothing']:fixArms()
    end)

    queuePersistCurrentSkin()

    if Config.Debug then
        lib.print.info('[Appearance] Applied native RCore clothing:', clothingData)
        lib.print.info('[Appearance] Queued RCore persistence after wardrobe closes')
    end

    return true
end

local function applyFullRcoreSkin(skinData)
    skinData = unwrapSkin(skinData)

    if not isNonEmptyTable(skinData) then
        lib.print.error('[Appearance] Full RCore skin payload is empty')
        return false
    end

    local ok, err = pcall(function()
        exports['rcore_clothing']:setPlayerSkin(skinData, false)
    end)

    if ok then
        return true
    end

    ok, err = pcall(function()
        exports['rcore_clothing']:setPedSkin(PlayerPedId(), skinData)
    end)

    if not ok then
        lib.print.error(('[Appearance] Failed to apply RCore skin: %s'):format(tostring(err)))
        return false
    end

    return true
end

Bridge.Appearance.fetchCurrentSkin = function()

    local clothing = getNativeCurrentClothing()

    if not clothing then
        return nil
    end

    if Config.Debug then
        lib.print.info('[Appearance] Captured native RCore wardrobe outfit:', clothing)
    end

    return clothing
end

Bridge.Appearance.fetchDatabaseSkin = function()
    local databaseSkin = lib.callback.await('p_bridge/server/getPlayerSkin', false)

    if Config.Debug then
        lib.print.info('[Appearance] Fetched database skin:', databaseSkin)
    end

    return databaseSkin
end

Bridge.Appearance.convertSkinFormat = function(skinData)
    skinData = decodeIfNeeded(skinData)

    if not skinData or type(skinData) ~= 'table' then
        lib.print.error('[Appearance] Skin data is nil or not a table!')
        return
    end

    return skinData
end

Bridge.Appearance.setPlayerSkin = function(skinData)
    skinData = decodeIfNeeded(skinData)

    if not isNonEmptyTable(skinData) then
        lib.print.error('[Appearance] Skin data is nil or empty!')
        return false
    end

    local applied = applyFullRcoreSkin(skinData)

    if applied then
        queuePersistCurrentSkin()
    end

    if Config.Debug then
        lib.print.info('[Appearance] Full skin applied:', applied)
        if applied then
            lib.print.info('[Appearance] Queued full-skin persistence after wardrobe closes')
        end
    end

    return applied
end

Bridge.Appearance.setPlayerClothing = function(clothingData)
    clothingData = decodeIfNeeded(clothingData)

    if not isNonEmptyTable(clothingData) then
        lib.print.error('[Appearance] Clothing data is nil or empty!')
        return false
    end

    if not isNativeRcoreClothing(clothingData) then
        lib.print.error('[Appearance] This police outfit is not saved in native rcore_clothing format. Recreate this outfit after installing the RCore bridge fix.')

        if Config.Debug then
            lib.print.info('[Appearance] Rejected non-RCore wardrobe payload:', clothingData)
        end

        return false
    end

    return applyNativeRcoreClothing(clothingData)
end