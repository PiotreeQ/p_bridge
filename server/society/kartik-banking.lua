if (Config.Society == 'auto' and not checkResource('kartik-banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'kartik-banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: kartik-banking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['kartik-banking']:AddAccountMoney(jobName, amount)
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['kartik-banking']:RemoveAccountMoney(jobName, amount)
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['kartik-banking']:GetAccountMoney(jobName)
    if money then
        return money
    end
    return 0
end