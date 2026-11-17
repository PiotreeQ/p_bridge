if (Config.Framework == 'auto' and not checkResource('qbx_core')) or (Config.Framework ~= 'auto' and Config.Framework ~= 'qbox') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Framework] Loaded: QBOX')
end

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(player)
    local playerId = player
    if type(playerId) == 'table' then
        playerId = (playerId.PlayerData and playerId.PlayerData.source) or playerId.source
    end
    playerId = tonumber(playerId) or tonumber(source)
    if not playerId or playerId <= 0 then return end
    TriggerEvent('p_bridge/server/playerLoaded', playerId) -- DONT TOUCH IT!
end)

Bridge.Framework = {}

Bridge.Framework.SetOfflineJob = function(uniqueId, jobName, jobGrade)
    local row = MySQL.single.await('SELECT job FROM players WHERE citizenid = ?', { uniqueId })
    if not row then
        return false
    end

    jobGrade = tonumber(jobGrade) or 0
    local currentJob = json.decode(row.job or '{}') or {}

    -- qbx_core keeps jobs in player_groups and rebuilds players.job from it, so a raw UPDATE on players.job
    -- doesn't stick; its exports accept offline citizenids and keep both in sync
    local ok, err = pcall(function()
        if jobName == 'unemployed' then
            if currentJob.name and currentJob.name ~= 'unemployed' then
                exports['qbx_core']:RemovePlayerFromJob(uniqueId, currentJob.name)
            end
            return
        end

        exports['qbx_core']:AddPlayerToJob(uniqueId, jobName, jobGrade)
        exports['qbx_core']:SetPlayerPrimaryJob(uniqueId, jobName)
    end)

    if not ok then
        lib.print.error(('SetOfflineJob failed for %s (%s %s): %s'):format(uniqueId, jobName, jobGrade, err))
        return false
    end

    return true
end

Bridge.Framework.SetJob = function(playerId, jobName, jobGrade)
    local xPlayer = exports['qbx_core']:GetPlayer(playerId)
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
    local xPlayer = exports['qbx_core']:GetPlayer(playerId)
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
    local xPlayer = exports['qbx_core']:GetPlayer(playerId)
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
    return Config.FrameworkUniqueId['qbox']
end

Bridge.Framework.getJobLabels = function()
    local jobLabels = {}
    local jobs = exports['qbx_core']:GetJobs()
    for k, v in pairs(jobs) do
        if not jobLabels[k] then
            jobLabels[k] = v.label
        end
    end
    return jobLabels
end

Bridge.Framework.getJobs = function()
    local jobsData = {}
    local jobs = exports['qbx_core']:GetJobs()
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

