--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Theme = require(ReplicatedStorage.UI.Styles.Theme)
local DragFrame = require(ReplicatedStorage.UI.Components.DragFrame)
local Input = require(ReplicatedStorage.UI.Components.Input)

local PlayerListMenu = Roact.Component:extend("PlayerListMenu")

local RANK_STYLES = {
	Owner = { Color = Color3.fromRGB(231, 76, 60), Tag = "OWNER" },
	Moderator = { Color = Color3.fromRGB(52, 152, 219), Tag = "MODERATOR" },
	VIP = { Color = Color3.fromRGB(241, 196, 15), Tag = "VIP" },
	Regular = { Color = Color3.fromRGB(46, 204, 113), Tag = "REGULAR" },
	Visitor = { Color = Color3.fromRGB(149, 165, 166), Tag = "VISITOR" },
}

function PlayerListMenu:init()
	self.state = {
		players = Players:GetPlayers(),
		searchText = "",
	}

	self.connections = {}
end

function PlayerListMenu:didMount()
	
	local addedConn = Players.PlayerAdded:Connect(function()
		self:setState({
			players = Players:GetPlayers()
		})
	end)
	local removedConn = Players.PlayerRemoving:Connect(function()
		self:setState({
			players = Players:GetPlayers()
		})
	end)

	self.connections = {
		added = addedConn,
		removed = removedConn,
	}
end

function PlayerListMenu:willUnmount()
	for _, conn in pairs(self.connections) do
		if conn then
			conn:Disconnect()
		end
	end
	self.connections = {}
end

function PlayerListMenu:render()
	local props = self.props
	local state = self.state

	
	local filteredPlayers = {}
	for _, player in ipairs(state.players) do
		local dispName = string.lower(player.DisplayName or "")
		local uName = string.lower(player.Name or "")
		local query = string.lower(state.searchText)

		if query == "" or string.find(dispName, query) or string.find(uName, query) then
			table.insert(filteredPlayers, player)
		end
	end

	
	local listChildren: { [string]: any } = {
		UIList = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		})
	}

	for index, p in ipairs(filteredPlayers) do
		local pRank = p:GetAttribute("Rank") or "Visitor"
		local style = RANK_STYLES[pRank] or RANK_STYLES.Visitor

		listChildren["Player_" .. p.UserId] = Roact.createElement("TextButton", {
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = Theme.Colors.Surface,
			BackgroundTransparency = 0.55,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = index,
			
			[Roact.Event.MouseButton1Click] = function()
				props.onSelectPlayer(p)
			end,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, Theme.CornerRadius.Small or 6),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.92,
				Thickness = 1,
			}),
			
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 5),
				PaddingBottom = UDim.new(0, 5),
			}),

			
			MiniAvatar = Roact.createElement("ImageLabel", {
				Size = UDim2.new(0, 40, 0, 40),
				Position = UDim2.new(0, 0, 0.5, -20),
				BackgroundColor3 = Theme.Colors.Background,
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=150&h=150",
				BorderSizePixel = 0,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 20),
				}),
				Stroke = Roact.createElement("UIStroke", {
					Color = style.Color,
					Thickness = 1.5,
					Transparency = 0.3,
				}),
			}),

			
			NamesFrame = Roact.createElement("Frame", {
				Size = UDim2.new(1, -125, 1, 0),
				Position = UDim2.new(0, 50, 0, 0),
				BackgroundTransparency = 1,
			}, {
				UIList = Roact.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 1),
				}),

				DisplayName = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Text = p.DisplayName or p.Name,
					TextColor3 = Theme.Colors.Text,
					Font = Theme.Fonts.Title,
					TextSize = 13,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 1,
				}),

				UserName = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, 12),
					BackgroundTransparency = 1,
					Text = "@" .. p.Name,
					TextColor3 = Theme.Colors.TextSecondary,
					Font = Theme.Fonts.Body,
					TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 2,
				}),
			}),

			
			GradeBadge = Roact.createElement("TextLabel", {
				Size = UDim2.new(0, 70, 0, 20),
				Position = UDim2.new(1, -70, 0.5, -10),
				BackgroundColor3 = style.Color,
				Text = style.Tag,
				TextColor3 = style.Color == Color3.fromRGB(241, 196, 15) and Color3.fromRGB(30, 30, 30) or Color3.fromRGB(255, 255, 255),
				Font = Theme.Fonts.Button,
				TextSize = 9,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 4),
				})
			})
		})
	end

	return Roact.createElement(DragFrame, {
		size = UDim2.new(0, 320, 0, 400),
		position = UDim2.new(0.15, 0, 0.5, 0), 
		headerText = "Membres (" .. #state.players .. ")",
		headerColor = Theme.Colors.Surface,
		onClose = props.onClose,
	}, {
		MainLayout = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 15),
				PaddingRight = UDim.new(0, 15),
				PaddingTop = UDim.new(0, 12),
				PaddingBottom = UDim.new(0, 12),
			}),

			
			SearchInput = Roact.createElement(Input, {
				size = UDim2.new(1, 0, 0, 35),
				position = UDim2.new(0, 0, 0, 0),
				anchorPoint = Vector2.new(0, 0),
				placeholder = "Rechercher un membre...",
				defaultValue = state.searchText,
				onChangeWhileTyping = function(text)
					self:setState({ searchText = text })
				end,
			}),

			
			ListScroll = Roact.createElement("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -45),
				Position = UDim2.new(0, 0, 0, 45),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 4,
				ScrollBarImageColor3 = Theme.Colors.Primary,
				CanvasSize = UDim2.new(0, 0, 0, #filteredPlayers * 60),
			}, listChildren),
		})
	})
end

return PlayerListMenu
