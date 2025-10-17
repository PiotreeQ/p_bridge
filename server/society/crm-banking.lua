if (Config.Society == 'auto' and not checkResource('crm-banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'crm-banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: crm-banking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['crm-banking']:addSocietyMoney(jobName, amount)
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['crm-banking']:removeSocietyMoney(jobName, amount)
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['crm-banking']:getSocietyMoney(jobName)
    if money then
        return money
    end
    return 0
end