if (Config.ProgressBar == 'auto' and not checkResource('esx_progressbar')) or (Config.ProgressBar ~= 'auto' and Config.ProgressBar ~= 'esx') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: ESX')
end

Bridge.Progress = {}

Bridge.Progress.Start = function(data)
    if Bridge.Progress.active then
        return false
    end

    local p = promise.new()
    Bridge.Progress.active = true
    exports['esx_progressbar']:Progressbar(data.label or 'Processing...', data.duration or 5000, {
        FreezePlayer = data.disable ~= nil, 
        animation = data.anim and {
            type = "anim",
            dict = data.anim?.dict, 
            lib = data.anim?.clip
        } or nil,
        onFinish = function()
        p:resolve(true)
    end, onCancel = function()
        p:resolve(false)
    end})

    Bridge.Progress.active = false
    return Citizen.Await(p)
end

Bridge.Progress.StartCircle = function(data)
    if Bridge.Progress.active then
        return false
    end

    local p = promise.new()
    Bridge.Progress.active = true
    exports['esx_progressbar']:Progressbar(data.label or 'Processing...', data.duration or 5000, {
        FreezePlayer = data.disable ~= nil, 
        animation = data.anim and {
            type = "anim",
            dict = data.anim?.dict, 
            lib = data.anim?.clip
        } or nil,
        onFinish = function()
        p:resolve(true)
    end, onCancel = function()
        p:resolve(false)
    end})

    Bridge.Progress.active = false
    return Citizen.Await(p)
end

Bridge.Progress.isActive = function()
    return Bridge.Progress.active
end

Bridge.Progress.Cancel = function()
    exports['esx_progressbar']:CancelProgressbar()
end