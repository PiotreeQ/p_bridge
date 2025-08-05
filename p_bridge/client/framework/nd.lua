if (Config.Framework == 'auto' and not checkResource('ND_Core')) or (Config.Framework ~= 'auto' and Config.Framework ~= 'nd') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Framework] Loaded: ND_Core')
end

Bridge.Framework = {}

--@return boolean [true if player is loaded, false otherwise]
Bridge.Framework.isPlayerLoaded = function()
    local player = exports['ND_Core']:getPlayer()
    return player and true or false
end

--@return { name: string, label: string, grade: number }
Bridge.Framework.fetchPlayerJob = function()
    local player = exports['ND_Core']:getPlayer()
    return player and { name = player.job, label = player.jobInfo?.label, grade = player.jobInfo?.rank } or { name = 'unemployed', label = 'Unemployed', grade = 0 } -- if PlayerData is not loaded yet, return a default job
end

--@return identifier: string [example 'char1:123456']
Bridge.Framework.getIdentifier = function()
    local player = exports['ND_Core']:getPlayer()
    if not player then
        lib.print.error('Player data is not available.')
        return nil
    end

    return player.identifier
end

--@return name: string [example 'John Doe']
Bridge.Framework.getPlayerName = function()
    local player = exports['ND_Core']:getPlayer()
    if not player then
        lib.print.error('Player data is not available.')
        return nil
    end
    
    return ('%s %s'):format(player.firstname, player.lastname)
end