if (Config.Appearance == 'auto' and not checkResource('um-clothing')) or (Config.Appearance ~= 'auto' and Config.Appearance ~= 'um-clothing') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Appearance] Loaded: um-clothing')
end

-- um-clothing is a drop-in replacement for illenium-appearance / fivem-appearance
-- with skinchanger event compatibility. The primary path uses the illenium-style
-- exports under the um-clothing resource name; if a build does not expose them,
-- the skinchanger compat events are used as fallback.

Bridge.Appearance = {}

Bridge.Appearance.fetchCurrentSkin = function()
    local ok, appearance = pcall(function()
        return exports['um-clothing']:getPedAppearance(cache.ped)
    end)
    if ok and appearance then
        if Config.Debug then
            lib.print.info('[Appearance] Fetched current skin (export):', appearance)
        end
        return appearance
    end

    -- Fallback: skinchanger event compat layer (bounded wait - the event may
    -- simply not be handled, and this must not hang the caller forever)
    local currentSkin = nil
    TriggerEvent('skinchanger:getSkin', function(skinData)
        currentSkin = skinData
    end)
    local deadline = GetGameTimer() + 2000
    while currentSkin == nil and GetGameTimer() < deadline do
        Citizen.Wait(10)
    end

    if currentSkin == nil then
        lib.print.error('[Appearance] um-clothing: could not fetch the current skin (no getPedAppearance export, no skinchanger compat)')
    elseif Config.Debug then
        lib.print.info('[Appearance] Fetched current skin (skinchanger compat):', currentSkin)
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

    if skinData.mask_1 then
        return {
            components = {
                { component_id = 1,  drawable = skinData.mask_1 or 0,      texture = skinData.mask_2 or 0 },   -- Mask
                { component_id = 3,  drawable = skinData.torso_1 or 0,     texture = skinData.torso_2 or 0 },  -- Torso
                { component_id = 4,  drawable = skinData.pants_1 or 0,     texture = skinData.pants_2 or 0 },  -- Pants
                { component_id = 5,  drawable = skinData.bags_1 or 0,      texture = skinData.bags_2 or 0 },   -- Bag
                { component_id = 6,  drawable = skinData.shoes_1 or 0,     texture = skinData.shoes_2 or 0 },  -- Shoes
                { component_id = 7,  drawable = skinData.accessory_1 or 0, texture = skinData.accessory_2 or 0 }, -- Accessories
                { component_id = 8,  drawable = skinData.tshirt_1 or 0,    texture = skinData.tshirt_2 or 0 }, -- Undershirt
                { component_id = 9,  drawable = skinData.armor_1 or 0,     texture = skinData.armor_2 or 0 },  -- Body Armor
                { component_id = 10, drawable = skinData.decals_1 or 0,    texture = skinData.decals_2 or 0 }, -- Decals
                { component_id = 11, drawable = skinData.torso_1 or 0,     texture = skinData.torso_2 or 0 },  -- Top
            },
            props = {
                { prop_id = 0, drawable = skinData.helmet_1 or -1,    texture = skinData.helmet_2 or 0 }, -- Helmet/Hat
                { prop_id = 1, drawable = skinData.glasses_1 or -1,   texture = skinData.glasses_2 or 0 }, -- Glasses
                { prop_id = 2, drawable = skinData.ears_1 or -1,      texture = skinData.ears_2 or 0 },   -- Ears
                { prop_id = 6, drawable = skinData.watches_1 or -1,   texture = skinData.watches_2 or 0 }, -- Watches
                { prop_id = 7, drawable = skinData.bracelets_1 or -1, texture = skinData.bracelets_2 or 0 } -- Bracelets
            }
        }
    elseif skinData.mask then
        return {
            components = {
                {component_id = 1, drawable = skinData.mask and skinData.mask.item or 0, texture = skinData.mask and skinData.mask.texture or 0},      -- Mask
                {component_id = 3, drawable = skinData.arms and skinData.arms.item or 0, texture = skinData.arms and skinData.arms.texture or 0},    -- Arms
                {component_id = 4, drawable = skinData.pants and skinData.pants.item or 0, texture = skinData.pants and skinData.pants.texture or 0},    -- Pants
                {component_id = 5, drawable = skinData.bag and skinData.bag.item or 0, texture = skinData.bag and skinData.bag.texture or 0},      -- Bag
                {component_id = 6, drawable = skinData.shoes and skinData.shoes.item or 0, texture = skinData.shoes and skinData.shoes.texture or 0},    -- Shoes
                {component_id = 7, drawable = skinData.accessory and skinData.accessory.item or 0, texture = skinData.accessory and skinData.accessory.texture or 0}, -- Accessories
                {component_id = 8, drawable = skinData['t-shirt'] and skinData['t-shirt'].item or 0, texture = skinData['t-shirt'] and skinData['t-shirt'].texture or 0},  -- T-Shirt
                {component_id = 9, drawable = skinData.vest and skinData.vest.item or 0, texture = skinData.vest and skinData.vest.texture or 0},    -- Body Vest
                {component_id = 10, drawable = skinData.decals and skinData.decals.item or 0, texture = skinData.decals and skinData.decals.texture or 0}, -- Decals
                {component_id = 11, drawable = skinData.torso2 and skinData.torso2.item or 0, texture = skinData.torso2 and skinData.torso2.texture or 0},   -- Torso
            },
            props = {
                {prop_id = 0, drawable = skinData.hat and skinData.hat.item or -1, texture = skinData.hat and skinData.hat.texture or 0},      -- Hat
                {prop_id = 1, drawable = skinData.glass and skinData.glass.item or -1, texture = skinData.glass and skinData.glass.texture or 0},    -- Glasses
                {prop_id = 2, drawable = skinData.ear and skinData.ear.item or -1, texture = skinData.ear and skinData.ear.texture or 0},          -- Ears
                {prop_id = 6, drawable = -1, texture = 0},    -- Watches
                {prop_id = 7, drawable = -1, texture = 0} -- Bracelets
            }
        }
    else
        return skinData
    end
