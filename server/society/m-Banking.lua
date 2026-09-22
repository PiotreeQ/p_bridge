if (Config.Society == 'auto' and not checkResource('m-Banking')) or (Config.Society ~= 'auto' and Config.Society ~= 'm-Banking') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Society] Loaded: m-Banking')
end

-- Docs: https://mscripts.gitbook.io/docs/premium/scripts/banking/exports
-- Society funds live on the job's business account (accountType 'business', accountName = job name)

Bridge.Society = {}

local function toBoolean(result)
    if type(result) == 'table' then
        return result.success == true
    end
    return result == true
end

Bridge.Society.addMoney = function(playerId, jobName, amount)
    local ok, result = pcall(function()
        return exports['m-Banking']:AddSocietyMoney(jobName, amount, 'pScripts')
    end)
    if not ok then
        lib.print.error(('[Society] m-Banking AddSocietyMoney failed for %s: %s'):format(jobName, result))
        return false
    end
    return toBoolean(result)
end

Bridge.Society.removeMoney = function(playerId, jobName, amount)
    local ok, result = pcall(function()
        return exports['m-Banking']:RemoveSocietyMoney(jobName, amount, 'pScripts')
    end)
    if not ok then
        lib.print.error(('[Society] m-Banking RemoveSocietyMoney failed for %s: %s'):format(jobName, result))
        return false
    end
    return toBoolean(result)
end

Bridge.Society.getMoney = function(playerId, jobName)
    -- GetAccountBalance(target, accountType, accountName): target can be a player source, an identifier
    -- or an account id. Prefer the requesting player, fall back to the society name as account id.
    local targets = {}
    if playerId then
        targets[#targets + 1] = playerId
    end
    targets[#targets + 1] = jobName

    for _, target in ipairs(targets) do
        local ok, balance = pcall(function()
            return exports['m-Banking']:GetAccountBalance(target, 'business', jobName)
        end)
        if ok and tonumber(balance) then
            return tonumber(balance)
        end
    end

    return 0
end
