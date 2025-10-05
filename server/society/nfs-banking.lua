if (Config.Society == 'auto' and not checkResource('nfs-banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'nfs-banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: nfs-banking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['p_banking']:addAccountMoney(jobName, amount)
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['p_banking']:removeAccountMoney(jobName, amount)
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['p_banking']:getAccountMoney(jobName)
    if money then
        return money
    end
    return 0
end