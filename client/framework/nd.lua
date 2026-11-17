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

-- Money / job / status for HUDs and UIs. Same shapes in every framework file.

--@return { cash: number, bank: number, dirty: number|nil }
Bridge.Framework.getMoney = function()
    local player = exports['ND_Core']:getPlayer()
    return { cash = player and player.cash or 0, bank = player and player.bank or 0, dirty = nil }
end

--@return { name: string, label: string, grade: number, gradeLabel: string, salary: number, onDuty: boolean }
Bridge.Framework.getJobInfo = function()
    local player = exports['ND_Core']:getPlayer()
    local job = Bridge.Framework.fetchPlayerJob()
    return {
        name = job.name,
        label = job.label or job.name,
        grade = tonumber(job.grade) or 0,
        gradeLabel = player and player.jobInfo?.rankName or '',
        salary = 0,
        onDuty = true,
    }
end

--@return { [string]: number } [0 - 100 per status, e.g. hunger, thirst, stress]
Bridge.Framework.getStatus = function()
    return {}
end

RegisterNetEvent('ND:characterUnloaded', function()
    TriggerEvent('p_bridge/client/playerUnloaded')
end)


-- Multicharacter: nothing to announce on this framework.
--@param isNew: boolean [first spawn of a new character]
Bridge.Framework.playerSpawned = function(isNew)
end

Bridge.Framework.name = 'nd'
