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

if Config.CheckVersion then
    CheckForUpdates()
end