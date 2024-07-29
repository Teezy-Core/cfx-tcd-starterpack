local Core, Framework = GetCore()
local Peds = {}
local Targets = {}

-- Define the list of available vehicles
local availableVehicles = Config.StarterVehicle.model
local availableItemPacks = Config.StarterPackItems

function ShowItemPackMenu(callback)
    local options = {}
    for i, pack in ipairs(availableItemPacks) do
        local itemList = ""
        for _, item in ipairs(pack.items) do
            itemList = itemList .. item.amount .. " x "  .. item.label .. "\n"
        end
        table.insert(options, {
            title = pack.name,
            description = itemList,
            onSelect = function()
                callback(pack.items)
            end
        })
    end

    lib.registerContext({
        id = 'item_pack_menu',
        title = 'Select Item Pack',
        options = options
    })

    -- Open the menu
    lib.showContext('item_pack_menu')
end

function ShowVehicleMenu(callback)
    local options = {}
    for i, veh in ipairs(availableVehicles) do
        table.insert(options, {
            title = veh.name,
            onSelect = function()
                callback(veh.model)
            end
        })
    end
    lib.registerContext({
        id = 'vehicle_menu',
        title = 'Select Starter Vehicle',
        options = options
    })
    lib.showContext('vehicle_menu')
end

function StarterVehicle(isTest, selectedVehicleModel)
    local vehicleModel = selectedVehicleModel
    local vehicle = GetHashKey(vehicleModel)
    local vehicleSpawns = Config.StarterVehicle.vehicle_spawns
    local isSpawned = false

    for spawnName, spawnCoords in pairs(vehicleSpawns) do
        local closestVehicle = GetClosestVehicle(spawnCoords.x, spawnCoords.y, spawnCoords.z, 3.0, 0, 70)
        if closestVehicle == 0 then
            if Framework == 'esx' then
                Core.Game.SpawnVehicle(vehicle, spawnCoords, spawnCoords.w, function(vehicle)
                    if Config.StarterVehicle.teleport_player then
                        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                    end
                    Config.SetFuel(vehicle, Config.StarterVehicle.fuel)

                    local vehicleData = {
                        props = Core.Game.GetVehicleProperties(vehicle),
                        model = vehicleModel -- Include the model in vehicleData
                    }

                    Config.GiveKey(vehicle)
                    if not isTest then
                        TriggerServerEvent('cfx-tcd-starterpack:ClaimVehicle', vehicleData, vehicleModel)
                    end
                end)
            else
                Core.Functions.SpawnVehicle(vehicle, function(veh)
                    SetEntityHeading(veh, spawnCoords.w)
                    if Config.StarterVehicle.teleport_player then
                        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                    end
                    Config.SetFuel(veh, Config.StarterVehicle.fuel)

                    local vehicleData = {
                        props = Core.Functions.GetVehicleProperties(veh),
                        model = vehicleModel -- Include the model in vehicleData
                    }
                    Config.GiveKey(veh)
                    if not isTest then
                        TriggerServerEvent('cfx-tcd-starterpack:ClaimVehicle', vehicleData, vehicleModel)
                    end
                end, spawnCoords, true)
            end

            isSpawned = true
            break
        else
            if Config.Debug then print("^1[ERROR] ^7Spawn point '" .. spawnName .. "' is already occupied.") end
        end
    end
    if not isSpawned then
        Config.Notification(Config.Locale[Config.Lang]['no_available_spawn'], 'error', false, source)
    end
end

local function InitializeScenario(selectedItemPack, selectedVehicleModel)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    for _, ped in pairs(Peds) do
        local pedCoords = GetEntityCoords(ped)
        if #(playerCoords - pedCoords) < 3 then
            LoadAnimDict("mp_common")
            LoadAnimDict("amb@prop_human_atm@male@enter")
            local boxprop = MakeProp({ prop = `hei_prop_heist_box`, coords = vector4(0, 0, 0, 0) }, 0, 1)
            AttachEntityToEntity(boxprop, ped, GetPedBoneIndex(ped, 57005), 0.1, -0.0, 0.0, -90.0, 0.0, 0.0, true, true, false, true, 1, true)
            ClearPedTasksImmediately(ped)
            LookEntity(ped)
            TaskPlayAnim(playerPed, "amb@prop_human_atm@male@enter", "enter", 1.0, 1.0, 0.3, 16, 0.2, 0, 0, 0)
            TaskPlayAnim(ped, "mp_common", "givetake2_b", 1.0, 1.0, 0.3, 16, 0.2, 0, 0, 0)
            Wait(1000)
            AttachEntityToEntity(boxprop, playerPed, GetPedBoneIndex(playerPed, 57005), 0.1, -0.0, 0.0, -90.0, 0.0, 0.0, true, true, false, true, 1, true)
            Wait(1000)

            TriggerServerEvent("cfx-tcd-starterpack:ClaimStarterpack", selectedItemPack, selectedVehicleModel)
            
            StopAnimTask(playerPed, "amb@prop_human_atm@male@enter", "enter", 1.0)
            StopAnimTask(ped, "mp_common", "givetake2_b", 1.0)
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_GUARD_STAND", -1, true)
            UnloadAnimDict("mp_common")
            UnloadAnimDict("amb@prop_human_atm@male@enter")
            DestroyProp(boxprop)
            UnloadModel(`prop_paper_bag_small`)
            DeleteObject(boxprop)
        end
    end
