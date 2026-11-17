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

-- Mirror qb-ambulancejob style death metadata (isdead / inlaststand) into
-- the replicated 'isDead' statebag; see qb.lua for the rationale. Only clears
-- a value this bridge set itself.
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

RegisterNetEvent('QBCore:Player:SetPlayerData', function(xPlayer)
    syncDeadState(xPlayer)
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
    local job = exports['qbx_core']:GetPlayerData()?.job
    if not job then
        return { name = 'unemployed', label = 'Unemployed', grade = 0 } -- if PlayerData is not loaded yet, return a default job
    end

    return { name = job.name, label = job.label or job.name, grade = tonumber(job.grade?.level) or 0 }
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

Bridge.Framework.CheckJobDuty = function()
    if GetResourceState('piotreq_jobcore') == 'started' then
        local dutyData = exports['piotreq_jobcore']:GetDutyData()
        return dutyData?.status == 1
    end

    local onDuty = exports['qbx_core']:GetPlayerData()?.job?.onduty
    return onDuty == true
end

-- Money / job / status for HUDs and UIs. Same shapes in every framework file.

--@return { cash: number, bank: number, dirty: number|nil }
Bridge.Framework.getMoney = function()
    local money = exports['qbx_core']:GetPlayerData()?.money or {}
    return { cash = money.cash or 0, bank = money.bank or 0, dirty = nil } -- dirty money is an item in QBox
end

--@return { name: string, label: string, grade: number, gradeLabel: string, salary: number, onDuty: boolean }
Bridge.Framework.getJobInfo = function()
    local job = exports['qbx_core']:GetPlayerData()?.job or {}
    return {
        name = job.name or 'unemployed',
        label = job.label or job.name or 'Unemployed',
        grade = tonumber(job.grade?.level) or 0,
        gradeLabel = job.grade?.name or '',
        salary = tonumber(job.payment) or 0,
        onDuty = Bridge.Framework.CheckJobDuty(),
    }
end

--@return { [string]: number } [0 - 100 per status, e.g. hunger, thirst, stress]
Bridge.Framework.getStatus = function()
    local meta = exports['qbx_core']:GetPlayerData()?.metadata or {}
    return { hunger = meta.hunger, thirst = meta.thirst, stress = meta.stress }
end

-- Money and needs live in PlayerData, so every PlayerData update may have changed them.
RegisterNetEvent('QBCore:Player:SetPlayerData', function(playerData)
    if type(playerData) ~= 'table' then return end
    TriggerEvent('p_bridge/client/moneyChanged', Bridge.Framework.getMoney())
    TriggerEvent('p_bridge/client/statusChanged', Bridge.Framework.getStatus())
end)

RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    TriggerEvent('p_bridge/client/playerUnloaded')
end)


-- Multicharacter: QB / QBox expect the spawn resource (qb-spawn, apartments) to announce the
-- loaded player once it stands in the world; the character resource calls this instead.
--@param isNew: boolean [first spawn of a new character]
Bridge.Framework.playerSpawned = function(isNew)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    TriggerServerEvent('qb-houses:server:SetInsideMeta', 0, false)
    TriggerServerEvent('qb-apartments:server:SetInsideMeta', 0, 0, false)
end

Bridge.Framework.name = 'qbox'
