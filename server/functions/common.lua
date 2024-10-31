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

function CheckForUpdates()
    PerformHttpRequest("https://api.github.com/repos/Teezy-Core/cfx-tcd-starterpack/releases/latest",
        function(statusCode, responseText, headers)
            if statusCode == 200 then
                local response = json.decode(responseText)
                local latestVersion = response.tag_name

                if latestVersion:sub(1, 1) == "v" then
                    latestVersion = latestVersion:sub(2)
                end

                local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version", 0)

                if currentVersion and latestVersion then
                    if currentVersion ~= latestVersion then
                        print("^5********************** [ADVANCED STARTERPACK SYSTEM] **********************^0")
                        warn("A new version is available: " .. latestVersion ..
                            ". You are currently using: " .. currentVersion)
                        warn("\n Please download the latest version from: " ..
                            response.html_url)
                        print("^5****************************************************************************^0")
                    else
                        print("^5********************** [ADVANCED STARTERPACK SYSTEM] **********************^0")
                        print("^5You are using the latest version: " .. currentVersion)
                        print("^5****************************************************************************^0")
                    end
                else
                    print("^5********************** [ADVANCED STARTERPACK SYSTEM] **********************^0")
                    warn("^Could not retrieve the current version.")
                    print("^5****************************************************************************^0")
                end
            else
                print("^5********************** [ADVANCED STARTERPACK SYSTEM] **********************^0")
                warn("Failed to fetch the latest version: HTTP " .. statusCode ..
                    ". Please check the latest version from the GitHub repository.")
                print("^5****************************************************************************^0")
            end
        end, "GET", "", { ["User-Agent"] = "FiveM" })
end
