local Core, Framework = GetCore()

local Peds, Targets = {}, {}
local IsBusy, PedSpawned = false, false

lib.locale()

-- [[ FUNCTIONS ]] --
local function giveVehicleStarter(data)
    local vehicle = nil
    local vehicleSpawns = data.starter_vehicle.vehicle_spawns
    local isSpawn = false

    if IsPedInAnyVehicle(PlayerPedId(), true) then
        debugPrint("info", "Player is in a vehicle")
        Config.Notification(locale("player_in_vehicle"), "error", false)
        IsBusy = false
        return
    end

    if data.starter_vehicle.random_vehicle then
        debugPrint("info", "Random vehicle is enabled")

        local random = math.random(1, #Config.RandomVehicles.vehicles)
        vehicle = GetHashKey(Config.RandomVehicles.vehicles[random])

        debugPrint("info", "Random vehicle: " .. Config.RandomVehicles.vehicles[random])
    else
        debugPrint("info", "Random vehicle is disabled")
        vehicle = GetHashKey(data.starter_vehicle.model)
    end
    
    for spawnName, spawnCoords in pairs(vehicleSpawns) do
        local closestVehicle = GetClosestVehicle(spawnCoords.x, spawnCoords.y, spawnCoords.z, 3.0, 0, 70)
        if closestVehicle == 0 then
            if Framework == "esx" then
                Core.Game.SpawnVehicle(vehicle, spawnCoords, spawnCoords.w, function(vehicle)
                    if data.starter_vehicle.teleport_player then
                        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                    end

                    local vehicleData = {
                        props = Core.Game.GetVehicleProperties(vehicle),
                        parking = data.starter_vehicle.parking and data.starter_vehicle.parking or nil
                    }

                    Config.SetFuel(vehicle, data.starter_vehicle.fuel)
                    Config.GiveKey(vehicle)

                    TriggerServerEvent("cfx-tcd-starterpack:Server:ClaimVehicle", vehicleData)

                    IsBusy = false
                end, spawnCoords, true)
            elseif Framework == "qbc" then
                Core.Functions.SpawnVehicle(vehicle, function(veh)
                    if data.starter_vehicle.teleport_player then
                        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                    end

                    local vehicleData = {
                        props = Core.Functions.GetVehicleProperties(veh),
                        parking = data.starter_vehicle.parking and data.starter_vehicle.parking or nil,
                        vehicle_name = data.starter_vehicle.model
                    }

                    Config.SetFuel(veh, data.starter_vehicle.fuel)
                    Config.GiveKey(veh)

                    TriggerServerEvent("cfx-tcd-starterpack:Server:ClaimVehicle", vehicleData)

                    IsBusy = false
                end, spawnCoords, true)
            end

            isSpawn = true
            break
        else
            debugPrint("warning", "Spawn point: " .. spawnName .. " is occupied")
            IsBusy = false
        end
    end

    if not isSpawn then
        debugPrint("info", "All spawn points are occupied")
        Config.Notification(locale("no_available_spawn"), "error", false)
        IsBusy = false
    end

    IsBusy = false
end

local function giveStarterPack(data)
    lib.callback('cfx-tcd-starterpack:CB:CheckPlayer', false, function(result)
        if result then
            debugPrint("info", "Player has already received the starter pack")
            Config.Notification(locale("already_received"), "error", false)
            IsBusy = false
        else
            debugPrint("info", "Player is eligible to receive the starter pack")

            if lib.progressCircle({
                    duration = 1000,
                    position = 'bottom',
                    useWhileDead = false,
                    canCancel = true,
                }) then
                local playerPed = cache.ped
                local playerCoords = GetEntityCoords(playerPed)
                for _, ped in pairs(Peds) do
                    local pedCoords = GetEntityCoords(ped)
                    if #(playerCoords - pedCoords) < 3 then
                        LoadAnimDict("mp_common")
                        LoadAnimDict("amb@prop_human_atm@male@enter")
                        local boxprop = MakeProp({ prop = `hei_prop_heist_box`, coords = vector4(0, 0, 0, 0) }, 0, 1)
                        AttachEntityToEntity(boxprop, ped, GetPedBoneIndex(ped, 57005), 0.1, -0.0, 0.0, -90.0, 0.0, 0.0,
                            true,
                            true,
                            false, true, 1, true)
                        ClearPedTasksImmediately(ped)
                        LookEntity(ped)
                        TaskPlayAnim(playerPed, "amb@prop_human_atm@male@enter", "enter", 1.0, 1.0, 0.3, 16, 0.2, 0, 0, 0)
                        TaskPlayAnim(ped, "mp_common", "givetake2_b", 1.0, 1.0, 0.3, 16, 0.2, 0, 0, 0)
                        Wait(1000)
                        AttachEntityToEntity(boxprop, playerPed, GetPedBoneIndex(playerPed, 57005), 0.1, -0.0, 0.0, -90.0,
                            0.0, 0.0,
                            true, true, false, true, 1, true)
                        Wait(1000)

                        TriggerServerEvent("cfx-tcd-starterpack:Server:ClaimStarterpack", data.starterpack_type)

                        Wait(1000)
                        StopAnimTask(playerPed, "amb@prop_human_atm@male@enter", "enter", 1.0)
                        StopAnimTask(ped, "mp_common", "givetake2_b", 1.0)
                        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_GUARD_STAND", -1, true)
                        UnloadAnimDict("mp_common")
                        UnloadAnimDict("amb@prop_human_atm@male@enter")
                        DestroyProp(boxprop)
                        UnloadModel(`prop_paper_bag_small`)
                        DeleteObject(boxprop)

                        Wait(500)

                        if data.starter_vehicle.enable then
                            debugPrint("info", "Spawning vehicle for the player")
                            giveVehicleStarter(data)
                        end
                    end
                end
                IsBusy = false
            else
                Config.Notification(locale("progress_cancelled"), "error", false)
            end
        end
    end)
end

local function draw3DText(coords, text, color)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local camCoords = GetGameplayCamCoord()
    local distance = GetDistanceBetweenCoords(camCoords, coords.x, coords.y, coords.z, true)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    local scale = scale * fov

    if onScreen then
        SetTextScale(0.0, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(x, y)
    end
end

local function intializeTargetWithPed(data)
    if Config.UseTarget then
        local ped = SetPed(data.ped.model, data.coords, true, false, data.ped.scenario, false)
        Peds[#Peds + 1] = ped

        if Config.TargetResource == 'ox_target' and GetResourceState(Config.TargetResource) == 'started' then
            local option = {
                name = "tcd_starterpack_" .. math.random(1, 1000), -- This to avoid conflicts
                icon = data.icon,
                label = data.label,
                distance = data.distance,
                onSelect = function()
                    giveStarterPack(data)
                    IsBusy = true
                end,
                canInteract = function(entity)
                    if IsPedInAnyVehicle(PlayerPedId(), true) or IsEntityDead(PlayerPedId()) or IsEntityDead(entity) or lib.progressActive() or IsBusy then
                        return false
                    end
                    return true
                end
            }

            exports.ox_target:addModel(data.ped.model, option)
            Targets[#Targets + 1] = { name = option.name, model = data.ped.model }
        elseif Config.TargetResource == 'qb-target' and GetResourceState(Config.TargetResource) == 'started' then
            exports['qb-target']:AddTargetModel(data.ped.model, {
                options = {
                    {
                        type = "client",
                        icon = data.icon,
                        label = data.label,
                        action = function()
                            giveStarterPack(data)
                            IsBusy = true
                        end,
                        canInteract = function(entity)
                            if IsPedInAnyVehicle(PlayerPedId(), true) or IsEntityDead(PlayerPedId()) or IsEntityDead(entity) or lib.progressActive() or IsBusy then
                                return false
                            end
                            return true
                        end
                    }
                },
                distance = data.distance
            })

            Targets[#Targets + 1] = { name = data.label, model = data.ped.model }
        end
    else
        debugPrint("warning", "Target system is disabled")
        local coords = data.coords
        local color = { r = 255, g = 255, b = 255, a = 255 }
        local text = "Press ~g~[E]~w~ to receive your starter pack"

        Citizen.CreateThread(function()
            while true do
                local playerPed = cache.ped
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(playerCoords - coords.xyz)

                if distance < data.distance then
                    draw3DText(coords.xyz, text, color)
                    if IsControlJustPressed(0, 38) then
                        giveStarterPack(data)
                        IsBusy = true
                    end
                end

                Wait(0)
            end
        end)
    end
end
-- [[ END FUNCTIONS ]] --

-- [[ EVENTS ]] --
RegisterNetEvent("cfx-tcd-starterpack:Client:GiveStarterVehicle", function(data)
    local vehicle = nil

    if data.random_vehicle then
        local random = math.random(1, #Config.RandomVehicles.vehicles)
        vehicle = GetHashKey(Config.RandomVehicles.vehicles[random])
    else
        vehicle = GetHashKey(data.model)
    end
    if Framework == "esx" then
        Core.Game.SpawnVehicle(vehicle, cache.coords, cache.heading, function(vehicle)
            TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
            Config.SetFuel(vehicle, data.fuel)
            Config.GiveKey(vehicle)

            local vehicleData = {
                props = Core.Game.GetVehicleProperties(vehicle),
                parking = data.parking and data.parking or nil
            }

            TriggerServerEvent("cfx-tcd-starterpack:Server:ClaimVehicle", vehicleData)
        end, cache.coords, true)
    elseif Framework == "qbc" then
        Core.Functions.SpawnVehicle(vehicle, function(vehicle)
            TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
            Config.SetFuel(vehicle, data.fuel)
            Config.GiveKey(vehicle)

            local vehicleData = {
                props = Core.Functions.GetVehicleProperties(vehicle),
                parking = data.parking and data.parking or nil,
                vehicle_name = data.model
            }

            TriggerServerEvent("cfx-tcd-starterpack:Server:ClaimVehicle", vehicleData)
        end, cache.coords, true)
    end
end)
-- [[ END EVENTS ]] --

-- [[ THREADS / CALLBACKS ]] --
lib.callback.register("cfx-tcd-starterpack:CB:CheckReceivingRadius", function()
    local playerPed = cache.ped
    local playerCoords = GetEntityCoords(playerPed)
    for _, location in pairs(Config.Locations) do
        local pedCoords = location.coords.xyz
        if #(playerCoords - pedCoords) < location.receiving_radius then
            return true
        end
    end
    return false
end)
-- [[ END THREADS / CALLBACKS ]] --

-- [[ ZONES ]] --
local zones = {}

for _, location in pairs(Config.Locations) do
    local zone = lib.points.new({
        coords = location.coords,
        distance = location.receiving_radius,
    })

    if location.safezone.enable then
        local safezone = lib.zones.poly({
            points = location.safezone.zone_points,
            thickness = 2,
            debug = Config.Debug,
        })

        function safezone:inside()
            SetPlayerCanDoDriveBy(cache.ped, false)
            SetCurrentPedWeapon(cache.ped, GetHashKey("WEAPON_UNARMED"), true)
            DisablePlayerFiring(cache.ped, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 106, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 47, true)
            SetEntityProofs(cache.ped, true, true, true, true, true, true, true, true)
        end

        function safezone:onEnter()
            debugPrint("info", "Player entered the safezone")

            Config.Notification(locale("safezone_enter"), "info", false)
        end

        function safezone:onExit()
            debugPrint("info", "Player exited the safezone")
            Config.Notification(locale("safezone_exit"), "info", false)

            SetPlayerCanDoDriveBy(cache.ped, true)
            SetEntityProofs(cache.ped, false, false, false, false, false, false, false, false)
        end
    end

    function zone:onEnter()
        debugPrint("info", "Player entered the zone")

        if location.ped.show_only_for_newbie then
            lib.callback("cfx-tcd-starterpack:CB:CheckPlayer", false, function(result)
                if not result then
                    debugPrint("info", "Player is eligible to receive the starter pack")
                    if not PedSpawned then
                        intializeTargetWithPed(location)
                        PedSpawned = true
                    end
                end
            end)
        else
            if not PedSpawned then
                intializeTargetWithPed(location)
                PedSpawned = true
            end
        end
    end

    function zone:onExit()
        debugPrint("info", "Player exited the zone")
        for _, ped in ipairs(Peds) do
            DeleteEntity(ped)
        end

        for _, target in ipairs(Targets) do
            debugPrint("info", "Removing target: " .. target.name)
            if Config.TargetResource == 'ox_target' and GetResourceState(Config.TargetResource) == 'started' then
                exports.ox_target:removeModel(target.model)
            elseif Config.TargetResource == 'qb-target' and GetResourceState(Config.TargetResource) == 'started' then
                exports['qb-target']:RemoveTargetModel(target.model)
            end
        end

        Peds = {}
        Targets = {}
        PedSpawned = false
    end

    zones[#zones + 1] = zone
end