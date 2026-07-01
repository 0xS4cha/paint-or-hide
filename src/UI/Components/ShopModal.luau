--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Theme = require(ReplicatedStorage.UI.Styles.Theme)
local DragFrame = require(ReplicatedStorage.UI.Components.DragFrame)
local Button = require(ReplicatedStorage.UI.Components.Button)
local Card = require(ReplicatedStorage.UI.Components.Card)
local BannerBackground = require(ReplicatedStorage.UI.Components.BannerBackground)

local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
local ShopController = require(playerScripts:WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("ShopController"))
local PlayerDataServiceClient = require(playerScripts:WaitForChild("Client"):WaitForChild("Services"):WaitForChild("PlayerDataServiceClient"))
local Config = require(ReplicatedStorage.Shared.Config)
local ShopItems = Config.Shop
local RankConfig = Config.Ranks

local function getBannerNameFromItemId(itemId: string): string?
	if string.sub(itemId, 1, 7) == "banner_" then
		local lowerName = string.sub(itemId, 8)
		for key, _ in pairs(RankConfig.BANNER_STYLES) do
			if string.lower(key) == lowerName then
				return key
			end
		end
	end
	return nil
end

local ShopModal = Roact.Component:extend("ShopModal")

type TabType = "Items" | "Profile" | "Abonnements" | "Caisses" | "Historique"
type SortType = "default" | "price_asc" | "price_desc" | "discount"

function ShopModal:init()
	self.state = {
		activeTab = "Items" :: TabType,
		sortBy = "default" :: SortType,
		coins = 0,
		inventory = {},
		gifts = {},
		history = {},
		giftingItemId = nil :: string?,
		selectedGiftRecipient = nil :: Player?,
		searchQuery = "",
	}

	self.dataConnection = nil
end

function ShopModal:didMount()
	local initialData = PlayerDataServiceClient:GetData()
	if initialData then
		self:setState({
			coins = initialData.Coins or 0,
			inventory = initialData.Inventory or {},
			gifts = initialData.Gifts or {},
			history = initialData.History or {},
		})
	end

	self.dataConnection = PlayerDataServiceClient.LocalDataChanged:Connect(function(data)
		self:setState({
			coins = data.Coins or 0,
			inventory = data.Inventory or {},
			gifts = data.Gifts or {},
			history = data.History or {},
		})
	end)
end

function ShopModal:willUnmount()
	if self.dataConnection then
		self.dataConnection:Disconnect()
		self.dataConnection = nil
	end
end

local function formatPriceText(normalPrice: number, discountPrice: number?): string
	if discountPrice then
		return string.format("<font color=\"#a0a6b2\"><s>%d</s></font> <font color=\"#ffffff\">%d</font>", normalPrice, discountPrice)
	else
		return string.format("<font color=\"#ffffff\">%d</font>", normalPrice)
	end
end

