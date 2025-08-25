Config = {} -- [dont change this]

--@param Config.Debug: boolean [true = script will print debug messages, display more info etc]
Config.Debug = false 

--@param Config.Language: string [this will change language in all our scripts which use this bridge]
Config.Language = 'en' -- [en, pl, fr, de, es, it, tr, ru]
-- open ticket on our discord if you want to add your language [discord.gg/piotreqscripts]

--@param Config.Framework: string [set which framework you are using]
Config.Framework = 'auto'
--[[
    auto - will try to detect framework automatically
    qbcore - QBCore Framework
    qbox = QBX Framework
    esx - ESX Framework
    standalone - Standalone (no framework)
    ox - ox_lib Framework
    nd - ND Framework

    -- open ticket on our discord if you want to add your framework [discord.gg/piotreqscripts]
]]

--@param Config.Target: string [set which target system you are using]
Config.Target = 'auto'
--[[
    auto - will try to detect target system automatically
    qb-target - QBCore Target
    ox_target - OX Target [recommended]
    standalone - Standalone (no target, script will try to use markers, doesnt work everytime!)

    -- open ticket on our discord if you want to add your target system [discord.gg/piotreqscripts]
]]

--@param Config.Inventory: string [set which inventory system you are using]
Config.Inventory = 'auto'
--[[
    auto - will try to detect inventory system automatically
    ox_inventory - Overextended Inventory [recommended]
    qb-inventory - QBCore Inventory
    ps-inventory - Project Sloth Inventory
    qs-inventory - Quasar Inventory
    tgiann-inventory - Tgiann Inventory
    codem-inventory - CodeM Inventory
    core_inventory - Core Inventory
    ak47_inventory - Ak47 Inventory
    origen_inventory - Origen Inventory
    standalone - Standalone framework inventory

    -- open ticket on our discord if you want to add your inventory system [discord.gg/piotreqscripts]
]]

--@param Config.Notify: string [set which notification system you are using]
Config.Notify = 'auto'
--[[
    auto - will try to detect notification system automatically
    ox_lib - ox_lib Notifications [recommended]
    esx - ESX Notifications
    qbcore - QBCore Notifications
    brutal - Brutal Notifications
    okok - Okok Notifications

    -- open ticket on our discord if you want to add your notification system [discord.gg/piotreqscripts]
]]

--@param Config.Appearance: string [set which appearance system you are using]
Config.Appearance = 'auto'
--[[
    auto - will try to detect appearance system automatically
    p_appearance - pScripts Appearance
    illenium-appearance - Illenium Appearance
    rcore_clothing - RCore Clothing
    bl_appearance - Bl Appearance
    crm-appearance - CRM Appearance
    esx_skin = ESX Skin
    qb-clothing = QBCore Clothing

    -- open ticket on our discord if you want to add your appearance system [discord.gg/piotreqscripts]
]]

--@param Config.CarKeys: string [set which car keys system you are using]
Config.CarKeys = 'auto'
--[[
    auto - will try to detect car keys system automatically
    p_carkeys - pScripts Car Keys
    qb-vehiclekeys - QBCore Vehicle Keys
    qbx_vehiclekeys - QBX Vehicle Keys
    wasabi_carlock - Wasabi Car Lock
    qs-vehiclekeys - QS Vehicle Keys
    tgiann-hotwire - Tgiann Hotwire
    none - no car keys system

    -- open ticket on our discord if you want to add your car keys system [discord.gg/piotreqscripts]
]]

--@param Config.Dispatch: string [set which dispatch system you are using]
Config.Dispatch = 'auto'
--[[
    auto - will try to detect dispatch system automatically
    ps-dispatch - Project Sloth Dispatch
    piotreq_gpt - pScripts Police MDT Dispatch
    cd_dispatch - CodeM Dispatch
    qs-dispatch - QS Dispatch
    tk_dispatch - TK Dispatch
    lb-tablet - LB-Tablet Dispatch

    -- open ticket on our discord if you want to add your dispatch system [discord.gg/piotreqscripts]
]]