end

RegisterNetEvent('cfx-tcd-starterpack:SpawnVehicle')
AddEventHandler('cfx-tcd-starterpack:SpawnVehicle', function(vehicleModel)
    print("Spawning vehicle with model: " .. vehicleModel) -- Debug statement
    StarterVehicle(false, vehicleModel)
end)

function InitializeTarget()
    if Config.UseTarget then
        if Config.TargetResource == 'ox_target' and GetResourceState(Config.TargetResource) == 'started' then
            if Config.Debug then print("[^2INFO^7] ^5Using ^7^1OX_TARGET^7 ^5resource^7") end
            local options = {}
            options[#options + 1] = {
                name = 'starterpack',
                icon = 'fa-solid fa-gift',
                label = Config.Target.label,
                distance = Config.Target.distance,
                onSelect = function()
                    local alert = nil
                    if Config.EnableAlertDialog then
                        alert = lib.alertDialog({
                            header = Config.Dialog.title,
                            content = Config.Dialog.message,
                            centered = true,
                            cancel = true,
                            size = 'xl',
                        })
                    end

                    if alert == "confirm" or not Config.EnableAlertDialog then
                        ShowItemPackMenu(function(selectedItemPack)
                            if Config.EnableStarterVehicle then
                                ShowVehicleMenu(function(selectedVehicleModel)
                                    lib.callback('cfx-tcd-starterpack:CheckPlayer', false, function(data)
                                        if data then
                                            if lib.progressCircle({
                                                duration = 3000,
                                                position = 'bottom',
                                                useWhileDead = false,
                                                canCancel = true,
                                            }) then
                                                InitializeScenario(selectedItemPack, selectedVehicleModel)
                                            else
                                                Config.Notification(Config.Locale[Config.Lang]['canceled'], 'inform', false, source)
                                            end
                                        else
                                            Config.Notification(Config.Locale[Config.Lang]['received'], 'error', false, source)
                                        end
                                    end)
                                end)
                            else
                                lib.callback('cfx-tcd-starterpack:CheckPlayer', false, function(data)
                                    if data then
                                        if lib.progressCircle({
                                            duration = 3000,
                                            position = 'bottom',
                                            useWhileDead = false,
                                            canCancel = true,
                                        }) then
                                            InitializeScenario(selectedItemPack, nil)
                                        else
                                            Config.Notification(Config.Locale[Config.Lang]['canceled'], 'inform', false, source)
                                        end
                                    else
                                        Config.Notification(Config.Locale[Config.Lang]['received'], 'error', false, source)
                                    end
                                end)
                            end
                        end)
                    else
                        Config.Notification(Config.Locale[Config.Lang]['canceled'], 'inform', false, source)
                    end
                end,
                canInteract = function()
                    if IsPedInAnyVehicle(PlayerPedId(), true) or IsEntityDead(PlayerPedId()) or lib.progressActive() then
                        return false
                    end
                    return true
                end
            }

            exports.ox_target:addModel(Config.Target.ped, options)
        elseif Config.TargetResource == 'qb-target' and GetResourceState(Config.TargetResource) == 'started' then
            if Config.Debug then print("[^2INFO^7] ^5Using ^7^1QB-TARGET^7 ^5resource^7") end
            Targets["qb_target_ped"] = exports['qb-target']:AddCircleZone("qb_target_ped", Config.Target.coords.xyz, 0.5,
                {
                    name = "qb_target_ped",
                    debugPoly = Config.Debug,
                    useZ = true,
                }, {
                    options = {
                        {
                            icon = "fas fa-gift",
                            label = Config.Target.label,
                            action = function()
                                local alert = nil
                                if Config.EnableAlertDialog then
                                    alert = lib.alertDialog({
                                        header = Config.Dialog.title,
                                        content = Config.Dialog.message,
                                        centered = true,
                                        cancel = true,
                                        size = 'xl',
                                    })
                                end
            
                                if alert == "confirm" or not Config.EnableAlertDialog then
                                    ShowItemPackMenu(function(selectedItemPack)
                                        if Config.EnableStarterVehicle then
                                            ShowVehicleMenu(function(selectedVehicleModel)
                                                lib.callback('cfx-tcd-starterpack:CheckPlayer', false, function(data)
                                                    if data then
                                                        if lib.progressCircle({
                                                            duration = 3000,
                                                            position = 'bottom',
                                                            useWhileDead = false,
                                                            canCancel = true,
                                                        }) then
                                                            InitializeScenario(selectedItemPack, selectedVehicleModel)
                                                        else
                                                            Config.Notification(Config.Locale[Config.Lang]['canceled'], 'inform', false, source)
                                                        end
                                                    else
                                                        Config.Notification(Config.Locale[Config.Lang]['received'], 'error', false, source)
                                                    end
                                                end)
                                            end)
                                        else
                                            lib.callback('cfx-tcd-starterpack:CheckPlayer', false, function(data)
                                                if data then
                                                    if lib.progressCircle({
                                                        duration = 3000,
                                                        position = 'bottom',
                                                        useWhileDead = false,
                                                        canCancel = true,
                                                    }) then
                                                        InitializeScenario(selectedItemPack, nil)
                                                    else
                                                        Config.Notification(Config.Locale[Config.Lang]['canceled'], 'inform', false, source)
                                                    end
                                                else
                                                    Config.Notification(Config.Locale[Config.Lang]['received'], 'error', false, source)
                                                end
                                            end)
                                        end
                                    end)
                                else
                                    Config.Notification(Config.Locale[Config.Lang]['canceled'], 'inform', false, source)
                                end
                            end,
                            canInteract = function()
                                if IsPedInAnyVehicle(PlayerPedId(), true) or IsEntityDead(PlayerPedId()) or lib.progressActive() then
                                    return false
                                end
                                return true
                            end
                        },
                    },
                    distance = 2.0
                })
        else
            print("^1[ERROR] ^7Target resource not found or not started")
        end
    else
        for k in pairs(Targets) do exports['qb-target']:RemoveZone(k) end
        for k in pairs(Peds) do DeleteEntity(Peds[k]) end
    end
