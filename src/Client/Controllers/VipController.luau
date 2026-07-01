--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.networker)

local VipController = {}
local networkerClient

function VipController:Init()
	networkerClient = Networker.client.new("VipService", self)
	Logger:info("VipController", "VipController started.")
end


function VipController:ToggleParticles(): boolean
	local success, result = pcall(function()
		return networkerClient:fetch("ToggleVipParticles")
	end)
	if success then
		Logger:info("VipController", "VIP Particles toggled. New state: ", result)
		return result
	else
		Logger:warn("VipController", "Failed to toggle particles: ", result)
		return false
	end
end


function VipController:IsVip(): boolean
	local success, result = pcall(function()
		return networkerClient:fetch("GetVipStatus")
	end)
	if success then
		return result
	end
	return false
end

return VipController
