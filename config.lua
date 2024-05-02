Config = {}

--[[
▀█▀ █▀▀ █▀▀ ▀█ █▄█   █▀▀ █▀█ █▀█ █▀▀   █▀▄ █▀▀ █░█ █▀▀ █░░ █▀█ █▀█ █▀▄▀█ █▀▀ █▄░█ ▀█▀
░█░ ██▄ ██▄ █▄ ░█░   █▄▄ █▄█ █▀▄ ██▄   █▄▀ ██▄ ▀▄▀ ██▄ █▄▄ █▄█ █▀▀ █░▀░█ ██▄ █░▀█ ░█░
]]

Config.Lang = 'en'
Config.Debug = true                       -- if you want to see debug messages in console

Config.TargetResource = 'ox_target'       -- supported: ox_target, qb-target
Config.InventoryResource = 'ox_inventory' -- supported: ox_inventory, qb-inventory, ps-inventory, qs-inventory
Config.SQLResource = 'oxmysql'            -- supported: oxmysql, mysql-async, ghmattimysql

Config.UseCommand = true                  -- if you want to use command to give starter pack to player
Config.Command = 'starterpack'            -- command to give starter package to player

Config.UseTarget = true                   -- if you want to use target script to give starter pack to player
Config.Target = {
    ped = 'a_m_y_business_03',            -- https://docs.fivem.net/docs/game-references/ped-models/
    label = 'Get your starter pack',
    receiving_radius = 20.0,              -- radius to receive the starter pack
    coords = vec4(-1040.479126, -2731.582520, 20.164062, 238.110229),
    distance = 2.0,
}

Config.StarterPackItems = { -- items that will be given to player
    { item = 'bread',    amount = 5 },
    { item = 'water',    amount = 5 },
    { item = 'phone',    amount = 1 },
    { item = 'lockpick', amount = 5 },
    { item = 'money',    amount = 5000 },
}

Config.EnableStarterVehicle = true -- if you want to give starter vehicle to player
Config.StarterVehicle = {
    model = 'adder',               -- https://docs.fivem.net/docs/game-references/vehicle-models/
    teleport_player = true,        -- player will be teleported to the vehicle
    vehicle_spawns = {             -- vehicle spawn points
        ["1"] = vector4(-1039.02, -2727.53, 19.65, 243.17),
        ["2"] = vector4(-1043.3, -2725.09, 19.65, 241.12),
        ["3"] = vector4(-1047.57, -2722.66, 19.65, 240.54),
        ["4"] = vector4(-1034.38, -2719.0, 19.65, 240.52),
        ["5"] = vector4(-1038.51, -2716.53, 19.64, 240.34),
    },
    fuel = 100.0, -- fuel level of the vehicle
}

Config.EnableAlertDialog = true -- if you want to use alert dialog to give a short message to the player
Config.Dialog = {
    title = 'TCD Roleplay Server',
    message = 'Welcome to the server, I hope you enjoy your stay. make sure to read the **rules** and have fun! \n\nDo you want to receive the starter pack?',
}

---@param vehicle any
---@param fuel number
---@decription Set fuel level of the vehicle by default it uses LegacyFuel
Config.SetFuel = function(vehicle, fuel)
    exports.LegacyFuel:SetFuel(vehicle, fuel)
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
