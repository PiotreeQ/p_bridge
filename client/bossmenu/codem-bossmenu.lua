if (Config.BossMenu == 'auto' and not checkResource('codem-bossmenu')) or (Config.BossMenu ~= 'auto' and Config.BossMenu ~= 'codem-bossmenu') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[BossMenu] Loaded: codem-bossmenu')
end

Bridge.BossMenu = {}

Bridge.BossMenu.openMenu = function()
    ExecuteCommand('bossmenu')
end