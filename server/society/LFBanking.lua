if (Config.Society == 'auto' and not checkResource('LfBanking')) or (Config.Society ~= 'auto' and Config.Society ~= 'LfBanking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: LfBanking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local plyIdentifier = Bridge.Framework.getPlayerId(playerId)
    local result = exports['LfBanking']:creditAccount(
        false,
        plyIdentifier,
        amount,
        'Deposit',
        'deposit'
    )
    return result?.success or false
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local plyIdentifier = Bridge.Framework.getPlayerId(playerId)
    local result = exports['LfBanking']:debitAccount(
        false,
        plyIdentifier,
        amount,
        'Withdrawal',
        'withdraw'
    )
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local money = exports['LfBanking']:getAccountMoney(jobName)
    if money then
        return money
    end
    return 0
end