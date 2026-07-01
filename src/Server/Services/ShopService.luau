--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.networker)
local PlayerDataService = require(script.Parent.PlayerDataService)
local InteractionService = require(script.Parent.InteractionService)
local Config = require(ReplicatedStorage.Shared.Config)
local ShopItems = Config.Shop

local ShopService = {}
local networkerServer

function ShopService:Init()
	networkerServer = Networker.server.new("ShopService", self, {})

	Logger:info("ShopService", "ShopService started.")
end

-- function ShopService:BuyItem(player: Player, itemId: string)
-- 	local item = ShopItems[itemId]
-- 	if not item then
-- 		InteractionService:SendNotification(player, "Boutique", "Objet inconnu !", "Error")
-- 		return { success = false, message = "Objet inconnu" }
-- 	end

-- 	local price = item.DiscountPrice or item.NormalPrice
-- 	local success = false
-- 	local errMsg = ""

-- 	PlayerDataService:Update(player, function(data)
-- 		local balance = data.Coins or 0
-- 		local inventory = data.Inventory or {}
		
-- 		local isUnique = item.Category == "Profile" or item.Category == "Items"
-- 		if isUnique and inventory[itemId] and inventory[itemId] > 0 then
-- 			success = false
-- 			errMsg = "Vous possédez déjà cet objet !"
-- 			return data
-- 		end

-- 		if balance < price then
-- 			success = false
-- 			errMsg = "Jetons insuffisants !"
-- 			return data
-- 		end

-- 		data.Coins = balance - price

-- 		inventory[itemId] = (inventory[itemId] or 0) + 1
-- 		data.Inventory = inventory

-- 		local history = data.History or {}
-- 		table.insert(history, {
-- 			Action = "buy",
-- 			ItemId = itemId,
-- 			Price = price,
-- 			Timestamp = os.time(),
-- 		})
-- 		if #history > 50 then
-- 			table.remove(history, 1)
-- 		end
-- 		data.History = history

-- 		success = true
-- 		return data
-- 	end)

-- 	if success then
-- 		InteractionService:SendNotification(
-- 			player,
-- 			"Achat réussi ! 🎉",
-- 			"Vous avez acheté " .. item.Name .. " pour " .. price .. " jetons.",
-- 			"Success"
-- 		)

-- 		if itemId == "sub_vip_1month" or itemId == "sub_vip_3month" or itemId == "sub_mvp_1month" then
-- 			local successVip, VipService = pcall(function()
-- 				return require(script.Parent.VipService)
-- 			end)
-- 			if successVip and VipService then
-- 				VipService:AwardVip(player)
-- 			end
-- 		end

-- 		return { success = true, message = "Achat réussi" }
-- 	else
-- 		InteractionService:SendNotification(player, "Achat échoué", errMsg, "Error")
-- 		return { success = false, message = errMsg }
-- 	end
-- end

-- function ShopService:GiftItem(player: Player, targetPlayer: Player, itemId: string)
-- 	local item = ShopItems[itemId]
-- 	if not item then
-- 		InteractionService:SendNotification(player, "Boutique", "Objet inconnu !", "Error")
-- 		return { success = false, message = "Objet inconnu" }
-- 	end

-- 	if not targetPlayer or not targetPlayer:IsDescendantOf(Players) then
-- 		InteractionService:SendNotification(player, "Cadeau", "Le destinataire n'est plus en jeu !", "Error")
-- 		return { success = false, message = "Destinataire hors ligne" }
-- 	end

-- 	if player == targetPlayer then
-- 		InteractionService:SendNotification(player, "Cadeau", "Vous ne pouvez pas vous offrir un cadeau à vous-même !", "Error")
-- 		return { success = false, message = "Action impossible" }
-- 	end

