if (Config.Society == 'auto' and not checkResource('m-BossMenu')) or (Config.Society ~= 'auto' and Config.Society ~= 'm-BossMenu') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: m-BossMenu')
end

-- Docs: https://mscripts.gitbook.io/docs/premium/scripts/boss-menu/server-exports
-- m-BossMenu forwards these to whatever banking it is configured with (Config.Society in m-BossMenu)

Bridge.Society = {}

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local ok, result = pcall(function()
        return exports['m-BossMenu']:AddSocietyMoney(jobName, amount)
    end)
    if not ok then
        lib.print.error(('[Society] m-BossMenu AddSocietyMoney failed for %s: %s'):format(jobName, result))
        return false
    end
    return result == true
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local ok, result = pcall(function()
        return exports['m-BossMenu']:RemoveSocietyMoney(jobName, amount)
    end)
    if not ok then
        lib.print.error(('[Society] m-BossMenu RemoveSocietyMoney failed for %s: %s'):format(jobName, result))
        return false
    end
    return result == true
end

Bridge.Society.getMoney = function(playerId, jobName)
    local ok, balance = pcall(function()
        return exports['m-BossMenu']:GetSocietyBalance(jobName)
    end)
    if ok and tonumber(balance) then
        return tonumber(balance)
    end
    return 0
end
