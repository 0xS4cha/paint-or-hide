local HttpService = game:GetService("HttpService")
local TestService = game:GetService("TestService")

local Logger = {}
Logger.Enabled = true

local function tableToString(t)
    local result = "{"
    for k, v in pairs(t) do
        local key = tostring(k)
        local value
        if type(v) == "table" then
            value = tableToString(v)
        else
            value = tostring(v)
        end
        result = result .. key .. "=" .. value .. ", "
    end
    return result .. "}"
end

local function parseArguments(...)
    local arguments = {...}
    local parsedArguments = {}
    for _, v in pairs(arguments) do
        if type(v) == "table" then
            parsedArguments[#parsedArguments + 1] = tableToString(v)
        else
            parsedArguments[#parsedArguments + 1] = tostring(v)
        end
    end
    return parsedArguments
end

function Logger:error(module, ...)
    if not self.Enabled then return end
    warn("🔴 [ERROR] [" .. string.upper(module) .. "] > " .. table.concat(parseArguments(...), " "))
end

function Logger:info(module, ...)
    if not self.Enabled then return end
    TestService:Message("🔵 [INFO] [" .. string.upper(module) .. "] > " .. table.concat(parseArguments(...), " "))
end

function Logger:warn(module, ...)
    if not self.Enabled then return end
    warn("🟡 [WARN] [" .. string.upper(module) .. "] > " .. table.concat(parseArguments(...), " "))
end

function Logger:debug(module, data)
    if not self.Enabled then return end
    local encoded = HttpService:JSONEncode(data)
    print("🟣 [TRACE] [" .. string.upper(module) .. "] > " .. encoded)
end

return Logger
