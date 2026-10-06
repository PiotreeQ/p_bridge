-- jota-dev Appearance System (resource folder: jc_appearance)
-- https://store.jotadev.site/documentation/scripts/jota-dev-appearance-system
-- Client exports used: getPedAppearance(ped), getAppearance(), setAppearance(appearance),
-- setPlayerAppearance(appearance). The appearance table is the illenium shape:
-- { model, headBlend, faceFeatures, hair, headOverlays, components, props, tattoos, pedHeight }.
if (Config.Appearance == 'auto' and not checkResource('jc_appearance')) or (Config.Appearance ~= 'auto' and Config.Appearance ~= 'jc_appearance') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Appearance] Loaded: jc_appearance')
end

local RESOURCE = 'jc_appearance'

-- jc_appearance stores saved appearances in its own tables and exposes no export to
-- read them back, so the civilian look is snapshotted right before duty clothing is
-- applied; fetchDatabaseSkin uses it when the framework table holds nothing.
local cachedCivilianSkin = nil

Bridge.Appearance = {}

local function getCurrentAppearance()
    local ok, appearance = pcall(function() return exports[RESOURCE]:getPedAppearance(cache.ped) end)
    if ok and type(appearance) == 'table' then return appearance end

    ok, appearance = pcall(function() return exports[RESOURCE]:getAppearance() end)
    if ok and type(appearance) == 'table' then return appearance end

    lib.print.error('[Appearance] jc_appearance did not return an appearance table')
    return nil
end

Bridge.Appearance.fetchCurrentSkin = function()
    local appearance = getCurrentAppearance()

    if Config.Debug then
        lib.print.info('[Appearance] Fetched current skin:', appearance)
    end

    return appearance
end

Bridge.Appearance.fetchDatabaseSkin = function()
    -- The snapshot taken when duty clothing was applied wins: it is the look this
    -- player actually had, while the framework table may be older or empty.
    if cachedCivilianSkin then
        if Config.Debug then
            lib.print.info('[Appearance] Restoring the civilian skin cached before duty clothing')
        end
        return cachedCivilianSkin
    end

    local databaseSkin = lib.callback.await('p_bridge/server/getPlayerSkin', false)

    if Config.Debug then
        lib.print.info('[Appearance] Fetched database skin:', databaseSkin)
    end

    -- Last resort: jc_appearance ships a /reloadskin command that re-applies the
    -- appearance it has saved for the player.
    if not databaseSkin then
        lib.print.info('[Appearance] No stored skin found - falling back to the jc_appearance reloadskin command')
        ExecuteCommand('reloadskin')
        Citizen.Wait(500)
        -- reloadskin re-applies the saved look itself; hand the caller what the ped
        -- now wears so it does not report a failure.
        return getCurrentAppearance()
    end

    return databaseSkin
end