end

if Config.UseCommand then
    RegisterCommand(Config.Command, function(source, args, raw)
        local pedCoords = Config.Target.coords.xyz

        if #(GetEntityCoords(PlayerPedId()) - pedCoords) > Config.Target.receiving_radius then
            Config.Notification(Config.Locale[Config.Lang]['not_near_receiving_point'], 'error', false, source)
            return
        end

        if IsPedInAnyVehicle(PlayerPedId(), true) then
            Config.Notification(Config.Locale[Config.Lang]['player_in_vehicle'], 'error', false, source)
            return
        end

        local alert = nil
        if Config.EnableAlertDialog then
            alert = lib.alertDialog({
                header = Config.Dialog.title,
                content = Config.Dialog.message,
                centered = true,
                cancel = true,
                size = 'xl',
            })
        end

        if alert == "confirm" or not Config.EnableAlertDialog then
            ShowItemPackMenu(function(selectedItemPack)
                if Config.EnableStarterVehicle then
                    ShowVehicleMenu(function(selectedVehicleModel)
                        lib.callback('cfx-tcd-starterpack:CheckPlayer', source, function(data)
                            if data then
                                if lib.progressCircle({
                                        duration = 3000,
                                        position = 'bottom',
                                        useWhileDead = false,
                                        canCancel = true,
                                    })
                                then
                                    TriggerServerEvent("cfx-tcd-starterpack:ClaimStarterpack", selectedItemPack, selectedVehicleModel)
                                    StarterVehicle(false, selectedVehicleModel)
                                else
                                    Config.Notification(Config.Locale[Config.Lang]['canceled'], 'inform', false, source)
                                end
                            else
                                Config.Notification(Config.Locale[Config.Lang]['received'], 'error', false, source)
                            end
                        end)
                    end)
                else
                    lib.callback('cfx-tcd-starterpack:CheckPlayer', source, function(data)
                        if data then
                            if lib.progressCircle({
                                    duration = 3000,
                                    position = 'bottom',
                                    useWhileDead = false,
                                    canCancel = true,
                                })
                            then
                                TriggerServerEvent("cfx-tcd-starterpack:ClaimStarterpack", selectedItemPack, nil)
                            else
                                Config.Notification(Config.Locale[Config.Lang]['canceled'], 'inform', false, source)
                            end
                        else
                            Config.Notification(Config.Locale[Config.Lang]['received'], 'error', false, source)
                        end
                    end)
                end
            end)
        else
            Config.Notification(Config.Locale[Config.Lang]['canceled'], 'inform', false, source)
        end
    end, false)

    TriggerEvent('chat:addSuggestion', '/' .. Config.Command, 'Get your starter pack', {})
end

local zone = lib.points.new(Config.Target.coords, 50, {})
function zone:onEnter()
    local ped = SetPed(Config.Target.ped, Config.Target.coords, true, false, 'WORLD_HUMAN_GUARD_STAND', false)
    Peds[#Peds + 1] = ped

    InitializeTarget()
end

function zone:onExit()
    for k in pairs(Targets) do exports['qb-target']:RemoveZone(k) end
    for k in pairs(Peds) do DeleteEntity(Peds[k]) end
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then end
    for k in pairs(Targets) do exports['qb-target']:RemoveZone(k) end
    for k in pairs(Peds) do DeleteEntity(Peds[k]) end
end)
