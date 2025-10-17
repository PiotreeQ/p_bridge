if (Config.Society == 'auto' and not checkResource('fd_banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'fd_banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: fd_banking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['fd_banking']:AddMoney(jobName, amount)
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['fd_banking']:RemoveMoney(jobName, amount)
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local account = exports['fd_banking']:GetAccount(jobName)
    return account and account.account_balance or 0
end