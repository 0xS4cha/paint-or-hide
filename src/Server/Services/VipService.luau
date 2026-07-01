--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.networker)
local PlayerDataService = require(script.Parent.PlayerDataService)
local Config = require(ReplicatedStorage.Shared.Config)

local VipService = {}

local VIP_GAMEPASS_ID = Config.Game.VIP_GAMEPASS_ID

local vipParticlesActive: { [Player]: boolean } = {}

local networkerServer

function VipService:Init()
	networkerServer = Networker.server.new("VipService", self, {
		self.ToggleVipParticles,
		self.GetVipStatus
	})

	PlayerDataService.ProfileLoaded:Connect(function(player, data)
		self:CheckVipStatus(player)
	end)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
		if wasPurchased and gamePassId == VIP_GAMEPASS_ID then
			Logger:info("VipService", player.Name .. " purchased the VIP Gamepass!")
			self:AwardVip(player)
		end
	end)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			task.wait(1)
			if self:IsVip(player) and vipParticlesActive[player] ~= false then
				self:ApplyVipParticles(character)
			end
		end)
	end)

	Logger:info("VipService", "VipService started.")
end

function VipService:CheckVipStatus(player: Player)
	task.spawn(function()
		local success, ownsVip = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_GAMEPASS_ID)
		end)

		if success and ownsVip then
			self:AwardVip(player)
		else
			local data = PlayerDataService:Get(player)
			if data and data.Vip then
				Logger:info("VipService", player.Name .. " is VIP via internal profile (admin/test).")
				player:SetAttribute("Vip", true)
			end
		end
	end)
end

function VipService:AwardVip(player: Player)
	PlayerDataService:SetVip(player, true)
	player:SetAttribute("Vip", true)
	if vipParticlesActive[player] == nil then
		vipParticlesActive[player] = true
	end

	if player.Character and vipParticlesActive[player] then
		self:ApplyVipParticles(player.Character)
	end

	Logger:info("VipService", "VIP granted to " .. player.Name)
end

function VipService:IsVip(player: Player): boolean
	local data = PlayerDataService:Get(player)
	return (data and data.Vip == true) or (player:GetAttribute("Vip") == true)
end

function VipService:ApplyVipParticles(character: Model)
	local rootPart = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not rootPart then return end
	local oldAttachment = rootPart:FindFirstChild("VipAttachment")
	if oldAttachment then
		oldAttachment:Destroy()
	end

	local attachment = Instance.new("Attachment")
	attachment.Name = "VipAttachment"
	attachment.Position = Vector3.new(0, -1, 0)
	attachment.Parent = rootPart

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "VipParticles"
	emitter.Texture = "rbxassetid://244220165"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(241, 196, 15)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(243, 156, 18)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
	})
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.8, 0.4),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Lifetime = NumberRange.new(1, 1.8)
	emitter.Rate = 8
	emitter.Speed = NumberRange.new(1, 2)
	emitter.VelocitySpread = 360
	emitter.Acceleration = Vector3.new(0, 1.5, 0)
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.2),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.Parent = attachment
end

function VipService:RemoveVipParticles(character: Model)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if rootPart then
		local attachment = rootPart:FindFirstChild("VipAttachment")
		if attachment then
			attachment:Destroy()
		end
	end
end

function VipService:ToggleVipParticles(player: Player)
	if not self:IsVip(player) then return false end

	local active = not (vipParticlesActive[player] ~= false)
	vipParticlesActive[player] = active

	if player.Character then
		if active then
			self:ApplyVipParticles(player.Character)
		else
			self:RemoveVipParticles(player.Character)
		end
	end

	Logger:info("VipService", "VIP particles of " .. player.Name .. " set to " .. tostring(active))
	return active
end

function VipService:GetVipStatus(player: Player)
	return self:IsVip(player)
end

return VipService
