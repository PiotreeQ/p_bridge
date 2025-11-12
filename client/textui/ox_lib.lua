if (Config.TextUI == 'auto' and not checkResource('ox_lib')) or (Config.TextUI ~= 'auto' and Config.TextUI ~= 'ox_lib') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[TextUI] Loaded: ox_lib')
end

Bridge.TextUI = {}

Bridge.TextUI.show = function(text)
    lib.showTextUI(text)
end

Bridge.TextUI.hide = function()
    lib.hideTextUI()
end