--@param playerId: number [player id]
--@return boolean [has a loaded character; no error log when not, e.g. still on the loading screen]
Bridge.Framework.isPlayerLoaded = function(playerId)
    return playerId ~= nil and exports['qbx_core']:GetPlayer(playerId) ~= nil
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

    local xPlayer = exports['qbx_core']:GetPlayer(playerId)
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

    local xPlayer = exports['qbx_core']:GetPlayerByCitizenId(uniqueId)
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

    local xPlayer = exports['qbx_core']:GetPlayerByCitizenId(uniqueId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with unique ID: %s'):format(uniqueId))
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
    local row = MySQL.single.await('SELECT * FROM players WHERE '..Config.FrameworkUniqueId['qbox']..' = ?', {citizenId})
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

    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
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

--@param plate: string [vehicle plate]
--@return { owner: string, props: string, plate: string, model: string|number }|nil
-- Normalized owned-vehicle data, framework agnostic. Returns nil when the plate is not owned.
-- `props` is the raw vehicle-properties JSON string (`mods`) as stored by qbx_core.
Bridge.Framework.getOwnedVehicle = function(plate)
    if not plate then return nil end

    local row = MySQL.single.await('SELECT citizenid, mods, vehicle, plate FROM player_vehicles WHERE plate = ?', {plate})
    if not row then return nil end

    return {
        owner = row.citizenid,
        props = row.mods,
        plate = row.plate,
        model = row.vehicle
    }
end

--@param plate: string [vehicle plate]
--@param impounded: boolean [true to mark as impounded, false to release back to the owner]
--@return boolean [true if a row was updated]
-- qbx_core player_vehicles `state`: 0 = out, 1 = garaged, 2 = impounded.
Bridge.Framework.setVehicleImpounded = function(plate, impounded)
    if not plate then return false end

    local affected = MySQL.update.await('UPDATE player_vehicles SET state = ? WHERE plate = ?', {impounded and 2 or 1, plate})
    return (affected or 0) > 0
end

--@param playerId: number|string [existing player id or unique identifier]
--@return { name: string, label: string, grade: number, grade_name: string, grade_label: string }
-- If playerId is a number, it fetches by ID; if it's a string, it fetches by identifier
Bridge.Framework.getPlayerJob = function(playerId)
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
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
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
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
--@return dob: string|nil [the player's date of birth]
Bridge.Framework.getPlayerDob = function(playerId)
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
    if not xPlayer then return nil end
    return xPlayer.PlayerData.charinfo.birthdate
end

--@param playerId: number|string [existing player id or unique identifier]
--@return gender: 'male'|'female'|nil [the player's gender from character data]
Bridge.Framework.getPlayerGender = function(playerId)
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
    if not xPlayer then return nil end

    local gender = xPlayer.PlayerData.charinfo and xPlayer.PlayerData.charinfo.gender
    if gender == nil then return nil end

    gender = tostring(gender):lower()
    return (gender == '1' or gender == 'f' or gender == 'female') and 'female' or 'male'
end

--@param playerId: number|string [existing player id or unique identifier]
--@return { money: number, bank: number, black_money: number }
-- If playerId is a number, it fetches by ID; if it's a string, it fetches by identifier
Bridge.Framework.getMoney = function(playerId)
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return nil
    end

    return {
        money = xPlayer.PlayerData.money['cash'] or 0,
        bank = xPlayer.PlayerData.money['bank'] or 0,
        black_money = GetResourceState('ox_inventory') == 'started' and exports['ox_inventory']:Search(playerId, 'count', 'black_money') or xPlayer.PlayerData.money['crypto'] or 0
    }
end

lib.callback.register('p_bridge/server/framework/getMoney', Bridge.Framework.getMoney)

--@param playerId: number|string [existing player id or unique identifier]
--@param account: string [account type, e.g., 'money', 'bank', 'black_money']
--@param amount: number [amount to add]
--@return boolean [true if money was added successfully, false otherwise]
Bridge.Framework.removeMoney = function(playerId, account, amount)
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    if account == 'black_money' and GetResourceState('ox_inventory') == 'started' then
        exports['ox_inventory']:RemoveItem(playerId, 'black_money', amount)
        return true
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
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    if account == 'black_money' and GetResourceState('ox_inventory') == 'started' then
        exports['ox_inventory']:AddItem(playerId, 'black_money', amount)
        return true
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
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    return xPlayer.PlayerData.metadata.licences[license] or false
end

--@param playerId: number|string [existing player id or unique identifier]
--@param license: string [license type, e.g., 'driver', 'weapon']
--@return boolean [true if license has been added, false if not]
Bridge.Framework.addPlayerLicense = function(playerId, license)
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    xPlayer.PlayerData.metadata.licences[license] = true
    xPlayer.Functions.SetMetaData('licences', xPlayer.PlayerData.metadata.licences)
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param license: string [license type, e.g., 'driver', 'weapon']
--@return boolean [true if license has been removed, false if not]
Bridge.Framework.removePlayerLicense = function(playerId, license)
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    xPlayer.PlayerData.metadata.licences[license] = false
    xPlayer.Functions.SetMetaData('licences', xPlayer.PlayerData.metadata.licences)
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param key: string [metadata key, e.g., 'callsign']
--@param value: any [metadata value]
--@return boolean [true if metadata has been set, false if not]
Bridge.Framework.setPlayerMetadata = function(playerId, key, value)
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    xPlayer.Functions.SetMetaData(key, value)
    return true
end

--@param playerId: number|string [existing player id or unique identifier]
--@param requiredGroups: table [list of required groups]
Bridge.Framework.checkPermissions = function(playerId, requiredGroups)
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
    if not xPlayer then
        if Config.Debug then
            lib.print.error(('No player found with ID: %s\nInvoker: %s'):format(playerId, GetInvokingResource() or GetCurrentResourceName()))
        end
        return false
    end

    for group, _ in pairs(requiredGroups) do
        if exports['qbx_core']:HasPermission(playerId, group) then
            return true
        end
    end

    return false
end

lib.callback.register('p_bridge/server/framework/checkPermissions', Bridge.Framework.checkPermissions)

--@param itemName: string [name of the item to register]
--@param itemFunction: function [function to execute when the item is used]
Bridge.Framework.registerItem = function(itemName, itemFunction)
    exports['qbx_core']:CreateUseableItem(itemName, itemFunction)
end

--@param playerId: number|string [existing player id or unique identifier]
--@return { fingerprint: string|nil, bloodType: string|nil }|nil
-- Forensic identifiers QBX generates at character creation. Returns nil when the
-- player can't be resolved (callers fall back to their own generated values).
Bridge.Framework.getForensics = function(playerId)
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
    if not xPlayer then return nil end
    local meta = xPlayer.PlayerData and xPlayer.PlayerData.metadata
    if not meta then return nil end
    return {
        fingerprint = meta.fingerprint,
        bloodType = meta.bloodtype,
    }
end

--@param playerId: number|string [existing player id or unique identifier]
--@return licenses: { name: string, label: string }[] [every license the player holds]
Bridge.Framework.getPlayerLicenses = function(playerId)
    local xPlayer = type(playerId) == 'number' and exports['qbx_core']:GetPlayer(playerId) or exports['qbx_core']:GetPlayerByCitizenId(playerId)
    if not xPlayer then return {} end

    local licenses = {}
    for name, owned in pairs(xPlayer.PlayerData.metadata.licences or {}) do
        if owned then
            licenses[#licenses + 1] = { name = name, label = name:gsub('^%l', string.upper) }
        end
    end
    return licenses
end


-- Characters (multicharacter). QBox keeps characters in `players` by license2 / license; the
-- slot is charinfo.cid, the unique id the citizenid. Set `characters.useExternalCharacters = true`
-- in qbx_core/config/client.lua so its own selection stays off.

local function decode(value)
    if type(value) ~= 'string' then return value or {} end
    local ok, result = pcall(json.decode, value)
    return ok and result or {}
end

local function isoDate(value)
    if type(value) ~= 'string' then return nil end
    local y, m, d = value:match('^(%d%d%d%d)-(%d%d?)-(%d%d?)')
    if y then return ('%04d-%02d-%02d'):format(y, m, d) end
    local a, b, year = value:match('^(%d%d?)[/.-](%d%d?)[/.-](%d%d%d%d)')
    if not a then return nil end
    local day, month = tonumber(a), tonumber(b)
    if month > 12 then day, month = month, day end
    return ('%04d-%02d-%02d'):format(year, month, day)
end

local function licenses(playerId)
    return GetPlayerIdentifierByType(playerId, 'license2'), GetPlayerIdentifierByType(playerId, 'license')
end

local function ownsCharacter(playerId, charId)
    local owner = MySQL.scalar.await('SELECT `license` FROM `players` WHERE `citizenid` = ?', { charId })
    local license2, license = licenses(playerId)
    return owner ~= nil and (owner == license2 or owner == license)
end

--@param playerId: number [player server id]
--@return characters: { id: string, slot: number, firstName: string, lastName: string, dob: string|nil, gender: 'male'|'female', job: { label: string, grade: string }, cash: number, bank: number, stateId: string|nil, playtime: number|nil, lastPlayed: number|nil, disabled: boolean }[]
Bridge.Framework.getCharacters = function(playerId)
    local license2, license = licenses(playerId)
    if not license2 and not license then return {} end
    local rows = MySQL.query.await('SELECT * FROM `players` WHERE `license` = ? OR `license` = ?', { license2 or '', license or '' }) or {}
    local characters = {}
    for _, row in ipairs(rows) do
        local charinfo, money, job = decode(row.charinfo), decode(row.money), decode(row.job)
        characters[#characters + 1] = {
            id = row.citizenid,
            slot = tonumber(charinfo.cid) or tonumber(row.cid) or #characters + 1,
            firstName = charinfo.firstname or '',
            lastName = charinfo.lastname or '',
            dob = isoDate(charinfo.birthdate),
            gender = tonumber(charinfo.gender) == 1 and 'female' or 'male',
            job = {
                label = job.label or job.name or 'Unemployed',
                grade = (job.name ~= 'unemployed' and type(job.grade) == 'table') and (job.grade.name or '') or '',
            },
            cash = money.cash or 0,
            bank = money.bank or 0,
            stateId = row.citizenid,
            lastPlayed = row.last_updated,
            disabled = false,
        }
    end
    table.sort(characters, function(a, b) return a.slot < b.slot end)
    return characters
end

--@param playerId: number [player server id]
--@param charId: string [citizenid]
--@return boolean [true once the character is loaded]
Bridge.Framework.loginCharacter = function(playerId, charId)
    if exports['qbx_core']:GetPlayer(playerId) or not ownsCharacter(playerId, charId) then return false end
    return exports['qbx_core']:Login(playerId, charId) == true
end

--@param playerId: number [player server id]
--@param slot: number [character slot (charinfo.cid)]
--@param data: { firstName: string, lastName: string, dob: string, gender: 'male'|'female', height: number|nil, nationality: string|nil, backstory: string|nil }
--@return charId: string|nil [citizenid of the new, loaded character]
Bridge.Framework.createCharacter = function(playerId, slot, data)
    if exports['qbx_core']:GetPlayer(playerId) then return nil end
    local ok = exports['qbx_core']:Login(playerId, nil, {
        charinfo = {
            firstname = data.firstName,
            lastname = data.lastName,
            birthdate = data.dob,
            gender = data.gender == 'female' and 1 or 0,
            nationality = data.nationality or 'American',
            backstory = data.backstory or 'placeholder backstory',
            cid = tonumber(slot),
        },
    })
    local player = ok and exports['qbx_core']:GetPlayer(playerId)
    return player and player.PlayerData.citizenid or nil
end

--@param playerId: number [player server id]
--@param charId: string [citizenid]
--@return boolean [true if the character was deleted]
Bridge.Framework.deleteCharacter = function(playerId, charId)
    if not ownsCharacter(playerId, charId) then return false end
    exports['qbx_core']:DeleteCharacter(charId)
    return true
end

--@param playerId: number [player server id]
--@return boolean [true once the character is saved and unloaded]
Bridge.Framework.logoutCharacter = function(playerId)
    if exports['qbx_core']:GetPlayer(playerId) then exports['qbx_core']:Logout(playerId) end
    return true
end

--@param playerId: number [player server id]
--@return position: { x: number, y: number, z: number, w: number }|nil [where the loaded character was last saved]
Bridge.Framework.getLastPosition = function(playerId)
    local player = exports['qbx_core']:GetPlayer(playerId)
    local pos = player and player.PlayerData.position
    if not pos or not pos.x then return nil end
    return { x = pos.x, y = pos.y, z = pos.z, w = pos.w or pos.heading or 0.0 }
end

Bridge.Framework.name = 'qbox'
