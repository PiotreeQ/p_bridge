if (Config.Framework == 'auto' and not checkResource('es_extended')) or (Config.Framework ~= 'auto' and Config.Framework ~= 'esx') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Framework] Loaded: ESX')
end

ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('esx:playerLoaded', function(playerId)
    TriggerEvent('p_bridge/server/playerLoaded', playerId) -- DONT TOUCH IT!
end)

Bridge.Framework = {}

Bridge.Framework.SetOfflineJob = function(uniqueId, jobName, jobGrade)
    local result = MySQL.update.await('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', {
        jobName,
        jobGrade,
        uniqueId
    })
    return result > 0
end

Bridge.Framework.SetJob = function(playerId, jobName, jobGrade)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    xPlayer.setJob(jobName, jobGrade)
    return true
end

Bridge.Framework.CheckJobDuty = function(playerId)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    if GetResourceState('piotreq_jobcore') == 'started' then
        return exports['piotreq_jobcore']:isPlayerOnDuty(xPlayer.identifier)
    end

    return xPlayer.job?.onDuty or false
end

Bridge.Framework.SetJobDuty = function(playerId, onDuty)
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    if GetResourceState('piotreq_jobcore') == 'started' then
        exports['piotreq_jobcore']:SwitchDuty(playerId, {duty = onDuty and 1 or 0})
        return true
    end

    xPlayer.setJob(xPlayer.job.name, xPlayer.job.grade, onDuty) -- newest esx version supports onDuty param
    return true
end

Bridge.Framework.frameworkUniqueId = function()
    return Config.FrameworkUniqueId['esx']
end

Bridge.Framework.getJobLabels = function()
    local jobLabels = {}
    local jobs = MySQL.query.await('SELECT * FROM jobs')
    for k, v in pairs(jobs) do
        if not jobLabels[v.name] then
            jobLabels[v.name] = v.label
        end
    end
    return jobLabels
end

Bridge.Framework.getJobs = function()
    local jobsData = {}
    local job_grades = MySQL.query.await('SELECT * FROM job_grades')
    for k, v in pairs(job_grades) do
        if not jobsData[v.job_name] then
            jobsData[v.job_name] = {}
        end
        jobsData[v.job_name][v.grade] = { name = v.name, label = v.label, grade = v.grade, job_name = v.job_name }
    end
    return jobsData
end

--@param playerId: number [existing player id]
--@return xPlayer: table [player object]
Bridge.Framework.getPlayerById = function(playerId)
    if not playerId then
        if Config.Debug then
            lib.print.error('Player ID is required to fetch player data.')
        end
        return nil
    end

    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return nil
    end

    return xPlayer
end

--@param uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
--@return playerId: number [player ID]
Bridge.Framework.getPlayerId = function(uniqueId)
    if not uniqueId then
        if Config.Debug then
            lib.print.error('Unique ID is required to fetch player ID.')
        end
        return nil
    end

    local xPlayer = ESX.GetPlayerFromIdentifier(uniqueId)
    if not xPlayer then
        return nil
    end

    return xPlayer.source
end

