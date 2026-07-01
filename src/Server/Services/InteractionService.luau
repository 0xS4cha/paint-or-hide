--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.networker)
local PlayerDataService = require(script.Parent.PlayerDataService)
local VipService = require(script.Parent.VipService)

local InteractionService = {}
local networkerServer

function InteractionService:Init()
	networkerServer = Networker.server.new("InteractionService", self, {
		self.Wave,
		self.GiftCoins,
		self.ToggleLike,
		self.AddComment,
		self.SubmitReport,
		self.SetEquippedBanner,
	})

	Logger:info("InteractionService", "InteractionService started.")
end


function InteractionService:SendNotification(recipient: Player, title: string, text: string, notifType: "Success" | "Warning" | "Error" | "Info", duration: number?)
	networkerServer:fire(recipient, "ReceiveServerNotification", {
		Title = title,
		Text = text,
		Type = notifType,
		Duration = duration or 4
	})
end


function InteractionService:Wave(player: Player, targetPlayer: Player)
	if not targetPlayer or targetPlayer == player then return end

	
	self:SendNotification(
		targetPlayer,
		"Wave 👋",
		player.DisplayName .. " waved at you!",
		"Info"
	)

	
	self:SendNotification(
		player,
		"Wave sent!",
		"You waved at " .. targetPlayer.DisplayName .. ".",
		"Success"
	)
end


function InteractionService:GiftCoins(player: Player, targetPlayer: Player, amount: number)
	if not targetPlayer or targetPlayer == player or amount <= 0 then return false end

	local donorData = PlayerDataService:Get(player)
	if not donorData or donorData.Coins < amount then
		self:SendNotification(player, "Transaction Failed", "You do not have enough Coins!", "Error")
		return false
	end

	
	PlayerDataService:Update(player, function(data)
		data.Coins = (data.Coins or 0) - amount
		return data
	end)

	
	PlayerDataService:Update(targetPlayer, function(data)
		data.Coins = (data.Coins or 0) + amount
		return data
	end)

	
	self:SendNotification(
		targetPlayer,
		"Gift received! 🪙",
		player.DisplayName .. " gifted you " .. amount .. " coins!",
		"Success"
	)

	self:SendNotification(
		player,
		"Gift sent!",
		"You transferred " .. amount .. " coins to " .. targetPlayer.DisplayName .. ".",
		"Success"
	)

	return true
end


function InteractionService:ToggleLike(player: Player, targetPlayer: Player, opinion: "Like" | "Dislike")
	if not targetPlayer or targetPlayer == player then return end
	if opinion ~= "Like" and opinion ~= "Dislike" then return end

	local voterIdStr = tostring(player.UserId)
	local targetData = PlayerDataService:Get(targetPlayer)
	if not targetData then return end

	
	local targetLikes = targetData.Likes or 0
	local targetDislikes = targetData.Dislikes or 0
	local likedPlayers = targetData.LikedPlayers or {}

	local currentVote = likedPlayers[voterIdStr]
	local newVote = opinion

	if currentVote == opinion then
		
		newVote = nil
		if opinion == "Like" then
			targetLikes = math.max(0, targetLikes - 1)
		else
			targetDislikes = math.max(0, targetDislikes - 1)
		end
		self:SendNotification(player, "Opinion removed", "You removed your opinion on " .. targetPlayer.DisplayName .. ".", "Info")
	else
		
		if currentVote == "Like" then
			targetLikes = math.max(0, targetLikes - 1)
		elseif currentVote == "Dislike" then
			targetDislikes = math.max(0, targetDislikes - 1)
		end

		if opinion == "Like" then
			targetLikes = targetLikes + 1
			self:SendNotification(targetPlayer, "Profile Liked! 👍", player.DisplayName .. " liked your profile!", "Success")
			self:SendNotification(player, "Opinion registered", "You liked " .. targetPlayer.DisplayName .. "'s profile.", "Success")
		else
			targetDislikes = targetDislikes + 1
			self:SendNotification(player, "Opinion registered", "You disliked " .. targetPlayer.DisplayName .. "'s profile.", "Warning")
		end
	end

	
	PlayerDataService:Update(targetPlayer, function(data)
		data.Likes = targetLikes
		data.Dislikes = targetDislikes
		data.LikedPlayers = likedPlayers
		data.LikedPlayers[voterIdStr] = newVote
		return data
	end)
end


function InteractionService:AddComment(player: Player, targetPlayer: Player, text: string)
	if not targetPlayer or text == "" then return false end
	text = string.sub(text, 1, 100) 

	
	local filteredText = ""
	local success, filterResult = pcall(function()
		return TextService:FilterStringAsync(text, player.UserId)
	end)
	
	if success and filterResult then
		local getSuccess, result = pcall(function()
			return filterResult:GetChatForUserAsync(targetPlayer.UserId)
		end)
		if getSuccess then
			filteredText = result
		end
	end

	
	if filteredText == "" then
		filteredText = "###"
	end

	local targetData = PlayerDataService:Get(targetPlayer)
	if not targetData then return false end

	local comments = targetData.Comments or {}
	
	
	table.insert(comments, {
		senderId = player.UserId,
		senderName = player.DisplayName or player.Name,
		text = filteredText,
		time = os.time(),
	})

	
	if #comments > 10 then
		table.remove(comments, 1)
	end

	
	PlayerDataService:Update(targetPlayer, function(data)
		data.Comments = comments
		return data
	end)

	self:SendNotification(
		targetPlayer,
		"New comment ✍️",
		player.DisplayName .. " wrote on your profile.",
		"Info"
	)

	self:SendNotification(
		player,
		"Comment sent!",
		"Your message has been posted on their profile.",
		"Success"
	)

	return true
end


function InteractionService:SubmitReport(player: Player, targetPlayer: Player, reason: string, details: string)
	if not targetPlayer or targetPlayer == player then return end

	
	Logger:warn("AdminReport", string.format(
		"REPORT: %s (ID: %d) reported %s (ID: %d) for '%s'. Details: %s",
		player.Name, player.UserId,
		targetPlayer.Name, targetPlayer.UserId,
		reason, details
	))

	
	self:SendNotification(
		player,
		"Report submitted ⚠️",
		"Thank you. Administrators received your report against " .. targetPlayer.DisplayName .. ".",
		"Warning",
		5
	)
end


function InteractionService:SetEquippedBanner(player: Player, bannerName: string)
	if bannerName == "GoldenVIP" and not VipService:IsVip(player) then
		self:SendNotification(player, "Access Blocked", "The GoldenVIP banner is reserved for VIPs!", "Error")
		return false
	end

	local Config = require(ReplicatedStorage.Shared.Config)
	local shopItemId = "banner_" .. string.lower(bannerName)
	local isShopItem = Config.Shop[shopItemId] ~= nil

	if isShopItem then
		local data = PlayerDataService:Get(player)
		local inventory = data and data.Inventory or {}
		if not inventory[shopItemId] or inventory[shopItemId] <= 0 then
			self:SendNotification(player, "Accès Refusé", "Vous devez acheter cette bannière dans la boutique !", "Error")
			return false
		end
	end

	PlayerDataService:SetBanner(player, bannerName)
	self:SendNotification(
		player,
		"Banner changed!",
		"Your profile now displays the " .. bannerName .. " theme.",
		"Success"
	)
	return true
end

return InteractionService
