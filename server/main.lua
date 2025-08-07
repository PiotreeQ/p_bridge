Bridge = {}

Bridge.Config = Config

function checkResource(resourceName)
    local state = GetResourceState(resourceName)
    return state ~= 'missing' and state ~= 'unknown'
end

exports('getObject', function() return Bridge end)

lib.versionCheck('PiotreeQ/p_bridge')