Core, Framework = GetCore()

lib.callback.register('cfx-tcd-starterpack:CheckPlayer', function(source)
    local Player = Framework == "esx" and Core.GetPlayerFromId(source) or Core.Functions.GetPlayer(source)
    local identifier = Framework == "esx" and Player.identifier or Player.PlayerData.citizenid

    local query = "SELECT * FROM tcd_starterpack WHERE identifier = ?"
    local params = { identifier }

    local response = FetchQuery(query, params)
    if not response or #response == 0 then
        if Config.Debug then print("^1[DEBUG] ^7Player not found in the database, adding them now") end

        local insertQuery = "INSERT INTO tcd_starterpack (identifier, received) VALUES (?, ?)"
        local insertParams = { identifier, 0 }

        InsertQuery(insertQuery, insertParams, function(rowsAffected)
            if rowsAffected > 0 then
                if Config.Debug then print("^2[DEBUG] ^7Added new row for player: " .. identifier) end
            else
                if Config.Debug then print("^1[DEBUG] ^7Failed to add new row for player: " .. identifier) end
            end
        end)

        return true
    else
        for i = 1, #response do
            local row = response[i]
            if not row.received then
                return true
            else
                return false
            end
        end
    end
end)

local function SendDiscordLog(source, desc)
    local time = os.date("%c")
    local webhook = DiscordConfig.webhook
    local title = DiscordConfig.title
    local thumbnail_url = DiscordConfig.thumbnail
    local color = DiscordConfig.color

    if not webhook then
        print("^1[ERROR] ^7Discord Webhook is not set")
        return
    end

    if Config.Debug then print("^1[DEBUG] ^7Sending Discord Log") end

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
                    ["value"] = "```" .. GetPlayerIdentifiers(source)[1] .. "```",
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

function UpdateRecevied(Player)
    local identifier = Framework == "esx" and Player.identifier or Player.PlayerData.citizenid
    local currentDate = os.date("%m/%d/%Y")
    local query = "UPDATE tcd_starterpack SET received = ?, date_received = ? WHERE identifier = ?"
    local params = { 1, currentDate, identifier }

    ExecuteQuery(query, params)

    if Config.Debug then print("^2[DEBUG] ^7Updated received status for player: " .. identifier) end
end

RegisterServerEvent("cfx-tcd-starterpack:ClaimVehicle")
AddEventHandler("cfx-tcd-starterpack:ClaimVehicle", function(vehicleData)
    local Player = Framework == "esx" and Core.GetPlayerFromId(source) or Core.Functions.GetPlayer(source)
    local identifier = Framework == "esx" and Player.identifier or Player.PlayerData.citizenid

    if Framework == 'esx' then
        local query = "INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)"
        local params = {
            ['@owner'] = identifier,
            ['@plate'] = vehicleData.props.plate,
            ['@vehicle'] = json.encode(vehicleData.props)
        }
        InsertQuery(query, params)
    else
        local query =
        "INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage) VALUES (@license, @citizenid, @vehicle, @hash, @mods, @plate, @garage)"
        local params = {
            ['@license'] = Player.PlayerData.license,
            ['@citizenid'] = identifier,
            ['@vehicle'] = Config.StarterVehicle.model,
            ['@hash'] = GetHashKey(vehicleData.props.model),
            ['@mods'] = '{}',
            ['@plate'] = vehicleData.props.plate,
            ['@garage'] = 'pillboxgarage'
        }
        InsertQuery(query, params)
    end
end)

RegisterServerEvent("cfx-tcd-starterpack:ClaimStarterpack")
AddEventHandler("cfx-tcd-starterpack:ClaimStarterpack", function()
    local src = source
    local Player = Framework == "esx" and Core.GetPlayerFromId(src) or Core.Functions.GetPlayer(src)

    for i = 1, #Config.StarterPackItems do
        local item = Config.StarterPackItems[i].item
        local amount = Config.StarterPackItems[i].amount

        if Config.InventoryResource == 'ox_inventory' and GetResourceState(Config.InventoryResource) == 'started' then
            local success, response = exports.ox_inventory:AddItem(src, item, amount)
            if not success then
                if response == 'invalid_item' then
                    print("^1[ERROR] ^7Invalid item: " .. item)
                end
            end
        elseif Config.InventoryResource == 'qb-inventory' or Config.InventoryResource == 'ps-inventory' and GetResourceState(Config.InventoryResource) == 'started' then
            local itemInfo = Core.Shared.Items[item]
            if itemInfo then
                Player.Functions.AddItem(item, amount)
                TriggerClientEvent('inventory:client:ItemBox', src, itemInfo, 'add', amount)
            else
                print("^1[ERROR] ^7Invalid item: " .. item)
            end
        elseif Config.InventoryResource == 'qs-inventory' and GetResourceState(Config.InventoryResource) == 'started' then
            exports['qs-inventory']:AddItem(src, item, amount)
            -- I don't have qs-inventory so I can't test this, and add error handling for this
        else
            error(Config.InventoryResource .. " is not found or not started", 2)
        end
    end

    UpdateRecevied(Player)
    SendDiscordLog(src, "Player has received their starter pack")
    Config.Notification(Config.Locale[Config.Lang]['success'], 'success', true, source)
end)
