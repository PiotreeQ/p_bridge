if (Config.Society == 'auto' and not checkResource('vms_bossmenu')) or (Config.Society ~= 'auto' and Config.Society ~= 'vms_bossmenu') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: vms_bossmenu')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = nil
    exports['vms_bossmenu']:addMoney(jobName, amount, function(success)
        result = success
    end)

    while result == nil do
        Citizen.Wait(1)
    end

    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = nil
    exports['vms_bossmenu']:removeMoney(jobName, amount, function(success)
        result = success
    end)

    while result == nil do
        Citizen.Wait(1)
    end

    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local account = exports['vms_bossmenu']:getSociety(jobName)
    if account then
        return account.balance
    end
    return 0
end