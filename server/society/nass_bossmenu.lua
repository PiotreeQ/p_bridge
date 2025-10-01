if (Config.Society == 'auto' and not checkResource('nass_bosmenu')) or (Config.Society ~= 'auto' and Config.Society ~= 'nass_bosmenu') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: nass_bosmenu')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    exports['nass_bossmenu']:addMoney(jobName, amount)
    return true
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['nass_bossmenu']:removeMoney(jobName, amount)
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['nass_bossmenu']:getAccount(jobName)
    if money then
        return money
    end
    return 0
end