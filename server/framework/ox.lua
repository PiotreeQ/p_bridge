if (Config.Framework == 'auto' and not checkResource('ox_core')) or (Config.Framework ~= 'auto' and Config.Framework ~= 'ox') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Framework] Loaded: OX')
end

-- NOT BEEN ABLE TO TEST IT, CREATE PULL REQUEST IF THERE IS SOME ISSUES :)

local Ox = require '@ox_core.lib.init'

RegisterNetEvent('ox:playerLoaded', function(playerId)
    TriggerEvent('p_bridge/server/playerLoaded', playerId) -- DONT TOUCH IT!
end)

Bridge.Framework = {}

Bridge.Framework.frameworkUniqueId = function()
    return Config.FrameworkUniqueId['ox']
end

--@param playerId: number [existing player id]
--@return xPlayer: table [player object]
Bridge.Framework.getPlayerById = function(playerId)
    if not playerId then
        lib.print.error('Player ID is required to fetch player data.')
        return nil
    end

    local player = Ox.GetPlayerFromFilter({ source = playerId })
    if not player then
        lib.print.error(('No player found with ID: %s'):format(playerId))
        return nil
    end

    return player
end

--@param uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
--@return playerId: number [player ID]
Bridge.Framework.getPlayerId = function(uniqueId)
    if not uniqueId then
        lib.print.error('Unique ID is required to fetch player ID.')
        return nil
    end

    local player = Ox.GetPlayerFromFilter({ identifier = uniqueId })
    if not player then
        lib.print.error(('No player found with unique ID: %s'):format(uniqueId))
        return nil
    end

    return player.source
end

--@param uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
--@return xPlayer: table [player object]
Bridge.Framework.getPlayerByUniqueId = function(uniqueId)
    if not uniqueId then
        lib.print.error('Unique ID is required to fetch player data.')
        return nil
    end

    local player = Ox.GetPlayerFromFilter({ identifier = uniqueId })
    if not player then
        lib.print.error(('No player found with unique ID: %s'):format(uniqueId))
        return nil
    end

    return player
end

--@param playerId: number|string [existing player id or unique identifier]
--@return uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
Bridge.Framework.getUniqueId = function(playerId, isCitizenId)
    if not playerId then
        lib.print.error('Player ID is required to fetch unique ID.')
        return nil
    end

    local player = Ox.GetPlayerFromFilter({ source = playerId })
    if not player then
        lib.print.error(('No player found with ID: %s'):format(playerId))
        return nil
    end

    return isCitizenId and player[Config.FrameworkUniqueId['ox']] or player.identifier
end

--@param plate: string [vehicle plate]
--@return { owner: string, props: string, plate: string, model: string|number }|nil
-- Normalized owned-vehicle data, framework agnostic. Returns nil when the plate is not owned.
-- NOT BEEN ABLE TO TEST IT, CREATE PULL REQUEST IF THERE IS SOME ISSUES :)
Bridge.Framework.getOwnedVehicle = function(plate)
    if not plate then return nil end

    local row = MySQL.single.await('SELECT owner, data, plate, model FROM vehicles WHERE plate = ?', {plate})
    if not row then return nil end

    return {
        owner = row.owner,
        props = row.data,
        plate = row.plate,
        model = row.model
    }
end

--@param plate: string [vehicle plate]
--@param impounded: boolean [true to mark as impounded, false to release back to the owner]
--@return boolean [true if a row was updated]
-- ox_core `stored` holds the garage name (or NULL when out). NOT BEEN ABLE TO TEST IT.
Bridge.Framework.setVehicleImpounded = function(plate, impounded)
    if not plate then return false end

    local affected
    if impounded then
        affected = MySQL.update.await('UPDATE vehicles SET stored = ? WHERE plate = ?', {'impound', plate})
    else
        -- released vehicles are spawned out at the impound lot, so `stored` goes back to NULL
        affected = MySQL.update.await('UPDATE vehicles SET stored = NULL WHERE plate = ?', {plate})
    end
    return (affected or 0) > 0
end

--@param playerId: number|string [existing player id or unique identifier]
--@return { name: string, label: string, grade: number, grade_name: string, grade_label: string }
-- If playerId is a number, it fetches by ID; if it's a string, it fetches by identifier
Bridge.Framework.getPlayerJob = function(playerId)
    local xPlayer = type(playerId) == 'number' and Ox.GetPlayerFromFilter({ source = playerId }) or Ox.GetPlayerFromFilter({ identifier = playerId })
    if not xPlayer then
        lib.print.error(('No player found with ID: %s'):format(playerId))
    end

    local jobName = xPlayer.activeGroup
    local jobGrade = jobName and xPlayer.getGroup(jobName) or nil
    return {
        name = jobName or 'unemployed',
        label = jobName or 'Unemployed',
        grade = jobGrade or 0,
        grade_name = jobName or 'unemployed',
        grade_label = jobName or 'Unemployed'
    }
end

--@param playerId: number|string [existing player id or unique identifier]
--@param separate: boolean [if true, returns firstname and lastname separately]
--@return name: string [example 'John Doe'] or firstname, lastname: string
Bridge.Framework.getPlayerName = function(playerId, separate)
    local xPlayer = type(playerId) == 'number' and Ox.GetPlayerFromFilter({ source = playerId }) or Ox.GetPlayerFromFilter({ identifier = playerId })
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return nil
    end

    if separate then
        return xPlayer.get('firstName'), xPlayer.get('lastName')
    end

    return ('%s %s'):format(xPlayer.get('firstName'), xPlayer.get('lastName'))
end

