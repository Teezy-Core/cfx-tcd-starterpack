Targets, Peds = {}, {}
local IsBusy, PedSpawned = false, false
local Core, Framework = GetCore()

lib.locale()

-- [[ FUNCTIONS ]] --
local function deleteNearbyPeds(coords)
    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= PlayerPedId() then
            local pedCoords = GetEntityCoords(ped)
            if #(coords - pedCoords) <= 1.0 then
                DeleteEntity(ped)
            end
        end
    end
end

local function giveVehicleStarter(data)
    local vehicle = nil
    local vehicleSpawns = data.starter_vehicle.vehicle_spawns
    local isSpawn = false
    local randomVehicleModel = nil

    if IsPedInAnyVehicle(PlayerPedId(), true) then
        debugPrint("info", "Player is in a vehicle")
        Config.Notification(locale("player_in_vehicle"), "error", false)
        IsBusy = false
        return
    end

    if data.starter_vehicle.random_vehicle then
        debugPrint("info", "Random vehicle is enabled")

        local random = math.random(1, #Config.RandomVehicles.vehicles)
        randomVehicleModel = Config.RandomVehicles.vehicles[random]
        vehicle = GetHashKey(randomVehicleModel)

        debugPrint("info", "Random vehicle: " .. randomVehicleModel)
    else
        debugPrint("info", "Random vehicle is disabled")
        randomVehicleModel = data.starter_vehicle.model
        vehicle = GetHashKey(randomVehicleModel)
    end

    for spawnName, spawnCoords in pairs(vehicleSpawns) do
        local closestVehicle = GetClosestVehicle(spawnCoords.x, spawnCoords.y, spawnCoords.z, 3.0, 0, 70)
        if closestVehicle == 0 then
            if Framework == "esx" then
                debugPrint("info", "Framework: ESX")
                Core.Game.SpawnVehicle(vehicle, spawnCoords, spawnCoords.w, function(vehicle)
                    if data.starter_vehicle.teleport_player then
                        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
                    end

                    local vehicleData = {
                        props = Core.Game.GetVehicleProperties(vehicle),
                    }

                    Config.SetFuel(vehicle, data.starter_vehicle.fuel)
                    Config.GiveKey(vehicle, Core.Game.GetVehicleProperties(vehicle).plate)

                    TriggerServerEvent("cfx-tcd-starterpack:Server:ClaimVehicle", vehicleData)

                    IsBusy = false
                end, spawnCoords, true)
            elseif Framework == "qbc" then
                Core.Functions.SpawnVehicle(vehicle, function(veh)
                    if data.starter_vehicle.teleport_player then
                        TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
                    end

                    local vehicleData = {
                        props = Core.Functions.GetVehicleProperties(veh),
                        vehicle_name = randomVehicleModel
                    }

                    Config.SetFuel(veh, data.starter_vehicle.fuel)
                    Config.GiveKey(veh, Core.Functions.GetPlate(veh))

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
                    duration = 2000,
                    position = 'bottom',
                    useWhileDead = false,
                    canCancel = true,
                    disable = {
                        car = true,
                    },
                }) then
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                for _, ped in pairs(Peds) do
                    local pedCoords = GetEntityCoords(ped)
                    if #(playerCoords - pedCoords) < 3 then
                        lib.requestAnimDict("mp_common")
                        lib.requestAnimDict("amb@prop_human_atm@male@enter")

                        if not IsPedFacingPed(playerPed, ped, 30.0) then
                            TaskTurnPedToFaceEntity(playerPed, ped, 1500)
                            Wait(1500)
                        end

                        ClearPedTasksImmediately(ped)

                        TaskPlayAnim(playerPed, "mp_common", "givetake1_a", 8.0, 1.0, -1, 0, 0, false, false, false)
                        TaskPlayAnim(ped, "amb@prop_human_atm@male@enter", "enter", 8.0, 1.0, -1, 0, 0, false, false,
                            false)
                        Wait(1000)

                        debugPrint("info", "Giving starter pack to the player")
                        TriggerServerEvent("cfx-tcd-starterpack:Server:ClaimStarterpack", data.starterpack_type)

                        Wait(1000)
                        RemoveAnimDict("mp_common")
                        RemoveAnimDict("amb@prop_human_atm@male@enter")

                        StopAnimTask(playerPed, "amb@prop_human_atm@male@enter", "enter", 1.0)
                        StopAnimTask(ped, "mp_common", "givetake2_b", 1.0)
                        TaskStartScenarioInPlace(ped, data.ped.scenario, 0, true)

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
                IsBusy = false
            end
        end
    end)
