if (Config.ProgressBar == 'auto' and not checkResource('ox_lib')) or (Config.ProgressBar ~= 'auto' and Config.ProgressBar ~= 'ox_lib') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Progress] Loaded: ox_lib')
end

Bridge.Progress = {}

Bridge.Progress.Start = function(data)
    return lib.progressBar({
        duration = data.duration or 5000,
        label = data.label or 'Processing...',
        useWhileDead = data.useWhileDead ~= nil and data.useWhileDead or false,
        canCancel = data.canCancel ~= nil and data.canCancel or true,
        anim = data.anim or nil,
        prop = data.prop or nil,
        disable = data.disable or {move = true, car = true, combat = true}
    })
end

Bridge.Progress.StartCircle = function(data)
    return lib.progressCircle({
        duration = data.duration or 5000,
        position = data.position or 'center',
        label = data.label or 'Processing...',
        useWhileDead = data.useWhileDead ~= nil and data.useWhileDead or false,
        canCancel = data.canCancel ~= nil and data.canCancel or true,
        anim = data.anim or nil,
        prop = data.prop or nil,
        disable = data.disable or {move = true, car = true, combat = true}
    })
end

Bridge.Progress.isActive = function()
    return lib.progressActive()
end

Bridge.Progress.Cancel = function()
    lib.cancelProgress()
end