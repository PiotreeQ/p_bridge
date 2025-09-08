if (Config.Framework == 'auto' and not checkResource('qb-core') and not checkResource('qbx_core')) or (Config.Framework ~= 'auto' and Config.Framework ~= 'qb') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Framework] Loaded: QB')
end

QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(playerId)
    TriggerEvent('p_bridge/server/playerLoaded', playerId) -- DONT TOUCH IT!
end)

Bridge.Framework = {}

--@param playerId: number [existing player id]
--@return xPlayer: table [player object]
Bridge.Framework.getPlayerById = function(playerId)
    if not playerId then
        lib.print.error('Player ID is required to fetch player data.')
        return nil
    end

    local xPlayer = QBCore.Functions.GetPlayer(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s'):format(playerId))
        return nil
    end

    xPlayer.source = xPlayer.PlayerData.source -- Ensure source is available
    xPlayer.identifier = xPlayer.PlayerData.citizenid -- Ensure identifier is available
    return xPlayer
end

--@param uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
--@return playerId: number [player ID]
Bridge.Framework.getPlayerId = function(uniqueId)
    if not uniqueId then
        lib.print.error('Unique ID is required to fetch player ID.')
        return nil
    end

    local xPlayer = QBCore.Functions.GetPlayerByCitizenId(uniqueId)
    if not xPlayer then
        return nil
    end

    return xPlayer.PlayerData.source
end

--@param uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
--@return xPlayer: table [player object]
Bridge.Framework.getPlayerByUniqueId = function(uniqueId)
    if not uniqueId then
        lib.print.error('Unique ID is required to fetch player data.')
        return nil
    end

    local xPlayer = QBCore.Functions.GetPlayerByCitizenId(uniqueId)
    if not xPlayer then
        lib.print.error(('No player found with Unique ID: %s'):format(uniqueId))
        return nil
    end

    xPlayer.source = xPlayer.PlayerData.source -- Ensure source is available
    xPlayer.identifier = xPlayer.PlayerData.citizenid -- Ensure identifier is available
    return xPlayer
end

--@param playerId: number|string [existing player id or unique identifier]
--@return uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
Bridge.Framework.getUniqueId = function(playerId)
    if not playerId then
        lib.print.error('Player ID is required to fetch unique ID.')
        return nil
    end

    local xPlayer = type(playerId) == 'number' and QBCore.Functions.GetPlayer(playerId) or QBCore.Functions.GetPlayerByCitizenId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return nil
    end

    return xPlayer.PlayerData.citizenid
end

--@param playerId: number|string [existing player id or unique identifier]
--@return { name: string, label: string, grade: number, grade_name: string, grade_label: string }
-- If playerId is a number, it fetches by ID; if it's a string, it fetches by identifier
Bridge.Framework.getPlayerJob = function(playerId)
    local xPlayer = type(playerId) == 'number' and QBCore.Functions.GetPlayer(playerId) or QBCore.Functions.GetPlayerByCitizenId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s'):format(playerId))
    end

    return {
        name = xPlayer.PlayerData.job?.name or 'unemployed',
        label = xPlayer.PlayerData.job?.label or 'Unemployed',
        grade = xPlayer.PlayerData.job?.grade?.level or 0,
        grade_name = xPlayer.PlayerData.job?.grade?.name or 'unemployed',
        grade_label = xPlayer.PlayerData.job?.grade?.name or 'Unemployed'
    }
end

--@param playerId: number|string [existing player id or unique identifier]
--@param separate: boolean [if true, returns firstname and lastname separately]
--@return name: string [example 'John Doe'] or firstname, lastname: string
Bridge.Framework.getPlayerName = function(playerId, separate)
    local xPlayer = type(playerId) == 'number' and QBCore.Functions.GetPlayer(playerId) or QBCore.Functions.GetPlayerByCitizenId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return nil
    end

    if separate then
        return xPlayer.PlayerData.charinfo.firstname, xPlayer.PlayerData.charinfo.lastname
    end

    return ('%s %s'):format(xPlayer.PlayerData.charinfo.firstname, xPlayer.PlayerData.charinfo.lastname)
end

--@param playerId: number|string [existing player id or unique identifier]
--@return { money: number, bank: number, black_money: number }
-- If playerId is a number, it fetches by ID; if it's a string, it fetches by identifier
Bridge.Framework.getMoney = function(playerId)
    local xPlayer = type(playerId) == 'number' and QBCore.Functions.GetPlayer(playerId) or QBCore.Functions.GetPlayerByCitizenId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return nil
    end

    return {
        money = xPlayer.PlayerData.money['cash'] or 0,
        bank = xPlayer.PlayerData.money['bank'] or 0,
        black_money = Bridge.Inventory.getItemCount('markedbills') or Bridge.Inventory.getItemCount('black_money')
    }
end

--@param playerId: number|string [existing player id or unique identifier]
--@param account: string [account type, e.g., 'money', 'bank', 'black_money']
--@param amount: number [amount to add]
--@return boolean [true if money was added successfully, false otherwise]
Bridge.Framework.removeMoney = function(playerId, account, amount)
    local xPlayer = type(playerId) == 'number' and QBCore.Functions.GetPlayer(playerId) or QBCore.Functions.GetPlayerByCitizenId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    local accounts = {
        ['money'] = 'cash',
        ['bank'] = 'bank',
        ['black_money'] = 'crypto'
    }
    xPlayer.Functions.RemoveMoney(accounts[account], amount)
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param account: string [account type, e.g., 'money', 'bank', 'black_money']
--@param amount: number [amount to add]
--@return boolean [true if money was added successfully, false otherwise]
Bridge.Framework.addMoney = function(playerId, account, amount)
    local xPlayer = type(playerId) == 'number' and QBCore.Functions.GetPlayer(playerId) or QBCore.Functions.GetPlayerByCitizenId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    local accounts = {
        ['money'] = 'cash',
        ['bank'] = 'bank',
        ['black_money'] = 'crypto'
    }
    xPlayer.Functions.AddMoney(accounts[account], amount)
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param license: string [license type, e.g., 'driver', 'weapon']
--@return boolean [true if player has the license, false otherwise]
Bridge.Framework.checkPlayerLicense = function(playerId, license)
    local xPlayer = type(playerId) == 'number' and QBCore.Functions.GetPlayer(playerId) or QBCore.Functions.GetPlayerByCitizenId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    return xPlayer.PlayerData.metadata.licences[license] or false
end

--@param playerId: number|string [existing player id or unique identifier]
--@param license: string [license type, e.g., 'driver', 'weapon']
--@return boolean [true if license has been added, false if not]
Bridge.Framework.addPlayerLicense = function(playerId, license)
    local xPlayer = type(playerId) == 'number' and QBCore.Functions.GetPlayer(playerId) or QBCore.Functions.GetPlayerByCitizenId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    xPlayer.PlayerData.metadata.licences[license] = true
    xPlayer.Functions.SetMetaData('licences', xPlayer.PlayerData.metadata.licences)
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param requiredGroups: table [list of required groups]
Bridge.Framework.checkPermissions = function(playerId, requiredGroups)
    local xPlayer = type(playerId) == 'number' and QBCore.Functions.GetPlayer(playerId) or QBCore.Functions.GetPlayerByCitizenId(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    for group, _ in pairs(requiredGroups) do
        if QBCore.Functions.HasPermission(playerId, group) then
            return true
        end
    end

    return false
end

lib.callback.register('p_bridge/server/framework/checkPermissions', Bridge.Framework.checkPermissions)