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

Bridge.Framework.SetOfflineJob = function(uniqueId, jobName, jobGrade)
    local row = MySQL.single.await('SELECT job FROM players WHERE citizenid = ?', { uniqueId })
    if not row then
        return false
    end

    row.job = json.decode(row.job)
    local newJob = {
        name = jobName,
        label = QBCore.Shared.Jobs[jobName]?.label or 'Unknown',
        onduty = row.job.onduty or false,
        type = QBCore.Shared.Jobs[jobName]?.type or 'none',
        grade = {
            name = QBCore.Shared.Jobs[jobName]?.grades[tostring(jobGrade)]?.name or 'No Grades',
            level = jobGrade,
            payment = QBCore.Shared.Jobs[jobName]?.grades[tostring(jobGrade)]?.payment or 0,
            isboss = QBCore.Shared.Jobs[jobName]?.grades[tostring(jobGrade)]?.isboss or false
        }
    }
    local result = MySQL.update.await('UPDATE players SET job = ? WHERE citizenid = ?', {
        newJob,
        uniqueId
    })
    return result > 0
end

Bridge.Framework.SetJob = function(playerId, jobName, jobGrade)
    local xPlayer = QBCore.Functions.GetPlayer(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    xPlayer.Functions.SetJob(jobName, jobGrade)
    return true
end

Bridge.Framework.CheckJobDuty = function(playerId)
    local xPlayer = QBCore.Functions.GetPlayer(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    if GetResourceState('piotreq_jobcore') == 'started' then
        return exports['piotreq_jobcore']:isPlayerOnDuty(xPlayer.PlayerData.citizenid)
    end

    return xPlayer.PlayerData.job.onduty or false
end

Bridge.Framework.SetJobDuty = function(playerId, onDuty)
    local xPlayer = QBCore.Functions.GetPlayer(playerId)
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

    xPlayer.Functions.SetJobDuty(onDuty)
    return true
end

Bridge.Framework.frameworkUniqueId = function()
    return Config.FrameworkUniqueId['qb']
end

Bridge.Framework.getJobLabels = function()
    local jobLabels = {}
    local jobs = QBCore.Shared.Jobs
    for k, v in pairs(jobs) do
        if not jobLabels[k] then
            jobLabels[k] = v.label
        end
    end
    return jobLabels
end

Bridge.Framework.getJobs = function()
    local jobsData = {}
    local jobs = QBCore.Shared.Jobs
    for k, v in pairs(jobs) do
        if not jobsData[k] then
            jobsData[k] = {}
        end
        for grade, gradeData in pairs(v.grades) do
            jobsData[k][tonumber(grade)] = {
                name = gradeData.isboss and 'boss' or gradeData.name,
                label = gradeData.name,
                grade = tonumber(grade),
            }
        end
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

    local xPlayer = QBCore.Functions.GetPlayer(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s'):format(playerId))
        end
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
        if Config.Debug then
            lib.print.error('Unique ID is required to fetch player ID.')
        end
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
        if Config.Debug then
            lib.print.error('Unique ID is required to fetch player data.')
        end
        return nil
    end

    local xPlayer = QBCore.Functions.GetPlayerByCitizenId(uniqueId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with Unique ID: %s'):format(uniqueId))
        end
        return nil
    end

    xPlayer.source = xPlayer.PlayerData.source -- Ensure source is available
    xPlayer.identifier = xPlayer.PlayerData.citizenid -- Ensure identifier is available
    return xPlayer
end

--@param citizenId: string [example '123456789']
--@return playerData: table [offline player data]
Bridge.Framework.getOfflinePlayerByCitizenId = function(citizenId)
    local row = MySQL.single.await('SELECT * FROM players WHERE '..Config.FrameworkUniqueId['qb']..' = ?', {citizenId})
    if not row then
        return nil
    end

    local jobData = json.decode(row.job)
    local charInfo = json.decode(row.charinfo)
    row.job = jobData.name
    row.job_grade = jobData.grade.level
    row.firstname = charInfo.firstname
    row.lastname = charInfo.lastname
    return row
end

--@param identifier: string [example 'steam:110000112345678']
--@return playerData: table [offline player data]
Bridge.Framework.getOfflinePlayerByUniqueId = function(identifier)
    local row = MySQL.single.await('SELECT * FROM players WHERE citizenid = ?', {identifier})
    if not row then
        return nil
    end

    local jobData = json.decode(row.job)
    local charInfo = json.decode(row.charinfo)
    row.job = jobData.name
    row.job_grade = jobData.grade.level
    row.firstname = charInfo.firstname
    row.lastname = charInfo.lastname
    return row
end

--@param playerId: number|string [existing player id or unique identifier]
--@return uniqueId: string [example 'char1:123456', for esx it will be identifier, for qb/qbox it will be citizenid]
Bridge.Framework.getUniqueId = function(playerId)
    if not playerId then
        if Config.Debug then
            lib.print.error('Player ID is required to fetch unique ID.')
        end
        return nil
    end

    local xPlayer = type(playerId) == 'number' and QBCore.Functions.GetPlayer(playerId) or QBCore.Functions.GetPlayerByCitizenId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return nil
    end

    return xPlayer.PlayerData.citizenid
end

--@param plate: string [vehicle plate]
--@return vehicleData: table [vehicle data from database]
Bridge.Framework.getVehicleByPlate = function(plate)
    local result = MySQL.single.await('SELECT * FROM player_vehicles WHERE plate = ?', {plate})
    return result
end

--@param playerId: number|string [existing player id or unique identifier]
--@return { name: string, label: string, grade: number, grade_name: string, grade_label: string }
-- If playerId is a number, it fetches by ID; if it's a string, it fetches by identifier
Bridge.Framework.getPlayerJob = function(playerId)
    local xPlayer = type(playerId) == 'number' and QBCore.Functions.GetPlayer(playerId) or QBCore.Functions.GetPlayerByCitizenId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s'):format(playerId))
        end
        return nil
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
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
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
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
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
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
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
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
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

--@param itemName: string [name of the item to register]
--@param itemFunction: function [function to execute when the item is used]
Bridge.Framework.registerItem = function(itemName, itemFunction)
    QBCore.Functions.CreateUseableItem(itemName, itemFunction)
end