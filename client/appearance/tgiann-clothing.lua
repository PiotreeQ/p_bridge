if (Config.Appearance == 'auto' and not checkResource('tgiann-clothing')) or (Config.Appearance ~= 'auto' and Config.Appearance ~= 'tgiann-clothing') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Appearance] Loaded: tgiann-clothing')
end

Bridge.Appearance = {}

Bridge.Appearance.fetchCurrentSkin = function()
    local currentSkin = lib.callback.await('p_bridge/server/getPlayerSkin', false)

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
    
    local restricted = {
        ['helmet'] = true, ['mask'] = true, ['glasses'] = true, ['ears'] = true,
        ['tshirt'] = true, ['torso'] = true, ['decals'] = true, ['arms'] = true,
        ['pants'] = true, ['shoes'] = true, ['bags'] = true, ['bproof'] = true,
        ['decals'] = true, ['watches'] = true, ['bracelet'] = true, ['chain'] = true
    }
    local convertedSkin = {}
    for k, v in pairs(skin) do
        for name, _ in pairs(restricted) do
            if k:find(name) then
                table.insert(convertedSkin, {name = k, value = v})
                break
            end
        end
    end
    return convertedSkin
end

Bridge.Appearance.setPlayerSkin = function(skinData)
    if not skinData then
        lib.print.error('[Appearance] Skin data is nil or empty!')
        return
    end

    if type(skinData) == 'string' then
        skinData = json.decode(skinData)
    end

    TriggerEvent("tgiann-clothing:changeScriptClothe", skinData)

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

    local restricted = {
        ['helmet'] = true, ['mask'] = true, ['glasses'] = true, ['ears'] = true,
        ['tshirt'] = true, ['torso'] = true, ['decals'] = true, ['arms'] = true,
        ['pants'] = true, ['shoes'] = true, ['bags'] = true, ['bproof'] = true,
        ['decals'] = true, ['watches'] = true, ['bracelet'] = true, ['chain'] = true
    }
    local skinData = {}
    for k, v in pairs(clothingData) do
        for name, _ in pairs(restricted) do
            if v.name:find(name) then
                table.insert(skinData, v)
                break
            end
        end
    end
    TriggerEvent("tgiann-clothing:changeScriptClothe", skinData)

    if Config.Debug then
        lib.print.info('[Appearance] Set player clothing:', clothingData)
    end
end