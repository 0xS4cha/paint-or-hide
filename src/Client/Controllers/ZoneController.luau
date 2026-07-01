--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.networker)
local Theme = require(ReplicatedStorage.UI.Styles.Theme)

local ZoneController = {}
local networkerClient

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")


local notificationGui: ScreenGui
local notificationLabel: TextLabel

local stageSpeakerGui: ScreenGui
local stageSpeakerLabel: TextLabel

function ZoneController:Init()
	networkerClient = Networker.client.new("ZoneService", self)

	
	self:CreateUI()

	
	task.spawn(function()
		local success, state = pcall(function()
			return networkerClient:fetch("GetZoneStates")
		end)

		if success and state then
			self:UpdateStageSpeaker(state.StageSpeakerName)
		end
	end)

	
	local zonesFolder = workspace:WaitForChild("Zones", 10)
	if zonesFolder then
		local stagePart = zonesFolder:WaitForChild("Stage", 5)
		if stagePart then
			stagePart:GetAttributeChangedSignal("SpeakerName"):Connect(function()
				local speakerName = stagePart:GetAttribute("SpeakerName") or ""
				self:UpdateStageSpeaker(speakerName)
			end)
		end
	end

	Logger:info("ZoneController", "ZoneController started.")
end


function ZoneController:CreateUI()
	
	notificationGui = Instance.new("ScreenGui")
	notificationGui.Name = "SpeakUpNotifications"
	notificationGui.ResetOnSpawn = false
	notificationGui.Parent = playerGui

	notificationLabel = Instance.new("TextLabel")
	notificationLabel.Size = UDim2.new(0, 400, 0, 50)
	notificationLabel.Position = UDim2.new(0.5, -200, 0.8, -25)
	notificationLabel.BackgroundColor3 = Theme.Colors.Surface
	notificationLabel.BackgroundTransparency = 0.2
	notificationLabel.TextColor3 = Theme.Colors.Danger
	notificationLabel.Font = Theme.Fonts.Title
	notificationLabel.TextSize = Theme.TextSizes.Body
	notificationLabel.Text = ""
	notificationLabel.TextStrokeTransparency = 0.5
	notificationLabel.Visible = false
	notificationLabel.Parent = notificationGui

	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Theme.CornerRadius.Small)
	corner.Parent = notificationLabel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.Colors.Danger
	stroke.Thickness = 2
	stroke.Parent = notificationLabel

	
	stageSpeakerGui = Instance.new("ScreenGui")
	stageSpeakerGui.Name = "StageSpeakerUI"
	stageSpeakerGui.ResetOnSpawn = false
	stageSpeakerGui.Parent = playerGui

	stageSpeakerLabel = Instance.new("TextLabel")
	stageSpeakerLabel.Size = UDim2.new(0, 350, 0, 45)
	stageSpeakerLabel.Position = UDim2.new(0.5, -175, 0, -60) 
	stageSpeakerLabel.BackgroundColor3 = Theme.Colors.Background
	stageSpeakerLabel.BackgroundTransparency = 0.3
	stageSpeakerLabel.TextColor3 = Theme.Colors.Accent
	stageSpeakerLabel.Font = Theme.Fonts.Title
	stageSpeakerLabel.TextSize = Theme.TextSizes.Body
	stageSpeakerLabel.Text = ""
	stageSpeakerLabel.Parent = stageSpeakerGui

	local stageCorner = Instance.new("UICorner")
	stageCorner.CornerRadius = UDim.new(0, Theme.CornerRadius.Medium)
	stageCorner.Parent = stageSpeakerLabel

	local stageStroke = Instance.new("UIStroke")
	stageStroke.Color = Theme.Colors.Primary
	stageStroke.Thickness = 1.5
	stageStroke.Parent = stageSpeakerLabel
end


function ZoneController:NotifyVipAccessDenied()
	notificationLabel.Text = "🛑 Access Denied: The VIP Lounge is reserved for VIPs!"
	notificationLabel.Visible = true
	notificationLabel.TextTransparency = 1
	notificationLabel.BackgroundTransparency = 1

	
	TweenService:Create(notificationLabel, TweenInfo.new(0.3), {
		TextTransparency = 0,
		BackgroundTransparency = 0.2
	}):Play()

	task.delay(3, function()
		local fadeTween = TweenService:Create(notificationLabel, TweenInfo.new(0.5), {
			TextTransparency = 1,
			BackgroundTransparency = 1
		})
		fadeTween.Completed:Connect(function()
			notificationLabel.Visible = false
		end)
		fadeTween:Play()
	end)
end


function ZoneController:UpdateStageSpeaker(speakerName: string)
	if speakerName and speakerName ~= "" then
		stageSpeakerLabel.Text = "🎤 On Stage: " .. speakerName
		stageSpeakerLabel.Visible = true

		
		TweenService:Create(stageSpeakerLabel, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -175, 0, 20)
		}):Play()
	else
		
		local upTween = TweenService:Create(stageSpeakerLabel, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, -175, 0, -60)
		})
		upTween.Completed:Connect(function()
			stageSpeakerLabel.Visible = false
		end)
		upTween:Play()
	end
end

return ZoneController
