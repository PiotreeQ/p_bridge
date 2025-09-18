if (Config.Target == 'auto' and checkResource('ox_target')) or (Config.Target ~= 'auto' and Config.Target ~= 'qb-target') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Target] Loaded: qb-target')
end

Bridge.Target = {}

--@param state: boolean [enable or disable target system]
Bridge.Target.toggleTarget = function(state)
    exports['qb-target']:AllowTargeting(state)
end

--@param options: table [options for the target, see ox_target documentation for details]
-- qb-target doesn't have export for global option so i used box zone, if u have better solution please contact me on discord :)

local globalOptions = {}

Bridge.Target.addGlobal = function(options)
    local name = ('p_bridge_global_%s_%s'):format(GetInvokingResource() or GetCurrentResourceName(), tostring(math.random(11111111, 99999999)))
    for i = 1, #options do
        if options[i].onSelect then
            options[i].action = options[i].onSelect
        end
        if options[i].groups then
            options[i].job = options[i].groups
        end
        if options[i].items then
            options[i].item = options[i].items
        end
    end
    globalOptions[name] = true
    Citizen.CreateThread(function()
        while globalOptions[name] do
            if globalOptions[name] then
                local coords = GetEntityCoords(cache.ped)
                exports['qb-target']:RemoveZone(name)
                Citizen.Wait(100)
                exports['qb-target']:AddBoxZone(name, coords, 1000.0, 1000.0, {
                    name = name,
                    heading = 0,
                    debugPoly = Config.Debug,
                    minZ = coords.z - 30.0,
                    maxZ = coords.z + 30.0,
                }, {
                    options = options,
                    distance = options[1]?.distance or 2.0,
                })
            end
            Citizen.Wait(5000)
        end

        exports['qb-target']:RemoveZone(name)
    end)
end

--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeGlobal = function(optionNames)
    globalOptions[optionNames] = nil
    exports['qb-target']:RemoveZone(optionNames)
end


--@param options: table [options for the target, see qb-target documentation for details]
Bridge.Target.addPlayer = function(options)
    for i = 1, #options do
        if options[i].onSelect then
            options[i].action = options[i].onSelect
        end
        if options[i].groups then
            options[i].job = options[i].groups
        end
        if options[i].items then
            options[i].item = options[i].items
        end
    end
    exports['qb-target']:AddGlobalPlayer({
        options = options,
        distance = options[1]?.distance or 2.0,
    })
end

--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removePlayer = function(optionNames)
    exports['qb-target']:RemoveGlobalPlayer(optionNames)
end

--@param options: table [options for the target, see qb-target documentation for details]
Bridge.Target.addVehicle = function(options)
    for i = 1, #options do
        if options[i].onSelect then
            options[i].action = options[i].onSelect
        end
        if options[i].groups then
            options[i].job = options[i].groups
        end
        if options[i].items then
            options[i].item = options[i].items
        end
    end
    exports['qb-target']:AddGlobalVehicle({
        options = options,
        distance = options[1]?.distance or 2.0,
    })
end

--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeVehicle = function(optionNames)
    exports['qb-target']:RemoveGlobalVehicle(optionNames)
end

--@param models: number | string | number[] | string[] | Array<number | string>
--@param options: table [options for the target, see qb-target documentation for details]
Bridge.Target.addModel = function(models, options)
    for i = 1, #options do
        if options[i].onSelect then
            options[i].action = options[i].onSelect
        end
        if options[i].groups then
            options[i].job = options[i].groups
        end
        if options[i].items then
            options[i].item = options[i].items
        end
    end
    exports['qb-target']:AddTargetModel(models, {
        options = options,
        distance = options[1]?.distance or 2.0,
    })
end

--@param models: number | string | number[] | string[] | Array<number | string>
--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeModel = function(models, optionNames)
    exports['qb-target']:RemoveTargetModel(models, optionNames)
end

--@param netIds: number | number[]
--@param options: table [options for the target, see qb-target documentation for details]
Bridge.Target.addEntity = function(netIds, options)
    local entities = {}
    if type(netIds) == 'number' then
        entities[1] = NetworkGetEntityFromNetworkId(netIds)
    else
        for i = 1, #netIds do
            entities[i] = NetworkGetEntityFromNetworkId(netIds[i])
        end
    end

    for i = 1, #options do
        if options[i].onSelect then
            options[i].action = options[i].onSelect
        end
        if options[i].groups then
            options[i].job = options[i].groups
        end
        if options[i].items then
            options[i].item = options[i].items
        end
    end
    exports['qb-target']:AddTargetEntity(entities, options)
end

--@param netIds: number | number[]
--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeEntity = function(netIds, optionNames)
    local entities = {}
    if type(netIds) == 'number' then
        entities[1] = NetworkGetEntityFromNetworkId(netIds)
    else
        for i = 1, #netIds do
            entities[i] = NetworkGetEntityFromNetworkId(netIds[i])
        end
    end
    exports['qb-target']:RemoveTargetEntity(entities, optionNames)
end


--@param entities: number | number[]
--@param options: table [options for the target, see ox_target documentation for details]
Bridge.Target.addLocalEntity = function(entities, options)
    for i = 1, #options do
        if options[i].onSelect then
            options[i].action = options[i].onSelect
        end
        if options[i].groups then
            options[i].job = options[i].groups
        end
        if options[i].items then
            options[i].item = options[i].items
        end
    end
    exports['qb-target']:AddTargetEntity(entities, options)
end

--@param entities: number | number[]
--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeLocalEntity = function(entities, optionNames)
    exports['qb-target']:RemoveTargetEntity(entities, optionNames)
end

--@param parameters: table [coords: vector3, name?: string, radius?: string, debug?: boolean, drawSprite?: boolean, options: table]
Bridge.Target.addSphereZone = function(parameters)
    for i = 1, #parameters.options do
        if parameters.options[i].onSelect then
            parameters.options[i].action = parameters.options[i].onSelect
        end
        if parameters.options[i].groups then
            parameters.options[i].job = parameters.options[i].groups
        end
        if parameters.options[i].items then
            parameters.options[i].item = parameters.options[i].items
        end
    end
    local invoker = GetInvokingResource() or GetCurrentResourceName()
    local targetName = ('%s_%s_%s'):format(invoker, 'sphere', tostring(math.random(11111111, 99999999)))
    exports['qb-target']:AddCircleZone(targetName, parameters.coords, parameters.radius or 1.5, {
        name = targetName,
        debugPoly = Config.Debug,
        drawSprite = parameters.drawSprite or false,
    }, {
        options = parameters.options,
        distance = parameters.options[1]?.distance or 2.0
    })
    return targetName
end

--@param id: number or string [id of the zone to remove]
Bridge.Target.removeSphereZone = function(id)
    exports['qb-target']:RemoveZone(id)
end