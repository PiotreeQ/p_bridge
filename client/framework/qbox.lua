if (Config.Framework == 'auto' and not checkResource('qbx_core')) or (Config.Framework ~= 'auto' and Config.Framework ~= 'qbox') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Framework] Loaded: QBOX')
end

Bridge.Framework = {}

RegisterNetEvent('QBCore:Player:SetPlayerData', function(xPlayer) 
    TriggerEvent('p_bridge/client/setPlayerData', xPlayer)
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= cache.resource then return end

    local playerData = exports['qbx_core']:GetPlayerData() or {}
    if not playerData then return end

    Citizen.Wait(1000)
    TriggerEvent('p_bridge/client/setPlayerData', playerData)
end)

--@return boolean [true if player is loaded, false otherwise]
Bridge.Framework.isPlayerLoaded = function()
    return LocalPlayer.state.isLoggedIn
end

--@return { name: string, label: string, grade: number }
Bridge.Framework.fetchPlayerJob = function()
    local playerData = exports['qbx_core']:GetPlayerData()
    return playerData?.job and { name = playerData.job.name, label = playerData.job.name, grade = playerData.job.grade.level } or { name = 'unemployed', label = 'Unemployed', grade = 0 } -- if PlayerData is not loaded yet, return a default job
end

--@return identifier: string [example 'char1:123456']
Bridge.Framework.getIdentifier = function()
    local playerData = exports['qbx_core']:GetPlayerData()
    local identifier = playerData?.citizenid
    if not identifier then
        lib.print.error('QB-Core PlayerData not loaded yet. Please wait for the playerLoaded event.')
        return nil
    end

    return identifier
end

--@return name: string [example 'John Doe']
Bridge.Framework.getPlayerName = function()
    local playerData = exports['qbx_core']:GetPlayerData()
    if not playerData then
        lib.print.error('Player data is not available.')
        return nil
    end

    return ('%s %s'):format(playerData?.charinfo.firstname, playerData?.charinfo.lastname)
end