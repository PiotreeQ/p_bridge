if (Config.Appearance == 'auto' and not checkResource('qb-clothing')) or (Config.Appearance ~= 'auto' and Config.Appearance ~= 'qb-clothing') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Appearance] Loaded: qb-clothing')
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
    
    return {
        ["hat"] = { item = skin.helmet_1 or 0, texture = skin.helmet_2 or 0 },
        ["mask"] = { item = skin.mask_1 or 0, texture = skin.mask_2 or 0 },
        ["glass"] = { item = skin.glasses_1 or 0, texture = skin.glasses_2 or 0 },
        ["ear"] = { item = skin.ears_1 or 0, texture = skin.ears_2 or 0 },
        ["t-shirt"] = { item = skin.tshirt_1 or 0, texture = skin.tshirt_2 or 0 },
        ["torso2"] = { item = skin.torso_1 or 0, texture = skin.torso_2 or 0 },
        ["decals"] = { item = skin.decals_1 or 0, texture = skin.decals_2 or 0 },
        ["arms"] = { item = skin.arms or 0, texture = 0 },
        ["pants"] = { item = skin.pants_1 or 0, texture = skin.pants_2 or 0 },
        ["shoes"] = { item = skin.shoes_1 or 0, texture = skin.shoes_2 or 0 },
        ["bag"] = { item = skin.bags_1 or 0, texture = skin.bags_2 or 0 },
        ["vest"] = { item = skin.bproof_1 or 0, texture = skin.bproof_2 or 0 },
        ["accessory"] = { item = skin.chain_1 or 0, texture = skin.chain_2 or 0 },
        ["watch"] = { item = skin.watches_1 or 0, texture = skin.watches_2 or 0 },
        ["bracelet"] = { item = skin.bracelets_1 or 0, texture = skin.bracelets_2 or 0 }
    }
end

Bridge.Appearance.setPlayerSkin = function(skinData)
    if not skinData then
        lib.print.error('[Appearance] Skin data is nil or empty!')
        return
    end

    if type(skinData) == 'string' then
        skinData = json.decode(skinData)
    end

    TriggerEvent('qb-clothing:client:loadPlayerClothing', skinData, nil)

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

    TriggerEvent('qb-clothing:client:loadOutfit', {outfitData = clothingData})

    if Config.Debug then
        lib.print.info('[Appearance] Set player clothing:', clothingData)
    end
end