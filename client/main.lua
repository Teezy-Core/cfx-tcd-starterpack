local Core, Framework = GetCore()
local Peds = {}
local Targets = {}

local function StarterVehicle()
    local vehicle = GetHashKey(Config.StarterVehicle.model)
    local vehicleSpawn = Config.StarterVehicle.vehicle_spawn
    if #(GetEntityCoords(PlayerPedId()) - vector3(vehicleSpawn.x, vehicleSpawn.y, vehicleSpawn.z)) > 10 then
        Config.Notification(Config.Locale[Config.Lang]['not_near_receiving_point'], 'error', false, source)
        return
    end
    if Framework == 'esx' then
        Core.Game.SpawnVehicle(vehicle, vehicleSpawn, vehicleSpawn.w, function(vehicle)
            if Config.StarterVehicle.teleport_player then
                TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
            end
            Config.SetFuel(vehicle, Config.StarterVehicle.fuel)

            local vehicleData = {
                props = Core.Game.GetVehicleProperties(vehicle),
            }

            TriggerServerEvent('cfx-tcd-starterpack:ClaimVehicle', vehicleData)
        end)
    else
        Core.Functions.SpawnVehicle(vehicle, function(veh)
            SetEntityHeading(veh, vehicleSpawn.w)
            if Config.StarterVehicle.teleport_player then
                TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
            end
            Config.SetFuel(veh, Config.StarterVehicle.fuel)

            local vehicleData = {
                props = Core.Functions.GetVehicleProperties(veh),
            }
            TriggerEvent("vehiclekeys:client:SetOwner", Core.Functions.GetPlate(veh))
            TriggerServerEvent('cfx-tcd-starterpack:ClaimVehicle', vehicleData)
        end, vehicleSpawn, true)
    end
end

local function InitializeScenario()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    for _, ped in pairs(Peds) do
        local pedCoords = GetEntityCoords(ped)
        if #(playerCoords - pedCoords) < 3 then
            LoadAnimDict("mp_common")
            LoadAnimDict("amb@prop_human_atm@male@enter")
            local boxprop = MakeProp({ prop = `hei_prop_heist_box`, coords = vector4(0, 0, 0, 0) }, 0, 1)
            AttachEntityToEntity(boxprop, ped, GetPedBoneIndex(ped, 57005), 0.1, -0.0, 0.0, -90.0, 0.0, 0.0, true, true,
                false, true, 1, true)
            ClearPedTasksImmediately(ped)
            LookEntity(ped)
            TaskPlayAnim(playerPed, "amb@prop_human_atm@male@enter", "enter", 1.0, 1.0, 0.3, 16, 0.2, 0, 0, 0)
            TaskPlayAnim(ped, "mp_common", "givetake2_b", 1.0, 1.0, 0.3, 16, 0.2, 0, 0, 0)
            Wait(1000)
            AttachEntityToEntity(boxprop, playerPed, GetPedBoneIndex(playerPed, 57005), 0.1, -0.0, 0.0, -90.0, 0.0, 0.0,
                true, true, false, true, 1, true)
            Wait(1000)

            TriggerServerEvent("cfx-tcd-starterpack:ClaimStarterpack")

            Wait(1000)
            StopAnimTask(playerPed, "amb@prop_human_atm@male@enter", "enter", 1.0)
            StopAnimTask(ped, "mp_common", "givetake2_b", 1.0)
            TaskStartScenarioInPlace(ped, "WORLD_HUMAN_GUARD_STAND", -1, true)
            UnloadAnimDict("mp_common")
            UnloadAnimDict("amb@prop_human_atm@male@enter")
            DestroyProp(boxprop)
            UnloadModel(`prop_paper_bag_small`)
            DeleteObject(boxprop)

            Wait(1000)
            if Config.EnableStarterVehicle then
                StarterVehicle()
            end
        end
    end
end

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
                    lib.callback('cfx-tcd-starterpack:CheckPlayer', false, function(data)
                        if data then
                            if lib.progressCircle({
                                    duration = 3000,
                                    position = 'bottom',
                                    useWhileDead = false,
                                    canCancel = true,
                                }) then
                                InitializeScenario()
                            else
                                Config.Notification(Config.Locale[Config.Lang]['canceled'], 'inform', false, source)
                            end
                        else
                            Config.Notification(Config.Locale[Config.Lang]['received'], 'error', false, source)
                        end
                    end)
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
                            lib.callback('cfx-tcd-starterpack:CheckPlayer', false, function(data)
                                if data then
                                    if lib.progressCircle({
                                            duration = 3000,
                                            position = 'bottom',
                                            useWhileDead = false,
                                            canCancel = true,
                                        }) then
                                        InitializeScenario()
                                    else
                                        Config.Notification(Config.Locale[Config.Lang]['canceled'], 'inform', false,
                                            source)
                                    end
                                else
                                    Config.Notification(Config.Locale[Config.Lang]['received'], 'error', false, source)
                                end
                            end)
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
        local vehicleSpawn = Config.StarterVehicle.vehicle_spawn
        if #(GetEntityCoords(PlayerPedId()) - vector3(vehicleSpawn.x, vehicleSpawn.y, vehicleSpawn.z)) > 10 then
            Config.Notification(Config.Locale[Config.Lang]['not_near_receiving_point'], 'error', false, source)
            return
        end
        lib.callback('cfx-tcd-starterpack:CheckPlayer', source, function(data)
            if data then
                if lib.progressCircle({
                        duration = 3000,
                        position = 'bottom',
                        useWhileDead = false,
                        canCancel = true,
                    })
                then
                    TriggerServerEvent("cfx-tcd-starterpack:ClaimStarterpack")
                    Wait(1000)
                    if Config.EnableStarterVehicle then
                        StarterVehicle()
                    end
                else
                    Config.Notification(Config.Locale[Config.Lang]['canceled'], 'inform', false, source)
                end
            else
                Config.Notification(Config.Locale[Config.Lang]['received'], 'error', false, source)
            end
        end)
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
