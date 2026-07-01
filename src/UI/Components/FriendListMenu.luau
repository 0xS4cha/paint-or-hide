--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Theme = require(ReplicatedStorage.UI.Styles.Theme)
local DragFrame = require(ReplicatedStorage.UI.Components.DragFrame)
local Button = require(ReplicatedStorage.UI.Components.Button)

local FriendListMenu = Roact.Component:extend("FriendListMenu")

function FriendListMenu:init()
	self.state = {
		friends = {},
		isLoading = true,
		error = nil,
	}
end

function FriendListMenu:didMount()
	self:refreshFriends()
end

function FriendListMenu:refreshFriends()
	self:setState({ isLoading = true, error = Roact.None })
	
	task.spawn(function()
		local success, result = pcall(function()
			
			return Players.LocalPlayer:GetFriendsOnline(50)
		end)

		if success and result then
			self:setState({
				friends = result,
				isLoading = false,
			})
		else
			self:setState({
				friends = {},
				isLoading = false,
				error = "Impossible de récupérer les amis"
			})
		end
	end)
end

function FriendListMenu:render()
	local props = self.props
	local state = self.state

	local scrollChildren: { [string]: any } = {
		UIList = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		})
	}

	if state.isLoading then
		scrollChildren.Loading = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 50),
			BackgroundTransparency = 1,
			Text = "Chargement des amis en ligne...",
			TextColor3 = Theme.Colors.TextSecondary,
			Font = Theme.Fonts.Body,
			TextSize = 14,
		})
	elseif state.error then
		scrollChildren.Error = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 50),
			BackgroundTransparency = 1,
			Text = state.error,
			TextColor3 = Theme.Colors.Danger,
			Font = Theme.Fonts.Body,
			TextSize = 14,
		})
	elseif #state.friends == 0 then
		scrollChildren.Empty = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 50),
			BackgroundTransparency = 1,
			Text = "Aucun ami en ligne 💤",
			TextColor3 = Theme.Colors.TextSecondary,
			Font = Theme.Fonts.Body,
			TextSize = 14,
		})
	else
		
		for index, friend in ipairs(state.friends) do
			
			local inThisGame = friend.PlaceId == game.PlaceId
			local statusText = friend.LastLocation or "En ligne"
			
			scrollChildren["Friend_" .. friend.VisitorId] = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 52),
				BackgroundColor3 = Theme.Colors.Surface,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				LayoutOrder = index,
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

				
				Avatar = Roact.createElement("ImageLabel", {
					Size = UDim2.new(0, 40, 0, 40),
					Position = UDim2.new(0, 0, 0.5, -20),
					BackgroundColor3 = Theme.Colors.Background,
					Image = "rbxthumb://type=AvatarHeadShot&id=" .. friend.VisitorId .. "&w=150&h=150",
					BorderSizePixel = 0,
				}, {
					Corner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 20),
					}),
					Stroke = Roact.createElement("UIStroke", {
						Color = Color3.fromRGB(255, 255, 255),
						Transparency = 0.85,
						Thickness = 1,
					}),
				}),

				
				NamesFrame = Roact.createElement("Frame", {
					Size = UDim2.new(1, inThisGame and -130 or -50, 1, 0),
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
						Text = friend.DisplayName or friend.UserName,
						TextColor3 = Theme.Colors.Text,
						Font = Theme.Fonts.Title,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 1,
					}),

					StatusLabel = Roact.createElement("TextLabel", {
						Size = UDim2.new(1, 0, 0, 14),
						BackgroundTransparency = 1,
						Text = inThisGame and "🎮 Parle dans SpeakUp" or "🟢 " .. statusText,
						TextColor3 = inThisGame and Theme.Colors.Secondary or Theme.Colors.TextSecondary,
						Font = Theme.Fonts.Body,
						TextSize = 10,
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 2,
					}),
				}),

				
				JoinButton = inThisGame and Roact.createElement(Button, {
					text = "Rejoindre",
					size = UDim2.new(0, 75, 0, 26),
					position = UDim2.new(1, -75, 0.5, -13),
					backgroundColor = Theme.Colors.Secondary,
					textSize = 12,
					onClick = function()
						local success, err = pcall(function()
							TeleportService:TeleportToPlaceInstance(friend.PlaceId, friend.GameId, Players.LocalPlayer)
						end)

						if not success then
							warn("Teleport failed: ", err)
							
							local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
							local notifController = require(playerScripts:WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("NotificationController"))
							notifController:Add("Téléportation échouée ❌", "Impossible de se connecter dans Roblox Studio.", Theme.Colors.Danger, 5)
						end
					end,
				}) or nil,
			})
		end
	end

	return Roact.createElement(DragFrame, {
		size = UDim2.new(0, 300, 0, 360),
		position = UDim2.new(0.85, 0, 0.5, 0), 
		headerText = "Amis en ligne",
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

			
			ListScroll = Roact.createElement("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -42),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 3,
				ScrollBarImageColor3 = Theme.Colors.Primary,
				CanvasSize = UDim2.new(0, 0, 0, #state.friends * 60),
			}, scrollChildren),

			
			RefreshBtn = Roact.createElement(Button, {
				text = "🔄 Actualiser la liste",
				size = UDim2.new(1, 0, 0, 30),
				position = UDim2.new(0.5, 0, 1, 0),
				anchorPoint = Vector2.new(0.5, 1),
				backgroundColor = Theme.Colors.Surface,
				textSize = 12,
				onClick = function()
					self:refreshFriends()
				end,
			}),
		})
	})
end

return FriendListMenu
