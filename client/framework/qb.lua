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
    syncDeadState(playerData)
    TriggerEvent('p_bridge/client/setPlayerData', playerData)
end)

Bridge.Framework = {}

--@return boolean [true if player is loaded, false otherwise]
Bridge.Framework.isPlayerLoaded = function()
    return LocalPlayer.state.isLoggedIn
end

--@return { name: string, label: string, grade: number }
Bridge.Framework.fetchPlayerJob = function()
    return QBCore.PlayerData?.job and { name = QBCore.PlayerData.job.name, label = QBCore.PlayerData.job.name, grade = QBCore.PlayerData.job.grade.level } or { name = 'unemployed', label = 'Unemployed', grade = 0 } -- if PlayerData is not loaded yet, return a default job
end

--@return identifier: string [example 'char1:123456']
Bridge.Framework.getIdentifier = function()
    local identifier = QBCore.PlayerData?.citizenid
    if not identifier then
        lib.print.error('QB-Core PlayerData not loaded yet. Please wait for the playerLoaded event.')
        return nil
    end

    return identifier
end

--@return name: string [example 'John Doe']
Bridge.Framework.getPlayerName = function()
    return ('%s %s'):format(QBCore.PlayerData?.charinfo.firstname, QBCore.PlayerData?.charinfo.lastname)
end

Bridge.Framework.CheckJobDuty = function()
    if GetResourceState('piotreq_jobcore') == 'started' then
        local dutyData = exports['piotreq_jobcore']:GetDutyData()
        return dutyData?.status == 1
    end

    local onDuty = QBCore.Functions.GetPlayerData()?.job?.onduty
    return onDuty == true
end