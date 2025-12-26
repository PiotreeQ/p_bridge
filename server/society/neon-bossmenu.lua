if (Config.Society == 'auto' and not checkResource('neon-boss')) or (Config.Society ~= 'auto' and Config.Society ~= 'neon-boss') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: neon-boss')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local playerName = Bridge.Framework.getPlayerName(playerId)
    return exports['neon-boss']:AddSocietyMoney(jobName, playerName, amount, 'Deposit')
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local playerName = Bridge.Framework.getPlayerName(playerId)
    return exports['neon-boss']:RemoveSocietyMoney(jobName, playerName, amount, 'Withdrawal')
end

Bridge.Society.getMoney = function(playerId, jobName)
    local account = exports['neon-boss']:GetSocietyData(jobName)
    if account then
        return account.balance
    end
    return 0
end