--@param uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
--@return xPlayer: table [player object]
Bridge.Framework.getPlayerByUniqueId = function(uniqueId)
    if not uniqueId then
        if Config.Debug then
            lib.print.error('Unique ID is required to fetch player data.')
        end
        return nil
    end

    local xPlayer = ESX.GetPlayerFromIdentifier(uniqueId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with Unique ID: %s\nInvoker: %s'):format(uniqueId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return nil
    end

    return xPlayer
end

--@param citizenId: string [example '123456789']
--@return playerData: table [offline player data]
Bridge.Framework.getOfflinePlayerByCitizenId = function(citizenId)
    return MySQL.single.await('SELECT * FROM users WHERE '..Config.FrameworkUniqueId['esx']..' = ?', {citizenId})
end

--@param identifier: string [example 'steam:110000112345678']
--@return playerData: table [offline player data]
Bridge.Framework.getOfflinePlayerByUniqueId = function(identifier)
    return MySQL.single.await('SELECT * FROM users WHERE identifier = ?', {identifier})
end

--@param playerId: number|string [existing player id or unique identifier]
--@return uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
Bridge.Framework.getUniqueId = function(playerId, isCitizenId)
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return nil
    end

    return isCitizenId and xPlayer[Config.FrameworkUniqueId['esx']] or xPlayer.identifier
end

--@param plate: string [vehicle plate]
--@return vehicleData: table [vehicle data from database]
Bridge.Framework.getVehicleByPlate = function(plate)
    local result = MySQL.single.await('SELECT * FROM owned_vehicles WHERE plate = ?', {plate})
    return result
end

--@param playerId: number|string [existing player id or unique identifier]
--@return { name: string, label: string, grade: number, grade_name: string, grade_label: string }
-- If playerId is a number, it fetches by ID; if it's a string, it fetches by identifier
Bridge.Framework.getPlayerJob = function(playerId)
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s'):format(playerId))
        end
        return nil
    end

    return {
        name = xPlayer.job?.name or 'unemployed',
        label = xPlayer.job?.label or 'Unemployed',
        grade = xPlayer.job?.grade or 0,
        grade_name = xPlayer.job?.grade_name or 'unemployed',
        grade_label = xPlayer.job?.grade_label or 'Unemployed'
    }
end

--@param playerId: number|string [existing player id or unique identifier]
--@param separate: boolean [if true, returns firstname and lastname separately]
--@return name: string [example 'John Doe'] or firstname, lastname: string
Bridge.Framework.getPlayerName = function(playerId, separate)
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
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
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return nil
    end

    return {
        money = xPlayer.getAccount('money')?.money or 0,
        bank = xPlayer.getAccount('bank')?.money or 0,
        black_money = xPlayer.getAccount('black_money')?.money or 0
    }
end

--@param playerId: number|string [existing player id or unique identifier]
--@param account: string [account type, e.g., 'money', 'bank', 'black_money']
--@param amount: number [amount to add]
--@return boolean [true if money was added successfully, false otherwise]
Bridge.Framework.removeMoney = function(playerId, account, amount)
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    xPlayer.removeAccountMoney(account, amount)
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param account: string [account type, e.g., 'money', 'bank', 'black_money']
--@param amount: number [amount to add]
--@return boolean [true if money was added successfully, false otherwise]
Bridge.Framework.addMoney = function(playerId, account, amount)
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    xPlayer.addAccountMoney(account, amount)
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param license: string [license type, e.g., 'driver', 'weapon']
--@return boolean [true if player has the license, false otherwise]
Bridge.Framework.checkPlayerLicense = function(playerId, license)
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    local row = MySQL.single.await('SELECT * FROM user_licenses WHERE owner = ? and type = ?', {xPlayer.identifier, license})
    return row and true or false
end

--@param playerId: number|string [existing player id or unique identifier]
--@param license: string [license type, e.g., 'driver', 'weapon']
--@return boolean [true if license has been added, false if not]
Bridge.Framework.addPlayerLicense = function(playerId, license)
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    MySQL.insert.await('INSERT INTO user_licenses (owner, type) VALUES (?, ?)', {xPlayer.identifier, license})
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param requiredGroups: table [list of required groups]
Bridge.Framework.checkPermissions = function(playerId, requiredGroups)
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    if requiredGroups[xPlayer.getGroup()] then
        return true
    end

    return false
end

lib.callback.register('p_bridge/server/framework/checkPermissions', Bridge.Framework.checkPermissions)

--@param itemName: string [name of the item to register]
--@param itemFunction: function [function to execute when the item is used]
Bridge.Framework.registerItem = function(itemName, itemFunction)
    ESX.RegisterUsableItem(itemName, itemFunction)
end