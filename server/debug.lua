while not Bridge do Citizen.Wait(0) end

Bridge.Debug = function(message)
    if Config.Debug then
        local invoker = GetInvokingResource() or GetCurrentResourceName()
        lib.print.info(('[%s] %s'):format(invoker, message))
    end
end