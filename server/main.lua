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
