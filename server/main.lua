local Core, Framework = GetCore()

lib.locale()

-- [[ FUNCTIONS ]] --
local function initializeStarterPackData(license)
    local query = "SELECT * FROM tcd_starterpack WHERE identifier = ?"
    local params = { license }

    local response = FetchQuery(query, params)

    if response[1] then
        return true
    else
        local insertQuery = "INSERT INTO tcd_starterpack (identifier, received, date_received, name) VALUES (?, ?, ?, ?)"
        local insertParams = { license, 0, nil, "Unknown" }
        
        ExecuteQuery(insertQuery, insertParams, function()
            debugPrint("success", "Player has received the starter pack")
        end)
        return false
    end
end

local function sendDiscordLog(source, desc)
    local time = os.date("%c")
    local webhook = DiscordConfig.webhook
    local title = DiscordConfig.title
    local thumbnail_url = DiscordConfig.thumbnail
    local color = DiscordConfig.color

    if not webhook then
        warn("Webhook not found, please set your webhook in the server/functions/discordlog.lua")
        return
    end

    debugPrint("info", "Sending Discord log")

    local embed = {
        {
            ["author"] = {
                ["name"] = "Teezy Core Development",
                ["icon_url"] = "https://i.imgur.com/6s82WUZ.png",
            },
            ["color"] = tonumber(color),
            ["title"] = title,
            ["description"] = desc,
            ["thumbnail"] = {
                ["url"] = thumbnail_url,
            },
            ["fields"] = {
                {
                    ["name"] = "Player: ",
                    ["value"] = "```" .. GetPlayerName(source) .. "```",
                    ["inline"] = true
                },
                {
                    ["name"] = "Server ID: ",
                    ["value"] = "```" .. source .. "```",
                    ["inline"] = true
                },
                {
                    ["name"] = "License ID:",
                    ["value"] = "```" .. GetPlayerLicense(source) .. "```",
                    ["inline"] = false
                },
                {
                    ["name"] = "Time",
                    ["value"] = time,
                    ["inline"] = true
                },
            },
            ["timestamp"] = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            ["footer"] = {
                ["text"] = "Powered by TCD",
                ["icon_url"] = "https://i.imgur.com/6s82WUZ.png",
            },
        }
    }
    PerformHttpRequest(webhook,
        function(err, text, headers) end, 'POST', json.encode({ embeds = embed }),
        { ['Content-Type'] = 'application/json' })
end

local function GetPlayerName(source)
    local Player = Framework == "esx" and Core.GetPlayerFromId(source) or Core.Functions.GetPlayer(source)
    return Framework == "esx" and Player.getName() or Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname or "Unknown"
end

local function updatePlayerData(name, license, received)
    local dateReceived = os.date("%Y-%m-%d %H:%M:%S")

    local query = "UPDATE tcd_starterpack SET received = ?, date_received = ?, name = ? WHERE identifier = ?"
    local params = { received, dateReceived, name, license }

    ExecuteQuery(query, params, function(success)
        if success then
            debugPrint("success", ("Player data has been updated: Name: %s, License: %s, Received: %s, Date: %s"):format(name, license, tostring(received), dateReceived))
        else
            debugPrint("error", ("Failed to update player data for License: %s"):format(license))
        end
    end)
end

local function giveVehicle(identifier, data, stored)
    if Framework == "esx" then
        local query = "INSERT INTO owned_vehicles (owner, plate, vehicle, stored) VALUES (?, ?, ?, ?)"
        local params = { identifier, data.props.plate, json.encode(data), stored }

        InsertQuery(query, params)
    elseif Framework == "qbc" then
        local Player = Framework == "esx" and Core.GetPlayerFromId(source) or Core.Functions.GetPlayer(source)
        local citizenId = Framework == "esx" and Player.identifier or Player.PlayerData.citizenid

        local query =
        "INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage) VALUES (?, ?, ?, ?, ?, ?, ?)"
        local params = { Player.PlayerData.license, citizenId, data.vehicle_name, GetHashKey(data.vehicle_name), json
            .encode(data.props), data.props.plate }

        InsertQuery(query, params, function(rowsAffected)
            if rowsAffected > 0 then
                debugPrint("success", "Vehicle has been added to the database")
            else
                error("Failed to add vehicle to the database")
            end
        end)
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
            exports['qb-inventory']:AddItem(src, item.item, item.amount, false, false, 'tcd-starterpack')
            TriggerClientEvent('qb-inventory:client:ItemBox', src, Core.Shared.Items[item.item], 'add')
        elseif Config.InventoryResource == "ps-inventory" and GetResourceState(Config.InventoryResource) == 'started' then
            exports['ps-inventory']:AddItem(src, item.item, item.amount, false, false, 'tcd-starterpack')
            TriggerClientEvent('ps-inventory:client:ItemBox', src, Core.Shared.Items[item.item], 'add')
        elseif Config.InventoryResource == "qs-inventory" and GetResourceState(Config.InventoryResource) == 'started' then
            exports['qs-inventory']:AddItem(src, item.item, item.amount)
        elseif Config.InventoryResource == "codem-inventory" and GetResourceState(Config.InventoryResource) == 'started' then
            exports['codem-inventory']:AddItem(src, item.item, item.amount)
        else
            error("Inventory resource not found, please set your inventory resource in the config.lua")
        end
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
            debugPrint("info", "Player has received the starter pack type: "..starterpack_type)
            giveItems(src, starterpack_type)
        end
        
    end)

    updatePlayerData(GetPlayerName(src), license, true)
    sendDiscordLog(src, "Player has received their starter pack")
    Config.Notification(locale("success"), "success", true, src)
end)

RegisterNetEvent('cfx-tcd-starterpack:Server:UpdateStarterPack', function(identifier, type)
    if type == 'reset' then
        local query = "UPDATE tcd_starterpack SET received = ? WHERE identifier = ?"
        local params = { 0, identifier }

        ExecuteQuery(query, params, function()
            debugPrint("success", "Player data has been updated")
        end)
    elseif type == 'delete' then
        local query = "DELETE FROM tcd_starterpack WHERE identifier = ?"
        local params = { identifier }

        ExecuteQuery(query, params, function()
            debugPrint("success", "Player data has been deleted")
        end)
    end
end)

-- [[ END EVENTS ]] --

-- [[ CALLBACKS ]] --
lib.callback.register('cfx-tcd-starterpack:CB:CheckPlayer', function(source)
    local license = GetPlayerLicense(source)

    initializeStarterPackData(license)
    return HasReceivedStarterPack(license)
end)
-- [[ END CALLBACKS ]] --

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

            updatePlayerData(GetPlayerName(src), license, true)
            sendDiscordLog(src, "Player has received their starter pack")
            Config.Notification(locale("success"), "success", true, src)
        end)
    end)
end

lib.addCommand(Config.CheckPacksCommand, {
    help = 'Check all players who have received the starter pack',
    restricted = 'group.admin'
}, function(source, args, raw)
    local src = source

    local query = "SELECT * FROM tcd_starterpack"
    local response = FetchQuery(query, {})

    for _, data in ipairs(response) do
        if type(data.date_received) == "number" then
            data.date_received = os.date("%Y-%m-%d %H:%M:%S", math.floor(data.date_received / 1000))
        else
            data.date_received = data.date_received
        end

        if data.name == "" then
            data.name = "Unknown" -- If you have the previous version of the script, this column is new, so it will be empty for old records
        end
    end
    
    if response[1] then
        TriggerClientEvent('cfx-tcd-starterpack:Client:ShowStarterPacks', src, response)
    else
        Config.Notification("No records found", "error", true, src)
    end
end)