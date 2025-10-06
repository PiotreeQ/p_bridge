if (Config.ProgressBar == 'auto' and not checkResource('qs-interface')) or (Config.ProgressBar ~= 'auto' and Config.ProgressBar ~= 'qs-interface') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Progress] Loaded: qs-interface')
end

Bridge.Progress = {}
Bridge.Progress.isActive = false

Bridge.Progress.Start = function(data)
    if data.canCancel == nil then
        data.canCancel = true
    end

    if data.useWhileDead == nil then
        data.useWhileDead = false
    end

    Bridge.Progress.isActive = true
    local success = exports['qs-interface']:ProgressBar({
        duration = data.duration or 5000,
        label = data.label or 'Processing...',
        useWhileDead = data.useWhileDead,
        canCancel = data.canCancel,
        anim = data.anim or nil,
        prop = data.prop or nil,
        disable = data.disable or {move = true, car = true, combat = true}
    })
    Bridge.Progress.isActive = false
end

Bridge.Progress.StartCircle = function(data)
    if data.canCancel == nil then
        data.canCancel = true
    end

    if data.useWhileDead == nil then
        data.useWhileDead = false
    end

    Bridge.Progress.isActive = true
    local success = exports['qs-interface']:ProgressBar({
        duration = data.duration or 5000,
        label = data.label or 'Processing...',
        useWhileDead = data.useWhileDead,
        canCancel = data.canCancel,
        anim = data.anim or nil,
        prop = data.prop or nil,
        disable = data.disable or {move = true, car = true, combat = true}
    })
    Bridge.Progress.isActive = false
end

Bridge.Progress.isActive = function()
    return Bridge.Progress.isActive
end

Bridge.Progress.Cancel = function()
    -- no export to cancel the progress bar
end