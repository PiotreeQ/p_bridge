if (Config.Target == 'auto' and not checkResource('ox_target')) or (Config.Target ~= 'auto' and Config.Target ~= 'ox_target') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Target] Loaded: ox_target')
end

Bridge.Target = {}

-- for storing targets to remove later
Bridge.Target.targets = {}

--@param state: boolean [enable or disable target system]
Bridge.Target.toggleTarget = function(state)
    exports['ox_target']:disableTargeting(not state)
end

--@param options: table [options for the target, see ox_target documentation for details]
Bridge.Target.addGlobal = function(options)
    local resourceName = GetInvokingResource() or cache.resource
    for i = 1, #options, 1 do
        Bridge.Target.targets[resourceName] = Bridge.Target.targets[resourceName] or {}
        table.insert(Bridge.Target.targets[resourceName], {type = 'global', name = options[i].name})
    end
    exports['ox_target']:addGlobalOption(options)
end

--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeGlobal = function(optionNames)
    exports['ox_target']:removeGlobalOption(optionNames)
end

--@param options: table [options for the target, see ox_target documentation for details]
Bridge.Target.addPlayer = function(options)
    local resourceName = GetInvokingResource() or cache.resource
    for i = 1, #options, 1 do
        Bridge.Target.targets[resourceName] = Bridge.Target.targets[resourceName] or {}
        table.insert(Bridge.Target.targets[resourceName], {type = 'player', name = options[i].name})
    end
    exports['ox_target']:addGlobalPlayer(options)
end

--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removePlayer = function(optionNames)
    exports['ox_target']:removeGlobalPlayer(optionNames)
end

--@param options: table [options for the target, see ox_target documentation for details]
Bridge.Target.addVehicle = function(options)
    local resourceName = GetInvokingResource() or cache.resource
    for i = 1, #options, 1 do
        Bridge.Target.targets[resourceName] = Bridge.Target.targets[resourceName] or {}
        table.insert(Bridge.Target.targets[resourceName], {type = 'vehicle', name = options[i].name})
    end
    exports['ox_target']:addGlobalVehicle(options)
end

--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeVehicle = function(optionNames)
    exports['ox_target']:removeGlobalVehicle(optionNames)
end

--@param models: number | string | number[] | string[] | Array<number | string>
--@param options: table [options for the target, see ox_target documentation for details]
Bridge.Target.addModel = function(models, options)
    local resourceName = GetInvokingResource() or cache.resource
    for i = 1, #options, 1 do
        Bridge.Target.targets[resourceName] = Bridge.Target.targets[resourceName] or {}
        table.insert(Bridge.Target.targets[resourceName], {type = 'model', model = models, name = options[i].name})
    end
    exports['ox_target']:addModel(models, options)
end

--@param models: number | string | number[] | string[] | Array<number | string>
--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeModel = function(models, optionNames)
    exports['ox_target']:removeModel(models, optionNames)
end

--@param netIds: number | number[]
--@param options: table [options for the target, see ox_target documentation for details]
Bridge.Target.addEntity = function(netIds, options)
    local resourceName = GetInvokingResource() or cache.resource
    for i = 1, #options, 1 do
        Bridge.Target.targets[resourceName] = Bridge.Target.targets[resourceName] or {}
        table.insert(Bridge.Target.targets[resourceName], {type = 'netEntity', netIds = netIds, name = options[i].name})
    end
    exports['ox_target']:addEntity(netIds, options)
end

--@param netIds: number | number[]
--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeEntity = function(netIds, optionNames)
    exports['ox_target']:removeEntity(netIds, optionNames)
end


--@param entities: number | number[]
--@param options: table [options for the target, see ox_target documentation for details]
Bridge.Target.addLocalEntity = function(entities, options)
    local resourceName = GetInvokingResource() or cache.resource
    for i = 1, #options, 1 do
        Bridge.Target.targets[resourceName] = Bridge.Target.targets[resourceName] or {}
        table.insert(Bridge.Target.targets[resourceName], {type = 'localEntity', entities = entities, name = options[i].name})
    end
    exports['ox_target']:addLocalEntity(entities, options)
end

--@param entities: number | number[]
--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeLocalEntity = function(entities, optionNames)
    exports['ox_target']:removeLocalEntity(entities, optionNames)
end

--@param parameters: table [coords: vector3, name?: string, radius?: string, debug?: boolean, drawSprite?: boolean, options: table]
Bridge.Target.addSphereZone = function(parameters)
    local resourceName = GetInvokingResource() or cache.resource
    local targetId = exports['ox_target']:addSphereZone(parameters)
    for i = 1, #parameters.options, 1 do
        Bridge.Target.targets[resourceName] = Bridge.Target.targets[resourceName] or {}
        table.insert(Bridge.Target.targets[resourceName], {type = 'sphereZone', id = targetId})
    end
    return targetId
end

--@param id: number or string [id of the zone to remove]
Bridge.Target.removeSphereZone = function(id)
    exports['ox_target']:removeZone(id)
end

AddEventHandler('onClientResourceStop', function(resourceName)
    if Bridge.Target.targets[resourceName] then
        for _, target in pairs(Bridge.Target.targets[resourceName]) do
            if target.type == 'model' then
                Bridge.Target.removeModel(target.model, target.name)
            elseif target.type == 'netEntity' then
                Bridge.Target.removeEntity(target.netIds, target.name)
            elseif target.type == 'localEntity' then
                Bridge.Target.removeLocalEntity(target.entities, target.name)
            elseif target.type == 'player' then
                Bridge.Target.removePlayer(target.name)
            elseif target.type == 'vehicle' then
                Bridge.Target.removeVehicle(target.name)
            elseif target.type == 'sphereZone' then
                Bridge.Target.removeSphereZone(target.id)
            elseif target.type == 'global' then
                Bridge.Target.removeGlobal(target.name)
            end
        end
        Bridge.Target.targets[resourceName] = nil
    end
end)