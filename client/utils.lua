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

---@param data table [openInventory('stash', data): { id, owner?, label?, slots?, maxWeight? }]
---@return stashId string, slots number|nil, maxWeight number|nil, label string|nil
-- Resolves the stash id and the size to open it with: the bigger of what the
-- caller passed and what the server registered (registerStash), so a stash that
-- was re-registered bigger opens bigger on inventories that size at open time.
Bridge.Utils.resolveStash = function(data)
    if type(data) ~= 'table' then
        return data, nil, nil, nil
    end
    local stashId = data.owner and ('%s_%s'):format(data.id, data.owner) or data.id
    local ok, reg = pcall(lib.callback.await, 'p_bridge/inventory/getStashInfo', false, stashId)
    reg = ok and type(reg) == 'table' and reg or {}
    local slots = math.max(tonumber(data.slots) or 0, tonumber(reg.slots) or 0)
    local maxWeight = math.max(tonumber(data.maxWeight) or 0, tonumber(reg.weight) or 0)
    return stashId, slots > 0 and slots or nil, maxWeight > 0 and maxWeight or nil, data.label or reg.label
end

Bridge.Debug = function(...)
    if Config.Debug then
        print('[Debug]', ...)
    end
end