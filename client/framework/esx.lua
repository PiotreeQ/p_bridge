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

-- UPDATE PLAYER DATA
RegisterNetEvent('esx:playerLoaded', function(xPlayer) 
    ESX.PlayerData = xPlayer 
    TriggerEvent('p_bridge/client/setPlayerData', ESX.PlayerData)
end)

RegisterNetEvent('esx:setJob', function(job) 
    ESX.PlayerData.job = job 
    TriggerEvent('p_bridge/client/setPlayerData', ESX.PlayerData)
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= cache.resource then return end
    ESX.PlayerData = ESX.GetPlayerData()

    Citizen.Wait(1000)
    if not ESX.IsPlayerLoaded() then
        return
    end
    
    TriggerEvent('p_bridge/client/setPlayerData', ESX.PlayerData)
end)

-- Live player data from es_extended. ESX here is a copy of the shared object, its PlayerData changes only
-- with the events above, so a missed update left an old (or empty -> unemployed) job in it.
--@return table [PlayerData, empty table before the character is loaded]
local function getPlayerData()
    local playerData = ESX.GetPlayerData()
    if type(playerData) == 'table' and next(playerData) then
        ESX.PlayerData = playerData
        return playerData
    end
    return ESX.PlayerData or {}
end

Bridge.Framework = {}

--@return boolean [true if player is loaded, false otherwise]
Bridge.Framework.isPlayerLoaded = function()
    return ESX.IsPlayerLoaded()
end

--@return { name: string, label: string, grade: number } [ESX job table, also grade_name, grade_label, onDuty]
Bridge.Framework.fetchPlayerJob = function()
    return getPlayerData().job or { name = 'unemployed', label = 'Unemployed', grade = 0 } -- if PlayerData is not loaded yet, return a default job
end

--@return identifier: string [example 'char1:123456']
Bridge.Framework.getIdentifier = function()
    local identifier = getPlayerData().identifier
    if not identifier then
        lib.print.error('ESX PlayerData not loaded yet. Please wait for the playerLoaded event.')
        return nil
    end

    return identifier
end

--@return name: string [example 'John Doe']
Bridge.Framework.getPlayerName = function()
    local playerData = getPlayerData()
    return ('%s %s'):format(playerData.firstName or '', playerData.lastName or '')
end

Bridge.Framework.CheckJobDuty = function()
    if GetResourceState('piotreq_jobcore') == 'started' then
        local dutyData = exports['piotreq_jobcore']:GetDutyData()
        return dutyData?.status == 1
    end

    local playerJob = Bridge.Framework.fetchPlayerJob()
    if playerJob.onDuty == nil then
        return true
    end

    return playerJob.onDuty
end