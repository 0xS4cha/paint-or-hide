--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Config = require(ReplicatedStorage.Shared.Config)
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)

local RankController = {}


function RankController:Init()
	
	Players.PlayerAdded:Connect(function(player)
		self:SetupPlayer(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:SetupPlayer(player)
	end

	
	self:SetupChatFormatting()

	Logger:info("RankController", "RankController started.")
end

function RankController:SetupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		-- self:CreateOverheadTag(player, character)
	end)

	if player.Character then
		-- self:CreateOverheadTag(player, player.Character)
	end

	
	player:GetAttributeChangedSignal("Rank"):Connect(function()
		-- if player.Character then
		-- 	self:CreateOverheadTag(player, player.Character)
		-- end
	end)
end

function RankController:SetupChatFormatting()
	
	TextChatService.OnIncomingMessage = function(message: TextChatMessage)
		local properties = Instance.new("TextChatMessageProperties")
		if not message.TextSource then
			return properties
		end

		local senderPlayer = Players:GetPlayerByUserId(message.TextSource.UserId)
		if not senderPlayer then
			return properties
		end

		local rank = senderPlayer:GetAttribute("Rank") or Config.Ranks.RANK_STYLES[Config.Ranks.DEFAULT_RANK]

		
		local prefix = string.format(
			"<font color=\"%s\"><b>%s</b></font> ",
			rank.Hex,
			rank.Tag
		)

		properties.PrefixText = prefix .. message.PrefixText
		return properties
	end
end

return RankController
