--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local UI = require(ReplicatedStorage.UI)


UI()
Logger:info("ClientBootstrapper", "UI modules initialized.")

local function loadAndInitFolder(folderName: string)
	local folder = script:FindFirstChild(folderName)
	if not folder then return end

	local modules = {}
	for _, moduleScript in ipairs(folder:GetChildren()) do
		if moduleScript:IsA("ModuleScript") then
			local success, mod = pcall(require, moduleScript)
			if success and type(mod) == "table" then
				modules[moduleScript.Name] = mod
			else
				Logger:error("ClientBootstrapper", "Failed to require " .. folderName .. " module: " .. moduleScript.Name .. " - " .. tostring(mod))
			end
		end
	end

	for name, mod in pairs(modules) do
		if type(mod.Init) == "function" then
			local success, err = pcall(function()
				mod:Init()
			end)
			if success then
				Logger:info("ClientBootstrapper", folderName .. "/" .. name .. " initialized.")
			else
				Logger:error("ClientBootstrapper", folderName .. "/" .. name .. " failed Init: " .. tostring(err))
			end
		elseif type(mod.init) == "function" then
			local success, err = pcall(function()
				mod:init()
			end)
			if success then
				Logger:info("ClientBootstrapper", folderName .. "/" .. name .. " (lowercase) initialized.")
			else
				Logger:error("ClientBootstrapper", folderName .. "/" .. name .. " failed init: " .. tostring(err))
			end
		end
	end
end


loadAndInitFolder("Services")
loadAndInitFolder("Controllers")

Logger:info("ClientBootstrapper", "All client controllers and services loaded.")