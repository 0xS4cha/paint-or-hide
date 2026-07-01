--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Networker = require(ReplicatedStorage.Packages.networker)

local PlayerDataServiceClient = {}
PlayerDataServiceClient.LocalDataChanged = Signal.new()
PlayerDataServiceClient.Data = nil

local networkerClient

function PlayerDataServiceClient:Init()
	networkerClient = Networker.client.new("PlayerDataService", self)
	self.networkerClient = networkerClient

	
	networkerClient:getServerChangedSignal("Data"):Connect(function(newData)
		self.Data = newData
		Logger:info("PlayerDataServiceClient", "Local data updated: ", newData)
		self.LocalDataChanged:Fire(newData)
	end)

	
	task.spawn(function()
		local success, result = pcall(function()
			return networkerClient:fetch("FetchData")
		end)
		if success and result then
			self.Data = result
			self.LocalDataChanged:Fire(result)
			Logger:info("PlayerDataServiceClient", "Successfully fetched initial data.")
		else
			Logger:warn("PlayerDataServiceClient", "Did not load data on initial startup: ", result)
		end
	end)
end

function PlayerDataServiceClient:GetData()
	return self.Data
end

function PlayerDataServiceClient:GetOtherPlayerData(targetPlayer: Player)
	local success, result = pcall(function()
		return networkerClient:fetch("FetchOtherPlayerData", targetPlayer)
	end)
	if success then
		return result
	end
	return nil
end

return PlayerDataServiceClient
