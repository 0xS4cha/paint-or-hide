--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Theme = require(ReplicatedStorage.UI.Styles.Theme)
local PlayerProfileModal = require(ReplicatedStorage.UI.Components.PlayerProfileModal)
local PlayerListMenu = require(ReplicatedStorage.UI.Components.PlayerListMenu)
local CustomLeaderboard = require(ReplicatedStorage.UI.Components.CustomLeaderboard)
local RightSidebar = require(ReplicatedStorage.UI.Components.RightSidebar)
local FriendListMenu = require(ReplicatedStorage.UI.Components.FriendListMenu)
local ReportModal = require(ReplicatedStorage.UI.Components.ReportModal)
local NotificationContainer = require(ReplicatedStorage.UI.Components.NotificationContainer)
local ShopModal = require(ReplicatedStorage.UI.Components.ShopModal)

local AppView = {}
local activeAppInstance = nil


local MainApp = Roact.Component:extend("MainApp")

function MainApp:init()
	activeAppInstance = self
	self:setState({
		isPlayerListOpen = false,
		isFriendListOpen = false,
		isShopOpen = false,
	})
end

function MainApp:render()
	local state = self.state

	return Roact.createElement("Folder", {}, {
		
		Leaderboard = Roact.createElement(CustomLeaderboard),

		
		Sidebar = Roact.createElement(RightSidebar),

		
		Notifications = Roact.createElement(NotificationContainer),

		
		PlayerListWindow = state.isPlayerListOpen and Roact.createElement(PlayerListMenu, {
			onClose = function()
				self:setState({ isPlayerListOpen = false })
			end,
			onSelectPlayer = function(targetPlayer)
				self:setState({ selectedPlayer = targetPlayer })
			end,
		}) or nil,

		
		FriendListWindow = state.isFriendListOpen and Roact.createElement(FriendListMenu, {
			onClose = function()
				self:setState({ isFriendListOpen = false })
			end,
		}) or nil,

		
		ProfileWindow = state.selectedPlayer and Roact.createElement(PlayerProfileModal, {
			player = state.selectedPlayer,
			onClose = function()
				self:setState({ selectedPlayer = Roact.None })
			end,
		}) or nil,

		
		ReportWindow = state.reportTargetPlayer and Roact.createElement(ReportModal, {
			player = state.reportTargetPlayer,
			onClose = function()
				self:setState({ reportTargetPlayer = Roact.None })
			end,
		}) or nil,

		ShopWindow = state.isShopOpen and Roact.createElement(ShopModal, {
			onClose = function()
				self:setState({ isShopOpen = false })
			end,
		}) or nil,
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
	screenGui.Name = "SpeakUpRoactRoot"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	screenGui.IgnoreGuiInset = true

	
	self.mountHandle = Roact.mount(
		Roact.createElement(MainApp),
		screenGui,
		"MainUI"
	)
end


function AppView:ShowProfile(player: Player)
	if activeAppInstance then
		activeAppInstance:setState({
			selectedPlayer = player,
		})
	end
end


function AppView:TogglePlayerList()
	if activeAppInstance then
		activeAppInstance:setState(function(state)
			return {
				isPlayerListOpen = not state.isPlayerListOpen,
			}
		end)
	end
end


function AppView:ToggleFriendList()
	if activeAppInstance then
		activeAppInstance:setState(function(state)
			return {
				isFriendListOpen = not state.isFriendListOpen,
			}
		end)
	end
end


function AppView:ShowReport(player: Player)
	if activeAppInstance then
		activeAppInstance:setState({
			reportTargetPlayer = player,
		})
	end
end

function AppView:ToggleShop()
	if activeAppInstance then
		activeAppInstance:setState(function(state)
			return {
				isShopOpen = not state.isShopOpen,
			}
		end)
	end
end

return AppView
