Config = {}

--[[
▀█▀ █▀▀ █▀▀ ▀█ █▄█   █▀▀ █▀█ █▀█ █▀▀   █▀▄ █▀▀ █░█ █▀▀ █░░ █▀█ █▀█ █▀▄▀█ █▀▀ █▄░█ ▀█▀
░█░ ██▄ ██▄ █▄ ░█░   █▄▄ █▄█ █▀▄ ██▄   █▄▀ ██▄ ▀▄▀ ██▄ █▄▄ █▄█ █▀▀ █░▀░█ ██▄ █░▀█ ░█░
]]

Config.Lang = 'en'
Config.Debug = false                     -- if you want to see debug messages in console

Config.TargetResource = 'qb-target'       -- supported: ox_target, qb-target
Config.InventoryResource = 'ps-inventory' -- supported: ox_inventory, qb-inventory, ps-inventory, qs-inventory
Config.SQLResource = 'oxmysql'            -- supported: oxmysql, mysql-async, ghmattimysql

Config.UseCommand = false                  -- if you want to use command to give starter pack to player
Config.Command = 'starterpack'            -- command to give starter package to player

Config.UseTarget = true                   -- if you want to use target script to give starter pack to player
Config.Target = {
    ped = 'a_m_y_business_03',            -- https://docs.fivem.net/docs/game-references/ped-models/
    label = 'Get your starter pack',
    receiving_radius = 20.0,              -- radius to receive the starter pack
    coords = vector4(-1041.904, -2732.908, 13.756646, 279.66772),
    distance = 2.0,
}

-- Config.StarterPackItems = { -- items that will be given to player
--     { item = 'bread',    amount = 5 },
--     { item = 'water',    amount = 5 },
--     { item = 'phone',    amount = 1 },
--     { item = 'lockpick', amount = 5 },
-- }
-- Define the list of available item packs
Config.StarterPackItems = {
{name = "Criminal Pack 1", items = {
        {item = 'bread', amount = 5, label = 'Bread'},
        {item = 'water', amount = 5, label = 'Water'},
        {item = 'phone', amount = 1, label = 'Phone'},
        {item = 'lockpick', amount = 10, label = 'Lockpick'},
    }
},
{name = "Criminal Pack 2", items = {
        {item = 'bread', amount = 5, label = 'Bread'},
        {item = 'water', amount = 5, label = 'Water'},
        {item = 'phone', amount = 1, label = 'Phone'},
        {item = 'lockpick', amount = 10, label = 'Lockpick'},
    }
},
{name = "Civillian Pack 1", items = {
        {item = 'bread', amount = 5, label = 'Bread'},
        {item = 'water', amount = 5, label = 'Water'},
        {item = 'phone', amount = 1, label = 'Phone'},
        {item = 'lockpick', amount = 10, label = 'Lockpick'},
    }
},
{name = "Civillian Pack 2", items = {
    {item = 'bread', amount = 5, label = 'Bread'},
    {item = 'water', amount = 5, label = 'Water'},
    {item = 'phone', amount = 1, label = 'Phone'},
    {item = 'lockpick', amount = 10, label = 'Lockpick'},
    }
},
    -- Add more item packs as needed
}

Config.EnableStarterVehicle = true -- if you want to give starter vehicle to player
Config.StarterVehicle = {
    model = {
        { model = 'baller2', name = 'Baller' },
        { model = 'f620', name = 'F620' },
        { model = 'cogcabrio', name = 'Cognoscenti Cabrio' },
        { model = 'dominator', name = 'Dominator' },
        { model = 'emperor', name = 'Emperor' },
        { model = 'felon', name = 'Felon' },
        { model = 'futo', name = 'Futo' },
        { model = 'gauntlet', name = 'Gauntlet' },
        { model = 'infernus', name = 'Infernus' },
        { model = 'phoenix', name = 'Phoenix' },
        { model = 'sultan', name = 'Sultan' },
    },
    teleport_player = true,        -- player will be teleported to the vehicle
    vehicle_spawns = {             -- vehicle spawn points
        ["1"] = vector4(-1032, -2659.066, 13.918387, 146.822),
        ["2"] = vector4(-1034.691, -2657.147, 13.918921, 154.49638),
        ["3"] = vector4(-1037.783, -2655.533, 13.918355, 152.50762),
        ["4"] = vector4(-1040.391, -2653.77, 13.918954, 149.14044),
        ["5"] = vector4(-1043.531, -2651.951, 13.918424, 152.89085),
        ['6'] = vector4(-1046.527, -2650.74, 13.918876, 148.28642),
        ['7'] = vector4(-1056.106, -2654.777, 13.918803, 281.40856),
        ['8'] = vector4(-1055.22, -2658.094, 13.918816, 287.3681),
        ['9'] = vector4(-1053.448, -2660.796, 13.918782, 288.92633),
        ['10'] = vector4(-1052.666, -2663.851, 13.919773, 292.16885),
        ['11'] = vector4(-1050.686, -2666.968, 13.918846, 305.18164),
        ['12'] = vector4(-1048.797, -2669.145, 13.918785, 308.52227),
        ['13'] = vector4(-1046.834, -2672.216, 13.919073, 313.55102),
        ['14'] = vector4(-1044.58, -2674.544, 13.918397, 323.21014),
        ['15'] = vector4(-1042.056, -2676.346, 13.918841, 323.25714),
    },
    fuel = 100.0, -- fuel level of the vehicle
}

Config.EnableAlertDialog = true -- if you want to use alert dialog to give a short message to the player
Config.Dialog = {
    title = 'British Improv Roleplay',
    message = 'Welcome to the server, I hope you enjoy your stay. make sure to read the **rules** and have fun! \n\nDo you want to receive the starter pack?',
}

---@param vehicle any
---@param fuel number
---@decription Set fuel level of the vehicle by default it uses LegacyFuel
Config.SetFuel = function(vehicle, fuel)
    exports['cdn-fuel']:SetFuel(vehicle, fuel)
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
            TriggerEvent('QBCore:Notify', message, type, 5000)
        end
    end
end

Config.Locale = {
    ['en'] = {
        ['received'] = 'You have already received your starter pack',
        ['success'] = 'You have received your starter pack, Enjoy!',
        ['canceled'] = 'You have canceled the starter pack',
        ['not_near_receiving_point'] = 'You are not near the receiving point',
        ['no_available_spawn'] = 'Possible area for vehicle spawn is occupied',
        ['player_in_vehicle'] = 'You can\'t receive the starter pack while in the vehicle',
    },
}
