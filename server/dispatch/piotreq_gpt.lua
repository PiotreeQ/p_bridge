if (Config.Dispatch == 'auto' and not checkResource('piotreq_gpt')) or (Config.Dispatch ~= 'auto' and Config.Dispatch ~= 'piotreq_gpt') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Notify] Loaded: piotreq_gpt')
end

Bridge.Dispatch = {}

--@param data: table
--@param data.title: string
--@param data.code: string
--@param data.icon?: string
--@param data.blip?: [scale: number, sprite: number, category: number, color: number, hidden: boolean, priority: number, short: boolean, alpha: number, name: string]
--@param data.priority?: 'low' | 'medium' | 'high'
--@param data.maxOfficers?: number [maximum number of officers that can answer the alert]
--@param data.time?: number [time in minutes how long the alert should be active]
--@param data.notify?: number [notify time]

Bridge.Dispatch.SendAlert = function(playerId, data)
    exports['piotreq_gpt']:SendAlert(playerId, {
        title = data.title or 'No Title',
        code = data.code or 'No Code',
        icon = data.icon or 'fa-solid fa-bell',
        info = {
            {icon = 'fa-solid fa-road', isStreet = true},
        },
        blip = { -- optional
            scale = data.blip?.scale or 1.1,
            sprite = data.blip?.sprite or 1,
            category = data.blip?.category or 1,
            color = data.blip?.color or 1,
            hidden = data.blip?.hidden or false,
            priority = data.blip?.priority or 5,
            short = data.blip?.short or true,
            alpha = data.blip?.alpha or 200,
            name = data.blip?.name or "Blip Name"
        },
        type = data.priority == 'high' and 'risk' or 'normal', -- default normal
        canAnswer = data.code == '911' and true or false, -- default false
        maxOfficers = data.maxOfficers or 4, -- default 4
        time = data.time or 10,
        notifyTime = data.notify or 8000,
    })
end