-- 	local targetData = PlayerDataService:Get(targetPlayer)
-- 	if targetData then
-- 		local targetInventory = targetData.Inventory or {}
-- 		local isUnique = item.Category == "Profile" or item.Category == "Items"
-- 		if isUnique and targetInventory[itemId] and targetInventory[itemId] > 0 then
-- 			InteractionService:SendNotification(player, "Cadeau", "Ce joueur possède déjà cet objet !", "Error")
-- 			return { success = false, message = "Déjà possédé" }
-- 		end
-- 	end

-- 	local price = item.DiscountPrice or item.NormalPrice
-- 	local success = false
-- 	local errMsg = ""

-- 	PlayerDataService:Update(player, function(data)
-- 		local balance = data.Coins or 0
-- 		if balance < price then
-- 			success = false
-- 			errMsg = "Jetons insuffisants !"
-- 			return data
-- 		end

-- 		data.Coins = balance - price

-- 		local history = data.History or {}
-- 		table.insert(history, {
-- 			Action = "gift",
-- 			ItemId = itemId,
-- 			TargetName = targetPlayer.DisplayName or targetPlayer.Name,
-- 			Price = price,
-- 			Timestamp = os.time(),
-- 		})
-- 		if #history > 50 then
-- 			table.remove(history, 1)
-- 		end
-- 		data.History = history

-- 		success = true
-- 		return data
-- 	end)

-- 	if success then
-- 		PlayerDataService:Update(targetPlayer, function(data)
-- 			local inventory = data.Inventory or {}
-- 			inventory[itemId] = (inventory[itemId] or 0) + 1
-- 			data.Inventory = inventory

-- 			local gifts = data.Gifts or {}
-- 			table.insert(gifts, {
-- 				SenderName = player.DisplayName or player.Name,
-- 				ItemId = itemId,
-- 				Timestamp = os.time(),
-- 			})
-- 			if #gifts > 50 then
-- 				table.remove(gifts, 1)
-- 			end
-- 			data.Gifts = gifts

-- 			local history = data.History or {}
-- 			table.insert(history, {
-- 				Action = "receive_gift",
-- 				ItemId = itemId,
-- 				SenderName = player.DisplayName or player.Name,
-- 				Timestamp = os.time(),
-- 			})
-- 			if #history > 50 then
-- 				table.remove(history, 1)
-- 			end
-- 			data.History = history

-- 			return data
-- 		end)

-- 		InteractionService:SendNotification(
-- 			player,
-- 			"Cadeau envoyé ! 🎁",
-- 			"Vous avez offert " .. item.Name .. " à " .. (targetPlayer.DisplayName or targetPlayer.Name) .. ".",
-- 			"Success"
-- 		)

-- 		InteractionService:SendNotification(
-- 			targetPlayer,
-- 			"Cadeau reçu ! 🎁",
-- 			(player.DisplayName or player.Name) .. " vous a offert " .. item.Name .. " !",
-- 			"Success"
-- 		)

-- 		if itemId == "sub_vip_1month" or itemId == "sub_vip_3month" or itemId == "sub_mvp_1month" then
-- 			local successVip, VipService = pcall(function()
-- 				return require(script.Parent.VipService)
-- 			end)
-- 			if successVip and VipService then
-- 				VipService:AwardVip(targetPlayer)
-- 			end
-- 		end

-- 		return { success = true, message = "Cadeau envoyé" }
-- 	else
-- 		InteractionService:SendNotification(player, "Cadeau échoué", errMsg, "Error")
-- 		return { success = false, message = errMsg }
-- 	end
-- end

-- function ShopService:SimulateAddCoins(player: Player)
-- 	PlayerDataService:Update(player, function(data)
-- 		data.Coins = (data.Coins or 0) + 5000
-- 		return data
-- 	end)

-- 	InteractionService:SendNotification(
-- 		player,
-- 		"Jetons Ajoutés ! 🪙",
-- 		"Simulé : +5 000 Jetons ajoutés à votre compte.",
-- 		"Success"
-- 	)

-- 	return true
-- end

return ShopService
