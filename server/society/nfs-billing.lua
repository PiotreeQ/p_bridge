if (Config.Society == 'auto' and not checkResource('nfs-billing')) or (Config.Society ~= 'auto' and Config.Society ~= 'nfs-billing') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: nfs-billing')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    exports['nfs-billing']:depositSociety(jobName, amount)
    return true
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    exports['nfs-billing']:withdrawSociety(jobName, amount)
    return true
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['nfs-billing']:getSocietyBalance(jobName)
    if money then
        return money
    end
    return 0
end