if (Config.Society == 'auto' and not checkResource('qs-banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'qs-banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: qs-banking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['qs-banking']:AddMoney(jobName, amount)
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['qs-banking']:RemoveMoney(jobName, amount)
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['qs-banking']:GetAccountBalance(jobName)
    if money then
        return money
    end
    return 0
end