if (Config.Framework == 'auto' and not checkResource('es_extended')) or (Config.Framework ~= 'auto' and Config.Framework ~= 'esx') then
    return
end

while not Bridge do
    Citizen.Wait(0)
end

if Config.Debug then
    lib.print.info('[Vehicles] Loaded: ESX (owned_vehicles)')
end

Bridge.Vehicles = {}
Bridge.Vehicles.tableName = 'owned_vehicles'

local EXTRA_COLUMNS = {
    { name = 'garage_id', definition = 'VARCHAR(64) NULL DEFAULT NULL' },
    { name = 'nickname', definition = 'VARCHAR(64) NULL DEFAULT NULL' },
    { name = 'favorite', definition = 'TINYINT(1) NOT NULL DEFAULT 0' },
    { name = 'mileage', definition = 'FLOAT NOT NULL DEFAULT 0' },
    { name = 'impound_data', definition = 'LONGTEXT NULL DEFAULT NULL' },
}

local function columnExists(column)
    local count = MySQL.scalar.await(
        'SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?',
        { Bridge.Vehicles.tableName, column }
    )
    return (count or 0) > 0
end

Bridge.Vehicles.ensureSchema = function()
    for _, col in ipairs(EXTRA_COLUMNS) do
        if not columnExists(col.name) then
            MySQL.query.await(('ALTER TABLE `%s` ADD COLUMN `%s` %s'):format(Bridge.Vehicles.tableName, col.name, col.definition))
        end
    end
end

CreateThread(function()
    Bridge.Vehicles.ensureSchema()
end)

local function trim(value)
    return (value or ''):match('^%s*(.-)%s*$')
end

local function decodeJson(value)
    if type(value) ~= 'string' or value == '' then return nil end
    local ok, decoded = pcall(json.decode, value)
    return ok and decoded or nil
end

local function toPercent(health)
    return math.max(0, math.min(100, math.floor((health or 1000) / 10)))
end

local function normalize(row)
    local props = decodeJson(row.vehicle) or {}
    local impound = decodeJson(row.impound_data)

    local state = 'out'
    if impound then
        state = 'impounded'
    elseif (row.stored or 0) == 1 then
        state = 'garaged'
    end

    return {
        plate = trim(row.plate),
        owner = row.owner,
        model = props.model,
        props = props,
        garage = row.garage_id,
        state = state,
        fuel = math.max(0, math.min(100, math.floor(props.fuelLevel or 100))),
        engine = toPercent(props.engineHealth),
        body = toPercent(props.bodyHealth),
        mileage = row.mileage or 0,
        nickname = row.nickname,
        favorite = (row.favorite or 0) == 1,
        impound = impound,
    }
end

Bridge.Vehicles.getPlayerVehicles = function(uniqueId)
    local rows = MySQL.query.await('SELECT * FROM `owned_vehicles` WHERE `owner` = ?', { uniqueId }) or {}
    local vehicles = {}
    for _, row in ipairs(rows) do
        vehicles[#vehicles + 1] = normalize(row)
    end
    return vehicles
end

Bridge.Vehicles.getVehicleByPlate = function(plate)
    local row = MySQL.single.await('SELECT * FROM `owned_vehicles` WHERE TRIM(`plate`) = ?', { trim(plate) })
    return row and normalize(row) or nil
end

Bridge.Vehicles.isOwner = function(uniqueId, plate)
    local owner = MySQL.scalar.await('SELECT `owner` FROM `owned_vehicles` WHERE TRIM(`plate`) = ?', { trim(plate) })
    return owner == uniqueId
end

Bridge.Vehicles.setStored = function(plate, garageId, props)
    if props then
        MySQL.update.await('UPDATE `owned_vehicles` SET `stored` = 1, `garage_id` = ?, `vehicle` = ? WHERE TRIM(`plate`) = ?', {
            garageId, json.encode(props), trim(plate),
        })
    else
        MySQL.update.await('UPDATE `owned_vehicles` SET `stored` = 1, `garage_id` = ? WHERE TRIM(`plate`) = ?', {
            garageId, trim(plate),
        })
    end
end

Bridge.Vehicles.setOut = function(plate)
    MySQL.update.await('UPDATE `owned_vehicles` SET `stored` = 0 WHERE TRIM(`plate`) = ?', { trim(plate) })
end

Bridge.Vehicles.saveProps = function(plate, props)
    MySQL.update.await('UPDATE `owned_vehicles` SET `vehicle` = ? WHERE TRIM(`plate`) = ?', { json.encode(props), trim(plate) })
end

Bridge.Vehicles.setNickname = function(plate, nickname)
    MySQL.update.await('UPDATE `owned_vehicles` SET `nickname` = ? WHERE TRIM(`plate`) = ?', { nickname, trim(plate) })
end

Bridge.Vehicles.setFavorite = function(plate, favorite)
    MySQL.update.await('UPDATE `owned_vehicles` SET `favorite` = ? WHERE TRIM(`plate`) = ?', { favorite and 1 or 0, trim(plate) })
end

Bridge.Vehicles.setMileage = function(plate, mileage)
    MySQL.update.await('UPDATE `owned_vehicles` SET `mileage` = ? WHERE TRIM(`plate`) = ?', { mileage, trim(plate) })
end

Bridge.Vehicles.transferOwner = function(plate, targetPlayerId)
    local uniqueId = Bridge.Framework.getUniqueId(targetPlayerId)
    if not uniqueId then return false end

    local affected = MySQL.update.await(
        'UPDATE `owned_vehicles` SET `owner` = ?, `nickname` = NULL, `favorite` = 0 WHERE TRIM(`plate`) = ?',
        { uniqueId, trim(plate) }
    )
    return (affected or 0) > 0
end

Bridge.Vehicles.setImpound = function(plate, impoundData)
    if impoundData then
        MySQL.update.await('UPDATE `owned_vehicles` SET `impound_data` = ?, `stored` = 0 WHERE TRIM(`plate`) = ?', {
            json.encode(impoundData), trim(plate),
        })
    else
        MySQL.update.await('UPDATE `owned_vehicles` SET `impound_data` = NULL, `stored` = 1 WHERE TRIM(`plate`) = ?', { trim(plate) })
    end
end

Bridge.Vehicles.getImpounded = function(uniqueId, location)
    local rows
    if uniqueId then
        rows = MySQL.query.await('SELECT * FROM `owned_vehicles` WHERE `impound_data` IS NOT NULL AND `owner` = ?', { uniqueId })
    else
        rows = MySQL.query.await('SELECT * FROM `owned_vehicles` WHERE `impound_data` IS NOT NULL')
    end

    local vehicles = {}
    for _, row in ipairs(rows or {}) do
        local vehicle = normalize(row)
        if not location or (vehicle.impound and vehicle.impound.location == location) then
            vehicles[#vehicles + 1] = vehicle
        end
    end
    return vehicles
end