function ShopModal:render()
	local props = self.props
	local state = self.state

	local itemsCount = 0
	local profileCount = 0
	local subsCount = 0
	local cratesCount = 0
	for _, item in pairs(ShopItems) do
		if item.Category == "Items" then
			itemsCount = itemsCount + 1
		elseif item.Category == "Profile" then
			profileCount = profileCount + 1
		elseif item.Category == "Abonnements" then
			subsCount = subsCount + 1
		elseif item.Category == "Caisses" then
			cratesCount = cratesCount + 1
		end
	end
	local historyCount = #state.history

	local filteredItems = {}
	local query = string.lower(state.searchQuery or "")
	if state.activeTab ~= "Historique" then
		for _, item in pairs(ShopItems) do
			if item.Category == state.activeTab then
				if query == "" or string.find(string.lower(item.Name), query) or string.find(string.lower(item.Description or ""), query) then
					table.insert(filteredItems, item)
				end
			end
		end
	end

	if state.sortBy == "price_asc" then
		table.sort(filteredItems, function(a, b)
			local priceA = a.DiscountPrice or a.NormalPrice
			local priceB = b.DiscountPrice or b.NormalPrice
			return priceA < priceB
		end)
	elseif state.sortBy == "price_desc" then
		table.sort(filteredItems, function(a, b)
			local priceA = a.DiscountPrice or a.NormalPrice
			local priceB = b.DiscountPrice or b.NormalPrice
			return priceA > priceB
		end)
	elseif state.sortBy == "discount" then
		table.sort(filteredItems, function(a, b)
			local discountA = a.DiscountPrice and (a.NormalPrice - a.DiscountPrice) or 0
			local discountB = b.DiscountPrice and (b.NormalPrice - b.DiscountPrice) or 0
			if discountA ~= discountB then
				return discountA > discountB
			end
			return (a.DiscountPrice or a.NormalPrice) < (b.DiscountPrice or b.NormalPrice)
		end)
	end

	local featuredElements = {}
	local catalogueElements = {}

	for idx, item in ipairs(filteredItems) do
		local isUnique = item.Category == "Profile" or item.Category == "Items"
		local isOwned = state.inventory and state.inventory[item.Id] and state.inventory[item.Id] > 0
		local canBuy = not (isUnique and isOwned)

		local cardProps = {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Theme.Colors.Surface,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			LayoutOrder = idx,
		}

		local badgeColor = Color3.fromRGB(37, 99, 235) 
		if item.Badge == "NOUVEAU" or item.Badge == "CONSEILLÉ" then
			badgeColor = Color3.fromRGB(16, 185, 129)
		elseif item.Badge == "PROMO" or item.Badge == "OFFRE" then
			badgeColor = Color3.fromRGB(225, 29, 72)
		elseif item.Badge == "TOP VENTE" or item.Badge == "POPULAIRE" or item.Badge == "MYTHIQUE" then
			badgeColor = Theme.Colors.Accent
		end

		local itemCard = Roact.createElement("Frame", cardProps, {
			Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, Theme.CornerRadius.Medium) }),
			Stroke = Roact.createElement("UIStroke", {
				Color = item.IsFeatured and Theme.Colors.Accent or Color3.fromRGB(255, 255, 255),
				Thickness = item.IsFeatured and 2 or 1,
				Transparency = item.IsFeatured and 0.2 or 0.85,
			}),
			ThumbnailContainer = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 120),
				BackgroundColor3 = Color3.fromRGB(15, 17, 23),
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
				ClipsDescendants = true,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, Theme.CornerRadius.Medium) }),
				Banner = getBannerNameFromItemId(item.Id) and Roact.createElement(BannerBackground, {
					bannerName = getBannerNameFromItemId(item.Id),
					size = UDim2.new(1, 0, 1, 0),
					cornerRadius = UDim.new(0, Theme.CornerRadius.Medium),
				}) or nil,
				Image = not getBannerNameFromItemId(item.Id) and Roact.createElement("ImageLabel", {
					Size = UDim2.new(0, 60, 0, 60),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = item.ImageId,
				}) or nil,
				Badge = item.Badge and Roact.createElement("Frame", {
					Size = UDim2.new(0, 74, 0, 20),
					Position = UDim2.new(0, 8, 0, 8),
					AnchorPoint = Vector2.new(0, 0),
					BackgroundColor3 = badgeColor,
					BorderSizePixel = 0,
					ZIndex = 5,
				}, {
					Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }),
					Label = Roact.createElement("TextLabel", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = item.Badge,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						Font = Theme.Fonts.Title,
						TextSize = 8,
						TextWrapped = true,
					})
				}) or nil,
				GiftBtn = Roact.createElement("ImageButton", {
					Size = UDim2.new(0, 16, 0, 16),
					Position = UDim2.new(1, -8, 0, 8),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					BackgroundTransparency = 0.5,
					BorderSizePixel = 0,
					Image = "rbxassetid://107234702040687",
					ZIndex = 10,
					[Roact.Event.MouseButton1Click] = function()
						self:setState({ giftingItemId = item.Id })
					end,
				}, {
					Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 8) })
				}) or nil,
			}),

			Details = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 1, -120),
				Position = UDim2.new(0, 0, 0, 120),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 8),
					PaddingBottom = UDim.new(0, 8),
				}),
				Title = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Text = item.Name,
					TextColor3 = Theme.Colors.Text,
					Font = Theme.Fonts.Title,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Desc = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, 40),
					Position = UDim2.new(0, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = item.Description,
					TextColor3 = Theme.Colors.TextSecondary,
					Font = Theme.Fonts.Body,
					TextSize = 9,
					TextWrapped = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
				}),

				ActionRow = Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 36),
					Position = UDim2.new(0, 0, 1, -36),
					BackgroundTransparency = 1,
				}, {
					BuyBtn = Roact.createElement("TextButton", {
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundColor3 = canBuy and Theme.Colors.Secondary or Color3.fromRGB(80, 80, 80),
						BackgroundTransparency = canBuy and 0 or 0.5,
						Text = "",
						BorderSizePixel = 0,
						AutoButtonColor = canBuy,
						[Roact.Event.MouseButton1Click] = function()
							if canBuy then
								ShopController:BuyItem(item.Id)
							end
						end,
					}, {
						Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
						Content = Roact.createElement("Frame", {
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
						}, {
							UIList = Roact.createElement("UIListLayout", {
								FillDirection = Enum.FillDirection.Horizontal,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder,
								Padding = UDim.new(0, 4),
							}),
							CoinIcon = canBuy and Roact.createElement("ImageLabel", {
								Size = UDim2.new(0, 16, 0, 16),
								BackgroundTransparency = 1,
								Image = "rbxassetid://121229647872473",
								ImageColor3 = Color3.fromRGB(241, 196, 15),
								LayoutOrder = 1,
							}) or nil,
							PriceLabel = Roact.createElement("TextLabel", {
								Size = UDim2.new(0, 0, 1, 0),
								BackgroundTransparency = 1,
								Text = canBuy and formatPriceText(item.NormalPrice, item.DiscountPrice) .. "  ACHETER" or "POSSÉDÉ",
								TextColor3 = canBuy and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(180, 180, 180),
								Font = Theme.Fonts.Title,
								TextSize = 12,
								RichText = true,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextYAlignment = Enum.TextYAlignment.Center,
								AutomaticSize = Enum.AutomaticSize.X,
								LayoutOrder = 2,
							}),
						})
					}),

				})
			})
		})

		if item.IsFeatured then
			featuredElements["Featured_" .. item.Id] = itemCard
		else
			catalogueElements["Item_" .. item.Id] = itemCard
		end
	end

	local function makeCategoryButton(tab: TabType, label: string, count: number, order: number)
		local isActive = state.activeTab == tab
		local icons = {
			Items = "🎒",
			Profile = "👤",
			Abonnements = "⭐",
			Caisses = "📦",
			Historique = "🕒"
		}
		return Roact.createElement("TextButton", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundColor3 = isActive and Theme.Colors.Surface or Color3.fromRGB(15, 17, 23),
			BackgroundTransparency = isActive and 0.2 or 1,
			BorderSizePixel = 0,
			Text = "",
			LayoutOrder = order,
			[Roact.Event.MouseButton1Click] = function()
				self:setState({ activeTab = tab, sortBy = "default" })
			end,
		}, {
			Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, Theme.CornerRadius.Small) }),
			ActiveIndicator = isActive and Roact.createElement("Frame", {
				Size = UDim2.new(0, 4, 1, -16),
				Position = UDim2.new(0, 4, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Theme.Colors.Accent,
				BorderSizePixel = 0,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(1, 0) })
			}) or nil,
			Label = Roact.createElement("TextLabel", {
				Size = UDim2.new(0.65, 0, 1, 0),
				Position = UDim2.new(0, isActive and 16 or 10, 0, 0),
				BackgroundTransparency = 1,
				Text = icons[tab] .. "  " .. label,
				TextColor3 = isActive and Theme.Colors.Text or Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Title,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			Count = Roact.createElement("TextLabel", {
				Size = UDim2.new(0.3, 0, 1, 0),
				Position = UDim2.new(0.7, -10, 0, 0),
				BackgroundTransparency = 1,
				Text = tostring(count),
				TextColor3 = isActive and Theme.Colors.Text or Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Body,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Right,
			})
		})
	end

	local historyElements = {
		UIList = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6),
		})
	}
	if state.activeTab == "Historique" then
		if #state.history == 0 then
			historyElements.Empty = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = "Aucun historique disponible.",
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Body,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			})
		else
			for idx, log in ipairs(state.history) do
				local item = ShopItems[log.ItemId]
				local itemName = item and item.Name or log.ItemId
				local icon = "🛒"
				local desc = "Achat"
				if log.Action == "buy" then
					desc = string.format("Achat réussi de %s pour %d jetons", itemName, log.Price)
				elseif log.Action == "gift" then
					icon = "🎁"
					desc = string.format("Offert %s à %s pour %d jetons", itemName, log.TargetName or "?", log.Price)
				elseif log.Action == "receive_gift" then
					icon = "📥"
					desc = string.format("Reçu %s en cadeau de %s", itemName, log.SenderName or "?")
				end

				local dateStr = os.date("%d/%m/%Y %H:%M", log.Timestamp)

				historyElements["Log_" .. idx] = Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 56),
					BackgroundColor3 = Theme.Colors.Surface,
					BackgroundTransparency = 0.5,
					BorderSizePixel = 0,
					LayoutOrder = -log.Timestamp,
				}, {
					Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
					Stroke = Roact.createElement("UIStroke", {
						Color = Color3.fromRGB(255, 255, 255),
						Transparency = 0.94,
						Thickness = 1,
					}),
					Padding = Roact.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 12),
						PaddingRight = UDim.new(0, 12),
						PaddingTop = UDim.new(0, 4),
						PaddingBottom = UDim.new(0, 4),
					}),
					Icon = Roact.createElement("TextLabel", {
						Size = UDim2.new(0, 32, 1, 0),
						BackgroundTransparency = 1,
						Text = icon,
						TextSize = 20,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
					}),
					Desc = Roact.createElement("TextLabel", {
						Size = UDim2.new(0.65, 0, 1, 0),
						Position = UDim2.new(0, 40, 0, 0),
						BackgroundTransparency = 1,
						Text = desc,
						TextColor3 = Theme.Colors.Text,
						Font = Theme.Fonts.Title,
						TextSize = 12,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
					}),
					Date = Roact.createElement("TextLabel", {
						Size = UDim2.new(0.3, 0, 1, 0),
						Position = UDim2.new(0.7, 0, 0, 0),
						BackgroundTransparency = 1,
						Text = dateStr,
						TextColor3 = Theme.Colors.TextSecondary,
						Font = Theme.Fonts.Body,
						TextSize = 9,
						TextXAlignment = Enum.TextXAlignment.Right,
						TextYAlignment = Enum.TextYAlignment.Center,
					})
				})
			end
		end
	end

	local giftingOverlay = nil
	if state.giftingItemId then
		local giftItem = ShopItems[state.giftingItemId]
		local playerElements = {
			UIList = Roact.createElement("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 6),
			})
		}

		local otherPlayers = {}
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= Players.LocalPlayer then
				table.insert(otherPlayers, player)
			end
		end

		if #otherPlayers == 0 then
			playerElements.Empty = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 100),
				BackgroundTransparency = 1,
				Text = "Aucun autre joueur sur le serveur.",
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Body,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
			})
		else
			for idx, p in ipairs(otherPlayers) do
				local isSelected = state.selectedGiftRecipient == p
				table.insert(playerElements, Roact.createElement("TextButton", {
					Size = UDim2.new(1, 0, 0, 36),
					BackgroundColor3 = isSelected and Theme.Colors.Accent or Theme.Colors.Background,
					BackgroundTransparency = isSelected and 0.1 or 0.5,
					BorderSizePixel = 0,
					Text = "",
					LayoutOrder = idx,
					[Roact.Event.MouseButton1Click] = function()
						self:setState({ selectedGiftRecipient = p })
					end,
				}, {
					Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
					Stroke = Roact.createElement("UIStroke", {
						Color = isSelected and Theme.Colors.Accent or Color3.fromRGB(255, 255, 255),
						Transparency = isSelected and 0.2 or 0.9,
						Thickness = 1,
					}),
					Avatar = Roact.createElement("ImageLabel", {
						Size = UDim2.new(0, 28, 0, 28),
						Position = UDim2.new(0, 8, 0.5, -14),
						BackgroundTransparency = 1,
						Image = "rbxthumb://type=AvatarHeadShot&id=" .. p.UserId .. "&w=150&h=150",
					}, {
						Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 14) })
					}),
					Name = Roact.createElement("TextLabel", {
						Size = UDim2.new(1, -50, 1, 0),
						Position = UDim2.new(0, 44, 0, 0),
						BackgroundTransparency = 1,
						Text = p.DisplayName or p.Name,
						TextColor3 = isSelected and Color3.fromRGB(15, 17, 23) or Theme.Colors.Text,
						Font = Theme.Fonts.Title,
						TextSize = 11,
						TextXAlignment = Enum.TextXAlignment.Left,
					})
				}))
			end
		end

		giftingOverlay = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.6,
			BorderSizePixel = 0,
			ZIndex = 100,
		}, {
			Card = Roact.createElement(Card, {
				size = UDim2.new(0, 340, 0, 360),
				position = UDim2.new(0.5, 0, 0.5, 0),
				anchorPoint = Vector2.new(0.5, 0.5),
			}, {
				Title = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundTransparency = 1,
					Text = "Offrir : " .. (giftItem and giftItem.Name or "Objet"),
					TextColor3 = Theme.Colors.Text,
					Font = Theme.Fonts.Title,
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),
				Subtitle = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, 16),
					Position = UDim2.new(0, 0, 0, 24),
					BackgroundTransparency = 1,
					Text = "Choisissez le destinataire sur le serveur :",
					TextColor3 = Theme.Colors.TextSecondary,
					Font = Theme.Fonts.Body,
					TextSize = 10,
					TextXAlignment = Enum.TextXAlignment.Center,
				}),

				PlayerScroll = Roact.createElement("ScrollingFrame", {
					Size = UDim2.new(1, 0, 1, -100),
					Position = UDim2.new(0, 0, 0, 48),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 2,
					ScrollBarImageColor3 = Theme.Colors.Primary,
					CanvasSize = UDim2.new(0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
				}, playerElements),

				ButtonRow = Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 32),
					Position = UDim2.new(0, 0, 1, -32),
					BackgroundTransparency = 1,
				}, {
					Cancel = Roact.createElement(Button, {
						text = "Annuler",
						size = UDim2.new(0.5, -6, 1, 0),
						backgroundColor = Theme.Colors.Danger,
						textSize = 12,
						onClick = function()
							self:setState({ giftingItemId = nil, selectedGiftRecipient = nil })
						end,
					}),
					Send = Roact.createElement(Button, {
						text = "Offrir 🎁",
						size = UDim2.new(0.5, -6, 1, 0),
						position = UDim2.new(0.5, 6, 0, 0),
						backgroundColor = Theme.Colors.Secondary,
						textSize = 12,
						onClick = function()
							if state.selectedGiftRecipient then
								ShopController:GiftItem(state.selectedGiftRecipient, state.giftingItemId)
								self:setState({ giftingItemId = nil, selectedGiftRecipient = nil })
							end
						end,
					})
				})
			})
		})
	end

	local hasFeatured = false
	for _, _ in pairs(featuredElements) do
		hasFeatured = true
		break
	end

	local contentCount = 0
	for _, _ in pairs(catalogueElements) do
		contentCount = contentCount + 1
	end

	local scrollContent = {
		UIList = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 12),
		})
	}
	if hasFeatured then
		scrollContent.FeaturedHeader = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text = "✨ EN VEDETTE",
			TextColor3 = Theme.Colors.Accent,
			Font = Theme.Fonts.Title,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
			LayoutOrder = 1,
		})

		local featuredGrid = {
			UIGrid = Roact.createElement("UIGridLayout", {
				CellSize = UDim2.new(0, 200, 0, 240),
				CellPadding = UDim2.new(0, 12, 0, 12),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})
		}
		for id, elem in pairs(featuredElements) do
			featuredGrid[id] = elem
		end

		scrollContent.FeaturedContainer = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, featuredGrid)
	end

	scrollContent.CatalogueHeader = Roact.createElement("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		BackgroundTransparency = 1,
		Text = "📦 CATALOGUE",
		TextColor3 = Theme.Colors.TextSecondary,
		Font = Theme.Fonts.Title,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 3,
	})

	local catalogueGrid = {
		UIGrid = Roact.createElement("UIGridLayout", {
			CellSize = UDim2.new(0, 200, 0, 240),
			CellPadding = UDim2.new(0, 12, 0, 12),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})
	}
	for id, elem in pairs(catalogueElements) do
		catalogueGrid[id] = elem
	end

	scrollContent.CatalogueContainer = Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = 4,
	}, catalogueGrid)

	if not hasFeatured and contentCount == 0 then
		scrollContent.EmptyState = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 100),
			BackgroundTransparency = 1,
			Text = "Aucun article disponible dans cette catégorie.",
			TextColor3 = Theme.Colors.TextSecondary,
			Font = Theme.Fonts.Body,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			LayoutOrder = 5,
		})
	end

	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 90,
	}, {
		GiftingPrompt = giftingOverlay,

		MainFrame = Roact.createElement(DragFrame, {
			size = UDim2.new(0, 960, 0, 640),
			position = UDim2.new(0.5, 0, 0.5, 0),
			showHeader = false,
		}, {
			TopBar = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 64),
				BackgroundColor3 = Color3.fromRGB(15, 17, 23),
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, Theme.CornerRadius.Large) }),
				CornerCache = Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 10),
					Position = UDim2.new(0, 0, 1, -10),
					BackgroundColor3 = Color3.fromRGB(15, 17, 23),
					BackgroundTransparency = 0.3,
					BorderSizePixel = 0,
				}),
				Line = Roact.createElement("Frame", {
					Size = UDim2.new(1, -24, 0, 1),
					Position = UDim2.new(0, 12, 1, -1),
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 0.85,
					BorderSizePixel = 0,
				}),

				Logo = Roact.createElement("Frame", {
					Size = UDim2.new(0, 200, 1, 0),
					Position = UDim2.new(0, 15, 0, 0),
					BackgroundTransparency = 1,
				}, {
					CartIcon = Roact.createElement("ImageLabel", {
						Size = UDim2.new(0, 24, 0, 24),
						Position = UDim2.new(0, 0, 0.5, -12),
						BackgroundTransparency = 1,
						Image = "rbxassetid://121229647872473",
						ImageColor3 = Theme.Colors.Accent,
					}),
					Officielle = Roact.createElement("TextLabel", {
						Size = UDim2.new(1, -30, 0, 12),
						Position = UDim2.new(0, 30, 0, 12),
						BackgroundTransparency = 1,
						Text = "OFFICIELLE",
						TextColor3 = Theme.Colors.TextSecondary,
						Font = Theme.Fonts.Title,
						TextSize = 8,
						TextXAlignment = Enum.TextXAlignment.Left,
					}),
					Boutique = Roact.createElement("TextLabel", {
						Size = UDim2.new(1, -30, 0, 20),
						Position = UDim2.new(0, 30, 0, 22),
						BackgroundTransparency = 1,
						Text = "BOUTIQUE",
						TextColor3 = Theme.Colors.Text,
						Font = Theme.Fonts.Title,
						TextSize = 18,
						TextXAlignment = Enum.TextXAlignment.Left,
					})
				}),

				HeaderActions = Roact.createElement("Frame", {
					Size = UDim2.new(0, 320, 1, 0),
					Position = UDim2.new(1, -15, 0, 0),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundTransparency = 1,
				}, {
					UIList = Roact.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 10),
					}),

					CoinsPill = Roact.createElement("Frame", {
						Size = UDim2.new(0, 110, 0, 32),
						BackgroundColor3 = Color3.fromRGB(15, 17, 23),
						BackgroundTransparency = 0.4,
						BorderSizePixel = 0,
						LayoutOrder = 1,
					}, {
						Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 16) }),
						Stroke = Roact.createElement("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1 }),
						Icon = Roact.createElement("ImageLabel", {
							Size = UDim2.new(0, 16, 0, 16),
							Position = UDim2.new(0, 10, 0.5, -8),
							BackgroundTransparency = 1,
							Image = "rbxassetid://119651319213657",
							ImageColor3 = Color3.fromRGB(241, 196, 15),
						}),
						Count = Roact.createElement("TextLabel", {
							Size = UDim2.new(1, -45, 0, 14),
							Position = UDim2.new(0, 32, 0, 4),
							BackgroundTransparency = 1,
							Text = tostring(state.coins),
							TextColor3 = Theme.Colors.Text,
							Font = Theme.Fonts.Title,
							TextSize = 11,
							TextXAlignment = Enum.TextXAlignment.Left,
						}),
						Label = Roact.createElement("TextLabel", {
							Size = UDim2.new(1, -45, 0, 10),
							Position = UDim2.new(0, 32, 0, 16),
							BackgroundTransparency = 1,
							Text = "COINS",
							TextColor3 = Theme.Colors.TextSecondary,
							Font = Theme.Fonts.Body,
							TextSize = 7,
							TextXAlignment = Enum.TextXAlignment.Left,
						})
					}),

					BuyTokensBtn = Roact.createElement("TextButton", {
						Size = UDim2.new(0, 130, 0, 32),
						BackgroundColor3 = Theme.Colors.Accent,
						BorderSizePixel = 0,
						Text = "+ ACHETER COINS",
						TextColor3 = Color3.fromRGB(15, 17, 23),
						Font = Theme.Fonts.Title,
						TextSize = 9,
						LayoutOrder = 2,
						[Roact.Event.MouseButton1Click] = function()
							ShopController:SimulateAddCoins()
						end,
					}, {
						Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
					}),
					CloseBtn = props.onClose and Roact.createElement("ImageButton", {
						Size = UDim2.new(0, 32, 0, 32),
						AnchorPoint = Vector2.new(1, 0),
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.6,
						Image = "rbxassetid://140355181374747",
						BorderSizePixel = 0,
						LayoutOrder = 3,
						
						[Roact.Event.MouseButton1Click] = props.onClose,
					}, {
						Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
						Stroke = Roact.createElement("UIStroke", {
							Color = Color3.fromRGB(255, 255, 255),
							Transparency = 0.8,
							Thickness = 1,
						}),
					}) or nil,
				})
			}),

			LeftPanel = Roact.createElement("Frame", {
				Size = UDim2.new(0, 230, 1, -80),
				Position = UDim2.new(0, 16, 0, 80),
				BackgroundTransparency = 1,
			}, {
				UIList = Roact.createElement("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 8),
				}),

				ItemsTab = makeCategoryButton("Items", "Items", itemsCount, 1),
				ProfileTab = makeCategoryButton("Profile", "Profile", profileCount, 2),
				AbonnementsTab = makeCategoryButton("Abonnements", "Abonnements", subsCount, 3),
				CaissesTab = makeCategoryButton("Caisses", "Caisses", cratesCount, 4),
				HistoriqueTab = makeCategoryButton("Historique", "Historique", historyCount, 5),

				Spacer = Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 1, -220),
					BackgroundTransparency = 1,
					LayoutOrder = 6,
				}),

			}),

			RightContent = Roact.createElement("Frame", {
				Size = UDim2.new(1, -270, 1, -80),
				Position = UDim2.new(0, 254, 0, 80),
				BackgroundTransparency = 1,
			}, {
				SectionHeader = Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 24),
					BackgroundTransparency = 1,
				}, {
					Title = Roact.createElement("TextLabel", {
						Size = UDim2.new(0.6, 0, 1, 0),
						BackgroundTransparency = 1,
						Text = "| Boutique • " .. state.activeTab,
						TextColor3 = Theme.Colors.Text,
						Font = Theme.Fonts.Title,
						TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Left,
						TextYAlignment = Enum.TextYAlignment.Center,
					}),

					ItemsCountPill = state.activeTab ~= "Historique" and Roact.createElement("Frame", {
						Size = UDim2.new(0, 0, 1, 0),
						Position = UDim2.new(0.65, 0, 0, 0),
						BackgroundTransparency = 1,
						AutomaticSize = Enum.AutomaticSize.X,
					}, {
						Pill = Roact.createElement("Frame", {
							Size = UDim2.new(1, 20, 1, 0),
							BackgroundColor3 = Theme.Colors.Surface,
							BackgroundTransparency = 0.4,
							BorderSizePixel = 0,
						}, {
							Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
							Stroke = Roact.createElement("UIStroke", { Color = Color3.fromRGB(255, 255, 255), Transparency = 0.9, Thickness = 1 }),
						})
					}) or nil,
				}),

				FilterBar = state.activeTab ~= "Historique" and Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 0, 36),
					Position = UDim2.new(0, 0, 0, 32),
					BackgroundTransparency = 1,
				}, {
					SortGroup = Roact.createElement("Frame", {
						Size = UDim2.new(0.6, 0, 1, 0),
						BackgroundTransparency = 1,
					}, {
						UIList = Roact.createElement("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 8),
							VerticalAlignment = Enum.VerticalAlignment.Center,
						}),
						Label = Roact.createElement("TextLabel", {
							Size = UDim2.new(0, 60, 1, 0),
							BackgroundTransparency = 1,
							Text = "Trier par :",
							TextColor3 = Theme.Colors.TextSecondary,
							Font = Theme.Fonts.Body,
							TextSize = 10,
							TextXAlignment = Enum.TextXAlignment.Left,
							TextYAlignment = Enum.TextYAlignment.Center,
							LayoutOrder = 1,
						}),
						SortAsc = Roact.createElement("TextButton", {
							Size = UDim2.new(0, 95, 1, 0),
							BackgroundColor3 = state.sortBy == "price_asc" and Theme.Colors.Accent or Theme.Colors.Surface,
							BackgroundTransparency = state.sortBy == "price_asc" and 0 or 0.6,
							Text = "🪙 Prix Croissant",
							TextColor3 = state.sortBy == "price_asc" and Color3.fromRGB(15, 17, 23) or Theme.Colors.Text,
							Font = Theme.Fonts.Title,
							TextSize = 8,
							BorderSizePixel = 0,
							LayoutOrder = 2,
							[Roact.Event.MouseButton1Click] = function()
								self:setState({ sortBy = state.sortBy == "price_asc" and "default" or "price_asc" })
							end,
						}, { Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
						SortDesc = Roact.createElement("TextButton", {
							Size = UDim2.new(0, 105, 1, 0),
							BackgroundColor3 = state.sortBy == "price_desc" and Theme.Colors.Accent or Theme.Colors.Surface,
							BackgroundTransparency = state.sortBy == "price_desc" and 0 or 0.6,
							Text = "🪙 Prix Décroissant",
							TextColor3 = state.sortBy == "price_desc" and Color3.fromRGB(15, 17, 23) or Theme.Colors.Text,
							Font = Theme.Fonts.Title,
							TextSize = 8,
							BorderSizePixel = 0,
							LayoutOrder = 3,
							[Roact.Event.MouseButton1Click] = function()
								self:setState({ sortBy = state.sortBy == "price_desc" and "default" or "price_desc" })
							end,
						}, { Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }) }),
						SortDiscount = Roact.createElement("TextButton", {
							Size = UDim2.new(0, 85, 1, 0),
							BackgroundColor3 = state.sortBy == "discount" and Theme.Colors.Accent or Theme.Colors.Surface,
							BackgroundTransparency = state.sortBy == "discount" and 0 or 0.6,
							Text = "🔥 Réductions",
							TextColor3 = state.sortBy == "discount" and Color3.fromRGB(15, 17, 23) or Theme.Colors.Text,
							Font = Theme.Fonts.Title,
							TextSize = 8,
							BorderSizePixel = 0,
							LayoutOrder = 4,
							[Roact.Event.MouseButton1Click] = function()
								self:setState({ sortBy = state.sortBy == "discount" and "default" or "discount" })
							end,
						}, { Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 4) }) })
					}),
					SearchGroup = Roact.createElement("Frame", {
						Size = UDim2.new(0.4, -10, 1, 0),
						Position = UDim2.new(1, -4, 0, 0),
						AnchorPoint = Vector2.new(1, 0),
						BackgroundTransparency = 1,
					}, {
						SearchBox = Roact.createElement("TextBox", {
							Size = UDim2.new(1, 0, 0, 32),
							Position = UDim2.new(0, 0, 0.5, 0),
							AnchorPoint = Vector2.new(0, 0.5),
							BackgroundColor3 = Color3.fromRGB(15, 17, 23),
							BackgroundTransparency = 0.5,
							PlaceholderText = "🔍 Rechercher...",
							Text = state.searchQuery,
							TextColor3 = Theme.Colors.Text,
							Font = Theme.Fonts.Body,
							TextSize = 12,
							ClearTextOnFocus = false,
							[Roact.Change.Text] = function(rbx)
								self:setState({ searchQuery = rbx.Text })
							end,
						}, {
							Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 6) }),
							Stroke = Roact.createElement("UIStroke", { Color = Theme.Colors.Surface, Thickness = 1 }),
							Padding = Roact.createElement("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }),
						})
					})
				}) or nil,

				ItemsScroll = state.activeTab ~= "Historique" and Roact.createElement("ScrollingFrame", {
					Size = UDim2.new(1, 0, 1, -76),
					Position = UDim2.new(0, 0, 0, 76),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 2,
					ScrollBarImageColor3 = Theme.Colors.Primary,
					CanvasSize = UDim2.new(0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
				}, scrollContent) or nil,

				HistoryScroll = state.activeTab == "Historique" and Roact.createElement("ScrollingFrame", {
					Size = UDim2.new(1, 0, 1, -32),
					Position = UDim2.new(0, 0, 0, 32),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ScrollBarThickness = 2,
					ScrollBarImageColor3 = Theme.Colors.Primary,
					CanvasSize = UDim2.new(0, 0, 0, 0),
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
				}, historyElements) or nil,
			})
		})
	})
end

return ShopModal
