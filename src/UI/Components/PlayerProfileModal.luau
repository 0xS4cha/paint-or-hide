--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Theme = require(ReplicatedStorage.UI.Styles.Theme)
local DragFrame = require(ReplicatedStorage.UI.Components.DragFrame)
local Button = require(ReplicatedStorage.UI.Components.Button)
local Input = require(ReplicatedStorage.UI.Components.Input)
local RankConfig = require(ReplicatedStorage.Shared.Config.RankConfig)
local BannerBackground = require(ReplicatedStorage.UI.Components.BannerBackground)

local localPlayer = Players.LocalPlayer
local playerScripts = localPlayer:WaitForChild("PlayerScripts")
local PlayerDataServiceClient = require(playerScripts:WaitForChild("Client"):WaitForChild("Services"):WaitForChild("PlayerDataServiceClient"))
local NotificationController = require(playerScripts:WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("NotificationController"))

local PlayerProfileModal = Roact.Component:extend("PlayerProfileModal")

local RANK_STYLES = {
	Owner = { Color = Color3.fromRGB(235, 94, 85), Tag = "OWNER" },
	Moderator = { Color = Color3.fromRGB(59, 130, 246), Tag = "MODO" },
	VIP = { Color = Color3.fromRGB(226, 180, 73), Tag = "VIP" },
	Regular = { Color = Color3.fromRGB(16, 185, 129), Tag = "MEMBRE" },
	Visitor = { Color = Color3.fromRGB(160, 166, 178), Tag = "VISITEUR" },
}

local BANNER_STYLES = {
	Default = { Color1 = Color3.fromRGB(20, 22, 28), Color2 = Color3.fromRGB(36, 42, 54) },
	GoldenVIP = { Color1 = Color3.fromRGB(226, 180, 73), Color2 = Color3.fromRGB(180, 140, 40) },
	Sunset = { Color1 = Color3.fromRGB(225, 29, 72), Color2 = Color3.fromRGB(124, 58, 237) },
	Ocean = { Color1 = Color3.fromRGB(37, 99, 235), Color2 = Color3.fromRGB(13, 148, 136) },
	Neon = { Color1 = Color3.fromRGB(168, 85, 247), Color2 = Color3.fromRGB(236, 72, 153) },
}

function PlayerProfileModal:init()
	local player = self.props.player
	
	self.state = {
		rank = player:GetAttribute("Rank") or "Visitor",
		vip = player:GetAttribute("Vip") or false,
		playTime = player:GetAttribute("PlayTime") or 0,
		coins = player:GetAttribute("Coins") or 0,
		customTitle = player:GetAttribute("CustomTitle") or "",
		newTitle = player:GetAttribute("CustomTitle") or "",
		banner = player:GetAttribute("Banner") or "Default",
		likes = player:GetAttribute("Likes") or 0,
		dislikes = player:GetAttribute("Dislikes") or 0,
		comments = {},
		commentText = "",
		isMuted = player:GetAttribute("IsLocalMuted") or false,
		
		
		isProfileSectionOpen = true,
		isCustomisationSectionOpen = false,
		isGuestbookSectionOpen = false,
	}

	self.connections = {}
end

function PlayerProfileModal:didMount()
	local player = self.props.player

	
	local function bindAttribute(name, stateKey)
		local connection = player:GetAttributeChangedSignal(name):Connect(function()
			self:setState({
				[stateKey] = player:GetAttribute(name)
			})
		end)
		table.insert(self.connections, connection)
	end

	bindAttribute("Rank", "rank")
	bindAttribute("Vip", "vip")
	bindAttribute("PlayTime", "playTime")
	bindAttribute("Coins", "coins")
	bindAttribute("CustomTitle", "customTitle")
	bindAttribute("Banner", "banner")
	bindAttribute("Likes", "likes")
	bindAttribute("Dislikes", "dislikes")

	
	self:refreshComments()
end

function PlayerProfileModal:willUnmount()
	for _, connection in ipairs(self.connections) do
		if connection then
			connection:Disconnect()
		end
	end
	self.connections = {}
end

function PlayerProfileModal:refreshComments()
	local player = self.props.player
	task.spawn(function()
		local data = PlayerDataServiceClient:GetOtherPlayerData(player)
		if data and data.Comments then
			self:setState({
				comments = data.Comments
			})
		end
	end)