end

local function showQuizDialog(callback)
    local questions = Config.DialogInfo.quiz.questions
    local wrongAnswers = 0

    math.randomseed(GetGameTimer())
    for i = #questions, 2, -1 do
        local j = math.random(i)
        questions[i], questions[j] = questions[j], questions[i]
    end

    for i, question in ipairs(questions) do
        local options = {}
        for _, answer in ipairs(question.answers) do
            table.insert(options, {
                label = answer.label,
                value = answer.label
            })
        end

        local input = lib.inputDialog('Question #' .. i, {
            {
                type = 'select',
                label = question.question,
                description = question.description,
                options = options,
                icon = 'fa-solid fa-question',
                required = true
            }
        }, {
            allowCancel = false
        })

        if input then
            local selectedAnswer = nil
            local correctAnswer = false

            for _, answer in ipairs(question.answers) do
                if input[1] == answer.label then
                    selectedAnswer = answer
                    if answer.correct then
                        correctAnswer = true
                    end
                end
            end

            if not correctAnswer then
                wrongAnswers = wrongAnswers + 1
            end
        end
    end

    if wrongAnswers == 0 then
        callback(true)
    else
        callback(false)
    end

    return wrongAnswers
end

local function generateCaptcha(type)
    if type == 'rl' then
        return string.char(math.random(65, 90)) ..
            string.char(math.random(65, 90)) .. string.char(math.random(65, 90)) ..
            string.char(math.random(65, 90)) .. string.char(math.random(65, 90)) .. string.char(math.random(65, 90))
    end
    if type == 'rn' then
        return tostring(math.random(100000, 999999))
    end
    if type == 'ra' then
        return generateCaptcha(math.random(1, 2) == 1 and 'rl' or 'rn')
    end
end

local function showCaptchaDialog(callback)
    local captcha = generateCaptcha(Config.DialogInfo.captcha.captcha_type)
    local input = lib.inputDialog('Solve the Captcha', {
        { type = 'input', label = 'Enter Captcha', description = 'Please enter: ' .. captcha, placeholder = 'Enter Captcha to continue', required = true }
    })

    if input and input[1] == captcha then
        callback(true)
    else
        callback(false)
    end
end

local function dialogHelper(data)
    if Config.DialogInfo.enable then
        local dialogType = Config.DialogInfo.dialog_type

        if dialogType == 'quiz' then
            showQuizDialog(function(success)
                if success then
                    debugPrint('info', 'Player has answered all the questions correctly')
                    Config.Notification(locale("answered_correctly"), 'success', false)

                    giveStarterPack(data)
                else
                    Config.Notification(locale("answered_incorrectly"), 'error', false)
                    IsBusy = false
                end
            end)
        elseif dialogType == 'captcha' then
            showCaptchaDialog(function(success)
                if success then
                    debugPrint('info', 'Player has solved the captcha')
                    Config.Notification(locale("solved_captcha"), 'success', false)

                    giveStarterPack(data)
                else
                    Config.Notification(locale("failed_captcha"), 'error', false)
                    IsBusy = false
                end
            end)
        elseif dialogType == 'rules' then
            local content = ''
            for i, rule in ipairs(Config.DialogInfo.rules) do
                content = content .. '### ' .. i .. '. ' .. rule.title .. '\n'
                content = content .. '> ' .. rule.description .. '\n\n'
            end
            local alert = lib.alertDialog({
                header = '# ' .. Config.DialogInfo.title .. '\n\n',
                content = content,
                centered = true,
                size = 'lg',
                cancel = true
            })

            if alert == 'confirm' then
                Config.Notification(locale("accepted_rules"), 'success', false)
                giveStarterPack(data)
            else
                Config.Notification(locale("declined_rules"), 'error', false)
                IsBusy = false
            end
        end
    else
        giveStarterPack(data)
    end
