Core, Framework = GetCore()

-- lib.callback('cfx-tcd-starterpack:CheckPlayer', false, function(data)
--     print("Checking player: " .. data)
-- end)

RegisterCommand("testdata", function(source, args, raw)
    print("Testing data")
    lib.callback('cfx-tcd-starterpack:CheckPlayer', false, function(data)
        if data then
            print("Checking player: " .. json.encode(data))
        else
            print("No data: " .. json.encode(data))
        end
    end)
end, false)
