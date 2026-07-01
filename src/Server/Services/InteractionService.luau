--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Networker = require(ReplicatedStorage.Packages.networker)
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

return InteractionService
