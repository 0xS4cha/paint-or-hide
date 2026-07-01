--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Theme = require(ReplicatedStorage.UI.Styles.Theme)
local RankConfig = require(ReplicatedStorage.Shared.Config.RankConfig)
local BannerBackground = require(ReplicatedStorage.UI.Components.BannerBackground)

local OverheadBillboard = Roact.Component:extend("OverheadBillboard")

function OverheadBillboard:init()
	local player = self.props.player
	self.state = {
		playTime = player:GetAttribute("PlayTime") or 0,
		rank = player:GetAttribute("Rank") or "Visitor",
		banner = player:GetAttribute("Banner") or "Default",
	}
	self.connections = {}
end

function OverheadBillboard:didMount()
	local player = self.props.player
	local function bindAttribute(name, stateKey)
		local connection = player:GetAttributeChangedSignal(name):Connect(function()
			self:setState({
				[stateKey] = player:GetAttribute(name)
			})
		end)
		table.insert(self.connections, connection)
	end

	bindAttribute("PlayTime", "playTime")
	bindAttribute("Rank", "rank")
	bindAttribute("Banner", "banner")
end

function OverheadBillboard:willUnmount()
	for _, connection in ipairs(self.connections) do
		if connection then
			connection:Disconnect()
		end
	end
	self.connections = {}
end

function OverheadBillboard:render()
	local player = self.props.player
	local state = self.state

	local level = math.floor(state.playTime / 60) + 1
	local rankInfo = RankConfig.RANK_STYLES[state.rank] or RankConfig.RANK_STYLES.Visitor
	local bannerName = state.banner

	local function onBillboardClicked()
		local success, AppView = pcall(function()
			return require(ReplicatedStorage.UI.Interfaces.AppView)
		end)
		if success and AppView then
			AppView:ShowProfile(player)
		end
	end

	local badgeTextColor = Color3.fromRGB(255, 255, 255)
	if state.rank == "VIP" or state.rank == "Regular" then
		badgeTextColor = Color3.fromRGB(15, 17, 23)
	end

	return Roact.createElement("ImageButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		[Roact.Event.MouseButton1Click] = onBillboardClicked,
	}, {
		Background = Roact.createElement(BannerBackground, {
			bannerName = bannerName,
			size = UDim2.new(1, 0, 1, 0),
			BorderSizePixel = 0,
			cornerRadius = UDim.new(0, 8),
			zIndex = 1,
		}),
		Stroke = Roact.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Thickness = 1,
			Transparency = 0.85,
			ZIndex = 2,
		}),

		Content = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			ZIndex = 2,
		}, {
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 8),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),

			Layout = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 2),
			}),


			Level = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 14),
				BackgroundTransparency = 1,
				Text = "Niveau: " .. level,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Theme.Fonts.Title,
				TextSize = 9,
				TextStrokeTransparency = 0.7,
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				LayoutOrder = 1,
				ZIndex = 2,
			}),

			Username = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = player.DisplayName or player.Name,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Theme.Fonts.Title,
				TextSize = 13,
				TextStrokeTransparency = 0.5,
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				LayoutOrder = 2,
				ZIndex = 2,
			}),

			BadgeFrame = Roact.createElement("Frame", {
				Size = UDim2.new(0.9, 0, 0, 16),
				BackgroundColor3 = rankInfo.Color,
				BorderSizePixel = 0,
				LayoutOrder = 3,
				ZIndex = 2,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }),
				Label = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = rankInfo.Tag,
					TextColor3 = badgeTextColor,
					Font = Theme.Fonts.Title,
					TextSize = 9,
					ZIndex = 2,
				})
			})
		})
	})
end

return OverheadBillboard
