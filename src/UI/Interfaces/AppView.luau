--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Roact = require(ReplicatedStorage.Packages.Roact)

local AppView = {}
local activeAppInstance = nil


local MainApp = Roact.Component:extend("MainApp")

function MainApp:init()
	activeAppInstance = self
	self:setState({
		isFriendListOpen = false,
		isShopOpen = false
	})
end

function MainApp:render()
	return Roact.createElement("Folder", {}, {
		-- INTERFACE
	})
end


function AppView:init()
	local localPlayer = Players.LocalPlayer
	local playerGui = localPlayer:WaitForChild("PlayerGui")

	
	task.spawn(function()
		local success = false
		local retries = 0
		while not success and retries < 10 do
			success = pcall(function()
				StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
			end)
			if not success then
				task.wait(0.2)
				retries = retries + 1
			end
		end
	end)

	
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "PoHRoactRoot"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	screenGui.IgnoreGuiInset = true

	
	self.mountHandle = Roact.mount(
		Roact.createElement(MainApp),
		screenGui,
		"MainUI"
	)
end



return AppView
