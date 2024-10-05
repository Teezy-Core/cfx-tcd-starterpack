local tableExist = false

---@param query string
---@param params table
---@description FetchQuery function to fetch data from the database
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

---@param query string
---@param params table
---@param callback function
---@description ExecuteQuery function to execute a query on the database
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

---@param query string
---@param params table
---@param callback function
---@description InsertQuery function to insert data into the database
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

---@description CheckTable function to check if the table exists in the database
---@return boolean
function CheckTable()
    if tableExist then
        return true
    end

    local query = [[
        CREATE TABLE IF NOT EXISTS tcd_starterpack (
            id INT AUTO_INCREMENT PRIMARY KEY,
            identifier VARCHAR(50) NOT NULL,
            received BOOLEAN NOT NULL,
            date_received DATETIME
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]]
    local params = {}

    ExecuteQuery(query, params, function()
        tableExist = true
    end)

    return tableExist
end