--@param playerId: number|string [existing player id or unique identifier]
--@return dob: string|nil [the player's date of birth]
Bridge.Framework.getPlayerDob = function(playerId)
    local xPlayer = type(playerId) == 'number' and Ox.GetPlayerFromFilter({ source = playerId }) or Ox.GetPlayerFromFilter({ identifier = playerId })
    if not xPlayer then return nil end
    return xPlayer.get('dateOfBirth')
end

--@param playerId: number|string [existing player id or unique identifier]
--@return gender: 'male'|'female'|nil [the player's gender from character data]
Bridge.Framework.getPlayerGender = function(playerId)
    local xPlayer = type(playerId) == 'number' and Ox.GetPlayerFromFilter({ source = playerId }) or Ox.GetPlayerFromFilter({ identifier = playerId })
    if not xPlayer then return nil end

    local gender = xPlayer.get('gender')
    if gender == nil then return nil end

    gender = tostring(gender):lower()
    return (gender == 'female' or gender == 'f' or gender == '1') and 'female' or 'male'
end

--@param playerId: number|string [existing player id or unique identifier]
--@return { money: number, bank: number, black_money: number }
-- If playerId is a number, it fetches by ID; if it's a string, it fetches by identifier
Bridge.Framework.getMoney = function(playerId)
     local xPlayer = type(playerId) == 'number' and Ox.GetPlayerFromFilter({ source = playerId }) or Ox.GetPlayerFromFilter({ identifier = playerId })
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return nil
    end

    local account = xPlayer.getAccount()
    return {
        money = exports['ox_inventory']:Search(playerId, 'count', 'money') or 0,
        bank = account.balance or 0,
        black_money = 0
    }
end

lib.callback.register('p_bridge/server/framework/getMoney', Bridge.Framework.getMoney)

--@param playerId: number|string [existing player id or unique identifier]
--@param account: string [account type, e.g., 'money', 'bank', 'black_money']
--@param amount: number [amount to add]
--@return boolean [true if money was added successfully, false otherwise]
Bridge.Framework.removeMoney = function(playerId, account, amount)
     local xPlayer = type(playerId) == 'number' and Ox.GetPlayerFromFilter({ source = playerId }) or Ox.GetPlayerFromFilter({ identifier = playerId })
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    if account == 'black_money' then
        lib.print.error('Black money removal is not supported in OX Framework.')
        return false
    elseif account == 'money' then
        exports['ox_inventory']:RemoveItem(playerId, 'money', amount)
    elseif account == 'bank' then
        local account = xPlayer.getAccount()
        account.removeBalance({ amount = amount, message = 'No reason', overdraw = false })
    end

    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param account: string [account type, e.g., 'money', 'bank', 'black_money']
--@param amount: number [amount to add]
--@return boolean [true if money was added successfully, false otherwise]
Bridge.Framework.addMoney = function(playerId, account, amount)
     local xPlayer = type(playerId) == 'number' and Ox.GetPlayerFromFilter({ source = playerId }) or Ox.GetPlayerFromFilter({ identifier = uniqueId })
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    if account == 'black_money' then
        lib.print.error('Black money add is not supported in OX Framework.')
        return false
    elseif account == 'money' then
        exports['ox_inventory']:AddItem(playerId, 'money', amount)
    elseif account == 'bank' then
        local account = xPlayer.getAccount()
        account.addBalance({ amount = amount, message = 'No reason' })
    end
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param license: string [license type, e.g., 'driver', 'weapon']
--@return boolean [true if player has the license, false otherwise]
Bridge.Framework.checkPlayerLicense = function(playerId, license)
    local xPlayer = type(playerId) == 'number' and Ox.GetPlayerFromFilter({ source = playerId }) or Ox.GetPlayerFromFilter({ identifier = uniqueId })
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    return xPlayer.getLicense(license)
end

--@param playerId: number|string [existing player id or unique identifier]
--@param license: string [license type, e.g., 'driver', 'weapon']
--@return boolean [true if license has been added, false if not]
Bridge.Framework.addPlayerLicense = function(playerId, license)
    local xPlayer = type(playerId) == 'number' and Ox.GetPlayerFromFilter({ source = playerId }) or Ox.GetPlayerFromFilter({ identifier = uniqueId })
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    xPlayer.addLicense(license)
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param license: string [license type, e.g., 'driver', 'weapon']
--@return boolean [true if license has been removed, false if not]
Bridge.Framework.removePlayerLicense = function(playerId, license)
    local xPlayer = type(playerId) == 'number' and Ox.GetPlayerFromFilter({ source = playerId }) or Ox.GetPlayerFromFilter({ identifier = uniqueId })
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    xPlayer.removeLicense(license)
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param key: string [metadata key, e.g., 'callsign']
--@param value: any [metadata value]
--@return boolean [true if metadata has been set, false if not]
Bridge.Framework.setPlayerMetadata = function(playerId, key, value)
    local xPlayer = type(playerId) == 'number' and Ox.GetPlayerFromFilter({ source = playerId }) or Ox.GetPlayerFromFilter({ identifier = uniqueId })
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    xPlayer.set(key, value, true)
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param requiredGroups: table [list of required groups]
Bridge.Framework.checkPermissions = function(playerId, requiredGroups)
    local xPlayer = type(playerId) == 'number' and Ox.GetPlayerFromFilter({ source = playerId }) or Ox.GetPlayerFromFilter({ identifier = uniqueId })
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    for group, _ in pairs(requiredGroups) do
        if xPlayer.getGroup(group) then
            return true
        end
    end

    return false
end

lib.callback.register('p_bridge/server/framework/checkPermissions', Bridge.Framework.checkPermissions)