end

Bridge.Appearance.setPlayerSkin = function(skinData)
    if not skinData then
        lib.print.error('[Appearance] Skin data is nil or empty!')
        return
    end

    if type(skinData) == 'string' then
        skinData = json.decode(skinData)
    end

    local rawSkin = skinData
    local isESX = skinData.torso_1 ~= nil or skinData.mask_1 ~= nil or skinData.sex ~= nil
    local isQB  = type(skinData.torso) == 'table' or type(skinData.pants) == 'table'
    if not skinData.components and (isESX or isQB) then
        skinData = Bridge.Appearance.convertSkinFormat(skinData)
    end

    local ok = pcall(function()
        exports['um-clothing']:setPlayerAppearance(skinData)
    end)
    if not ok then
        -- Fallback: skinchanger compat expects the legacy (unconverted) format
        TriggerEvent('skinchanger:loadSkin', rawSkin)
    end

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

    local rawClothing = clothingData
    local isESX = clothingData.torso_1 ~= nil or clothingData.mask_1 ~= nil or clothingData.sex ~= nil
    local isQB  = type(clothingData.torso) == 'table' or type(clothingData.pants) == 'table'
    if not clothingData.components and (isESX or isQB) then
        clothingData = Bridge.Appearance.convertSkinFormat(clothingData)
    end

    local ok = pcall(function()
        exports['um-clothing']:setPedComponents(cache.ped, clothingData.components)
        exports['um-clothing']:setPedProps(cache.ped, clothingData.props)
    end)
    if not ok then
        -- Fallback: skinchanger compat expects the legacy (unconverted) format
        TriggerEvent('skinchanger:getSkin', function(skinData)
            TriggerEvent('skinchanger:loadClothes', skinData, rawClothing)
        end)
    end

    if Config.Debug then
        lib.print.info('[Appearance] Set player clothing:', clothingData)
    end
end
