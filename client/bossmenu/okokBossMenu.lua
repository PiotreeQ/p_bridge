if (Config.BossMenu == 'auto' and not checkResource('okokBossMenu')) or (Config.BossMenu ~= 'auto' and Config.BossMenu ~= 'okokBossMenu') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[BossMenu] Loaded: okokBossMenu')
end

Bridge.BossMenu = {}

Bridge.BossMenu.openMenu = function()
    TriggerEvent('okokBossMenu:openBossMenu')
end