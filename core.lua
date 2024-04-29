---@return table
---@description GetCore function to get ESX or QBCore object
function GetCore()
    local Framework = nil
    local Core = nil

    if GetResourceState('es_extended') == "started" then
        while Core == nil do
            local success, error = pcall(function()
                if Config.Debug then print("[^2INFO^7] ^5Getting ESX object^7") end
                Core = exports['es_extended']:getSharedObject()
                Framework = 'esx'
            end)

            if not success then
                print("[^1ERROR^7] ^1Error getting ESX object: ^7", error)
            else
                if Config.Debug then print("[^2INFO^7] ^5ESX object found^7") end
            end

            Citizen.Wait(0)
        end
    elseif GetResourceState('qb-core') == "started" then
        local success, error = pcall(function()
            if Config.Debug then print("^[^2INFO^7] ^5Getting QBCore object^7") end
            Core = exports['qb-core']:GetCoreObject()
            Framework = 'qb-core'
        end)

        if not success then
            print("[^1ERROR^7] ^1Error getting QBCore object: ^7", error)
        else
            if Config.Debug then print("[^2INFO^7] ^5QBCore object found^7") end
        end
    else
        print("[^1ERROR^7] ^1Core object not found^7")
    end

    if Core == nil then
        print("[^1ERROR^7] ^1Core object not found^7")
    end

    return Core, Framework
end