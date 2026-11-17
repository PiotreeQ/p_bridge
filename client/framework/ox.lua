if (Config.Framework == 'auto' and not checkResource('ox_core')) or (Config.Framework ~= 'auto' and Config.Framework ~= 'ox') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Framework] Loaded: OX')
end

Bridge.Framework = {}

local Ox = require '@ox_core.lib.init'

RegisterNetEvent('ox:playerLoaded', function(playerId)
    Bridge.Framework.Loaded = true
end)

--@return boolean [true if player is loaded, false otherwise]
Bridge.Framework.isPlayerLoaded = function()
    return Bridge.Framework.Loaded
end

--@return { name: string, label: string, grade: number }
Bridge.Framework.fetchPlayerJob = function()
    local player = Ox.GetPlayer()
    local jobName, jobGrade = player.activeGroup, player.getGroup(player.activeGroup)
    return player and { name = jobName, label = jobName, grade = jobGrade } or { name = 'unemployed', label = 'Unemployed', grade = 0 } -- if PlayerData is not loaded yet, return a default job
end

--@return identifier: string [example 'char1:123456']
Bridge.Framework.getIdentifier = function()
    local player = Ox.GetPlayer()
    if not player then
        lib.print.error('Player data is not available.')
        return nil
    end

    return player.stateId
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
    local cash = GetResourceState('ox_inventory') == 'started' and exports.ox_inventory:Search('count', 'money') or 0
    return { cash = cash or 0, bank = 0, dirty = nil } -- ox_core keeps bank accounts server side
end

--@return { name: string, label: string, grade: number, gradeLabel: string, salary: number, onDuty: boolean }
Bridge.Framework.getJobInfo = function()
    local job = Bridge.Framework.fetchPlayerJob()
    return { name = job.name, label = job.label or job.name, grade = tonumber(job.grade) or 0, gradeLabel = '', salary = 0, onDuty = true }
end

--@return { [string]: number } [0 - 100 per status, e.g. hunger, thirst, stress]
Bridge.Framework.getStatus = function()
    return {}
end

RegisterNetEvent('ox:playerLogout', function()
    Bridge.Framework.Loaded = false
    TriggerEvent('p_bridge/client/playerUnloaded')
end)


-- Multicharacter: nothing to announce on this framework.
--@param isNew: boolean [first spawn of a new character]
Bridge.Framework.playerSpawned = function(isNew)
end

Bridge.Framework.name = 'ox'
