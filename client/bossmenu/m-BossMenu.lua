if (Config.BossMenu == 'auto' and not checkResource('m-BossMenu')) or (Config.BossMenu ~= 'auto' and Config.BossMenu ~= 'm-BossMenu') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[BossMenu] Loaded: m-BossMenu')
end

Bridge.BossMenu = {}

-- m-BossMenu exposes no client export/event to open the menu, only its command
-- (`command = "bossmenu"` in its config). Change this if you renamed the command.
Bridge.BossMenu.openMenu = function()
    ExecuteCommand('bossmenu')
end
