if (Config.Society == 'auto' and not checkResource('qb-banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'qb-banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: qb-banking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['qb-banking']:AddMoney(jobName, amount)
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['qb-banking']:RemoveMoney(jobName, amount)
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local account = exports['qb-banking']:GetAccount(jobName)
    if account then
        return account.account_balance or 0
    end
    return 0
end