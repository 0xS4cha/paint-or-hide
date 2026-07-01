--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)

local services: { [string]: any } = {}


local servicesFolder = script:WaitForChild("Services")
for _, moduleScript in ipairs(servicesFolder:GetChildren()) do
	if moduleScript:IsA("ModuleScript") then
		local success, service = pcall(require, moduleScript)
		if success and type(service) == "table" then
			services[moduleScript.Name] = service
		else
			Logger:error("ServerBootstrapper", "Failed to require service: " .. moduleScript.Name .. " - " .. tostring(service))
		end
	end
end


for name, service in pairs(services) do
	if type(service.Init) == "function" then
		local success, err = pcall(function()
			service:Init()
		end)
		if success then
			Logger:info("ServerBootstrapper", name .. " initialized successfully.")
		else
			Logger:error("ServerBootstrapper", name .. " failed to initialize: " .. tostring(err))
		end
	elseif type(service.init) == "function" then
		local success, err = pcall(function()
			service:init()
		end)
		if success then
			Logger:info("ServerBootstrapper", name .. " (lowercase init) initialized successfully.")
		else
			Logger:error("ServerBootstrapper", name .. " failed to initialize: " .. tostring(err))
		end
	end
end

Logger:info("ServerBootstrapper", "All server services loaded and initialized.")
