if (Config.Society == 'auto' and not checkResource('esx_addonaccount')) or (Config.Society ~= 'auto' and Config.Society ~= 'esx_addonaccount') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: esx_addonaccount')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local account = exports['esx_addonaccount']:GetSharedAccount(('society_%s'):format(jobName))
    if account then
        account.addMoney(amount)
        return true
    end
    return false
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local account = exports['esx_addonaccount']:GetSharedAccount(('society_%s'):format(jobName))
    if account then
        account.removeMoney(amount)
        return true
    end
    return false
end

Bridge.Society.getMoney = function(playerId, jobName)
    local account = exports['esx_addonaccount']:GetSharedAccount(('society_%s'):format(jobName))
    if account then
        return account.money
    end
    return 0
end