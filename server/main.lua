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
            help = 'Type of setup (ped/point)',
            type = 'string',
        }
    },
    restricted = 'group.admin',
}, function(source, args, raw)
    local _source = source
    TriggerClientEvent('p_bridge/client/setup/start', _source, args.type)
end)