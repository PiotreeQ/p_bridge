if (Config.Inventory == 'auto' and not checkResource('jaksam_inventory')) or (Config.Inventory ~= 'auto' and Config.Inventory ~= 'jaksam_inventory') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Inventory] Loaded: jaksam_inventory')
end

Bridge.Inventory = {}

--@param invType: string [inventory type, only 'player' is routed here]
--@param data: number|table [target player id, or { id = targetId }]
RegisterNetEvent('p_bridge/inventory/openInventory', function(invType, data)
    local _source = source
    if invType ~= 'player' then return end

    local targetId = tonumber(type(data) == 'table' and (data.id or data.owner) or data)
    if not targetId then return end

    exports['jaksam_inventory']:forceOpenInventory(_source, targetId)
end)

--@param playerId: number [existing player id]
--@return items: table [{name: string, amount: number, metadata: table, slot: number}]
Bridge.Inventory.getPlayerItems = function(playerId)
    return exports['jaksam_inventory']:getInventory(playerId)?.items or {}
end

--@param prefix: string [prefix for the drop]
--@param items: table [name: string, count: number, metadata: table]
--@param coords: vector3 [drop coordinates]
Bridge.Inventory.CustomDrop = function(prefix, items, coords)
   lib.print.error('CustomDrop is not supported in jaksam_inventory, please change type in config')
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.addItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['jaksam_inventory']:addItem(playerId, itemName, itemCount, itemMetadata, itemSlot)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemCount: number [amount of items to add]
--@param itemMetadata: table [item metadata, optional]
--@param itemSlot: number [item slot, optional]
Bridge.Inventory.removeItem = function(playerId, itemName, itemCount, itemMetadata, itemSlot)
    exports['jaksam_inventory']:removeItem(playerId, itemName, itemCount, itemMetadata, itemSlot)
end

--@param playerId: number [existing player id]
--@param itemName: string [item name]
--@param itemMetadata: table [item metadata, optional]
--@return count: number [amount of items in inventory]
Bridge.Inventory.getItemCount = function(playerId, itemName, itemMetadata)
    return exports['jaksam_inventory']:getTotalItemAmount(playerId, itemName, itemMetadata)
end

Bridge.Inventory.getItemSlot = function(playerId, slot)
    return exports['jaksam_inventory']:GetSlot(playerId, slot)
end

Bridge.Inventory.createShop = function(shopName, data)
    while GetResourceState('jaksam_inventory') ~= 'started' do
        Citizen.Wait(100)
    end

    Citizen.Wait(100)
    exports['jaksam_inventory']:RegisterShop(shopName, data)
end

---@param itemName: string [item name]
Bridge.Inventory.getItemData = function(itemName)
    return exports['jaksam_inventory']:getStaticItem(itemName)
end

---@param stashId: string [unique stash id]
---@param label: string [stash label]
---@param slots: number [number of slots]
---@param weight: number [max weight]
-- jaksam_inventory creates stashes lazily when they are first opened, so nothing
-- to pre-register here; kept for interface parity with ox_inventory.
Bridge.Inventory.registerStash = function(stashId, label, slots, weight)
    return
end

---@param playerId: number|string [player id or stash id]
---@param slot: number [slot index]
---@param metadata: table [new metadata to write to the slot]
Bridge.Inventory.setMetadata = function(playerId, slot, metadata)
    lib.print.error('setMetadata is not supported in jaksam_inventory, please change type in config')
end

---@param invId: number|string [player id or stash id]
---@return inventory: table|nil [{ items = { name, amount, metadata, slot } }]
Bridge.Inventory.getInventory = function(invId)
    return exports['jaksam_inventory']:getInventory(invId)
end

