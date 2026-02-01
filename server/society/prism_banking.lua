if (Config.Society == 'auto' and not checkResource('prism_banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'prism_banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: prism_banking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    exports['prism_banking']:AddSocietyMoney(jobName, amount)
    return true
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    exports['prism_banking']:RemoveSocietyMoney(jobName, amount)
    return true
end

Bridge.Society.getMoney = function(playerId, jobName)
    local societyBalance = exports['prism_banking']:GetSocietyBalance(jobName)
    if societyBalance then
        return societyBalance
    end
    return 0
end