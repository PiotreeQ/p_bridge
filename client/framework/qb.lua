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

-- UPDATE PLAYER DATA
RegisterNetEvent('QBCore:Player:SetPlayerData', function(xPlayer) 
    QBCore.PlayerData = xPlayer 
    TriggerEvent('p_bridge/client/setPlayerData', QBCore.PlayerData)
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= cache.resource then return end
    if not QBCore.PlayerData then return end 

    Citizen.Wait(1000)
    TriggerEvent('p_bridge/client/setPlayerData', QBCore.PlayerData)
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