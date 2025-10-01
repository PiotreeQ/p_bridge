Bridge = {}

Bridge.Config = Config

function checkResource(resourceName)
    local state = GetResourceState(resourceName)
    return state ~= 'missing' and state ~= 'unknown'
end

exports('getObject', function() return Bridge end)

lib.versionCheck('PiotreeQ/p_bridge')

lib.addCommand('setup', {
    help = 'Setup ped or point',
    params = {
        {
            name = 'type',
            help = 'Type of setup (ped/point/prop)',
            type = 'string',
        }
    },
    restricted = 'group.admin',
}, function(source, args, raw)
    local _source = source
    TriggerClientEvent('p_bridge/client/setup/start', _source, args.type)
end)

RegisterNetEvent('p_bridge/server/removeItem', function(itemName, amount, metadata)
    local _source = source
    if not itemName or type(itemName) ~= 'string' then return end
    if not amount or type(amount) ~= 'number' then amount = 1 end

    if Bridge.Inventory then
        Bridge.Inventory.removeItem(_source, itemName, amount, metadata)
    end
end)

lib.callback.register('p_bridge/server/getPlayerSkin', function(source)
    local _source = source
    if GetResourceState('tgiann-clothing') == 'started' then
        local xPlayer = Bridge.Framework.getPlayerById(_source)
        local result = MySQL.query.await('SELECT * FROM tgiann_skin WHERE citizenid = ?', { xPlayer.identifier })
        if result and result[1] then
            return json.decode(result[1].skin)
        end
    end

    return nil 
end)