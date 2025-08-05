if (Config.Appearance == 'auto' and not checkResource('esx_skin')) or (Config.Appearance ~= 'auto' and Config.Appearance ~= 'esx_skin') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Appearance] Loaded: esx_skin')
end

Bridge.Appearance = {}

Bridge.Appearance.fetchCurrentSkin = function()
    local currentSkin = nil
    TriggerEvent('skinchanger:getSkin', function(skinData)
        currentSkin = skinData
    end)

    while currentSkin == nil do
        Citizen.Wait(1)
    end

    if Config.Debug then
        lib.print.info('[Appearance] Fetched current skin:', currentSkin)
    end

    return currentSkin
end

Bridge.Appearance.fetchDatabaseSkin = function()
    local databaseSkin = nil
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skinData, _)
        databaseSkin = skinData
    end)

    while databaseSkin == nil do
        Citizen.Wait(1)
    end

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

    TriggerEvent('skinchanger:loadSkin', skinData)

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

    TriggerEvent('skinchanger:getSkin', function(skinData)
        TriggerEvent('skinchanger:loadClothes', skinData, clothingData)
    end)

    if Config.Debug then
        lib.print.info('[Appearance] Set player clothing:', clothingData)
    end
end