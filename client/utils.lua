while not Bridge do
    Citizen.Wait(0)
end

Bridge.Utils = {}

Bridge.Utils.getNetIdFromEntity = function(entity)
    local timer = 0
    local netId = NetworkGetNetworkIdFromEntity(entity)
    while netId == 0 do
        Citizen.Wait(100)
        netId = NetworkGetNetworkIdFromEntity(entity)
        timer += 1
        if timer >= 20 then
            break
        end
    end

    return netId
end

Bridge.Utils.getEntityFromNetId = function(netId)
    local timer = 0
    local entity = NetworkGetEntityFromNetworkId(netId)
    while entity == 0 do
        Citizen.Wait(100)
        entity = NetworkGetEntityFromNetworkId(netId)
        timer += 1
        if timer >= 20 then
            break
        end
    end

    return entity
end