if (Config.Society == 'auto' and not checkResource('okokBanking')) or (Config.Society ~= 'auto' and Config.Society ~= 'okokBanking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: okokBanking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    exports['okokBanking']:AddMoney(jobName, amount)
    return true
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    exports['okokBanking']:RemoveMoney(jobName, amount)
    return true
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['okokBanking']:GetAccount(jobName)
    if money then
        return money
    end
    return 0
end