if (Config.Society == 'auto' and not checkResource('oxide-banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'oxide-banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: oxide-banking')
end

Bridge.Society = {}

local function ensureAccount(jobName)
    if not exports['oxide-banking']:GetAccountData(jobName) then
        exports['oxide-banking']:CreateJobAccount(jobName, 0)
    end
end

Bridge.Society.addMoney = function(playerId, jobName, amount)
    ensureAccount(jobName)
    local result = exports['oxide-banking']:AddMoney(jobName, amount, 'p_bridge')
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['oxide-banking']:RemoveMoney(jobName, amount, 'p_bridge')
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local balance = exports['oxide-banking']:GetAccountBalance(jobName)
    return balance or 0
end
