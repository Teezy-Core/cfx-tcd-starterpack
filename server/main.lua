local Core, Framework = GetCore()

lib.locale()

-- [[ FUNCTIONS ]] --
local function updatePlayerData(license, received)
    local query = "UPDATE tcd_starterpack SET received = ?, date_received = ? WHERE identifier = ?"
    local params = { received, os.date("%Y-%m-%d %H:%M:%S", os.time()), license }

    ExecuteQuery(query, params, function()
        debugPrint("success", "Player data has been updated")
    end)
end

local function initializeStarterPackData(license)
    local query = "SELECT * FROM tcd_starterpack WHERE identifier = ?"
    local params = { license }

    local response = FetchQuery(query, params)

    if response[1] then
        return true
    else
        local insertQuery = "INSERT INTO tcd_starterpack (identifier, received, date_received) VALUES (?, ?, ?)"
        local insertParams = { license, 0, nil }

        ExecuteQuery(insertQuery, insertParams, function()
            debugPrint("success", "Player has received the starter pack")
        end)
        return false
    end
end

local function giveItems(src, type)
    if not type then return end

    local data = Config.StarterPackItems[type]

    if not data then
        error("Invalid starter pack type, please check your config.lua")
        return
    end

    for _, item in ipairs(data) do
        debugPrint("info", "Giving item: " .. item.item .. " x" .. item.amount)

        if Config.InventoryResource == "ox_inventory" and GetResourceState(Config.InventoryResource) == 'started' then
            local success, response = exports.ox_inventory:AddItem(src, item.item, item.amount)
            if not success then
                if response == 'invalid_item' then
                    error("Invalid item: " .. item.item)
                end
            end
        elseif Config.InventoryResource == "qb-inventory" and GetResourceState(Config.InventoryResource) == 'started' then
            local itemInfo = Core.Shared.Items[item.item]

            if not itemInfo then
                error("Invalid item: " .. item.item .. " make sure the item exists in your inventory resource")
            end

            exports['qb-inventory']:AddItem(src, item.item, item.amount, false, false, 'tcd-starterpack')
            TriggerClientEvent('qb-inventory:client:ItemBox', src, itemInfo, 'add')
        elseif Config.InventoryResource == "ps-inventory" and GetResourceState(Config.InventoryResource) == 'started' then
            local itemInfo = Core.Shared.Items[item]

            if not itemInfo then
                error("Invalid item: " .. item.item .. " make sure the item exists in your inventory resource")
            end

            exports['ps-inventory']:AddItem(src, item.item, item.amount, false, false, 'tcd-starterpack')
            TriggerClientEvent('ps-inventory:client:ItemBox', src, itemInfo, 'add')
        elseif Config.InventoryResource == "qs-inventory" and GetResourceState(Config.InventoryResource) == 'started' then
            exports['qs-inventory']:AddItem(src, item.item, item.amount)
        else
            error("Inventory resource not found, please set your inventory resource in the config.lua")
        end
    end
end

local function giveVehicle(identifier, data, stored)
    if Framework == "esx" then
        local query_parking = "SELECT parking FROM owned_vehicles LIMIT 1"
        local response = FetchQuery(query_parking)
        if not response[1] then
            error("Parking column not found in the database")

            local query = "ALTER TABLE owned_vehicles ADD COLUMN parking VARCHAR(255) DEFAULT NULL"
            ExecuteQuery(query)

            print("Parking column has been added to the database")
            return
        end

        local query = "INSERT INTO owned_vehicles (owner, plate, vehicle, parking, stored) VALUES (?, ?, ?, ?, ?)"
        local params = { identifier, data.props.plate, json.encode(data.props), data.parking, stored }

        InsertQuery(query, params)
    elseif Framework == "qbc" then
        local Player = Framework == "esx" and Core.GetPlayerFromId(source) or Core.Functions.GetPlayer(source)
        local citizenId = Framework == "esx" and Player.identifier or Player.PlayerData.citizenid

        local query =
        "INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage) VALUES (?, ?, ?, ?, ?, ?, ?)"
        local params = { Player.PlayerData.license, citizenId, data.vehicle_name, GetHashKey(data.vehicle_name), json
            .encode(data.props), data.props.plate, data.parking }

        InsertQuery(query, params, function(rowsAffected)
            if rowsAffected > 0 then
                debugPrint("success", "Vehicle has been added to the database")
            else
                error("Failed to add vehicle to the database")
            end
        end)
    end
end
-- [[ END FUNCTIONS ]] --

-- [[ EVENTS ]] --
RegisterNetEvent('cfx-tcd-starterpack:Server:ClaimVehicle', function(vehicleData)
    local src = source
    local Player = Framework == "esx" and Core.GetPlayerFromId(src) or Core.Functions.GetPlayer(src)
    local identifier = Framework == "esx" and Player.identifier or Player.PlayerData.citizenid

    lib.callback("cfx-tcd-starterpack:CB:CheckReceivingRadius", src, function(result)
        if not result then
            debugPrint("error", "Player is not in the receiving radius")
            Config.Notification(locale("not_near_receiving_point"), "error", false, src)
            return
        end

        giveVehicle(identifier, vehicleData, false)
    end)
end)

RegisterNetEvent('cfx-tcd-starterpack:Server:ClaimStarterpack', function(starterpack_type)
    local src = source
    local license = GetPlayerLicense(src)

    if HasReceivedStarterPack(license) then
        debugPrint("info", "Player has already received the starter pack")
        Config.Notification(locale("already_received"), "error", false, src)
        return
    end

    lib.callback("cfx-tcd-starterpack:CB:CheckReceivingRadius", src, function(result)
        if not result then
            debugPrint("error", "Player is not in the receiving radius")
            Config.Notification(locale("not_near_receiving_point"), "error", false, src)
            return
        end

        if starterpack_type then
            giveItems(src, starterpack_type)
        end
        
    end)

    updatePlayerData(license, true)
    SendDiscordLog(src, "Player has received their starter pack")
    Config.Notification(locale("success"), "success", true, src)
end)
-- [[ END EVENTS ]] --


-- [[ CALLBACKS ]] --
lib.callback.register('cfx-tcd-starterpack:CB:CheckPlayer', function(source)
    local license = GetPlayerLicense(source)

    initializeStarterPackData(license)
    return HasReceivedStarterPack(license)
end)
-- [[ END CALLBACKS ]] --

-- [[ COMMANDS ]] --
if Config.CommandConfig.enable then
    lib.addCommand(Config.CommandConfig.command, {
        help = Config.CommandConfig.command_help,
    }, function(source, args, raw)
        local src = source
        local license = GetPlayerLicense(src)

        initializeStarterPackData(license)

        if HasReceivedStarterPack(license) then
            debugPrint("info", "Player has already received the starter pack")
            Config.Notification(locale("already_received"), "error", true, src)
            return
        end

        lib.callback("cfx-tcd-starterpack:CB:CheckReceivingRadius", src, function(result)
            if not result then
                debugPrint("error", "Player is not in the receiving radius")
                Config.Notification(locale("not_near_receiving_point"), "error", true, src)
                return
            end

            giveItems(src, Config.CommandConfig.starterpack_type)
            if Config.CommandConfig.starter_vehicle.enable then
                TriggerClientEvent('cfx-tcd-starterpack:Client:GiveStarterVehicle', src,
                    Config.CommandConfig.starter_vehicle)
            end

            updatePlayerData(license, true)
            SendDiscordLog(src, "Player has received their starter pack")
            Config.Notification(locale("success"), "success", true, src)
        end)
    end)
end

CheckTable()
if Config.CheckVersion then
    CheckForUpdates()
end