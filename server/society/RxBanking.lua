if (Config.Society == 'auto' and not checkResource('RxBanking')) or (Config.Society ~= 'auto' and Config.Society ~= 'RxBanking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: RxBanking')
end

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local result = exports['RxBanking']:AddSocietyMoney(jobName, amount)
    return result
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local result = exports['RxBanking']:RemoveSocietyMoney(jobName, amount)
    return result
end

Bridge.Society.getMoney = function(playerId, jobName)
    local data = exports['RxBanking']:GetSocietyAccount(jobName)
    if data then
        return type(data) == 'number' and data or (data.money or data.balance) -- idk what this export return :c
    end
    return 0
end