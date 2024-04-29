Core, Framework = GetCore()

lib.callback.register('cfx-tcd-starterpack:CheckPlayer', function(source)
    local Player = Framework == "esx" and Core.GetPlayerFromId(source) or Core.Functions.GetPlayer(source)
    local identifier = Framework == "esx" and Player.identifier or Player.PlayerData.citizenid

    local query = "SELECT * FROM tcd_starterpack WHERE identifier = ?"
    local params = {identifier}

    local response = FetchQuery(query, params)
    if not response or #response == 0 then
        if Config.Debug then print("^1[DEBUG] ^7Player not found in the database, adding them now") end

        local insertQuery = "INSERT INTO tcd_starterpack (identifier, received) VALUES (?, ?)"
        local insertParams = {identifier, 0}

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

function UpdateRecevied(Player)
    local currentDate = os.date("%m/%d/%Y")
    local query = "UPDATE tcd_starterpack SET received = ?, date_received = ? WHERE identifier = ?"
    local params = {1, currentDate, Player.identifier}

    ExecuteQuery(query, params)
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

    end
end)

RegisterServerEvent("cfx-tcd-starterpack:ClaimStarterpack")
AddEventHandler("cfx-tcd-starterpack:ClaimStarterpack", function()
    local Player = Framework == "esx" and Core.GetPlayerFromId(source) or Core.Functions.GetPlayer(source)

    for i = 1, #Config.StarterPackItems do
        local item = Config.StarterPackItems[i].item
        local amount = Config.StarterPackItems[i].amount

        if Config.InventoryResource == 'ox_inventory' then
            if Config.Debug then print("^1[DEBUG] ^7Adding item: ^5" .. item .. "^7 to player: ^5" .. Player.identifier .. "^7 with amount: ^5" .. amount .. "^7") end
            exports.ox_inventory:AddItem(source, item, amount)
        elseif Config.InventoryResource == 'qb-inventory' or Config.InventoryResource == 'ps-inventory' then
            Player.Functions.AddItem(item, amount)
        else
            if Config.Debug then print("^1[DEBUG] ^7Inventory resource not found") end
        end
    end

    UpdateRecevied(Player)
    Config.Notification(Config.Locale[Config.Lang]['success'], 'success', true, source)
end)