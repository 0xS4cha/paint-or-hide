--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Theme = require(ReplicatedStorage.UI.Styles.Theme)

local RightSidebar = Roact.Component:extend("RightSidebar")


local SidebarButton = Roact.Component:extend("SidebarButton")

function SidebarButton:init()
	self:setState({
		isHovered = false,
		isPressed = false,
	})
end

function SidebarButton:render()
	local props = self.props
	local state = self.state

	local bgTrans = state.isHovered and 0.15 or 0.35
	local scale = state.isPressed and 0.9 or (state.isHovered and 1.1 or 1.0)
	local strokeTrans = state.isHovered and 0.45 or 0.8
	local strokeColor = state.isHovered and Theme.Colors.Accent or Color3.fromRGB(255, 255, 255)

	return Roact.createElement("ImageButton", {
		Size = UDim2.new(0, 46 * scale, 0, 46 * scale),
		BackgroundColor3 = Color3.fromRGB(15, 17, 23),
		BackgroundTransparency = bgTrans,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		LayoutOrder = props.layoutOrder,

		[Roact.Event.MouseEnter] = function()
			self:setState({ isHovered = true })
		end,
		[Roact.Event.MouseLeave] = function()
			self:setState({ isHovered = false, isPressed = false })
		end,
		[Roact.Event.MouseButton1Down] = function()
			self:setState({ isPressed = true })
		end,
		[Roact.Event.MouseButton1Up] = function()
			if self.state.isPressed then
				self:setState({ isPressed = false })
				props.onClick()
			end
		end,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 23),
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = strokeColor,
			Thickness = 1.5,
			Transparency = strokeTrans,
		}),
		Icon = Roact.createElement("ImageLabel", {
			Size = UDim2.new(0, 22, 0, 22),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = props.iconImage or "",
			ImageColor3 = Theme.Colors.Text,
		}),
		Tooltip = state.isHovered and Roact.createElement("TextLabel", {
			Size = UDim2.new(0, 110, 0, 26),
			Position = UDim2.new(0, -125, 0.5, -13),
			BackgroundColor3 = Color3.fromRGB(12, 14, 20),
			BackgroundTransparency = 0.15,
			Text = props.tooltipText,
			TextColor3 = Theme.Colors.Text,
			Font = Theme.Fonts.Body,
			TextSize = 11,
			ZIndex = 20,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Thickness = 1,
				Transparency = 0.85,
			})
		}) or nil,
	})
end

function RightSidebar:render()
	local props = self.props

	return Roact.createElement("Frame", {
		Size = UDim2.new(0, 50, 0, 300),
		Position = UDim2.new(1, -20, 0.5, 0), 
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
	}, {
		UIList = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
		}),

		
		FriendsBtn = Roact.createElement(SidebarButton, {
			iconImage = "rbxassetid://134452874406441",
			tooltipText = "Amis en ligne",
			layoutOrder = 1,
			onClick = function()
				local AppView = require(ReplicatedStorage.UI.Interfaces.AppView)
				AppView:ToggleFriendList()
			end,
		}),

		
		ShopBtn = Roact.createElement(SidebarButton, {
			iconImage = "rbxassetid://121229647872473",
			tooltipText = "Boutique Officielle",
			layoutOrder = 2,
			onClick = function()
				local AppView = require(ReplicatedStorage.UI.Interfaces.AppView)
				AppView:ToggleShop()
			end,
		}),

		
		ProfileBtn = Roact.createElement(SidebarButton, {
			iconImage = "rbxassetid://140355181374747",
			tooltipText = "Mon Profil",
			layoutOrder = 3,
			onClick = function()
				local AppView = require(ReplicatedStorage.UI.Interfaces.AppView)
				AppView:ShowProfile(Players.LocalPlayer)
			end,
		}),

		
		VipBtn = Roact.createElement(SidebarButton, {
			iconImage = "rbxassetid://140355181374747",
			tooltipText = "Effets VIP",
			layoutOrder = 4,
			onClick = function()
				local player = Players.LocalPlayer
				if player:GetAttribute("Vip") then
					local success, VipController = pcall(function()
						local playerScripts = player:WaitForChild("PlayerScripts")
						return require(playerScripts:WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("VipController"))
					end)
					if success and VipController then
						VipController:ToggleParticles()
					end
				else
					
					local MarketplaceService = game:GetService("MarketplaceService")
					local VIP_GAMEPASS_ID = 123456789
					pcall(function()
						MarketplaceService:PromptGamePassPurchase(player, VIP_GAMEPASS_ID)
					end)
				end
			end,
		}),

		
		MembersBtn = Roact.createElement(SidebarButton, {
			iconImage = "rbxassetid://140355181374747",
			tooltipText = "Membres",
			layoutOrder = 5,
			onClick = function()
				local AppView = require(ReplicatedStorage.UI.Interfaces.AppView)
				AppView:TogglePlayerList()
			end,
		}),
	})
end

return RightSidebar