end

function PlayerProfileModal:formatPlayTime(minutes: number)
	if minutes < 60 then
		return minutes .. " min"
	else
		local hours = math.floor(minutes / 60)
		local mins = minutes % 60
		return hours .. "h " .. mins .. "m"
	end
end

function PlayerProfileModal:render()
	local props = self.props
	local state = self.state
	local targetPlayer = props.player
	local isLocalPlayer = targetPlayer == localPlayer

	local style = RANK_STYLES[state.rank] or RANK_STYLES.Visitor
	local bannerColors = BANNER_STYLES[state.banner] or BANNER_STYLES.Default

	
	local bannerSelectors = {}
	local bannerCount = 0
	if isLocalPlayer then
		local index = 0
		for bannerName, styleData in pairs(RankConfig.BANNER_STYLES) do
			index = index + 1
			bannerCount = bannerCount + 1
			local isVipOnly = bannerName == "GoldenVIP"
			
			bannerSelectors[bannerName] = Roact.createElement("TextButton", {
				Size = UDim2.new(0, 52, 0, 32),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Text = isVipOnly and "👑" or "",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Theme.Fonts.Button,
				TextSize = 12,
				LayoutOrder = index,
				
				[Roact.Event.MouseButton1Click] = function()
					pcall(function()
						local net = NotificationController.networkerClient
						if net then
							net:fire("SetEquippedBanner", bannerName)
						end
					end)
				end,
			}, {
				Background = Roact.createElement(BannerBackground, {
					bannerName = bannerName,
					size = UDim2.new(1, 0, 1, 0),
					cornerRadius = UDim.new(0, 4),
					zIndex = 1,
				}),
				Stroke = Roact.createElement("UIStroke", {
					Color = state.banner == bannerName and Theme.Colors.Accent or Color3.fromRGB(255, 255, 255),
					Transparency = state.banner == bannerName and 0.2 or 0.85,
					Thickness = state.banner == bannerName and 2 or 1,
					ZIndex = 2,
				})
			})
		end
	end

	
	local commentElements = {
		UIList = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		})
	}

	for idx, c in ipairs(state.comments) do
		commentElements["Comment_" .. idx] = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundColor3 = Theme.Colors.Background,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			LayoutOrder = idx,
		}, {
			Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
			Stroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.94,
				Thickness = 1,
			}),
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),

			SenderName = Roact.createElement("TextLabel", {
				Size = UDim2.new(0.35, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = c.senderName,
				TextColor3 = Theme.Colors.Text,
				Font = Theme.Fonts.Title,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			Text = Roact.createElement("TextLabel", {
				Size = UDim2.new(0.65, 0, 1, 0),
				Position = UDim2.new(0.35, 0, 0, 0),
				BackgroundTransparency = 1,
				Text = c.text,
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Body,
				TextSize = 11,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
		})
	end

	return Roact.createElement(DragFrame, {
		size = UDim2.new(0, 360, 0, 500),
		position = UDim2.new(0.5, 0, 0.5, 0),
		showHeader = false, 
	}, {
		
		HubHeader = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundColor3 = Theme.Colors.Surface,
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			ZIndex = 10,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, Theme.CornerRadius.Large or 14),
			}),
			CornerCache = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 10),
				Position = UDim2.new(0, 0, 1, -10),
				BackgroundColor3 = Theme.Colors.Surface,
				BackgroundTransparency = 0.4,
				BorderSizePixel = 0,
				ZIndex = 10,
			}),
			Separator = Roact.createElement("Frame", {
				Size = UDim2.new(1, -24, 0, 1),
				Position = UDim2.new(0, 12, 1, -1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
				ZIndex = 10,
			}),
			TitleLabel = Roact.createElement("TextLabel", {
				Size = UDim2.new(0.7, 0, 1, 0),
				Position = UDim2.new(0, 15, 0, 0),
				BackgroundTransparency = 1,
				Text = "🏠 HUB",
				TextColor3 = Theme.Colors.Text,
				Font = Theme.Fonts.Title,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 10,
			}),
			CloseBtn = Roact.createElement("ImageButton", {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(1, -12, 0.5, -12),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.6,
				Image = "rbxassetid://140355181374747",
				BorderSizePixel = 0,
				Active = true,
				ZIndex = 11,
				
				[Roact.Event.MouseButton1Click] = function()
					if props.onClose then
						props.onClose()
					end
				end,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
				Stroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Transparency = 0.85,
					Thickness = 1,
				})
			})
		}),

		
		ProfileCard = Roact.createElement("Frame", {
			Size = UDim2.new(1, -24, 0, 96),
			Position = UDim2.new(0, 12, 0, 56),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
		}, {
			Background = Roact.createElement(BannerBackground, {
				bannerName = state.banner,
				size = UDim2.new(1, 0, 1, 0),
				cornerRadius = UDim.new(0, Theme.CornerRadius.Medium or 10),
				zIndex = 1,
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.92,
				Thickness = 1,
				ZIndex = 2,
			}),

			
			AvatarImage = Roact.createElement("ImageLabel", {
				Size = UDim2.new(0, 72, 0, 72),
				Position = UDim2.new(0, 12, 0.5, -36),
				BackgroundColor3 = Theme.Colors.Background,
				Image = "rbxthumb://type=AvatarHeadShot&id=" .. targetPlayer.UserId .. "&w=150&h=150",
				BorderSizePixel = 0,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 36) }),
				Stroke = Roact.createElement("UIStroke", {
					Color = style.Color,
					Thickness = 2,
					Transparency = 0.25,
				})
			}),

			
			DetailsFrame = Roact.createElement("Frame", {
				Size = UDim2.new(1, -100, 1, -16),
				Position = UDim2.new(0, 96, 0, 8),
				BackgroundTransparency = 1,
			}, {
				UIList = Roact.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
					Padding = UDim.new(0, 2),
				}),

				
				Names = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Text = (targetPlayer.DisplayName or targetPlayer.Name) .. "  <font color=\"#a0a6b2\">@" .. targetPlayer.Name .. "</font>",
					TextColor3 = Theme.Colors.Text,
					Font = Theme.Fonts.Title,
					TextSize = 13,
					RichText = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 1,
				}),

				
				GradeLabel = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Text = "<font color=\"#" .. style.Color:ToHex() .. "\">" .. style.Tag .. "</font>",
					TextColor3 = Theme.Colors.Text,
					Font = Theme.Fonts.Title,
					TextSize = 11,
					RichText = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 2,
				}),

				
				CashLabel = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Text = "💰 <font color=\"#10b981\">" .. state.coins .. " coins</font>",
					TextColor3 = Theme.Colors.Text,
					Font = Theme.Fonts.Body,
					TextSize = 11,
					RichText = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 3,
				}),

				
				TimeLabel = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					BackgroundTransparency = 1,
					Text = "⏱️ " .. self:formatPlayTime(state.playTime),
					TextColor3 = Theme.Colors.TextSecondary,
					Font = Theme.Fonts.Body,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					LayoutOrder = 4,
				}),
			})
		}),

		
		HubContent = Roact.createElement("ScrollingFrame", {
			Size = UDim2.new(1, -24, 1, -164),
			Position = UDim2.new(0, 12, 0, 160),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.Colors.Primary,
			CanvasSize = UDim2.new(0, 0, 0, 500), 
		}, {
			UIList = Roact.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 10),
			}),

			
			
			
			ProfileHeader = Roact.createElement("TextButton", {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = Theme.Colors.Surface,
				BackgroundTransparency = 0.5,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = 1,
				[Roact.Event.MouseButton1Click] = function()
					self:setState(function(state)
						return { isProfileSectionOpen = not state.isProfileSectionOpen }
					end)
				end,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Stroke = Roact.createElement("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1 }),
				
				Icon = Roact.createElement("TextLabel", {
					Size = UDim2.new(0, 30, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = "👤",
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Title = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, -60, 1, 0),
					Position = UDim2.new(0, 35, 0, 0),
					BackgroundTransparency = 1,
					Text = isLocalPlayer and "OPTIONS DU PROFIL" or "INTERACTIONS",
					TextColor3 = Theme.Colors.Text,
					Font = Theme.Fonts.Title,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Arrow = Roact.createElement("TextLabel", {
					Size = UDim2.new(0, 20, 1, 0),
					Position = UDim2.new(1, -25, 0, 0),
					BackgroundTransparency = 1,
					Text = state.isProfileSectionOpen and "▼" or "►",
					TextColor3 = Theme.Colors.TextSecondary,
					Font = Theme.Fonts.Title,
					TextSize = 10,
				})
			}),

			ProfileContent = state.isProfileSectionOpen and Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, isLocalPlayer and 75 or 120),
				BackgroundTransparency = 1,
				LayoutOrder = 2,
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
				}),

				
				LocalLayout = isLocalPlayer and Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
				}, {
					TitleInput = Roact.createElement(Input, {
						size = UDim2.new(1, -90, 0, 32),
						position = UDim2.new(0, 0, 0, 10),
						anchorPoint = Vector2.new(0, 0),
						placeholder = "Modifier mon titre...",
						defaultValue = state.customTitle,
						label = "Titre personnalisé :",
						onChangeWhileTyping = function(text)
							self:setState({ newTitle = text })
						end,
					}),
					SaveTitleBtn = Roact.createElement(Button, {
						text = "Confirmer",
						size = UDim2.new(0, 80, 0, 32),
						position = UDim2.new(1, 0, 0, 34),
						anchorPoint = Vector2.new(1, 0),
						backgroundColor = Theme.Colors.Primary,
						textSize = 12,
						onClick = function()
							pcall(function()
								local net = PlayerDataServiceClient.networkerClient
								if net then net:fire("SetCustomTitle", state.newTitle) end
							end)
						end,
					})
				}) or nil,

				
				VisitorLayout = not isLocalPlayer and Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
				}, {
					UIList = Roact.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 8),
					}),

					ButtonsRow = Roact.createElement("Frame", {
						Size = UDim2.new(1, 0, 0, 30),
						BackgroundTransparency = 1,
						LayoutOrder = 1,
					}, {
						UIList = Roact.createElement("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 8),
						}),
						WaveBtn = Roact.createElement(Button, {
							text = "👋 Saluer",
							size = UDim2.new(0, 95, 1, 0),
							backgroundColor = Theme.Colors.Primary,
							textSize = 11,
							layoutOrder = 1,
							onClick = function()
								pcall(function()
									local net = NotificationController.networkerClient
									if net then net:fire("Wave", targetPlayer) end
								end)
							end,
						}),
						GiftBtn = Roact.createElement(Button, {
							text = "🪙 Offrir 50",
							size = UDim2.new(0, 110, 1, 0),
							backgroundColor = Theme.Colors.Secondary,
							textSize = 11,
							layoutOrder = 2,
							onClick = function()
								pcall(function()
									local net = NotificationController.networkerClient
									if net then net:fire("GiftCoins", targetPlayer, 50) end
								end)
							end,
						}),
						ReportBtn = Roact.createElement(Button, {
							text = "⚠️ Signaler",
							size = UDim2.new(1, -221, 1, 0),
							backgroundColor = Theme.Colors.Danger,
							textSize = 11,
							layoutOrder = 3,
							onClick = function()
								local AppView = require(ReplicatedStorage.UI.Interfaces.AppView)
								AppView:ShowReport(targetPlayer)
							end,
						}),
					}),

					MuteRow = Roact.createElement("Frame", {
						Size = UDim2.new(1, 0, 0, 30),
						BackgroundTransparency = 1,
						LayoutOrder = 2,
					}, {
						UIList = Roact.createElement("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 8),
						}),
						MuteBtn = Roact.createElement(Button, {
							text = state.isMuted and "🔊 Démuter localement" or "🔇 Muter localement",
							size = UDim2.new(0, 180, 1, 0),
							backgroundColor = state.isMuted and Theme.Colors.Secondary or Theme.Colors.Danger,
							textSize = 11,
							layoutOrder = 1,
							onClick = function()
								local nextMute = not state.isMuted
								targetPlayer:SetAttribute("IsLocalMuted", nextMute)
								self:setState({ isMuted = nextMute })
								
								local char = targetPlayer.Character
								if char then
									for _, desc in ipairs(char:GetDescendants()) do
										if desc:IsA("Sound") then desc.Volume = nextMute and 0 or 0.5 end
									end
								end
							end,
						}),
						LikesFrame = Roact.createElement("Frame", {
							Size = UDim2.new(1, -188, 1, 0),
							BackgroundTransparency = 1,
							LayoutOrder = 2,
						}, {
							UIList = Roact.createElement("UIListLayout", {
								FillDirection = Enum.FillDirection.Horizontal,
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0, 4),
							}),
							Like = Roact.createElement("TextButton", {
								Size = UDim2.new(0.5, -2, 1, 0),
								BackgroundColor3 = Theme.Colors.Secondary,
								BackgroundTransparency = 0.3,
								Text = "👍 " .. state.likes,
								TextColor3 = Color3.fromRGB(255, 255, 255),
								Font = Theme.Fonts.Title,
								TextSize = 11,
								BorderSizePixel = 0,
								LayoutOrder = 1,
								[Roact.Event.MouseButton1Click] = function()
									pcall(function()
										local net = NotificationController.networkerClient
										if net then net:fire("ToggleLike", targetPlayer, "Like") end
									end)
								end,
							}, {
								Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) })
							}),
							Dislike = Roact.createElement("TextButton", {
								Size = UDim2.new(0.5, -2, 1, 0),
								BackgroundColor3 = Theme.Colors.Danger,
								BackgroundTransparency = 0.3,
								Text = "👎 " .. state.dislikes,
								TextColor3 = Color3.fromRGB(255, 255, 255),
								Font = Theme.Fonts.Title,
								TextSize = 11,
								BorderSizePixel = 0,
								LayoutOrder = 2,
								[Roact.Event.MouseButton1Click] = function()
									pcall(function()
										local net = NotificationController.networkerClient
										if net then net:fire("ToggleLike", targetPlayer, "Dislike") end
									end)
								end,
							}, {
								Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) })
							})
						})
					}),

					TitleDisplay = state.customTitle ~= "" and Roact.createElement("TextLabel", {
						Size = UDim2.new(1, 0, 0, 20),
						BackgroundTransparency = 1,
						Text = "Titre actuel : « " .. state.customTitle .. " »",
						TextColor3 = Theme.Colors.Accent,
						Font = Theme.Fonts.Body,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
						LayoutOrder = 3,
					}) or nil,
				}) or nil,
			}) or nil,

			
			
			
			CustomHeader = Roact.createElement("TextButton", {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = Theme.Colors.Surface,
				BackgroundTransparency = 0.5,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = 3,
				[Roact.Event.MouseButton1Click] = function()
					self:setState(function(state)
						return { isCustomisationSectionOpen = not state.isCustomisationSectionOpen }
					end)
				end,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Stroke = Roact.createElement("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1 }),
				
				Icon = Roact.createElement("TextLabel", {
					Size = UDim2.new(0, 30, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = "🪪",
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Title = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, -60, 1, 0),
					Position = UDim2.new(0, 35, 0, 0),
					BackgroundTransparency = 1,
					Text = "CUSTOMISATION (BANNIÈRES)",
					TextColor3 = Theme.Colors.Text,
					Font = Theme.Fonts.Title,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Arrow = Roact.createElement("TextLabel", {
					Size = UDim2.new(0, 20, 1, 0),
					Position = UDim2.new(1, -25, 0, 0),
					BackgroundTransparency = 1,
					Text = state.isCustomisationSectionOpen and "▼" or "►",
					TextColor3 = Theme.Colors.TextSecondary,
					Font = Theme.Fonts.Title,
					TextSize = 10,
				})
			}),

			CustomContent = state.isCustomisationSectionOpen and Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, isLocalPlayer and 45 or 30),
				BackgroundTransparency = 1,
				LayoutOrder = 4,
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 12),
					PaddingRight = UDim.new(0, 12),
				}),

				LocalCustom = isLocalPlayer and (function()
					local containerChildren = {
						UIList = Roact.createElement("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 6),
							VerticalAlignment = Enum.VerticalAlignment.Center,
						})
					}
					for name, selector in pairs(bannerSelectors) do
						containerChildren[name] = selector
					end

					return Roact.createElement("Frame", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
					}, {
						UIList = Roact.createElement("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							SortOrder = Enum.SortOrder.LayoutOrder,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							Padding = UDim.new(0, 8),
						}),
						Label = Roact.createElement("TextLabel", {
							Size = UDim2.new(0, 60, 1, 0),
							BackgroundTransparency = 1,
							Text = "Équiper :",
							TextColor3 = Theme.Colors.TextSecondary,
							Font = Theme.Fonts.Body,
							TextSize = 11,
							TextXAlignment = Enum.TextXAlignment.Left,
							LayoutOrder = 1,
						}),
						Container = Roact.createElement("ScrollingFrame", {
							Size = UDim2.new(1, -68, 1, 0),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							CanvasSize = UDim2.new(0, bannerCount * 58, 0, 0),
							ScrollBarThickness = 2,
							ScrollBarImageColor3 = Theme.Colors.Primary,
							ScrollingDirection = Enum.ScrollingDirection.X,
							LayoutOrder = 2,
						}, containerChildren)
					})
				end)() or Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Text = "Bannière équipée : " .. state.banner,
					TextColor3 = Theme.Colors.TextSecondary,
					Font = Theme.Fonts.Body,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
			}) or nil,

			
			
			
			GuestbookHeader = Roact.createElement("TextButton", {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundColor3 = Theme.Colors.Surface,
				BackgroundTransparency = 0.5,
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = 5,
				[Roact.Event.MouseButton1Click] = function()
					self:setState(function(state)
						return { isGuestbookSectionOpen = not state.isGuestbookSectionOpen }
					end)
				end,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Stroke = Roact.createElement("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1 }),
				
				Icon = Roact.createElement("TextLabel", {
					Size = UDim2.new(0, 30, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = "✍️",
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Title = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, -60, 1, 0),
					Position = UDim2.new(0, 35, 0, 0),
					BackgroundTransparency = 1,
					Text = "LIVRE D'OR (" .. #state.comments .. ")",
					TextColor3 = Theme.Colors.Text,
					Font = Theme.Fonts.Title,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Arrow = Roact.createElement("TextLabel", {
					Size = UDim2.new(0, 20, 1, 0),
					Position = UDim2.new(1, -25, 0, 0),
					BackgroundTransparency = 1,
					Text = state.isGuestbookSectionOpen and "▼" or "►",
					TextColor3 = Theme.Colors.TextSecondary,
					Font = Theme.Fonts.Title,
					TextSize = 10,
				})
			}),

			GuestbookContent = state.isGuestbookSectionOpen and Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, isLocalPlayer and 120 or 160),
				BackgroundTransparency = 1,
				LayoutOrder = 6,
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 6),
					PaddingRight = UDim.new(0, 6),
				}),

				
				CommentsScroll = Roact.createElement("ScrollingFrame", {
					Size = UDim2.new(1, 0, 1, isLocalPlayer and 0 or -36),
					Position = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 2,
					ScrollBarImageColor3 = Theme.Colors.Primary,
					CanvasSize = UDim2.new(0, 0, 0, #state.comments * 46),
				}, commentElements),

				
				AddCommentFrame = not isLocalPlayer and Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 30),
					Position = UDim2.new(0, 0, 1, 0),
					AnchorPoint = Vector2.new(0, 1),
					BackgroundTransparency = 1,
				}, {
					CommentInput = Roact.createElement(Input, {
						size = UDim2.new(1, -76, 1, 0),
						position = UDim2.new(0, 0, 0, 0),
						anchorPoint = Vector2.new(0, 0),
						placeholder = "Commentaire...",
						defaultValue = state.commentText,
						onChangeWhileTyping = function(text)
							self:setState({ commentText = text })
						end,
					}),

					PostCommentBtn = Roact.createElement(Button, {
						text = "Poster",
						size = UDim2.new(0, 70, 1, 0),
						position = UDim2.new(1, 0, 0, 0),
						anchorPoint = Vector2.new(1, 0),
						backgroundColor = Theme.Colors.Primary,
						textSize = 11,
						onClick = function()
							if state.commentText == "" then return end
							pcall(function()
								local net = NotificationController.networkerClient
								if net then
									net:fire("AddComment", targetPlayer, state.commentText)
								end
							end)
							self:setState({ commentText = "" })
							
							task.delay(0.5, function()
								self:refreshComments()
							end)
						end,
					})
				}) or nil,
			}) or nil,
		})
	})
end

return PlayerProfileModal
