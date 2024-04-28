Config = {}

Config.Lang = 'en'

Config.Debug = true

Config.TargetResource = 'ox_target' -- supported: ox_target, qb-target
Config.InventoryResource = 'ox_inventory' -- supported: ox_inventory, qb-inventory, ps-inventory
Config.SQLResource = 'oxmysql' -- supported: oxmysql, mysql-async, ghmattimysql

Config.ProgressDuration = 10000 -- in milliseconds (10 seconds) to give starter pack to player

Config.UseCommand = true -- if you want to use command to give starter pack to player
Config.Command = 'starterpack' -- command to give starter package to player

Config.UseGiftItem = true -- if you want to use gift item to give starter pack to player

Config.UseTarget = true -- if you want to use target script to give starter pack to player
Config.Target = {
    ped = 's_m_y_dealer_01', 
    label = 'Dealer',
    coords = vector3(-772.0, -244.0, 37.0),
    heading = 0.0,
    distance = 2.0,
}

Config.StarterPackItems = {
    {item = 'bread', amount = 5},
    {item = 'water', amount = 5},
}

Config.EnableStarterVehicle = true -- if you want to give starter vehicle to player
Config.StarterVehicle = {
    model = 'adder',
    teleport_player = true, -- if you want to teleport player to vehicle
    vehicle_spawn = vector3(-772.0, -244.0, 37.0),
    heading = 0.0,
    fuel = 100.0,
}

Config.Notification = function (message, type, is_server, src)
    if is_server then
        if exports.tcd_lib:GetFramework() == "esx" then
            TriggerClientEvent("esx:showNotification", src, message)
        else
            TriggerClientEvent('QBCore:Notify', src, message, type, 20000)
        end
    else
        if exports.tcd_lib:GetFramework() == "esx" then
            TriggerEvent("esx:showNotification", message)
        else
            TriggerEvent('QBCore:Notify', message, type, 20000)
        end
    end
end

Config.Locale = {
    ['en'] = {

    },
}