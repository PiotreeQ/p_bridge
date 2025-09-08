while not Bridge do
    Citizen.Wait(1)
end

Bridge.Setup = {}
Bridge.Setup.inSetup = false

Bridge.Setup.Point = function()
    if Bridge.Setup.inSetup then
        return
    end

    AddTextEntry("pBridgeHelpNotification", 'Press ~INPUT_ATTACK~ to select point\nPress ~INPUT_VEH_DUCK~ to cancel')
    local currentCoords = nil
    Bridge.Setup.inSetup = true
    Citizen.CreateThread(function()
        while Bridge.Setup.inSetup do
            Citizen.Wait(0)
            local hit, entityHit, coords, _, _ = lib.raycast.fromCamera(511, 4, 15.0)
            if hit and hit ~= 0 then
                currentCoords = coords
            end
        end
    end)
    Citizen.CreateThread(function()
        while Bridge.Setup.inSetup do
            Citizen.Wait(0)
            DisableControlAction(0, 24, true)
            if currentCoords then
                DisplayHelpTextThisFrame("pBridgeHelpNotification", false)
                DrawMarker(
                    28, currentCoords.x, currentCoords.y, currentCoords.z, 
                    0.0, 0.0, 0.0, 
                    0.0, 0.0, 0.0, 
                    0.4, 0.4, 0.4, 
                    255, 0, 0, 150, 
                    false, false, false, false
                )
                if IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24) then
                    Bridge.Setup.inSetup = false
                    lib.setClipboard(('vec3(%.2f, %.2f, %.2f),'):format(currentCoords.x, currentCoords.y, currentCoords.z))
                    Bridge.Notify.showNotify('Point coords has been copied to your clipboard!', 'success')
                end
                if IsControlPressed(0, 73) then
                    Bridge.Setup.inSetup = false
                    Bridge.Notify.showNotify('Point setup has been cancelled!', 'error')
                end
            end
        end
    end)
end

Bridge.Setup.Ped = function()
    if Bridge.Setup.inSetup then
        return
    end

    AddTextEntry("pBridgeHelpNotification", 'Press ~INPUT_ATTACK~ to select point\nPress ~INPUT_CELLPHONE_LEFT~/~INPUT_CELLPHONE_RIGHT~ to rotate ped\nPress ~INPUT_VEH_DUCK~ to cancel')
    local pedModel = lib.requestModel('mp_m_freemode_01')
    local offset = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 1.0, 0.1)
    local currentPed = CreatePed(4, pedModel, offset, 0.0, false, true)
    SetEntityAlpha(currentPed, 200)
    FreezeEntityPosition(currentPed, true)
    SetEntityInvincible(currentPed, true)
    SetEntityCollision(currentPed, false, false)
    SetBlockingOfNonTemporaryEvents(currentPed, true)

    local currentCoords = nil
    Bridge.Setup.inSetup = true
    Citizen.CreateThread(function()
        while Bridge.Setup.inSetup do
            Citizen.Wait(0)
            local hit, entityHit, coords, _, _ = lib.raycast.fromCamera(511, 4, 15.0)
            if hit and hit ~= 0 then
                currentCoords = coords
            end
        end
    end)
    Citizen.CreateThread(function()
        while Bridge.Setup.inSetup do
            Citizen.Wait(0)
            DisableControlAction(0, 24, true)
            if currentCoords then
                DisplayHelpTextThisFrame("pBridgeHelpNotification", false)
                SetEntityCoordsNoOffset(currentPed, currentCoords.x, currentCoords.y, currentCoords.z + 1.0, true, true, true)
                DrawMarker(
                    28, currentCoords.x, currentCoords.y, currentCoords.z, 
                    0.0, 0.0, 0.0, 
                    0.0, 0.0, 0.0, 
                    0.25, 0.25, 0.25, 
                    255, 0, 0, 150, 
                    false, false, false, false
                )
                if IsControlPressed(0, 24) or IsDisabledControlPressed(0, 24) then
                    Bridge.Setup.inSetup = false
                    lib.setClipboard(('vec4(%.2f, %.2f, %.2f, %.2f),'):format(currentCoords.x, currentCoords.y, currentCoords.z, GetEntityHeading(currentPed)))
                    Bridge.Notify.showNotify('Ped coords has been copied to your clipboard!', 'success')
                    DeletePed(currentPed)
                end
                if IsControlPressed(0, 174) or IsDisabledControlPressed(0, 174) then
                    SetEntityHeading(currentPed, GetEntityHeading(currentPed) + 1.0)
                end
                if IsControlPressed(0, 175) or IsDisabledControlPressed(0, 175) then
                    SetEntityHeading(currentPed, GetEntityHeading(currentPed) - 1.0)
                end
                if IsControlPressed(0, 73) then
                    Bridge.Setup.inSetup = false
                    DeletePed(currentPed)
                    Bridge.Notify.showNotify('Ped setup has been cancelled!', 'error')
                end
            end
        end
    end)
end

RegisterNetEvent('p_bridge/client/setup/start', function(setupType)
    if setupType == 'ped' then
        Bridge.Setup.Ped()
    elseif setupType == 'point' then
        Bridge.Setup.Point()
    else
        Bridge.Notify.showNotify('Invalid setup type!', 'error')
    end
end)