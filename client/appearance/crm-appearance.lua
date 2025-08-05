if (Config.Appearance == 'auto' and not checkResource('crm-appearance')) or (Config.Appearance ~= 'auto' and Config.Appearance ~= 'crm-appearance') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Appearance] Loaded: crm-appearance')
end

Bridge.Appearance = {}

Bridge.Appearance.fetchCurrentSkin = function()
    local currentSkin = exports['crm-appearance']:crm_get_ped_appearance(cache.ped)

    if Config.Debug then
        lib.print.info('[Appearance] Fetched current skin:', currentSkin)
    end

    return currentSkin
end

Bridge.Appearance.fetchDatabaseSkin = function()
    local databaseSkin = exports['crm-appearance']:crm_get_ped_appearance(cache.ped)

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

    exports['crm-appearance']:crm_set_ped_appearance(cache.ped, skinData)

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

    exports['crm-appearance']:crm_set_ped_clothing(cache.ped, clothingData)

    if Config.Debug then
        lib.print.info('[Appearance] Set player clothing:', clothingData)
    end
end