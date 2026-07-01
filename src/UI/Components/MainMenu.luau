--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Theme = require(ReplicatedStorage.UI.Styles.Theme)
local Button = require(ReplicatedStorage.UI.Components.Button)
local Card = require(ReplicatedStorage.UI.Components.Card)

local MainMenu = Roact.Component:extend("MainMenu")

function MainMenu:init()
	self.state = {
		friends = {},
		isLoading = true,
	}
end

function MainMenu:didMount()
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
			})
		end
	end)
end

function MainMenu:render()
	local props = self.props
	local state = self.state

	
	local joinableFriends = {}
	for _, friend in ipairs(state.friends) do
		if friend.PlaceId == game.PlaceId then
			table.insert(joinableFriends, friend)
		end
	end

	
	local friendElements = {
		UIList = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		})
	}

	if state.isLoading then
		friendElements.Loading = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "Chargement...",
			TextColor3 = Theme.Colors.TextSecondary,
			Font = Theme.Fonts.Body,
			TextSize = 13,
		})
	elseif #joinableFriends == 0 then
		friendElements.Empty = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "AUCUN AMI EN JEU\nTROUVÉ",
			TextColor3 = Theme.Colors.TextSecondary,
			Font = Theme.Fonts.Title,
			TextSize = 16,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
		})
	else
		for idx, friend in ipairs(joinableFriends) do
			friendElements["Friend_" .. friend.VisitorId] = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 48),
				BackgroundColor3 = Theme.Colors.Surface,
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
				LayoutOrder = idx,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, Theme.CornerRadius.Small) }),
				Stroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Transparency = 0.94,
					Thickness = 1,
				}),
				Padding = Roact.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 8),
					PaddingRight = UDim.new(0, 8),
					PaddingTop = UDim.new(0, 4),
					PaddingBottom = UDim.new(0, 4),
				}),

				Avatar = Roact.createElement("ImageLabel", {
					Size = UDim2.new(0, 36, 0, 36),
					Position = UDim2.new(0, 0, 0.5, -18),
					BackgroundColor3 = Theme.Colors.Background,
					Image = "rbxthumb://type=AvatarHeadShot&id=" .. friend.VisitorId .. "&w=150&h=150",
					BorderSizePixel = 0,
				}, {
					Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 18) })
				}),

				NameLabel = Roact.createElement("TextLabel", {
					Size = UDim2.new(0.5, 0, 1, 0),
					Position = UDim2.new(0, 44, 0, 0),
					BackgroundTransparency = 1,
					Text = friend.DisplayName or friend.UserName,
					TextColor3 = Theme.Colors.Text,
					Font = Theme.Fonts.Title,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				JoinBtn = Roact.createElement(Button, {
					text = "Rejoindre",
					size = UDim2.new(0, 72, 0, 24),
					position = UDim2.new(1, 0, 0.5, 0),
					anchorPoint = Vector2.new(1, 0.5),
					backgroundColor = Theme.Colors.Secondary,
					textSize = 10,
					onClick = function()
						pcall(function()
							TeleportService:TeleportToPlaceInstance(friend.PlaceId, friend.GameId, Players.LocalPlayer)
						end)
					end
				})
			})
		end
	end

	
	local updateItems = {
		UIList = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 10),
		}),

		Log1 = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 60),
			BackgroundTransparency = 1,
			LayoutOrder = 1,
		}, {
			Title = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = "🛠️ UI REMASTER V1.0 - 07/06",
				TextColor3 = Theme.Colors.Accent,
				Font = Theme.Fonts.Title,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Desc = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 38),
				Position = UDim2.new(0, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = "Remise à neuf complète de toutes les interfaces avec un style premium en verre dépoli.",
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Body,
				TextSize = 11,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),

		Log2 = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 60),
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, {
			Title = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = "🎙️ CHAT VOCAL SPATIAL",
				TextColor3 = Theme.Colors.Accent,
				Font = Theme.Fonts.Title,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Desc = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 38),
				Position = UDim2.new(0, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = "Parlez avec vos amis en temps réel grâce à l'intégration du chat vocal Roblox.",
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Body,
				TextSize = 11,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),

		Log3 = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 60),
			BackgroundTransparency = 1,
			LayoutOrder = 3,
		}, {
			Title = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = "🪪 PROFILS HUB",
				TextColor3 = Theme.Colors.Accent,
				Font = Theme.Fonts.Title,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Desc = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 38),
				Position = UDim2.new(0, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = "Consultez les statistiques, distribuez des likes et commentez le livre d'or des joueurs.",
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Body,
				TextSize = 11,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),

		Log4 = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 60),
			BackgroundTransparency = 1,
			LayoutOrder = 4,
		}, {
			Title = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = "✨ SYSTÈME VIP EXCLUSIF",
				TextColor3 = Theme.Colors.Accent,
				Font = Theme.Fonts.Title,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Desc = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 38),
				Position = UDim2.new(0, 0, 0, 18),
				BackgroundTransparency = 1,
				Text = "Profitez de traînées de particules VIP, de bannières dorées et de grades uniques.",
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Body,
				TextSize = 11,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		}),
	}

	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Color3.fromRGB(8, 10, 14),
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		ZIndex = 50,
	}, {
		
		DecorGradient = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ZIndex = 1,
		}, {
			Gradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(15, 17, 23)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 10, 14)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 18, 30)),
				}),
				Rotation = 135,
			})
		}),

		
		
		
		LeftPanel = Roact.createElement(Card, {
			size = UDim2.new(0, 310, 0, 360),
			position = UDim2.new(0.05, 0, 0.5, 0),
			anchorPoint = Vector2.new(0, 0.5),
		}, {
			Title = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				Text = "Mise à jour",
				TextColor3 = Theme.Colors.Text,
				Font = Theme.Fonts.Title,
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Line = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 0, 28),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
			}),
			ScrollLogs = Roact.createElement("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -38),
				Position = UDim2.new(0, 0, 0, 38),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Theme.Colors.Primary,
				CanvasSize = UDim2.new(0, 0, 0, 250),
			}, updateItems)
		}),

		
		
		
		CenterContent = Roact.createElement("Frame", {
			Size = UDim2.new(0, 400, 0, 300),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ZIndex = 5,
		}, {
			UIList = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),

			
			LogoTitle = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 48),
				BackgroundTransparency = 1,
				Text = "SPEAKUP",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Theme.Fonts.Title,
				TextSize = 44,
				RichText = true,
				LayoutOrder = 1,
			}),
			LogoSubtitle = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				Text = "<i>ROLEPLAY</i>",
				TextColor3 = Color3.fromRGB(236, 72, 153), 
				Font = Theme.Fonts.Title,
				TextSize = 20,
				RichText = true,
				LayoutOrder = 2,
			}),

			
			WarningLabel = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = "Serveurs 18+",
				TextColor3 = Color3.fromRGB(226, 180, 73), 
				Font = Theme.Fonts.Title,
				TextSize = 13,
				LayoutOrder = 3,
			}),

			
			Spacer = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 16),
				BackgroundTransparency = 1,
				LayoutOrder = 4,
			}),

			
			PlayBtn = Roact.createElement(Button, {
				text = "Jouer",
				size = UDim2.new(0, 220, 0, 48),
				backgroundColor = Theme.Colors.Primary,
				textSize = 16,
				onClick = props.onPlay,
				layoutOrder = 5,
			}),

			
			ServerListBtn = Roact.createElement("TextButton", {
				Size = UDim2.new(0, 180, 0, 24),
				BackgroundTransparency = 1,
				Text = "<i>Liste des serveurs</i>",
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Body,
				TextSize = 13,
				RichText = true,
				BorderSizePixel = 0,
				LayoutOrder = 6,
				[Roact.Event.MouseButton1Click] = function()
					
				end
			})
		}),

		
		
		
		RightPanel = Roact.createElement(Card, {
			size = UDim2.new(0, 310, 0, 360),
			position = UDim2.new(0.95, 0, 0.5, 0),
			anchorPoint = Vector2.new(1, 0.5),
		}, {
			Title = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				Text = "Rejoindre un ami",
				TextColor3 = Theme.Colors.Text,
				Font = Theme.Fonts.Title,
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Line = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 0, 28),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
			}),
			ScrollFriends = Roact.createElement("ScrollingFrame", {
				Size = UDim2.new(1, 0, 1, -38),
				Position = UDim2.new(0, 0, 0, 38),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = Theme.Colors.Primary,
				CanvasSize = UDim2.new(0, 0, 0, #joinableFriends * 56),
			}, friendElements)
		})
	})
end

return MainMenu
