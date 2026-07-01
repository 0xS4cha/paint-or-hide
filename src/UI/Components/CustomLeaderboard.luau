--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Theme = require(ReplicatedStorage.UI.Styles.Theme)

local CustomLeaderboard = Roact.Component:extend("CustomLeaderboard")

function CustomLeaderboard:init()
	self:setState({
		players = Players:GetPlayers(),
		updateTrigger = 0, 
	})

	self.connections = {}
	self.attributeConnections = {}
end

function CustomLeaderboard:didMount()
	
	local addedConn = Players.PlayerAdded:Connect(function(player)
		self:setState({
			players = Players:GetPlayers()
		})
		self:trackPlayerAttributes(player)
	end)

	local removedConn = Players.PlayerRemoving:Connect(function(player)
		self:setState({
			players = Players:GetPlayers()
		})
		self:untrackPlayerAttributes(player)
	end)

	self.connections = {
		added = addedConn,
		removed = removedConn,
	}

	
	for _, player in ipairs(self.state.players) do
		self:trackPlayerAttributes(player)
	end
end

function CustomLeaderboard:willUnmount()
	
	for _, conn in pairs(self.connections) do
		if conn then conn:Disconnect() end
	end
	self.connections = {}

	
	for _, conns in pairs(self.attributeConnections) do
		for _, conn in ipairs(conns) do
			if conn then conn:Disconnect() end
		end
	end
	self.attributeConnections = {}
end


function CustomLeaderboard:trackPlayerAttributes(player: Player)
	if self.attributeConnections[player] then return end

	local playTimeConn = player:GetAttributeChangedSignal("PlayTime"):Connect(function()
		self:setState(function(state)
			return { updateTrigger = state.updateTrigger + 1 }
		end)
	end)

	local coinsConn = player:GetAttributeChangedSignal("Coins"):Connect(function()
		self:setState(function(state)
			return { updateTrigger = state.updateTrigger + 1 }
		end)
	end)

	local rankConn = player:GetAttributeChangedSignal("Rank"):Connect(function()
		self:setState(function(state)
			return { updateTrigger = state.updateTrigger + 1 }
		end)
	end)

	self.attributeConnections[player] = { playTimeConn, coinsConn, rankConn }
end

function CustomLeaderboard:untrackPlayerAttributes(player: Player)
	local conns = self.attributeConnections[player]
	if conns then
		for _, conn in ipairs(conns) do
			if conn then conn:Disconnect() end
		end
		self.attributeConnections[player] = nil
	end
end


function CustomLeaderboard:formatNumber(value: number)
	if value >= 1000000 then
		return string.format("%.1f M", value / 1000000):gsub("%.0", "")
	elseif value >= 1000 then
		return string.format("%.1f K", value / 1000):gsub("%.0", "")
	else
		return tostring(value)
	end
end

