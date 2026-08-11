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
    if type(playerId) == 'table' then
        playerId = playerId.source or (playerId.PlayerData and playerId.PlayerData.source)
    end
    playerId = tonumber(playerId) or tonumber(source)
    if not playerId or playerId <= 0 then return end
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

    if isCitizenId then
        local citizenId = xPlayer[Config.FrameworkUniqueId['esx']]
        if not citizenId then
            local row = MySQL.single.await('SELECT '..Config.FrameworkUniqueId['esx']..' FROM users WHERE identifier = ?', {xPlayer.identifier})
            if row and row[Config.FrameworkUniqueId['esx']] then
                return row[Config.FrameworkUniqueId['esx']]
            end
        else
            return citizenId
        end
    end

    return xPlayer.identifier
end

--@param plate: string [vehicle plate]
--@return vehicleData: table [vehicle data from database]
Bridge.Framework.getVehicleByPlate = function(plate)
    local result = MySQL.single.await('SELECT * FROM owned_vehicles WHERE plate = ?', {plate})
    return result
end

--@param plate: string [vehicle plate]
--@return { owner: string, props: string, plate: string, model: string|number }|nil
-- Normalized owned-vehicle data, framework agnostic. Returns nil when the plate is not owned.
-- `props` is the raw vehicle-properties JSON string as stored by the framework.
Bridge.Framework.getOwnedVehicle = function(plate)
    if not plate then return nil end

    local row = MySQL.single.await('SELECT owner, vehicle, plate FROM owned_vehicles WHERE plate = ?', {plate})
    if not row then return nil end

    return {
        owner = row.owner,
        props = row.vehicle,
        plate = row.plate,
        model = nil
    }
end

--@param plate: string [vehicle plate]
--@param impounded: boolean [true to mark as impounded, false to release back to the owner]
--@return boolean [true if a row was updated]
-- ESX owned_vehicles has no dedicated impound column, so we toggle `stored`
-- (0 = out of garage / impounded, 1 = back in garage / released).
Bridge.Framework.setVehicleImpounded = function(plate, impounded)
    if not plate then return false end

    local affected = MySQL.update.await('UPDATE owned_vehicles SET stored = ? WHERE plate = ?', {impounded and 0 or 1, plate})
    return (affected or 0) > 0
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

local identityCache = {}
local function getUsersRow(identifier)
    local cached = identityCache[identifier]
    if not cached then
        local row = MySQL.single.await('SELECT firstname, lastname, dateofbirth, sex FROM users WHERE identifier = ?', { identifier })
        cached = row or {}
        identityCache[identifier] = cached
    end
    return cached
end

local function resolveIdentity(xPlayer)
    local firstName = xPlayer.get and (xPlayer.get('firstName') or xPlayer.get('firstname'))
    local lastName  = xPlayer.get and (xPlayer.get('lastName') or xPlayer.get('lastname'))

    local vars = xPlayer.variables
    if vars then
        firstName = firstName or vars.firstName or vars.firstname
        lastName  = lastName or vars.lastName or vars.lastname
    end

    if firstName and lastName then return firstName, lastName end

    local row = getUsersRow(xPlayer.identifier)
    return firstName or row.firstname, lastName or row.lastname
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

    local firstName, lastName = resolveIdentity(xPlayer)
    if not firstName and not lastName then
        -- Last resort: account name, so callers never receive/format nils
        firstName = (xPlayer.getName and xPlayer.getName()) or GetPlayerName(xPlayer.source) or 'Unknown'
        lastName = ''
    end
    firstName = firstName or ''
    lastName = lastName or ''

    if separate then
        return firstName, lastName
    end

    return (('%s %s'):format(firstName, lastName):gsub('%s+$', ''))
end

--@param playerId: number|string [existing player id or unique identifier]
--@return dob: string|nil [the player's date of birth]
Bridge.Framework.getPlayerDob = function(playerId)
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then return nil end

    local dob = xPlayer.get and xPlayer.get('dateofbirth')
    if dob == nil and xPlayer.variables then
        dob = xPlayer.variables.dateofbirth
    end
    if dob == nil then
        dob = getUsersRow(xPlayer.identifier).dateofbirth
    end
    return dob
end

--@param playerId: number|string [existing player id or unique identifier]
--@return gender: 'male'|'female'|nil [the player's gender from character data]
Bridge.Framework.getPlayerGender = function(playerId)
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then return nil end

    local sex = xPlayer.get and xPlayer.get('sex')
    if sex == nil and xPlayer.variables then
        sex = xPlayer.variables.sex
    end
    if sex == nil then
        sex = getUsersRow(xPlayer.identifier).sex
    end
    if sex == nil then return nil end

    sex = tostring(sex):lower()
    return (sex == 'f' or sex == 'female' or sex == '1') and 'female' or 'male'
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

lib.callback.register('p_bridge/server/framework/getMoney', Bridge.Framework.getMoney)

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

    -- ESX has no 'cash' account; callers use the shared 'cash'/'bank' naming
    xPlayer.removeAccountMoney(account == 'cash' and 'money' or account, amount)
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

    -- ESX has no 'cash' account; callers use the shared 'cash'/'bank' naming
    xPlayer.addAccountMoney(account == 'cash' and 'money' or account, amount)
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
--@param license: string [license type, e.g., 'driver', 'weapon']
--@return boolean [true if license has been removed, false if not]
Bridge.Framework.removePlayerLicense = function(playerId, license)
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    MySQL.query.await('DELETE FROM user_licenses WHERE owner = ? AND type = ?', {xPlayer.identifier, license})
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param key: string [metadata key, e.g., 'callsign']
--@param value: any [metadata value]
--@return boolean [true if metadata has been set, false if not]
Bridge.Framework.setPlayerMetadata = function(playerId, key, value)
    local xPlayer = type(playerId) == 'number' and ESX.GetPlayerFromId(playerId) or ESX.GetPlayerFromIdentifier(playerId)
    if not xPlayer then
        lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    if not xPlayer.setMeta then
        lib.print.error(('xPlayer.setMeta is not available on this ESX version\nInvoker: %s'):format(GetInvokingResource() or GetCurrentResourceName()))
        return false
    end

    xPlayer.setMeta(key, value)
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