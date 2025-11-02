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
Bridge.Framework.getUniqueId = function(playerId)
    if not playerId then
        lib.print.error('Player ID is required to fetch unique ID.')
        return nil
    end

    local player = Ox.GetPlayerFromFilter({ source = playerId })
    if not player then
        lib.print.error(('No player found with ID: %s'):format(playerId))
        return nil
    end

    return player.identifier
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

