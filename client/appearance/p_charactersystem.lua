if (Config.Appearance == 'auto' and not checkResource('p_charactersystem')) or (Config.Appearance ~= 'auto' and Config.Appearance ~= 'p_charactersystem') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Appearance] Loaded: p_charactersystem')
end

-- p_charactersystem stores skins in illenium-appearance's format (users.skin / playerskins)
-- and exports illenium's functions under its own resource name.
local appearance = exports['p_charactersystem']

Bridge.Appearance = {}

Bridge.Appearance.fetchCurrentSkin = function()
    return appearance:getPedAppearance(cache.ped)
end

Bridge.Appearance.fetchDatabaseSkin = function()
    local databaseSkin = lib.callback.await('p_bridge/server/getPlayerSkin', false)

    if Config.Debug then
        lib.print.info('[Appearance] Fetched database skin:', databaseSkin)
    end

    return databaseSkin
end

local ESX_COMPONENTS = {
    { 1, 'mask_1', 'mask_2' }, { 3, 'arms', 'arms_2' }, { 4, 'pants_1', 'pants_2' }, { 5, 'bags_1', 'bags_2' },
    { 6, 'shoes_1', 'shoes_2' }, { 7, 'chain_1', 'chain_2' }, { 8, 'tshirt_1', 'tshirt_2' },
    { 9, 'bproof_1', 'bproof_2' }, { 10, 'decals_1', 'decals_2' }, { 11, 'torso_1', 'torso_2' },
}
local ESX_PROPS = {
    { 0, 'helmet_1', 'helmet_2' }, { 1, 'glasses_1', 'glasses_2' }, { 2, 'ears_1', 'ears_2' },
    { 6, 'watches_1', 'watches_2' }, { 7, 'bracelets_1', 'bracelets_2' },
}
local QB_COMPONENTS = {
    { 1, 'mask' }, { 3, 'arms' }, { 4, 'pants' }, { 5, 'bag' }, { 6, 'shoes' }, { 7, 'accessory' },
    { 8, 't-shirt' }, { 9, 'vest' }, { 10, 'decals' }, { 11, 'torso2' },
}
local QB_PROPS = { { 0, 'hat' }, { 1, 'glass' }, { 2, 'ear' }, { 6, 'watch' }, { 7, 'bracelet' } }

--@param skinData: table [esx skinchanger, qb-clothing or illenium format]
--@return table [illenium format: { components = {...}, props = {...} }]
Bridge.Appearance.convertSkinFormat = function(skinData)
    if not skinData or type(skinData) ~= 'table' then
        lib.print.error('[Appearance] Skin data is nil or not a table!')
        return
    end

    if skinData.components then
        return skinData
    end

    local components, props = {}, {}
    if skinData.torso_1 ~= nil or skinData.mask_1 ~= nil or skinData.sex ~= nil then
        for _, map in ipairs(ESX_COMPONENTS) do
            components[#components + 1] = { component_id = map[1], drawable = skinData[map[2]] or 0, texture = skinData[map[3]] or 0 }
        end
        for _, map in ipairs(ESX_PROPS) do
            props[#props + 1] = { prop_id = map[1], drawable = skinData[map[2]] or -1, texture = skinData[map[3]] or 0 }
        end
    else
        for _, map in ipairs(QB_COMPONENTS) do
            local v = skinData[map[2]]
            components[#components + 1] = { component_id = map[1], drawable = v and v.item or 0, texture = v and v.texture or 0 }
        end
        for _, map in ipairs(QB_PROPS) do
            local v = skinData[map[2]]
            props[#props + 1] = { prop_id = map[1], drawable = v and v.item or -1, texture = v and v.texture or 0 }
        end
    end

    return { components = components, props = props }
end

local function decode(data)
    if type(data) == 'string' then
        return json.decode(data)
    end
    return data
end

Bridge.Appearance.setPlayerSkin = function(skinData)
    skinData = decode(skinData)
    if not skinData then
        lib.print.error('[Appearance] Skin data is nil or empty!')
        return
    end

    if skinData.model then
        appearance:setPlayerAppearance(skinData)
    else
        local converted = Bridge.Appearance.convertSkinFormat(skinData)
        appearance:setPedComponents(cache.ped, converted.components)
        appearance:setPedProps(cache.ped, converted.props)
    end

    if Config.Debug then
        lib.print.info('[Appearance] Set player skin:', skinData)
    end
end

Bridge.Appearance.setPlayerClothing = function(clothingData)
    clothingData = decode(clothingData)
    if not clothingData then
        lib.print.error('[Appearance] Clothing data is nil or empty!')
        return
    end

    local converted = Bridge.Appearance.convertSkinFormat(clothingData)
    appearance:setPedComponents(cache.ped, converted.components)
    appearance:setPedProps(cache.ped, converted.props)

    if Config.Debug then
        lib.print.info('[Appearance] Set player clothing:', clothingData)
    end
end
