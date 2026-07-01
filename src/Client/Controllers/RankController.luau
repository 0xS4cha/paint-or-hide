--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)

local RankController = {}

local RANK_STYLES = {
	Owner = { Color = Color3.fromRGB(231, 76, 60), Tag = "[OWNER]", Hex = "#e74c3c" },
	Moderator = { Color = Color3.fromRGB(52, 152, 219), Tag = "[MOD]", Hex = "#3498db" },
	VIP = { Color = Color3.fromRGB(241, 196, 15), Tag = "[VIP]", Hex = "#f1c40f" },
	Regular = { Color = Color3.fromRGB(46, 204, 113), Tag = "[REGULAR]", Hex = "#2ecc71" },
	Visitor = { Color = Color3.fromRGB(149, 165, 166), Tag = "[VISITOR]", Hex = "#95a5a6" },
}

local defaultStyle = RANK_STYLES.Visitor

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
		self:CreateOverheadTag(player, character)
	end)

	if player.Character then
		self:CreateOverheadTag(player, player.Character)
	end

	
	player:GetAttributeChangedSignal("Rank"):Connect(function()
		if player.Character then
			self:CreateOverheadTag(player, player.Character)
		end
	end)
	player:GetAttributeChangedSignal("CustomTitle"):Connect(function()
		if player.Character then
			self:CreateOverheadTag(player, player.Character)
		end
	end)
end

function RankController:CreateOverheadTag(player: Player, character: Model)
	local head = character:WaitForChild("Head", 5) :: BasePart?
	if not head then return end

	
	local oldTag = head:FindFirstChild("OverheadTag")
	if oldTag then
		oldTag:Destroy()
	end

	
	local customTitle = player:GetAttribute("CustomTitle") or ""

	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OverheadTag"
	billboard.Size = UDim2.new(0, 200, 0, 75)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = false
	billboard.Active = true 
	billboard.MaxDistance = 100

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.Parent = billboard



	billboard.Parent = head
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

		local rank = senderPlayer:GetAttribute("Rank") or "Visitor"
		local style = RANK_STYLES[rank] or defaultStyle

		
		local prefix = string.format(
			"<font color=\"%s\"><b>%s</b></font> ",
			style.Hex,
			style.Tag
		)

		properties.PrefixText = prefix .. message.PrefixText
		return properties
	end
end

return RankController
