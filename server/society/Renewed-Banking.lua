if (Config.Society == 'auto' and not checkResource('Renewed-Banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'Renewed-Banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: Renewed-Banking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['Renewed-Banking']:AddAccountMoney(jobName, amount)
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['Renewed-Banking']:RemoveAccountMoney(jobName, amount)
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['Renewed-Banking']:GetAccountMoney(jobName)
    if money then
        return money
    end
    return 0
end