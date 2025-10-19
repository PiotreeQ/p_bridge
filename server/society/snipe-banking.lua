if (Config.Society == 'auto' and not checkResource('snipe-banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'snipe-banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: snipe-banking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['snipe-banking']:AddMoneyToAccount(jobName, amount)
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['snipe-banking']:RemoveMoneyFromAccount(jobName, amount)
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['snipe-banking']:GetAccountBalance(jobName)
    if money then
        return money
    end
    return 0
end