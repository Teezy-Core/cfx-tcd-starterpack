---@return table
---@description GetCore function to get the core object
---@usage local Core, Framework = GetCore()
local CachedCore, CachedFramework = nil, nil

function GetCore()
    if CachedCore and CachedFramework then
        return CachedCore, CachedFramework
    end

    local Resources = {
        Config.TargetResource,
        Config.InventoryResource,
        Config.SQLResource
    }

    local Frameworks = {
        {name = 'es_extended', obj = 'getSharedObject', framework = 'esx'},
        {name = 'qb-core', obj = 'GetCoreObject', framework = 'qbc'},
        {name = 'qbx_core', obj = 'GetCoreObject', framework = 'qbx'}
    }
    
    local Core, Framework = nil, nil

    if Config.Debug then print("[^2INFO^7] ^5Getting Core object^7") end

    for _, fw in ipairs(Frameworks) do
        if GetResourceState(fw.name) == "started" then
            local success, err = pcall(function()
                if Config.Debug then print(("[^2INFO^7] ^5Getting %s object^7"):format(fw.framework)) end
                Core = exports[fw.name][fw.obj]()
                Framework = fw.framework
            end)
            
            if not success then
                print(("[^1ERROR^7] ^1Error getting %s object: ^7%s"):format(fw.framework, err))
            else
                if Config.Debug then print(("[^2INFO^7] ^5%s object found^7"):format(fw.framework)) end
                CachedCore, CachedFramework = Core, Framework
                for _, resource in ipairs(Resources) do
                    if resource == Config.TargetResource and not Config.UseTarget then
                        if Config.Debug then print(("[^2INFO^7] ^5Skipping %s Resource check as UseTarget is false^7"):format(resource)) end
                    else
                        if GetResourceState(resource) ~= "started" then
                            error(("[^1ERROR] %s Resource not found^7"):format(resource))
                        end
                    end
                end
                return Core, Framework
            end
        end
        Citizen.Wait(0)
    end

    error("Framework or Core object not found")
end