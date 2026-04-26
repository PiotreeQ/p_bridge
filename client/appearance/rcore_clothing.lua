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

local CLOTHING_KEYS = {
    tshirt_1 = true,
    tshirt_2 = true,
    torso_1 = true,
    torso_2 = true,
    decals_1 = true,
    decals_2 = true,
    arms = true,
    arms_2 = true,

    pants_1 = true,
    pants_2 = true,
    shoes_1 = true,
    shoes_2 = true,

    mask_1 = true,
    mask_2 = true,
    bproof_1 = true,
    bproof_2 = true,
    chain_1 = true,
    chain_2 = true,
    bags_1 = true,
    bags_2 = true,

    helmet_1 = true,
    helmet_2 = true,
    glasses_1 = true,
    glasses_2 = true,
    ears_1 = true,
    ears_2 = true,
    watches_1 = true,
    watches_2 = true,
    bracelets_1 = true,
    bracelets_2 = true,
}

local function decodeIfNeeded(data)
    if type(data) == 'string' then
        local ok, decoded = pcall(json.decode, data)
        if ok and decoded then
            return decoded
        end

        lib.print.error('[Appearance] Failed to decode skin/clothing JSON')
        return nil
    end

    return data
end

local function cloneTable(data)
    if type(data) ~= 'table' then return data end

    local copy = {}

    for k, v in pairs(data) do
        if type(v) == 'table' then
            copy[k] = cloneTable(v)
        else
            copy[k] = v
        end
    end

    return copy
end

local function extractClothingOnly(skinData)
    skinData = decodeIfNeeded(skinData)

    if not skinData or type(skinData) ~= 'table' then
        lib.print.error('[Appearance] Skin data is nil or not a table!')
        return {}
    end

    local clothing = {}

    for key, value in pairs(skinData) do
        if CLOTHING_KEYS[key] then
            clothing[key] = value
        end
    end

    if type(skinData.components) == 'table' then
        clothing.components = cloneTable(skinData.components)
    end

    if type(skinData.props) == 'table' then
        clothing.props = cloneTable(skinData.props)
    end

    return clothing
end

local function mergeClothingIntoSkin(baseSkin, clothingData)
    baseSkin = decodeIfNeeded(baseSkin)
    clothingData = decodeIfNeeded(clothingData)

    if not baseSkin or type(baseSkin) ~= 'table' then
        baseSkin = {}
    end

    if not clothingData or type(clothingData) ~= 'table' then
        lib.print.error('[Appearance] Clothing data is nil or not a table!')
        return baseSkin
    end

    local mergedSkin = cloneTable(baseSkin)
    local clothingOnly = extractClothingOnly(clothingData)

    for key, value in pairs(clothingOnly) do
        mergedSkin[key] = value
    end

    return mergedSkin
end

Bridge.Appearance.fetchCurrentSkin = function()
    local currentSkin = exports['rcore_clothing']:getPlayerSkin(false)

    local clothingOnly = extractClothingOnly(currentSkin)

    if Config.Debug then
        lib.print.info('[Appearance] Fetched current clothing only:', clothingOnly)
    end

    return clothingOnly
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

    return skinData
end

Bridge.Appearance.setPlayerSkin = function(skinData)
    skinData = decodeIfNeeded(skinData)

    if not skinData or type(skinData) ~= 'table' then
        lib.print.error('[Appearance] Skin data is nil or empty!')
        return
    end

    exports['rcore_clothing']:setPlayerSkin(skinData)

    if Config.Debug then
        lib.print.info('[Appearance] Set full player skin:', skinData)
    end
end

Bridge.Appearance.setPlayerClothing = function(clothingData)
    clothingData = decodeIfNeeded(clothingData)

    if not clothingData or type(clothingData) ~= 'table' then
        lib.print.error('[Appearance] Clothing data is nil or empty!')
        return
    end

    local currentSkin = exports['rcore_clothing']:getPlayerSkin(false)

    local mergedSkin = mergeClothingIntoSkin(currentSkin, clothingData)

    exports['rcore_clothing']:setPlayerSkin(mergedSkin)

    if Config.Debug then
        lib.print.info('[Appearance] Set player clothing only:', extractClothingOnly(clothingData))
        lib.print.info('[Appearance] Final merged skin applied:', mergedSkin)
    end
end
