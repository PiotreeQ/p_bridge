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
    local identifier = Bridge.Framework.getUniqueId(_source)
    if GetResourceState('tgiann-clothing') == 'started' then
        local result = MySQL.query.await('SELECT * FROM tgiann_skin WHERE citizenid = ?', { identifier })
        if result and result[1] then
            return json.decode(result[1].skin)
        end
    elseif GetResourceState('rcore_clothing') == 'started' then
        local identifier = Bridge.Framework.getUniqueId(_source)
        return exports["rcore_clothing"]:getSkinByIdentifier(identifier)
    elseif GetResourceState('es_extended') == 'started' then
        local row = MySQL.single.await('SELECT skin FROM users WHERE identifier = ?', {
            identifier
        })
        return row and json.decode(row.skin) or nil
    elseif GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started' then
        local row = MySQL.single.await('SELECT * FROM playerskins WHERE citizenid = ? AND active = 1', {
            identifier
        })
        return row and json.decode(row.skin) or nil
    end

    return nil 
end)