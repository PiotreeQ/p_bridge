if (Config.Framework == 'auto' and not checkResource('qb-core')) or (Config.Framework ~= 'auto' and Config.Framework ~= 'qb') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Framework] Loaded: QB')
end

QBCore = exports['qb-core']:GetCoreObject()

-- qb-ambulancejob tracks death only in player metadata (isdead / inlaststand)
-- and never sets a statebag, while the ped itself is resurrected into an
-- animation - so neither statebag nor native checks see the player as dead.
-- Mirror the metadata into the replicated 'isDead' statebag. Only ever clear
-- a value this bridge set itself, so death scripts that manage the statebag
-- on their own are never overridden.
local deadSetByBridge = false
local function syncDeadState(playerData)
    local meta = playerData and playerData.metadata
    if type(meta) ~= 'table' then return end

    local metaDead = (meta.isdead or meta.inlaststand) and true or false
    local state = LocalPlayer.state

    if metaDead and not state.isDead then
        state:set('isDead', true, true)
        deadSetByBridge = true
    elseif not metaDead and deadSetByBridge and state.isDead then
        state:set('isDead', false, true)
        deadSetByBridge = false
    end
end

-- UPDATE PLAYER DATA
RegisterNetEvent('QBCore:Player:SetPlayerData', function(xPlayer)
    QBCore.PlayerData = xPlayer
    syncDeadState(xPlayer)
    TriggerEvent('p_bridge/client/setPlayerData', QBCore.PlayerData)
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= cache.resource then return end

    Citizen.Wait(1000)
    local playerData = QBCore.Functions.GetPlayerData()
    QBCore.PlayerData = playerData
    syncDeadState(playerData)
    TriggerEvent('p_bridge/client/setPlayerData', playerData)
end)

-- Live player data from qb-core. QBCore here is a copy of the core object, its PlayerData changes only
-- with QBCore:Player:SetPlayerData, so a missed update left an old (or empty -> unemployed) job in it.
--@return table [PlayerData, empty table before the character is loaded]
local function getPlayerData()
    local playerData = QBCore.Functions.GetPlayerData()
    if type(playerData) == 'table' and next(playerData) then
        QBCore.PlayerData = playerData
        return playerData
    end
    return QBCore.PlayerData or {}
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    local timeout = GetGameTimer() + 10000
    while not LocalPlayer.state.isLoggedIn and GetGameTimer() < timeout do
        Citizen.Wait(100)
    end
    Citizen.Wait(1000)

    local playerData = getPlayerData()
    syncDeadState(playerData)
    if Config.Debug then
        lib.print.info(('[Framework] OnPlayerLoaded -> setPlayerData (Job: %s)'):format(tostring(playerData.job?.name)))
    end
    TriggerEvent('p_bridge/client/setPlayerData', playerData)
end)

Bridge.Framework = {}

--@return boolean [true if player is loaded, false otherwise]
Bridge.Framework.isPlayerLoaded = function()
    return LocalPlayer.state.isLoggedIn
end

--@return { name: string, label: string, grade: number }
Bridge.Framework.fetchPlayerJob = function()
    local job = getPlayerData().job
    if not job then
        return { name = 'unemployed', label = 'Unemployed', grade = 0 } -- if PlayerData is not loaded yet, return a default job
    end

    return { name = job.name, label = job.label or job.name, grade = tonumber(job.grade?.level) or 0 }
end

--@return identifier: string [example 'char1:123456']
Bridge.Framework.getIdentifier = function()
    local identifier = getPlayerData().citizenid
    if not identifier then
        lib.print.error('QB-Core PlayerData not loaded yet. Please wait for the playerLoaded event.')
        return nil
    end

    return identifier
end

--@return name: string [example 'John Doe']
Bridge.Framework.getPlayerName = function()
    local charinfo = getPlayerData().charinfo or {}
    return ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or '')
end

Bridge.Framework.CheckJobDuty = function()
    if GetResourceState('piotreq_jobcore') == 'started' then
        local dutyData = exports['piotreq_jobcore']:GetDutyData()
        return dutyData?.status == 1
    end

    local onDuty = getPlayerData().job?.onduty
    return onDuty == true
end
