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
RegisterNetEvent('esx:playerLoaded', function(xPlayer) ESX.PlayerData = xPlayer end)
RegisterNetEvent('esx:setJob', function(job) ESX.PlayerData.job = job end)

Bridge.Framework = {}

--@return boolean [true if player is loaded, false otherwise]
Bridge.Framework.isPlayerLoaded = function()
    return ESX.IsPlayerLoaded()
end

--@return { name: string, label: string, grade: number }
Bridge.Framework.fetchPlayerJob = function()
    return ESX.PlayerData?.job or { name = 'unemployed', label = 'Unemployed', grade = 0 } -- if PlayerData is not loaded yet, return a default job
end

--@return identifier: string [example 'char1:123456']
Bridge.Framework.getIdentifier = function()
    local identifier = ESX.PlayerData?.identifier
    if not identifier then
        lib.print.error('ESX PlayerData not loaded yet. Please wait for the playerLoaded event.')
        return nil
    end

    return identifier
end

--@return name: string [example 'John Doe']
Bridge.Framework.getPlayerName = function()
    return ('%s %s'):format(ESX.PlayerData?.firstname, ESX.PlayerData?.lastname)
end