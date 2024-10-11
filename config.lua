Config = {}

--[[
▀█▀ █▀▀ █▀▀ ▀█ █▄█   █▀▀ █▀█ █▀█ █▀▀   █▀▄ █▀▀ █░█ █▀▀ █░░ █▀█ █▀█ █▀▄▀█ █▀▀ █▄░█ ▀█▀
░█░ ██▄ ██▄ █▄ ░█░   █▄▄ █▄█ █▀▄ ██▄   █▄▀ ██▄ ▀▄▀ ██▄ █▄▄ █▄█ █▀▀ █░▀░█ ██▄ █░▀█ ░█░

    Documentation: https://tcdev.gitbook.io/tcd-documentation/free-release/advanced-starterpack-system
]]

Config.Debug = false                      -- enable debug mode to see more information in the console

Config.TargetResource = 'ox_target'       -- supported: ox_target, qb-target
Config.InventoryResource = 'ox_inventory' -- supported: ox_inventory, qb-inventory, ps-inventory, qs-inventory
Config.SQLResource = 'oxmysql'            -- supported: oxmysql, mysql-async, ghmattimysql

Config.UsePlayerLicense = true            -- if you want to use player license to check if they have received the starter pack or not

Config.UseTarget = true                   -- enable target system to interact with the peds

Config.CommandConfig = {                  -- command to give the starter package
    enable           = true,
    command          = 'starterpack',
    command_help     = 'Get your starter pack',
    starterpack_type = 'normal',
    starter_vehicle  = {
        enable = true,
        model = 'adder',
        parking = "pillboxgarage",
    }
}

Config.Locations = {
    ["1"] = {                                                                       -- Unique identifier for the location
        starterpack_type = 'normal',                                                -- Type of starter pack given to the player
        label            = 'Get your starter pack',                                 -- Target label (shown to the player)
        icon             = 'fa-solid fa-gift',                                      -- Target icon (from FontAwesome)

        coords           = vec4(-1040.479126, -2731.582520, 20.164062, 238.110229), -- Coordinates and heading of the NPC (ped)

        ped              = {                                                        -- Settings for the ped (NPC)
            model = 'a_m_y_business_03',                                            -- Ped model (see the FiveM ped model list)
            scenario = 'WORLD_HUMAN_CLIPBOARD',                                     -- Ped scenario (animation/behavior)
            heading = 238.110229,                                                   -- Direction the ped is facing
        },

        safezone         = { -- Safe zone settings (optional)
            enable = false,  -- Enable or disable the safe zone
            zone_points = {} -- Define safe zone points (if enabled)
        },

        starter_vehicle  = {           -- Vehicle settings for players receiving a starter vehicle
            enable = true,             -- Enable or disable the starter vehicle
            model = 'adder',           -- Vehicle model (from FiveM vehicle model list)
            random_vehicle = true,     -- Spawn a random vehicle from the list (true/false)
            teleport_player = false,   -- Teleport player to the vehicle (true/false)
            parking = "pillboxgarage", -- Parking location name for storing the vehicle in the database
            vehicle_spawns = {         -- Spawn points for the vehicle (multiple spawn locations)
                vec4(-1039.02, -2727.53, 19.65, 243.17),
                vec4(-1043.3, -2725.09, 19.65, 241.12),
                vec4(-1047.57, -2722.66, 19.65, 240.54),
                vec4(-1034.38, -2719.0, 19.65, 240.52),
                vec4(-1038.51, -2716.53, 19.64, 240.34),
            },
            fuel = 100.0, -- Fuel level of the vehicle when spawned
        },

        receiving_radius = 20.0, -- Radius around the location where players can receive the starter pack
        distance         = 2.0,  -- Distance from the ped to interact with it
    },
    -- add more locations here
}

Config.RandomVehicles = { -- list of vehicles to be given randomly to the player
    vehicles = {
        "adder",
        "zentorno",
        "t20",
        "osiris",
        "reaper",
        "tempesta",
        "italigtb",
        "italigtb2",
        "nero",
        -- add more vehicles here
    }
}

Config.StarterPackItems = { -- items that will be given to player
    ["normal"] = {
        { item = 'burger',   amount = 5 },
        { item = 'sprunk',   amount = 5 },
        { item = 'phone',    amount = 1 },
        { item = 'lockpick', amount = 5 },
        { item = 'money',    amount = 5000 },
    },
    -- add more starter pack types here
}

---@param vehicle any
---@param fuel number
---@decription Set fuel level of the vehicle using the fuel resources
Config.SetFuel = function(vehicle, fuel)
    if GetResourceState("LegacyFuel") == "started" then
        exports['LegacyFuel']:SetFuel(vehicle, fuel)
    elseif GetResourceState("cdn-fuel") == "started" then
        exports['cdn-fuel']:SetFuel(vehicle, fuel)
    elseif GetResourceState("ps-fuel") == "started" then
        exports['ps-fuel']:SetFuel(vehicle, fuel)
    elseif GetResourceState("lj-fuel") == "started" then
        exports['lj-fuel']:SetFuel(vehicle, fuel)
    else
        warn("Fuel resource not found, please set your fuel resource in the config.lua")
    end
end

---@param vehicle any
---@return string
---@decription If you have a custom vehicle key system you can give the key to the player
Config.GiveKey = function(vehicle)
    local Core, Framework = GetCore()
    if Framework == "esx" then
        -- ESX Vehicle Key System
    else
        TriggerEvent("vehiclekeys:client:SetOwner", Core.Functions.GetPlate(vehicle))
    end
end

---@param message string
---@param type string
---@param is_server boolean
---@decription Send notification to the player
Config.Notification = function(message, type, is_server, src)
    local Core, Framework = GetCore()
    if is_server then
        if Framework == "esx" then
            TriggerClientEvent("esx:showNotification", src, message)
        else
            TriggerClientEvent('QBCore:Notify', src, message, type, 5000)
        end
    else
        if Framework == "esx" then
            TriggerEvent("esx:showNotification", message)
        else
            Core.Functions.Notify(message, type, 5000)
        end
    end
end
