--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Networker = require(ReplicatedStorage.Packages.networker)

local NotificationController = {}
NotificationController.NotificationAdded = Signal.new()

local networkerClient

export type NotificationData = {
	Id: string,
	Title: string,
	Text: string,
	Color: Color3,
	Duration: number,
}

function NotificationController:Init()
	networkerClient = Networker.client.new("InteractionService", self)
	self.networkerClient = networkerClient
	Logger:info("NotificationController", "NotificationController started.")
end


function NotificationController:ReceiveServerNotification(methodKey: string, payload: any)
	
	if payload and type(payload) == "table" then
		local color = Color3.fromRGB(52, 152, 219) 
		if payload.Type == "Success" then
			color = Color3.fromRGB(46, 204, 113) 
		elseif payload.Type == "Warning" then
			color = Color3.fromRGB(241, 196, 15) 
		elseif payload.Type == "Error" then
			color = Color3.fromRGB(231, 76, 60) 
		end
		
		self:Add(payload.Title or "Alert", payload.Text or "", color, payload.Duration)
	end
end


function NotificationController:Add(title: string, text: string, color: Color3?, duration: number?)
	local notification: NotificationData = {
		Id = HttpService:GenerateGUID(false),
		Title = title,
		Text = text,
		Color = color or Color3.fromRGB(52, 152, 219),
		Duration = duration or 4,
	}

	self.NotificationAdded:Fire(notification)
end

return NotificationController
