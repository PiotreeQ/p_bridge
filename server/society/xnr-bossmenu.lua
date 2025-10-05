if (Config.Society == 'auto' and not checkResource('xnr-bossmenu')) or (Config.Society ~= 'auto' and Config.Society ~= 'xnr-bossmenu') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: xnr-bossmenu')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    return exports['xnr-bossmenu']:addMoney(jobName, amount)
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    return exports['xnr-bossmenu']:removeMoney(jobName, amount)
end

Bridge.Society.getMoney = function(playerId, jobName)
    local account = exports['xnr-bossmenu']:getSociety(jobName)
    if account then
        return account.balance
    end
    return 0
end