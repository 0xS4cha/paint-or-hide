--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.networker)
local ZoneManager = require(ReplicatedStorage.Shared.Modules.Game.ZoneManager)
local VipService = require(script.Parent.VipService)
local Config = require(ReplicatedStorage.Shared.Config)

local ZoneService = {}

local vipZoneInstance
local stageZoneInstance

local vipZone
local stageZone

local networkerServer

function ZoneService:Init()
	networkerServer = Networker.server.new("ZoneService", self, {
		self.GetZoneStates
	})

	
	self:InitializePhysicalZones()

	
	self:StartMonitoring()

	Logger:info("ZoneService", "ZoneService started.")
end


function ZoneService:InitializePhysicalZones()
	local zonesFolder = workspace:FindFirstChild("Zones")
	if not zonesFolder then
		zonesFolder = Instance.new("Folder")
		zonesFolder.Name = "Zones"
		zonesFolder.Parent = workspace
	end

	
	vipZoneInstance = zonesFolder:FindFirstChild("VIPLounge") :: BasePart?
	if not vipZoneInstance then
		local config = Config.Zones.VIPLounge
		vipZoneInstance = Instance.new("Part")
		vipZoneInstance.Name = "VIPLounge"
		vipZoneInstance.Size = config.Size
		vipZoneInstance.Position = config.Position
		vipZoneInstance.Anchored = true
		vipZoneInstance.CanCollide = false
		vipZoneInstance.Transparency = config.Transparency
		vipZoneInstance.Color = config.Color
		vipZoneInstance.Material = config.Material
		vipZoneInstance.Parent = zonesFolder
		Logger:info("ZoneService", "Created default VIPLounge zone.")
	end

	stageZoneInstance = zonesFolder:FindFirstChild("Stage") :: BasePart?
	if not stageZoneInstance then
		local config = Config.Zones.Stage
		stageZoneInstance = Instance.new("Part")
		stageZoneInstance.Name = "Stage"
		stageZoneInstance.Size = config.Size
		stageZoneInstance.Position = config.Position
		stageZoneInstance.Anchored = true
		stageZoneInstance.CanCollide = false
		stageZoneInstance.Transparency = config.Transparency
		stageZoneInstance.Color = config.Color
		stageZoneInstance.Material = config.Material
		stageZoneInstance.Parent = zonesFolder
		Logger:info("ZoneService", "Created default Stage zone.")
	end
end


function ZoneService:StartMonitoring()
	
	if vipZoneInstance then
		vipZone = ZoneManager.new(vipZoneInstance, 0.2)
		vipZone.PlayerEntered:Connect(function(player)
			self:OnPlayerEnterVipLounge(player)
		end)
		vipZone:Start()
	end

	
	if stageZoneInstance then
		stageZone = ZoneManager.new(stageZoneInstance, 0.2)
		stageZone.PlayerEntered:Connect(function(player)
			self:OnPlayerEnterStage(player)
		end)
		stageZone.PlayerLeft:Connect(function(player)
			self:OnPlayerLeftStage(player)
		end)
		stageZone:Start()
	end
end


function ZoneService:OnPlayerEnterVipLounge(player: Player)
	local isVip = VipService:IsVip(player)
	
	if not isVip then
		Logger:info("ZoneService", player.Name .. " attempted to enter the VIP lounge without being VIP.")
		
		
		local character = player.Character
		if character then
			local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if rootPart then
				
				local zonePos = vipZoneInstance.Position
				local playerPos = rootPart.Position
				local direction = (playerPos - zonePos).Unit
				if direction.Magnitude == 0 or direction ~= direction then 
					direction = Vector3.new(0, 0, 1)
				end
				
				
				rootPart.CFrame = CFrame.new(rootPart.Position + direction * 8)
			end
		end

		
		networkerServer:fire(player, "NotifyVipAccessDenied")
	else
		Logger:info("ZoneService", player.Name .. " (VIP) entered the VIP lounge.")
	end
end


function ZoneService:OnPlayerEnterStage(player: Player)
	Logger:info("ZoneService", player.Name .. " stepped onto the stage!")
	if stageZoneInstance then
		stageZoneInstance:SetAttribute("SpeakerName", player.DisplayName or player.Name)
		stageZoneInstance:SetAttribute("SpeakerUserId", player.UserId)
	end
end


function ZoneService:OnPlayerLeftStage(player: Player)
	Logger:info("ZoneService", player.Name .. " stepped off the stage.")
	if stageZoneInstance then
		
		local currentSpeakerId = stageZoneInstance:GetAttribute("SpeakerUserId")
		if currentSpeakerId == player.UserId then
			stageZoneInstance:SetAttribute("SpeakerName", "")
			stageZoneInstance:SetAttribute("SpeakerUserId", 0)
		end
	end
end


function ZoneService:GetZoneStates()
	return {
		VipZonePosition = vipZoneInstance and vipZoneInstance.Position or Vector3.new(0,0,0),
		VipZoneSize = vipZoneInstance and vipZoneInstance.Size or Vector3.new(0,0,0),
		StageSpeakerName = stageZoneInstance and stageZoneInstance:GetAttribute("SpeakerName") or "",
		StageSpeakerUserId = stageZoneInstance and stageZoneInstance:GetAttribute("SpeakerUserId") or 0,
	}
end

return ZoneService
