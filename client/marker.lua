while not Bridge do
    Citizen.Wait(1)
end

Bridge.Marker = {}

--- `groundZ` (optional): a line runs from under the label down to that height, onto the thing marked
Bridge.Marker.draw = function(coords, label, color, groundZ)
    if not coords or not label or not cache.coords then return end

    color = color or {61, 135, 255, 255}
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)
    local iconScale, textScale = 1.0, 0.25

    if groundZ and onScreen then
        local groundOn, _, groundY = GetScreenCoordFromWorldCoord(coords.x, coords.y, groundZ)
        if groundOn and groundY > screenY then
            -- starts just under the label's two lines, wherever that is on the way down
            local share = math.min(0.052 / (groundY - screenY), 1.0)
            if share < 1.0 then
                local fromZ = coords.z + (groundZ - coords.z) * share
                DrawLine(coords.x, coords.y, fromZ, coords.x, coords.y, groundZ, color[1], color[2], color[3], color[4])
            end
        end
    end

    RequestStreamedTextureDict('basejumping', false)
    DrawSprite('basejumping', 'arrow_pointer', screenX, screenY - 0.015, 0.015 * iconScale, 0.0225 * iconScale, 180.0, color[1], color[2], color[3], color[4])
    SetTextCentre(true)
    SetTextScale(0.0, textScale)
    SetTextDropShadow(1.0, 0, 0, 0, 100)
    SetTextEntry("STRING")
    AddTextComponentString(('%s \n %sm'):format(label, math.floor(#(cache.coords - coords))))
    DrawText(screenX, screenY)
end