function CustomLeaderboard:render()
	local state = self.state

	
	local sortedPlayers = {}
	for _, player in ipairs(state.players) do
		table.insert(sortedPlayers, player)
	end
	table.sort(sortedPlayers, function(a, b)
		local aTime = a:GetAttribute("PlayTime") or 0
		local bTime = b:GetAttribute("PlayTime") or 0
		return aTime > bTime
	end)

	
	local listChildren: { [string]: any } = {
		UIList = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 1),
		})
	}

	for index, p in ipairs(sortedPlayers) do
		local pPlayTime = p:GetAttribute("PlayTime") or 0
		local pCoins = p:GetAttribute("Coins") or 0
		local pVip = p:GetAttribute("Vip") or false

		listChildren["PlayerRow_" .. p.UserId] = Roact.createElement("TextButton", {
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = false,
			LayoutOrder = index,
			
			[Roact.Event.MouseButton1Click] = function()
				local AppView = require(ReplicatedStorage.UI.Interfaces.AppView)
				AppView:ShowProfile(p)
			end,
		}, {
			
			HoverBackground = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.97,
				BorderSizePixel = 0,
				Visible = true,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }),
			}),

			
			MiniAvatar = Roact.createElement("ImageLabel", {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(0, 8, 0.5, -12),
				BackgroundColor3 = Theme.Colors.Surface,
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=150&h=150",
				BorderSizePixel = 0,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 12),
				}),
				Stroke = Roact.createElement("UIStroke", {
					Color = pVip and Theme.Colors.Accent or Color3.fromRGB(120, 120, 130),
					Transparency = 0.5,
					Thickness = 1.5,
				}),
			}),

			
			DisplayName = Roact.createElement("TextLabel", {
				Size = UDim2.new(0.5, -36, 1, 0),
				Position = UDim2.new(0, 38, 0, 0),
				BackgroundTransparency = 1,
				Text = p.DisplayName or p.Name,
				TextColor3 = pVip and Theme.Colors.Accent or Theme.Colors.Text,
				Font = pVip and Theme.Fonts.Title or Theme.Fonts.Body,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			
			MinutesVal = Roact.createElement("TextLabel", {
				Size = UDim2.new(0.2, 0, 1, 0),
				Position = UDim2.new(0.6, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = tostring(pPlayTime),
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Body,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),

			
			CoinsVal = Roact.createElement("TextLabel", {
				Size = UDim2.new(0.2, 0, 1, 0),
				Position = UDim2.new(0.8, -8, 0, 0),
				BackgroundTransparency = 1,
				Text = self:formatNumber(pCoins),
				TextColor3 = Theme.Colors.Secondary, 
				Font = Theme.Fonts.Title,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		})
	end

	return Roact.createElement("Frame", {
		Size = UDim2.new(0, 290, 0, 220),
		Position = UDim2.new(1, -10, 0, 10), 
		AnchorPoint = Vector2.new(1, 0),
		BackgroundColor3 = Theme.Colors.Background,
		BackgroundTransparency = 0.25, 
		BorderSizePixel = 0,
	}, {
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, Theme.CornerRadius.Medium or 10),
		}),

		Stroke = Roact.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Transparency = 0.88, 
			Thickness = 1,
		}),

		
		Header = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 32),
			BackgroundColor3 = Theme.Colors.Surface,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, Theme.CornerRadius.Medium or 10),
			}),

			
			CornerCache = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 8),
				Position = UDim2.new(0, 0, 1, -8),
				BackgroundColor3 = Theme.Colors.Surface,
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
			}),

			
			HeaderLine = Roact.createElement("Frame", {
				Size = UDim2.new(1, -16, 0, 1),
				Position = UDim2.new(0, 8, 1, -1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
			}),

			
			PlayersLabel = Roact.createElement("TextLabel", {
				Size = UDim2.new(0.5, 0, 1, 0),
				Position = UDim2.new(0, 10, 0, 0),
				BackgroundTransparency = 1,
				Text = "Players (" .. #state.players .. ")",
				TextColor3 = Theme.Colors.Text,
				Font = Theme.Fonts.Title,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			
			MinutesLabel = Roact.createElement("TextLabel", {
				Size = UDim2.new(0.2, 0, 1, 0),
				Position = UDim2.new(0.6, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = "Minutes",
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Title,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),

			
			CoinsLabel = Roact.createElement("TextLabel", {
				Size = UDim2.new(0.2, 0, 1, 0),
				Position = UDim2.new(0.8, -8, 0, 0),
				BackgroundTransparency = 1,
				Text = "Coins",
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Title,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Right,
			}),
		}),

		
		Container = Roact.createElement("ScrollingFrame", {
			Size = UDim2.new(1, -8, 1, -38),
			Position = UDim2.new(0, 4, 0, 34),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Colors.Primary,
			CanvasSize = UDim2.new(0, 0, 0, #sortedPlayers * 35),
			ScrollBarImageTransparency = 0.3,
		}, listChildren),
	})
end

return CustomLeaderboard
