Core, Framework = GetCore()

function AddItemToInventory(playerId, item, amount)
    if Config.InventoryResource == 'ox_inventory' then
        -- Implementation for OX Inventory
    elseif Config.InventoryResource == 'qb-inventory' or Config.InventoryResource == 'ps-inventory' then
        -- Implementation for QBCore Inventory
    else
        print('Unsupported inventory resource: ' .. Config.InventoryResource)
    end
end

function FetchQuery(query, params)
    if Config.SQLResource == 'oxmysql' then
        return exports.oxmysql:query_async(query, params)
    elseif Config.SQLResource == 'mysql-async' then
        return MySQL.query.await(query, params)
    elseif Config.SQLResource == 'ghmattimysql' then
        return exports.ghmattimysql.execute(query, params)
    else
        print('Unsupported SQL resource: ' .. Config.SQLResource)
    end
end


function ExecuteQuery(query, params, callback)
    if Config.SQLResource == 'oxmysql' then
        exports.oxmysql:execute(query, params, callback)
    elseif Config.SQLResource == 'mysql-async' then
        MySQL.Async.execute(query, params, callback)
    elseif Config.SQLResource == 'ghmattimysql' then
        exports.ghmattimysql.execute(query, params, callback)
    else
        print('Unsupported SQL resource: ' .. Config.SQLResource)
    end
end

function InsertQuery(query, params, callback)
    if Config.SQLResource == 'oxmysql' then
        exports.oxmysql:insert(query, params, callback)
    elseif Config.SQLResource == 'mysql-async' then
        MySQL.Async.insert(query, params, callback)
    elseif Config.SQLResource == 'ghmattimysql' then
        exports.ghmattimysql.execute(query, params, callback)
    else
        print('Unsupported SQL resource: ' .. Config.SQLResource)
    end
end