if (Config.Society == 'auto' and not checkResource('bcs_companymanager')) or (Config.Society ~= 'auto' and Config.Society ~= 'bcs_companymanager') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: bcs_companymanager')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    exports['bcs_companymanager']:AddCompanyMoney(jobName, 'money', amount)
    return true
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    -- RemoveCompanyMoney doesn't return a result, so check the balance first
    if Bridge.Society.getMoney(playerId, jobName) < amount then
        return false
    end

    exports['bcs_companymanager']:RemoveCompanyMoney(jobName, 'money', amount)
    return true
end

Bridge.Society.getMoney = function(playerId, jobName)
    return exports['bcs_companymanager']:GetCompanyMoney(jobName, 'money') or 0
end
