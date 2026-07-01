local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage.Packages

local Promise = require(Packages.promise)
local Signal = require(Packages.Signal)
local Networker = require(Packages.networker)

local UIServiceClient = {}

UIServiceClient.ShopDataChanged = Signal.new()
UIServiceClient.PurchaseCompleted = Signal.new()
UIServiceClient.OpenShopRequested = Signal.new()

local _shopData = {
	items = {},
	playerData = { coins = 0 }
}

function UIServiceClient:init()
	self.networker = Networker.client.new("ShopService", self)
	
	task.spawn(function()
		local openShopEvent = ReplicatedStorage:WaitForChild("OpenShopEvent", 10)
		if openShopEvent then
			openShopEvent.OnClientEvent:Connect(function()
				self.OpenShopRequested:Fire()
			end)
		else
			warn("UIServiceClient: OpenShopEvent not found!")
		end
	end)
end

function UIServiceClient:getShopItems()
	return Promise.new(function(resolve, reject)
		local success, result = pcall(function()
			return self.networker:fetch("sendShopData")
		end)
		
		if success and result then
			_shopData.items = result.Items
			_shopData.playerData = result.PlayerData
			self.ShopDataChanged:Fire(_shopData)
			resolve(_shopData.items)
		else
			warn("[UIServiceClient] Failed to fetch shop data:", result)
			reject(result or "Unknown error")
		end
	end)
end

function UIServiceClient:getPlayerData()
	return _shopData.playerData
end

function UIServiceClient:validatePurchase(itemId)
	local item = nil
	for _, i in ipairs(_shopData.items) do
		if i.id == itemId then
			item = i
			break
		end
	end
	
	if item and _shopData.playerData.coins >= item.price then
		return true
	end
	return false
end

function UIServiceClient:purchaseItem(itemId)
	task.spawn(function()
		local success, result = pcall(function()
			return self.networker:fetch("processPurchase", itemId)
		end)
		
		if success and result then
			if result.Success then
				_shopData.playerData.coins = result.NewBalance
				self.ShopDataChanged:Fire(_shopData)
			end
			self.PurchaseCompleted:Fire(result)
		else
			warn("Purchase failed:", result)
			self.PurchaseCompleted:Fire({ Success = false, Message = "Network error" })
		end
	end)
end

return UIServiceClient
