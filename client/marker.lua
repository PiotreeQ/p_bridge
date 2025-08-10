while not Bridge do
    Citizen.Wait(1)
end

Bridge.Marker = {}

Bridge.Marker.draw = function(coords, label, color)
    if not coords or not label or not cache.coords then return end

    color = color or {61, 135, 255, 255}
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    local iconScale, textScale = 1.0, 0.25

    RequestStreamedTextureDict('basejumping', false)
    DrawSprite('basejumping', 'arrow_pointer', screenX, screenY - 0.015, 0.015 * iconScale, 0.0225 * iconScale, 180.0, color[1], color[2], color[3], color[4])
    SetTextCentre(true)
    SetTextScale(0.0, textScale)
    SetTextDropShadow(1.0, 0, 0, 0, 100)
    SetTextEntry("STRING")
    AddTextComponentString(('%s \n %sm'):format(label, math.floor(#(cache.coords - coords))))
    DrawText(screenX, screenY)
end