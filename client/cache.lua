local plyState = LocalPlayer.state

local function isLocalPlayerStateBag(bagName)
    local playerServerId = GetPlayerServerId(PlayerId())
    return bagName == ('player:%s'):format(playerServerId)
end

local function updateDeadState()
    cache:set('dead', (plyState.isDead or plyState.dead) and true or false)
end

AddStateBagChangeHandler('isDead', nil, function(bagName, _, value)
    if not isLocalPlayerStateBag(bagName) then
        return
    end

    cache:set('dead', value and true or false)
end)

AddStateBagChangeHandler('dead', nil, function(bagName, _, value)
    if not isLocalPlayerStateBag(bagName) then
        return
    end

    cache:set('dead', value and true or false)
end)

local activeThread = false

local function startPedCacheThread()
    if activeThread then return end
    activeThread = true

    Citizen.CreateThread(function()
        while cache.ped and cache.ped ~= 0 do
            local sleep = 300
            local playerPed = cache.ped
            local inWater = IsEntityInWater(playerPed)
            local jumping = IsPedJumping(playerPed)
            local ragdoll = IsPedRagdoll(playerPed)
            local cuffed = IsPedCuffed(playerPed)
            local coords = GetEntityCoords(playerPed)
            local inVehicle = IsPedInAnyVehicle(playerPed, false)
            local speed = GetEntitySpeed(playerPed)

            cache:set('water', inWater)
            cache:set('jump', jumping)
            cache:set('coords', coords)
            cache:set('cuffed', cuffed)
            cache:set('ragdoll', ragdoll)

            -- Keep loop lightweight while still reacting quickly during active movement/combat states.
            if inWater or jumping or ragdoll or inVehicle or speed > 1.5 then
                sleep = 300
            end

            updateDeadState()
            Citizen.Wait(sleep)
        end

        activeThread = false
    end)
end

lib.onCache('ped', function(ped)
    if not ped or ped == 0 then return end
    startPedCacheThread()
end)

Citizen.CreateThread(function()
    if cache.ped and cache.ped ~= 0 then
        startPedCacheThread()
    end
end)
