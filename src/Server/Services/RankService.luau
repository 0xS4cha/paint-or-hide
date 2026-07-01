--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local PlayerDataService = require(script.Parent.PlayerDataService)

local RankService = {}

local MODERATORS: { [number]: boolean } = {
}

local REGULAR_TIME_THRESHOLD = 30

local RANK_NAMES = {
	Owner = "Owner",
	Moderator = "Moderator",
	VIP = "VIP",
	Regular = "Regular",
	Visitor = "Visitor",
}

function RankService:Init()
	PlayerDataService.ProfileLoaded:Connect(function(player, data)
		self:UpdateRank(player, data)
		self:CreateLeaderstats(player, data)
	end)

	PlayerDataService.DataChanged:Connect(function(player, key, value)
		local data = PlayerDataService:Get(player)
		if not data then return end

		if key == "PlayTime" or key == "Vip" then
			self:UpdateRank(player, data)
			
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local minsVal = leaderstats:FindFirstChild("Minutes")
				if minsVal and key == "PlayTime" then
					minsVal.Value = value
				end
			end
		end

		if key == "CustomTitle" then
			player:SetAttribute("CustomTitle", value)
		end
	end)

	Logger:info("RankService", "RankService started.")
end

function RankService:UpdateRank(player: Player, data: any)
	local rank = RANK_NAMES.Visitor

	if player.UserId == game.CreatorId then
		rank = RANK_NAMES.Owner
	elseif MODERATORS[player.UserId] then
		rank = RANK_NAMES.Moderator
	elseif data.Vip then
		rank = RANK_NAMES.VIP
	elseif data.PlayTime >= REGULAR_TIME_THRESHOLD then
		rank = RANK_NAMES.Regular
	end

	if data.Rank ~= rank then
		PlayerDataService:SetRank(player, rank)
	end
	player:SetAttribute("Rank", rank)
	player:SetAttribute("Vip", data.Vip or false)
	player:SetAttribute("CustomTitle", data.CustomTitle or "")
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rankVal = leaderstats:FindFirstChild("Rank")
		if rankVal then
			rankVal.Value = rank
		end
	end

	Logger:info("RankService", "Rank of " .. player.Name .. " updated to: " .. rank)
end

function RankService:CreateLeaderstats(player: Player, data: any)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	
	local rankVal = Instance.new("StringValue")
	rankVal.Name = "Rank"
	rankVal.Value = player:GetAttribute("Rank") or RANK_NAMES.Visitor
	rankVal.Parent = leaderstats

	local minutesVal = Instance.new("IntValue")
	minutesVal.Name = "Minutes"
	minutesVal.Value = data.PlayTime or 0
	minutesVal.Parent = leaderstats

	leaderstats.Parent = player
end

return RankService
