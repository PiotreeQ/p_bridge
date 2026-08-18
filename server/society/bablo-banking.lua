if (Config.Society == 'auto' and not checkResource('bablo-banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'bablo-banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: bablo-banking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['bablo-banking']:AddSocietyMoney(jobName, amount, 'p_bridge')
    return result?.success or false
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['bablo-banking']:RemoveSocietyMoney(jobName, amount)
    return result?.success or false
end

Bridge.Society.getMoney = function(playerId, jobName)
    local balance = exports['bablo-banking']:GetSocietyBalance(jobName)
    return balance or 0
end
