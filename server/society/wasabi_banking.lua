if (Config.Society == 'auto' and not checkResource('wasabi_banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'wasabi_banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: wasabi_banking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['wasabi_banking']:AddMoney('society', jobName, amount)
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['wasabi_banking']:RemoveMoney('society', jobName, amount)
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['wasabi_banking']:GetAccountBalance(jobName, 'society')
    if money then
        return money
    end
    return 0
end