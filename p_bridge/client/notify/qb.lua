if (Config.Notify == 'auto' and not checkResource('qb-core')) or (Config.Notify ~= 'auto' and Config.Notify ~= 'qbcore') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: QB')
end

Bridge.Notify = {}

local QBCore = exports['qb-core']:GetCoreObject()

Bridge.Notify.showNotify = function(message, type)
    QBCore.Functions.Notify(message, type)
end
