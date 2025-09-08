if (Config.Framework == 'auto' and not checkResource('ND_Core')) or (Config.Framework ~= 'auto' and Config.Framework ~= 'nd') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Framework] Loaded: ND_Core')
end

-- NOT BEEN ABLE TO TEST IT, CREATE PULL REQUEST IF THERE IS SOME ISSUES :)

RegisterNetEvent('ND:characterLoaded', function(player)
    TriggerEvent('p_bridge/server/playerLoaded', player.source) -- DONT TOUCH IT!
end)

Bridge.Framework = {}

--@param playerId: number [existing player id]
--@return xPlayer: table [player object]
Bridge.Framework.getPlayerById = function(playerId)
    if not playerId then
        lib.print.error('Player ID is required to fetch player data.')
        return nil
    end

    local xPlayer = exports["ND_Core"]:getPlayer(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s'):format(playerId))
        return nil
    end

    return xPlayer
end

--@param uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
--@return playerId: number [player ID]
Bridge.Framework.getPlayerId = function(uniqueId)
    if not uniqueId then
        lib.print.error('Unique ID is required to fetch player ID.')
        return nil
    end

    -- if you have better solution, please contact us on discord [discord.gg/piotreqscripts]
    local playerData = nil
    local players = exports["ND_Core"]:getPlayers()
    for id, data in pairs(players) do
        if data.identifier == uniqueId then
            playerData = data
            break
        end
    end

    return playerData?.source or nil
end

--@param uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
--@return xPlayer: table [player object]
Bridge.Framework.getPlayerByUniqueId = function(uniqueId)
    if not uniqueId then
        lib.print.error('Unique ID is required to fetch player data.')
        return nil
    end

    local playerData = nil
    local players = exports["ND_Core"]:getPlayers()
    for id, data in pairs(players) do
        if data.identifier == uniqueId then
            playerData = data
            break
        end
    end

    if not playerData then
        lib.print.error(('No player found with Unique ID: %s'):format(uniqueId))
        return nil
    end

    return playerData
end

--@param playerId: number|string [existing player id or unique identifier]
--@return uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
Bridge.Framework.getUniqueId = function(playerId)
    local xPlayer = type(playerId) == 'number' and exports["ND_Core"]:getPlayer(playerId) or Bridge.Framework.getPlayerByUniqueId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return nil
    end

    return xPlayer.identifier
end

--@param playerId: number|string [existing player id or unique identifier]
--@return { name: string, label: string, grade: number, grade_name: string, grade_label: string }
-- If playerId is a number, it fetches by ID; if it's a string, it fetches by identifier
Bridge.Framework.getPlayerJob = function(playerId)
    local xPlayer = type(playerId) == 'number' and exports["ND_Core"]:getPlayer(playerId) or Bridge.Framework.getPlayerByUniqueId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s'):format(playerId))
    end

    return {
        name = xPlayer.job or 'unemployed',
        label = xPlayer.jobInfo?.label or 'Unemployed',
        grade = xPlayer.jobInfo?.rank or 0,
        grade_name = xPlayer.jobInfo?.rankName or 'unemployed',
        grade_label = xPlayer.jobInfo?.rankName or 'Unemployed'
    }
end

--@param playerId: number|string [existing player id or unique identifier]
--@param separate: boolean [if true, returns firstname and lastname separately]
--@return name: string [example 'John Doe'] or firstname, lastname: string
Bridge.Framework.getPlayerName = function(playerId, separate)
    local xPlayer = type(playerId) == 'number' and exports["ND_Core"]:getPlayer(playerId) or Bridge.Framework.getPlayerByUniqueId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return nil
    end

    if separate then
        return xPlayer.firstname, xPlayer.lastname
    end

    return ('%s %s'):format(xPlayer.firstname, xPlayer.lastname)
end

--@param playerId: number|string [existing player id or unique identifier]
--@return { money: number, bank: number, black_money: number }
-- If playerId is a number, it fetches by ID; if it's a string, it fetches by identifier
Bridge.Framework.getMoney = function(playerId)
    local xPlayer = type(playerId) == 'number' and exports["ND_Core"]:getPlayer(playerId) or Bridge.Framework.getPlayerByUniqueId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return nil
    end

    return {
        money = xPlayer.cash or 0,
        bank = xPlayer.bank or 0,
        black_money = 0
    }
end

--@param playerId: number|string [existing player id or unique identifier]
--@param account: string [account type, e.g., 'money', 'bank', 'black_money']
--@param amount: number [amount to add]
--@return boolean [true if money was added successfully, false otherwise]
Bridge.Framework.removeMoney = function(playerId, account, amount)
    local xPlayer = type(playerId) == 'number' and exports["ND_Core"]:getPlayer(playerId) or Bridge.Framework.getPlayerByUniqueId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    local accounts = {
        ['money'] = 'cash',
        ['bank'] = 'bank',
    }

    xPlayer.deductMoney(accounts[account], amount, "")
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param account: string [account type, e.g., 'money', 'bank', 'black_money']
--@param amount: number [amount to add]
--@return boolean [true if money was added successfully, false otherwise]
Bridge.Framework.addMoney = function(playerId, account, amount)
    local xPlayer = type(playerId) == 'number' and exports["ND_Core"]:getPlayer(playerId) or Bridge.Framework.getPlayerByUniqueId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    local accounts = {
        ['money'] = 'cash',
        ['bank'] = 'bank',
    }
    xPlayer.addMoney(accounts[account], amount, "")
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param license: string [license type, e.g., 'driver', 'weapon']
--@return boolean [true if player has the license, false otherwise]
Bridge.Framework.checkPlayerLicense = function(playerId, license)
    local xPlayer = type(playerId) == 'number' and exports["ND_Core"]:getPlayer(playerId) or Bridge.Framework.getPlayerByUniqueId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    local licenses = xPlayer.getMetadata("licenses")
    if not licenses or type(licenses) ~= 'table' then
        lib.print.error(('Player %s does not have any licenses or metadata is not a table.'):format(playerId))
        return false
    end


    for i=1, #licenses do
        if licenses[i].type == license then
            return true
        end
    end

    return false
end

--@param playerId: number|string [existing player id or unique identifier]
--@param license: string [license type, e.g., 'driver', 'weapon']
--@return boolean [true if license has been added, false if not]
Bridge.Framework.addPlayerLicense = function(playerId, license)
    local xPlayer = type(playerId) == 'number' and exports["ND_Core"]:getPlayer(playerId) or Bridge.Framework.getPlayerByUniqueId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    player.createLicense(license, os.time() + 99999999)
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param requiredGroups: table [list of required groups]
Bridge.Framework.checkPermissions = function(playerId, requiredGroups)
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
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