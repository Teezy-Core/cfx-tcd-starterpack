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
            name VARCHAR(50) NOT NULL,
            identifier VARCHAR(50) NOT NULL,
            received BOOLEAN NOT NULL,
            date_received DATETIME
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
    ]]
    local params = {}

    ExecuteQuery(query, params, function()
        tableExist = true
        CheckColumns() -- Check for columns after table creation
    end)

    return tableExist
end

function CheckColumns()
    local columns = {
        { name = "name",          type = "VARCHAR(50) NOT NULL" },
        { name = "identifier",    type = "VARCHAR(50) NOT NULL" },
        { name = "received",      type = "BOOLEAN NOT NULL" },
        { name = "date_received", type = "DATETIME" }
    }

    for _, column in ipairs(columns) do
        local checkQuery = string.format([[
            SELECT COUNT(*) AS count FROM information_schema.COLUMNS
            WHERE TABLE_NAME = 'tcd_starterpack'
            AND COLUMN_NAME = '%s';
        ]], column.name)

        local result = FetchQuery(checkQuery, {})

        if result and result[1] and result[1].count == 0 then
            local alterQuery = string.format([[
                ALTER TABLE tcd_starterpack
                ADD COLUMN %s %s;
            ]], column.name, column.type)

            ExecuteQuery(alterQuery, {})
        end
    end
end

-- Call CheckTable to ensure the table and columns are set up
if Config.DBChecking then
    CheckTable()
end