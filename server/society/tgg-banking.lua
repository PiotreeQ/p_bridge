if (Config.Society == 'auto' and not checkResource('tgg-banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'tgg-banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: tgg-banking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['tgg-banking']:AddSocietyMoney(jobName, amount)
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['tgg-banking']:RemoveSocietyMoney(jobName, amount)
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['tgg-banking']:GetSocietyAccountMoney(jobName)
    if money then
        return money
    end
    return 0
end