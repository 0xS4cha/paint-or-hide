--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local PlayerDataService = require(script.Parent.PlayerDataService)
local Config = require(ReplicatedStorage.Shared.Config)
local RankService = {}

local MODERATORS: { [number]: boolean } = {
}


function RankService:Init()
	PlayerDataService.ProfileLoaded:Connect(function(player, data)
		self:UpdateRank(player, data)
		self:CreateLeaderstats(player, data)
	end)

	PlayerDataService.DataChanged:Connect(function(player, key, value)
		local data = PlayerDataService:Get(player)
		if not data then return end

		if key == "PlayTime" then
			self:UpdateRank(player, data)
			
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local minsVal = leaderstats:FindFirstChild("Minutes")
				if minsVal and key == "PlayTime" then
					minsVal.Value = value
				end
			end
		end
	end)

	Logger:info("RankService", "RankService started.")
end

function RankService:UpdateRank(player: Player, data: any)
	local rank = Config.Ranks.RANK_STYLES[Config.Ranks.DEFAULT_RANK]

	if player.UserId == game.CreatorId then
		rank = Config.Ranks.RANK_STYLES['owner']
	elseif MODERATORS[player.UserId] then
		rank = Config.Ranks.RANK_STYLES['moderator']
	elseif data.PlayTime >= Config.Ranks.REGULAR_TIME_THRESHOLD then
		rank = Config.Ranks.RANK_STYLES['regular']
	end

	if data.Rank.Id ~= rank.Id then
		PlayerDataService:SetRank(player, rank.id)
	end
	player:SetAttribute("Rank", rank.id)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local rankVal = leaderstats:FindFirstChild("Rank")
		if rankVal then
			rankVal.Value = rank.Tag
		end
	end

	Logger:info("RankService", "Rank of " .. player.Name .. " updated to: " .. rank.Tag)
end

function RankService:CreateLeaderstats(player: Player, data: any)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	
	local rankVal = Instance.new("StringValue")
	rankVal.Name = "Rank"
	print(player:GetAttribute("Rank"))
	rankVal.Value = player:GetAttribute("Rank") and Config.Ranks.RANK_STYLES[player:GetAttribute("Rank")].Tag or Config.Ranks.RANK_STYLES[Config.Ranks.DEFAULT_RANK].Tag
	rankVal.Parent = leaderstats

	local minutesVal = Instance.new("IntValue")
	minutesVal.Name = "Minutes"
	minutesVal.Value = data.PlayTime or 0
	minutesVal.Parent = leaderstats

	leaderstats.Parent = player
end

return RankService