---@param invId: number|string [player id]
Bridge.Inventory.clearInventory = function(invId)
    local playerId = tonumber(invId)
    if not playerId then
        lib.print.error('clearInventory only supports player ids in jaksam_inventory')
        return
    end

    for _, item in pairs(Bridge.Inventory.getPlayerItems(playerId) or {}) do
        local amount = item.amount or item.count
        if item.name and amount and amount > 0 then
            Bridge.Inventory.removeItem(playerId, item.name, amount, nil, item.slot)
        end
    end
end

---@param event: string [hook name]
---@param cb: function [hook callback]
---@param options: table|nil [hook options]
---@return nil [inventory hooks are ox_inventory only]
Bridge.Inventory.registerHook = function(event, cb, options)
    return nil
end

-- ===========================================================================
-- BENUTZBARE ITEMS (Rechtsklick) - eigene Anpassung, nach Bridge-Updates erneut einfuegen!
-- ===========================================================================
-- Bridge.Framework.registerItem meldet Items nur ueber QBCore.Functions.CreateUseableItem
-- an - diesen Weg loest jaksam beim Benutzen nicht aus. Deshalb jedes Item zusaetzlich
-- direkt per exports.jaksam_inventory:registerUsableItem anmelden.
--
-- Drei Fallen, die zu "Items gehen erst nach Neustart von p_policejob" fuehren:
-- 1. Andere Ressourcen bekommen Bridge per getObject() als KOPIE beim Start. Der Wrapper
--    muss daher sofort (synchron) gesetzt werden, nicht spaeter in einem Thread.
-- 2. jaksam laedt seine Itemliste nach dem Start asynchron. Vorher angemeldete Items
--    werden still verworfen -> pro Item warten, bis getStaticItem es kennt.
-- 3. Startet jaksam_inventory neu, sind alle Anmeldungen weg -> erneut anmelden.
-- 4. jaksam verwirft die Anmeldungen vom Serverstart offenbar NOCH EINMAL, nachdem es
--    fertig geladen hat (getestet: /reitems danach -> Items gehen). Deshalb zeitversetzt
--    nach dem Start und bei jedem Spieler-Login erneut anmelden.

local usableItems = {} -- [itemName] = abgesicherter Callback
local warnedMissing = {}
local originalRegisterItem = nil -- QBCore-Registrierung der Bridge (vor dem Wrapper)
local lastUse = {}
local DEBOUNCE_MS = 500
local ITEM_WAIT_MS = 60000

local function jaksamKnowsItem(itemName)
    local ok, data = pcall(function()
        return exports['jaksam_inventory']:getStaticItem(itemName)
    end)
    return ok and data ~= nil
end

local function registerWithJaksam(itemName)
    CreateThread(function()
        while GetResourceState('jaksam_inventory') ~= 'started' do
            Citizen.Wait(250)
        end

        local timeout = GetGameTimer() + ITEM_WAIT_MS
        while not jaksamKnowsItem(itemName) and GetGameTimer() < timeout do
            Citizen.Wait(500)
        end

        if not jaksamKnowsItem(itemName) then
            if not warnedMissing[itemName] then
                warnedMissing[itemName] = true
                lib.print.error(('[Inventory] Item "%s" ist in jaksam_inventory nicht definiert - '
                    .. 'es kann nicht benutzt werden. Bitte in jaksam_inventory anlegen.'):format(itemName))
            end
            return
        end

        local cb = usableItems[itemName]
        if not cb then return end

        -- QBCore-Weg ebenfalls erneut anmelden: Ein Neustart von p_policejob macht genau
        -- das (zweite Anmeldung, nachdem jaksam fertig geladen ist) - und danach gehen die Items.
        if originalRegisterItem then
            pcall(originalRegisterItem, itemName, cb)
        end

        local ok, err = pcall(function()
            return exports['jaksam_inventory']:registerUsableItem(itemName, cb, 'p_bridge')
        end)

        if not ok then
            lib.print.error(('[Inventory] registerUsableItem("%s") fehlgeschlagen: %s'):format(itemName, tostring(err)))
        elseif Config.Debug then
            lib.print.info(('[Inventory] Benutzbares Item bei jaksam angemeldet: %s'):format(itemName))
        end
    end)
