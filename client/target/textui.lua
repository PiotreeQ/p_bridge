if Config.Target ~= 'textui' then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Target] Loaded: textui')
end

Bridge.Target = {}

Bridge.Target.targets = {}
Bridge.Target.isDisabled = false

-- Didnt get better solution for making textui works like a target system

local function targetToContext(options, entity)
    local contextOptions = {}
    for i = 1, #options, 1 do
        table.insert(contextOptions, {
            title = options[i].label,
            icon = options[i].icon or '',
            onSelect = function()
                options[i].onSelect(entity)
            end,
            disabled = options[i].canInteract and not options[i].canInteract(entity) or false,
        })
    end
    return contextOptions
end

local function getClosestEntity(entityType, distance, filter)
    local coords = GetEntityCoords(cache.ped)
    if entityType == 'player' then
        local plyId, plyPed, plyCoords = lib.getClosestPlayer(coords, distance, false)
        if plyPed and plyPed ~= 0 then
            return plyPed
        end
    elseif entityType == 'vehicle' then
        local vehicle, vehCoords = lib.getClosestVehicle(coords, distance, false)
        if vehicle and vehicle ~= 0 then
            return vehicle
        end
    else
        local objects = lib.getNearbyObjects(coords, distance)
        for _, obj in pairs(objects) do
            local objInfo = entityType == 'model' and joaat(GetEntityModel(obj.object)) or NetworkGetEntityFromNetworkId(obj.object)
            if type(filter) == 'string' then
                if objInfo == joaat(filter) then
                    return obj.object
                end
            elseif type(filter) == 'number' then
                if objInfo == filter then
                    return obj.object
                end
            elseif type(filter) == 'table' then
                if entityType == 'model' then
                    for _, model in pairs(filter) do
                        if objInfo == joaat(model) then
                            return obj.object
                        end
                    end
                else
                    for _, netId in pairs(filter) do
                        if objInfo == netId then
                            return obj.object
                        end
                    end
                end
            end
        end
    end
end

local lastEntity, lastOptions = nil
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1500)
        if Bridge.Target.isDisabled then
            goto skip
        end

        for _, target in pairs(Bridge.Target.targets) do
            local entity = getClosestEntity(target.type, 5.0, target.models or target.netIds or target.entities)
            if entity and (not lastEntity or entity ~= lastEntity) then
                lib.showTextUI('Press E to interact')
                lastEntity = entity
                lastOptions = target.options
            elseif lastEntity then
                lastEntity = nil
                lib.hideTextUI()
            end
        end
        ::skip::
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if Bridge.Target.isDisabled then
            goto skip
        end

        if lastEntity then
            sleep = 1
            if IsControlJustReleased(0, 38) then
                local invoker = GetInvokingResource() or cache.resource
                local randomId = ('%s_%s'):format(invoker, math.random(1111111, 9999999))
                lib.registerContext({
                    id = randomId,
                    title = 'Interaction',
                    options = targetToContext(lastOptions, lastEntity)
                })
                lib.showContext(randomId)
            end
        end
        ::skip::
        Citizen.Wait(sleep)
    end
end)

--@param state: boolean [enable or disable target system]
Bridge.Target.toggleTarget = function(state)
    Bridge.Target.isDisabled = not state
end

Bridge.Target.addGlobal = function(options)
    return 'textUI' -- dont touch it
end

--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeGlobal = function(optionNames)
    -- dont touch it, scripts use text ui instead
end

--@param options: table [options for the target, see ox_target documentation for details]
Bridge.Target.addPlayer = function(options)
    local resourceName = GetInvokingResource() or cache.resource
    table.insert(Bridge.Target.targets, {
        type = 'player',
        options = options
    })
end

--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removePlayer = function(optionNames)
    -- exports['ox_target']:removeGlobalPlayer(optionNames)
end

--@param options: table [options for the target, see ox_target documentation for details]
Bridge.Target.addVehicle = function(options)
    local resourceName = GetInvokingResource() or cache.resource
    table.insert(Bridge.Target.targets, {
        type = 'vehicle',
        options = options
    })
end

--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeVehicle = function(optionNames)
    -- exports['ox_target']:removeGlobalVehicle(optionNames)
end

--@param models: number | string | number[] | string[] | Array<number | string>
--@param options: table [options for the target, see ox_target documentation for details]
Bridge.Target.addModel = function(models, options)
    local resourceName = GetInvokingResource() or cache.resource
    table.insert(Bridge.Target.targets, {
        type = 'model',
        models = models,
        options = options
    })
end

--@param models: number | string | number[] | string[] | Array<number | string>
--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeModel = function(models, optionNames)
end

--@param netIds: number | number[]
--@param options: table [options for the target, see ox_target documentation for details]
Bridge.Target.addEntity = function(netIds, options)
    local resourceName = GetInvokingResource() or cache.resource
    table.insert(Bridge.Target.targets, {
        type = 'netEntity',
        netIds = netIds,
        options = options
    })
end

--@param netIds: number | number[]
--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeEntity = function(netIds, optionNames)
    -- exports['ox_target']:removeEntity(netIds, optionNames)
end


--@param entities: number | number[]
--@param options: table [options for the target, see ox_target documentation for details]
Bridge.Target.addLocalEntity = function(entities, options)
    local resourceName = GetInvokingResource() or cache.resource
    table.insert(Bridge.Target.targets, {
        type = 'localEntity',
        entities = entities,
        options = options
    })
end

--@param entities: number | number[]
--@param optionNames: string | string[] [names of the options to remove]
Bridge.Target.removeLocalEntity = function(entities, optionNames)
    -- exports['ox_target']:removeLocalEntity(entities, optionNames)
end

--@param parameters: table [coords: vector3, name?: string, radius?: string, debug?: boolean, drawSprite?: boolean, options: table]
Bridge.Target.addSphereZone = function(parameters)
    local point = lib.points.new({
        coords = parameters.coords, 
        distance = parameters.radius and parameters.radius + 1.0 or 3.0,
    })

    local invoker = GetInvokingResource() or cache.resource
    local randomId = ('%s_%s'):format(invoker, math.random(1111111, 9999999))
 
    function point:onEnter()
        lib.showTextUI('Press E to interact')
    end
 
    function point:onExit()
        lib.hideTextUI()
    end

    function point:nearby()
        if IsControlJustReleased(0, 38) then
            lib.registerContext({
                id = randomId,
                title = 'Interaction',
                options = targetToContext(parameters.options, nil)
            })
            lib.showContext(randomId)
        end
    end

    return point
end

--@param id: number or string [id of the zone to remove]
Bridge.Target.removeSphereZone = function(id)
    id:remove()
end