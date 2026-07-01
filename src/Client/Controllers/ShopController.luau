--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.networker)

local ShopController = {}
local networkerClient

function ShopController:Init()
	networkerClient = Networker.client.new("ShopService", self)
	Logger:info("ShopController", "ShopController started.")
end

function ShopController:BuyItem(itemId: string)
	local success, result = pcall(function()
		return networkerClient:fetch("BuyItem", itemId)
	end)
	if success then
		return result
	else
		Logger:warn("ShopController", "Failed to buy item: ", result)
		return { success = false, message = "Network error" }
	end
end

function ShopController:GiftItem(targetPlayer: Player, itemId: string)
	local success, result = pcall(function()
		return networkerClient:fetch("GiftItem", targetPlayer, itemId)
	end)
	if success then
		return result
	else
		Logger:warn("ShopController", "Failed to gift item: ", result)
		return { success = false, message = "Network error" }
	end
end

function ShopController:SimulateAddCoins()
	local success, result = pcall(function()
		return networkerClient:fetch("SimulateAddCoins")
	end)
	if success then
		return result
	else
		Logger:warn("ShopController", "Failed to simulate add coins: ", result)
		return false
	end
end

return ShopController