end

local function installUsableItemWrapper()
    local original = Bridge.Framework.registerItem
    originalRegisterItem = original

    Bridge.Framework.registerItem = function(itemName, itemFunction)
        -- Schutz gegen doppelte Ausfuehrung, falls jaksam den QBCore-Weg doch bedient
        local guarded = function(playerId, ...)
            if Config.Debug then
                lib.print.info(('[Inventory] Item benutzt: %s (Spieler %s, Aufruf von %s)'):format(
                    tostring(itemName), tostring(playerId), tostring(GetInvokingResource())))
            end

            local key = ('%s:%s'):format(tostring(playerId), tostring(itemName))
            local now = GetGameTimer()
            if lastUse[key] and (now - lastUse[key]) < DEBOUNCE_MS then return end
            lastUse[key] = now

            local ok, err = pcall(itemFunction, playerId, ...)
            if not ok then
                lib.print.error(('[Inventory] Fehler im Item-Callback "%s": %s'):format(tostring(itemName), tostring(err)))
            end
            return err
        end

        usableItems[itemName] = guarded
        original(itemName, guarded)
        registerWithJaksam(itemName)
    end
end

-- framework/*.lua laedt laut fxmanifest vor inventory/*.lua, Bridge.Framework ist also da
if type(Bridge.Framework) == 'table' and type(Bridge.Framework.registerItem) == 'function' then
    installUsableItemWrapper()
else
    lib.print.error('[Inventory] Bridge.Framework fehlt beim Laden - laeuft qb-core VOR p_bridge? '
        .. 'Benutzbare Items funktionieren so nicht. Startreihenfolge in der server.cfg pruefen.')
end

local lastReregister = 0

--@param reason string [nur fuer das Debug-Log]
--@return number [Anzahl neu angemeldeter Items]
local function reregisterAll(reason)
    lastReregister = GetGameTimer()
    local count = 0
    for itemName in pairs(usableItems) do
        registerWithJaksam(itemName)
        count += 1
    end
    if Config.Debug then
        lib.print.info(('[Inventory] %s Items neu angemeldet (%s)'):format(count, reason))
    end
    return count
end

-- Manuell: alle Items neu anmelden, ohne p_policejob neu zu starten
lib.addCommand('reitems', {
    help = 'Benutzbare Items erneut bei jaksam/QBCore anmelden',
    restricted = 'group.admin',
}, function(source)
    local count = reregisterAll('/reitems')
    lib.print.info(('[Inventory] /reitems: %s Items werden neu angemeldet'):format(count))
    if source > 0 then
        lib.notify(source, { title = ('%s Items neu angemeldet'):format(count), type = 'success' })
    end
end)

-- Zeitversetzt nach dem Start von jaksam erneut anmelden (Falle 4)
local function scheduleDelayedReregister()
    CreateThread(function()
        while GetResourceState('jaksam_inventory') ~= 'started' do
            Citizen.Wait(500)
        end
        for _, delay in ipairs({ 15000, 45000, 120000 }) do
            Citizen.Wait(delay)
            reregisterAll(('%ss nach jaksam-Start'):format(delay // 1000))
        end
    end)
end
scheduleDelayedReregister()

-- Bei jedem Spieler-Login erneut anmelden - spaetestens dann sind die Items sicher aktiv.
-- Hoechstens alle 10 Sekunden, falls mehrere Spieler gleichzeitig laden.
AddEventHandler('p_bridge/server/playerLoaded', function()
    if GetGameTimer() - lastReregister < 10000 then return end
    SetTimeout(2000, function() reregisterAll('Spieler-Login') end)
end)

-- jaksam neu gestartet -> alle Anmeldungen sind weg, sofort und zeitversetzt erneut anmelden
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= 'jaksam_inventory' then return end
    reregisterAll('jaksam neu gestartet')
    scheduleDelayedReregister()
end)