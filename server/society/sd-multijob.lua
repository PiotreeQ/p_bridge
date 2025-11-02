if (Config.Society == 'auto' and not checkResource('sd-multijob')) or (Config.Society ~= 'auto' and Config.Society ~= 'sd-multijob') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: sd-multijob')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['sd-multijob']:addSocietyDeposit(playerId, jobName, amount, 'bank')
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['sd-multijob']:withdrawSocietyFunds(playerId, jobName, amount, 'bank')
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['sd-multijob']:getSocietyBalance(jobName)
    if money then
        return money
    end
    return 0
end