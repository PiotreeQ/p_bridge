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

Bridge.Appearance.fetchCurrentSkin = function()
    local currentSkin = exports['rcore_clothing']:getPlayerSkin(false)

    if Config.Debug then
        lib.print.info('[Appearance] Fetched current skin:', currentSkin)
    end

    return currentSkin
end

Bridge.Appearance.fetchDatabaseSkin = function()
    local databaseSkin = lib.callback.await('p_bridge/server/getPlayerSkin', false)

    if Config.Debug then
        lib.print.info('[Appearance] Fetched database skin:', databaseSkin)
    end

    return databaseSkin
end

Bridge.Appearance.convertSkinFormat = function(skinData)
    if not skinData or type(skinData) ~= 'table' then
        lib.print.error('[Appearance] Skin data is nil or not a table!')
        return
    end
    
    return skinData -- no need to convert [esx skin format is default]
end

Bridge.Appearance.setPlayerSkin = function(skinData)
    if not skinData then
        lib.print.error('[Appearance] Skin data is nil or empty!')
        return
    end

    if type(skinData) == 'string' then
        skinData = json.decode(skinData)
    end

    exports['rcore_clothing']:setPlayerSkin(skinData)

    if Config.Debug then
        lib.print.info('[Appearance] Set player skin:', skinData)
    end
end

Bridge.Appearance.setPlayerClothing = function(clothingData)
    if not clothingData then
        lib.print.error('[Appearance] Clothing data is nil or empty!')
        return
    end

    if type(clothingData) == 'string' then
        clothingData = json.decode(clothingData)
    end

    exports['rcore_clothing']:setPlayerSkin(clothingData)

    if Config.Debug then
        lib.print.info('[Appearance] Set player clothing:', clothingData)
    end
end