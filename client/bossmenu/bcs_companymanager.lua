if (Config.BossMenu == 'auto' and not checkResource('bcs_companymanager')) or (Config.BossMenu ~= 'auto' and Config.BossMenu ~= 'bcs_companymanager') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[BossMenu] Loaded: bcs_companymanager')
end

Bridge.BossMenu = {}

Bridge.BossMenu.openMenu = function()
    local playerJob = Bridge.Framework.fetchPlayerJob()
    if not playerJob or not playerJob.name then
        lib.print.error('No job found for the player')
        return
    end

    TriggerEvent('CompanyManager:client:OpenBossMenu', playerJob.name)
end
