while not Bridge do Citizen.Wait(0) end

Bridge.Logs = {}

Bridge.Logs.Send = function(playerId, title, message, webhook)
    Citizen.CreateThread(function()
        if not Config.Logs then return end
        -- An empty webhook just means this log is disabled
        if not webhook or webhook == '' then return end
        if not message then
            lib.print.error(('No message provided for logging [%s]'):format(GetInvokingResource() or cache.resource))
            return
        end
        local steamName, steamHex, discordId, license = 'Unknown', 'Unknown', 'Unknown', Bridge.Framework.getUniqueId(playerId) or 'Unknown'
        if playerId then
            steamName = GetPlayerName(playerId) or 'Unknown'
            local identifiers = GetPlayerIdentifiers(playerId)
            for i = 1, #identifiers do
                if string.find(identifiers[i], 'steam:') then
                    steamHex = identifiers[i]
                elseif string.find(identifiers[i], 'discord:') then
                    discordId = string.gsub(identifiers[i], 'discord:', '')
                end
            end
        end

        message = message..'\n\n-----------\n**Source Info**\nID: '..(playerId or 'Server')..'\nSteam Name: '..steamName..'\nSteam HEX: '..steamHex..'\nDiscord: <@'..discordId..'>\nLicense: '..license
        local embedData = { {
            ['title'] = title or GetInvokingResource(),
            ['color'] = 14423100,
            ['footer'] = {
                ['text'] = ("%s | pScripts | " .. os.date()):format(title or GetInvokingResource()),
                ['icon_url'] = "https://r2.fivemanage.com/xlufCGKYLtGfU8IBmjOL9/LOGO3.png"
            },
            ['description'] = message,
            ['author'] = {
                ['name'] = "pScripts",
                ['icon_url'] = "https://r2.fivemanage.com/xlufCGKYLtGfU8IBmjOL9/LOGO3.png"
            }
        } }
        -- A rejected or unreachable webhook used to fail without a trace
        PerformHttpRequest(webhook, function(status, body)
            if status < 200 or status >= 300 then
                lib.print.error(('Discord webhook failed for log "%s": HTTP %s %s'):format(title or 'unknown', status, tostring(body or ''):sub(1, 200)))
            end
        end, 'POST', json.encode({
            username = 'pScripts',
            embeds = embedData
        }), {
            ['Content-Type'] = 'application/json'
        })
    end)    
end