end

local function initializeTarget(data)
    if not Config.UseTarget then return end
    if Config.TargetResource == 'ox_target' and GetResourceState(Config.TargetResource) == 'started' then
        debugPrint('info', Config.TargetResource .. ' is started')
        local shown = false
        local option = {
            name = "tcd_starterpack_" .. math.random(1, 1000), -- This to avoid conflicts
            icon = data.icon,
            label = data.label,
            distance = data.distance,
            onSelect = function()
                debugPrint('info', 'Player is interacting with the ped')

                lib.callback('cfx-tcd-starterpack:CB:CheckPlayer', false, function(result)
                    if result then
                        debugPrint("info", "Player has already received the starter pack")
                        Config.Notification(locale("already_received"), "error", false)
                        IsBusy = false
                    else
                        if Config.DialogInfo.enable then
                            if not shown then
                                lib.alertDialog({
                                    header = Config.DialogInfo.title,
                                    content = Config.DialogInfo.alert_description,
                                    centered = true,
                                    cancel = false
                                })
                                shown = true
                            end
                        end
                        dialogHelper(data)
                    end
                end)

                IsBusy = false
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
        debugPrint('info', Config.TargetResource .. ' is started')

        local shown = false
        exports['qb-target']:AddTargetModel(data.ped.model, {
            options = {
                {
                    type = "client",
                    icon = data.icon,
                    label = data.label,
                    action = function()
                        debugPrint('info', 'Player is interacting with the ped')

                        lib.callback('cfx-tcd-starterpack:CB:CheckPlayer', false, function(result)
                            if result then
                                debugPrint("info", "Player has already received the starter pack")
                                Config.Notification(locale("already_received"), "error", false)
                                IsBusy = false
                            else
                                if Config.DialogInfo.enable then
                                    if not shown then
                                        lib.alertDialog({
                                            header = Config.DialogInfo.title,
                                            content = Config.DialogInfo.alert_description,
                                            centered = true,
                                            cancel = false
                                        })
                                        shown = true
                                    end
                                end
                                dialogHelper(data)
                            end
                        end)

                        IsBusy = false
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
    else
        debugPrint('error', Config.TargetResource .. ' is not started')
    end
end

local function draw3DText(coords, text, color)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    local camCoords = GetGameplayCamCoord()
    local distance = GetDistanceBetweenCoords(camCoords, coords.x, coords.y, coords.z, true)
    local scale = (1 / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100

    if onScreen then
        SetTextScale(0.0, 0.35)
        SetTextFont(4)
        SetTextProportional(true)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(x, y)
    end
end

local function spawnPeds(data)
    debugPrint('info', 'Spawning peds')
    deleteNearbyPeds(vector3(data.coords.x, data.coords.y, data.coords.z))
    Wait(100)

    local ped = SetPed(data.ped.model, data.coords, true, false, data.ped.scenario, false)
    Peds[#Peds + 1] = ped

    local inRange = false
    local shownTextUI = false
    local coords = data.coords
    local shown = false

    if not Config.UseTarget then
        local claimZone = lib.zones.sphere({
            name = 'claimZone',
            coords = vector3(data.coords.x, data.coords.y, data.coords.z),
            radius = data.receiving_radius,
            debug = Config.Debug,
        })

        function claimZone:onEnter()
            inRange = true
            debugPrint('info', 'Player is in range to interact with the ped')

            CreateThread(function()
                repeat
                    local playerPed = cache.ped or PlayerPedId()
                    local playerCoords = GetEntityCoords(playerPed)
                    local distance = #(playerCoords - coords.xyz)

                    if distance < data.distance and not IsPedInAnyVehicle(playerPed, true) and not IsEntityDead(playerPed) and not IsBusy then
                        if not shownTextUI and not Config.Use3DText then
                            shownTextUI = true
                            lib.showTextUI('Press [E] to receive your starter pack', {
                                icon = 'fa-solid fa-gift',
                            })
                        elseif Config.Use3DText then
                            draw3DText(coords.xyz, "Press ~g~[E]~w~ to receive your starter pack",
                                { r = 255, g = 255, b = 255, a = 255 })
                        end

                        if IsControlJustPressed(0, 38) then
                            debugPrint('info', 'Player is interacting with the ped')
                            lib.callback('cfx-tcd-starterpack:CB:CheckPlayer', false, function(result)
                                if result then
                                    debugPrint("info", "Player has already received the starter pack")
                                    Config.Notification(locale("already_received"), "error", false)
                                    IsBusy = false
                                else
                                    if Config.DialogInfo.enable then
                                        if not shown then
                                            lib.alertDialog({
                                                header = Config.DialogInfo.title,
                                                content = Config.DialogInfo.alert_description,
                                                centered = true,
                                                cancel = false
                                            })
                                            shown = true
                                        end
                                    end
                                    dialogHelper(data)
                                    IsBusy = true
                                end
                            end)
                            IsBusy = false
                        end
                    else
                        if shownTextUI then
                            shownTextUI = false
                            lib.hideTextUI()
                        end
                    end

                    Wait(0)
                until not inRange
            end)
        end

        function claimZone:onExit()
            inRange = false
            debugPrint('info', 'Player is out of range to interact with the ped')
            if shownTextUI then
                shownTextUI = false
                lib.hideTextUI()
            end
        end
    end

    initializeTarget(data)
end
-- [[ END FUNCTIONS ]] --

for _, location in pairs(Config.Locations) do
    spawnPeds(location)

    if location.safezone.enable and #location.safezone.zone_points == 0 then
        debugPrint("error", "Safezone is enabled for location but no zone points are defined")
        return
    end
    if location.safezone.enable then
        debugPrint("info", "Safezone is enabled")
        local playerPed = cache.ped or PlayerPedId()

        local safezone = lib.zones.poly({
            points = location.safezone.zone_points,
            thickness = 2,
            debug = Config.Debug,
        })

        function safezone:inside()
            SetPlayerCanDoDriveBy(playerPed, false)
            SetCurrentPedWeapon(playerPed, GetHashKey("WEAPON_UNARMED"), true)
            DisablePlayerFiring(playerPed, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 106, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 47, true)
            SetEntityProofs(playerPed, true, true, true, true, true, true, true, true)
        end

        function safezone:onEnter()
            debugPrint("info", "Player entered the safezone")

            Config.Notification(locale("safezone_enter"), "info", false)
        end

        function safezone:onExit()
            debugPrint("info", "Player exited the safezone")
            Config.Notification(locale("safezone_exit"), "info", false)

            SetPlayerCanDoDriveBy(playerPed, true)
            SetEntityProofs(playerPed, false, false, false, false, false, false, false, false)
        end
    end
end

-- [[ EVENTS ]] --
RegisterNetEvent('cfx-tcd-starterpack:Client:ShowStarterPacks', function(data)
    local options = {}

    for _, player in ipairs(data) do
        table.insert(options, {
            title = player.name .. " - " .. player.date_received,
            description = "Click to view more information",
            icon = 'fa-solid fa-gift',
            metadata = {
                { label = 'Player', value = player.name },
                { label = 'Time',   value = player.date_received },
                { label = 'Status', value = player.received and 'Received' or 'Not Received' }
            },
            onSelect = function()
                local input = lib.inputDialog('Update Starter Pack', {
                    {
                        type = 'input',
                        label = 'Player Name',
                        description = 'Name of the player',
                        default = player.name,
                        disabled = true
                    },
                    {
                        type = 'input',
                        label = 'Player Identifier',
                        description = 'Identifier of the player',
                        default = player.identifier,
                        disabled = true
                    },
                    {
                        type = 'input',
                        label = 'Status',
                        description = 'Status of the starter pack',
                        default = player.received and 'Received' or 'Not Received',
                        disabled = true
                    },

                    {
                        type = 'date',
                        label = 'Date Received',
                        description = 'Date the player received the starter pack',
                        default = player.date_received,
                        format = "DD/MM/YYYY",
                        disabled = true
                    },

                    {
                        type = 'select',
                        label = 'Starter Pack',
                        description = 'Select an option to update the starter pack',
                        options = {
                            { label = 'Reset Starter Pack', value = 'reset' },
                            { label = 'Delete Data',        value = 'delete' }
                        },
                        default = 'reset',
                        required = true
                    },
                })

                if input then
                    if input[5] == 'reset' then
                        debugPrint("info", "Resetting the starter pack for " .. player.name)
                        Config.Notification("Starter pack has been reset for " .. player.name, "info", false)

                        TriggerServerEvent("cfx-tcd-starterpack:Server:UpdateStarterPack", player.identifier, 'reset')
                    elseif input[5] == 'delete' then
                        debugPrint("info", "Deleting the data for " .. player.name)
                        Config.Notification("Data has been deleted for " .. player.name, "info", false)

                        TriggerServerEvent("cfx-tcd-starterpack:Server:UpdateStarterPack", player.identifier, 'delete')
                    end
                end
            end
        })
    end

    lib.registerContext({
        id = 'starterpacks',
        title = 'Starter Packs',
        options = options
    })

    lib.showContext('starterpacks')
end)

RegisterNetEvent("cfx-tcd-starterpack:Client:GiveStarterVehicle", function(data)
    local vehicle = nil
    local selectedVehicleModel = nil

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)

    if data.random_vehicle then
        local random = math.random(1, #Config.RandomVehicles.vehicles)
        selectedVehicleModel = Config.RandomVehicles.vehicles[random]
        vehicle = GetHashKey(selectedVehicleModel)
    else
        selectedVehicleModel = data.model
        vehicle = GetHashKey(data.model)
    end

    if Framework == "esx" then
        Core.Game.SpawnVehicle(vehicle, playerCoords, playerHeading, function(vehicle)
            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
            Config.SetFuel(vehicle, data.fuel)
            Config.GiveKey(vehicle, Core.Game.GetVehicleProperties(vehicle).plate)

            local vehicleData = {
                props = Core.Game.GetVehicleProperties(vehicle),
            }

            TriggerServerEvent("cfx-tcd-starterpack:Server:ClaimVehicle", vehicleData)
        end, playerCoords, true)
    elseif Framework == "qbc" then
        Core.Functions.SpawnVehicle(vehicle, function(vehicle)
            TaskWarpPedIntoVehicle(playerPed, vehicle, -1)
            Config.SetFuel(vehicle, data.fuel)
            Config.GiveKey(vehicle, Core.Functions.GetPlate(vehicle))

            local vehicleData = {
                props = Core.Functions.GetVehicleProperties(vehicle),
                vehicle_name = selectedVehicleModel
            }

            TriggerServerEvent("cfx-tcd-starterpack:Server:ClaimVehicle", vehicleData)
        end, playerCoords, true)
    end
end)
-- [[ END EVENTS ]] --

AddEventHandler('onResourceStop', function(resource)
    if GetCurrentResourceName() == resource then
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

        Targets = {}
        Peds = {}
    end
end)

lib.callback.register("cfx-tcd-starterpack:CB:CheckReceivingRadius", function()
    local playerPed = cache.ped or PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    for _, location in pairs(Config.Locations) do
        local pedCoords = location.coords.xyz
        if #(playerCoords - pedCoords) < location.receiving_radius then
            return true
        end
    end
    return false
end)
