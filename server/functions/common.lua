local Core, Framework = GetCore()

---@param source number
---@return string
---@description Get the player license using their identifiers
function GetPlayerLicense(source)
    local identifiers = GetPlayerIdentifiers(source)
    local license = ""

    if Config.UsePlayerLicense then
        for _, id in ipairs(identifiers) do
            if string.match(id, "license:") then
                license = id
                break
            end
        end

        if not license then
            for _, id in ipairs(identifiers) do
                if string.match(id, "steam:") then
                    license = id
                    break
                elseif string.match(id, "discord:") then
                    license = id
                    break
                end
            end
        end
    else
        local Player = Framework == "esx" and Core.GetPlayerFromId(source) or Core.Functions.GetPlayer(source)
        license = Framework == "esx" and Player.identifier or Player.PlayerData.citizenid
    end

    return license
end

---@param source number
---@param desc string
---@description Send the discord log to the webhook
---@example SendDiscordLog(source, "Player has claimed the starter pack")
function SendDiscordLog(source, desc)
    local time = os.date("%c")
    local webhook = DiscordConfig.webhook
    local title = DiscordConfig.title
    local thumbnail_url = DiscordConfig.thumbnail
    local color = DiscordConfig.color

    if not webhook then
        warn("Webhook not found, please set your webhook in the discordlog.lua")
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

---@param license string
---@return boolean
---@description Check if the player has received the starter pack
function HasReceivedStarterPack(license)
    local query = "SELECT received FROM tcd_starterpack WHERE identifier = ?"
    local params = { license }

    local response = FetchQuery(query, params)

    if response[1] then
        return response[1].received
    else
        return false
    end
end
