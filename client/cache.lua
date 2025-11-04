local plyState = LocalPlayer.state
Citizen.CreateThread(function()
    while true do
        local playerPed = cache.ped
        cache:set('water', IsEntityInWater(playerPed) and true or false)
        cache:set('jump', IsPedJumping(playerPed) and true or false)
        cache:set('coords', GetEntityCoords(playerPed))
        cache:set('dead', plyState.isDead or plyState.dead)
        cache:set('cuffed', IsPedCuffed(playerPed))
        cache:set('ragdoll', IsPedRagdoll(playerPed))
        Citizen.Wait(500)
    end
end)