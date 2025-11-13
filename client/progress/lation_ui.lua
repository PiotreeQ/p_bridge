if (Config.ProgressBar == 'auto' and not checkResource('lation_ui')) or (Config.ProgressBar ~= 'auto' and Config.ProgressBar ~= 'lation_ui') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Progress] Loaded: lation_ui')
end

Bridge.Progress = {}

Bridge.Progress.Start = function(data)
    return exports.lation_ui:progressBar({
        label = data.label or 'Processing...',
        duration = data.duration or 5000,
        useWhileDead = data.useWhileDead,
        canCancel = data.canCancel,
        anim = data.anim or nil,
        prop = data.prop or nil,
        disable = data.disable or { move = true, car = true, combat = true }
    })
end

Bridge.Progress.StartCircle = function(data)
    return exports.lation_ui:progressBar({
        label = data.label or 'Processing...',
        duration = data.duration or 5000,
        useWhileDead = data.useWhileDead,
        canCancel = data.canCancel,
        anim = data.anim or nil,
        prop = data.prop or nil,
        disable = data.disable or { move = true, car = true, combat = true }
    })
end

Bridge.Progress.isActive = function()
    return exports.lation_ui:progressActive()
end

Bridge.Progress.Cancel = function()
    exports.lation_ui:cancelProgress()
end