Bridge.Appearance.convertSkinFormat = function(skinData)
    if not skinData or type(skinData) ~= 'table' then
        lib.print.error('[Appearance] Skin data is nil or not a table!')
        return
    end

    if skinData.mask_1 then
        -- ESX / skinchanger format
        return {
            components = {
                { component_id = 1,  drawable = skinData.mask_1 or 0,      texture = skinData.mask_2 or 0 },      -- Mask
                { component_id = 3,  drawable = skinData.torso_1 or 0,     texture = skinData.torso_2 or 0 },     -- Torso
                { component_id = 4,  drawable = skinData.pants_1 or 0,     texture = skinData.pants_2 or 0 },     -- Pants
                { component_id = 5,  drawable = skinData.bags_1 or 0,      texture = skinData.bags_2 or 0 },      -- Bag
                { component_id = 6,  drawable = skinData.shoes_1 or 0,     texture = skinData.shoes_2 or 0 },     -- Shoes
                { component_id = 7,  drawable = skinData.accessory_1 or 0, texture = skinData.accessory_2 or 0 }, -- Accessories
                { component_id = 8,  drawable = skinData.tshirt_1 or 0,    texture = skinData.tshirt_2 or 0 },    -- Undershirt
                { component_id = 9,  drawable = skinData.armor_1 or 0,     texture = skinData.armor_2 or 0 },     -- Body Armor
                { component_id = 10, drawable = skinData.decals_1 or 0,    texture = skinData.decals_2 or 0 },    -- Decals
                { component_id = 11, drawable = skinData.torso_1 or 0,     texture = skinData.torso_2 or 0 },     -- Top
            },
            props = {
                { prop_id = 0, drawable = skinData.helmet_1 or -1,    texture = skinData.helmet_2 or 0 },    -- Helmet/Hat
                { prop_id = 1, drawable = skinData.glasses_1 or -1,   texture = skinData.glasses_2 or 0 },   -- Glasses
                { prop_id = 2, drawable = skinData.ears_1 or -1,      texture = skinData.ears_2 or 0 },      -- Ears
                { prop_id = 6, drawable = skinData.watches_1 or -1,   texture = skinData.watches_2 or 0 },   -- Watches
                { prop_id = 7, drawable = skinData.bracelets_1 or -1, texture = skinData.bracelets_2 or 0 }, -- Bracelets
            }
        }
    elseif skinData.mask then
        -- QB / qb-clothing format
        local tshirt = skinData["t-shirt"]
        return {
            components = {
                { component_id = 1,  drawable = skinData.mask and skinData.mask.item or 0,           texture = skinData.mask and skinData.mask.texture or 0 },
                { component_id = 3,  drawable = skinData.arms and skinData.arms.item or 0,           texture = skinData.arms and skinData.arms.texture or 0 },
                { component_id = 4,  drawable = skinData.pants and skinData.pants.item or 0,         texture = skinData.pants and skinData.pants.texture or 0 },
                { component_id = 5,  drawable = skinData.bag and skinData.bag.item or 0,             texture = skinData.bag and skinData.bag.texture or 0 },
                { component_id = 6,  drawable = skinData.shoes and skinData.shoes.item or 0,         texture = skinData.shoes and skinData.shoes.texture or 0 },
                { component_id = 7,  drawable = skinData.accessory and skinData.accessory.item or 0, texture = skinData.accessory and skinData.accessory.texture or 0 },
                { component_id = 8,  drawable = tshirt and tshirt.item or 0,                         texture = tshirt and tshirt.texture or 0 },
                { component_id = 9,  drawable = skinData.vest and skinData.vest.item or 0,           texture = skinData.vest and skinData.vest.texture or 0 },
                { component_id = 10, drawable = skinData.decals and skinData.decals.item or 0,       texture = skinData.decals and skinData.decals.texture or 0 },
                { component_id = 11, drawable = skinData.torso2 and skinData.torso2.item or 0,       texture = skinData.torso2 and skinData.torso2.texture or 0 },
            },
            props = {
                { prop_id = 0, drawable = skinData.hat and skinData.hat.item or -1,     texture = skinData.hat and skinData.hat.texture or 0 },
                { prop_id = 1, drawable = skinData.glass and skinData.glass.item or -1, texture = skinData.glass and skinData.glass.texture or 0 },
                { prop_id = 2, drawable = skinData.ear and skinData.ear.item or -1,     texture = skinData.ear and skinData.ear.texture or 0 },
                { prop_id = 6, drawable = -1, texture = 0 },
                { prop_id = 7, drawable = -1, texture = 0 },
            }
        }
    end

    -- Already a jc_appearance / illenium table
    return skinData
end

--- Read whatever the caller passed as a jc_appearance appearance table
local function toAppearance(data)
    if type(data) == 'string' then
        data = json.decode(data)
    end
    if type(data) ~= 'table' then return nil end

    local isESX = data.torso_1 ~= nil or data.mask_1 ~= nil or data.sex ~= nil
    local isQB  = type(data.torso) == 'table' or type(data.pants) == 'table' or type(data.mask) == 'table'
    if not data.components and (isESX or isQB) then
        data = Bridge.Appearance.convertSkinFormat(data)
    end

    return data
end

Bridge.Appearance.setPlayerSkin = function(skinData)
    if not skinData then
        lib.print.error('[Appearance] Skin data is nil or empty!')
        return
    end

    local appearance = toAppearance(skinData)
    if not appearance then
        lib.print.error('[Appearance] Skin data could not be read as an appearance table!')
        return
    end

    -- An outfit-only table (no model/headBlend) would reset face and hair, so merge
    -- it into what the ped is wearing right now instead.
    if not appearance.model and not appearance.headBlend then
        local current = getCurrentAppearance()
        if current then
            current.components = appearance.components or current.components
            current.props = appearance.props or current.props
            appearance = current
        end
    end

    exports[RESOURCE]:setPlayerAppearance(appearance)

    -- Back in their own clothes: the snapshot has done its job.
    cachedCivilianSkin = nil

    if Config.Debug then
        lib.print.info('[Appearance] Set player skin:', appearance)
    end
end

Bridge.Appearance.setPlayerClothing = function(clothingData)
    if not clothingData then
        lib.print.error('[Appearance] Clothing data is nil or empty!')
        return
    end

    local outfit = toAppearance(clothingData)
    if not outfit then
        lib.print.error('[Appearance] Clothing data could not be read as an appearance table!')
        return
    end

    -- jc_appearance has no per-component export, so the outfit is merged into the
    -- current appearance, which keeps face, hair and tattoos untouched.
    local appearance = getCurrentAppearance()
    if not appearance then
        appearance = outfit
    else
        if not cachedCivilianSkin then
            -- deep copy: the merge below mutates `appearance`, and the export may
            -- well hand out the same table twice
            cachedCivilianSkin = lib.table.deepclone(appearance)
        end
        appearance.components = outfit.components or appearance.components
        appearance.props = outfit.props or appearance.props
    end

    exports[RESOURCE]:setPlayerAppearance(appearance)

    if Config.Debug then
        lib.print.info('[Appearance] Set player clothing:', appearance)
    end
end
