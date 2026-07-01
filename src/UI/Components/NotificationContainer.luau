--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Theme = require(ReplicatedStorage.UI.Styles.Theme)
local NotificationController = require(Players.LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("Controllers"):WaitForChild("NotificationController"))

local NotificationContainer = Roact.Component:extend("NotificationContainer")


local NotificationCard = Roact.Component:extend("NotificationCard")

function NotificationCard:init()
	self.cardRef = Roact.createRef()
end

function NotificationCard:didMount()
	local card = self.cardRef:getValue()
	if card then
		
		card.Position = UDim2.new(1, 50, 0, 0)
		card.GroupColor = self.props.color
		
		
		TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0, 0, 0, 0)
		}):Play()
	end
end

function NotificationCard:render()
	local props = self.props

	return Roact.createElement("Frame", {
		Size = UDim2.new(0, 260, 0, 56),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		LayoutOrder = props.layoutOrder,
	}, {
		
		Card = Roact.createElement("CanvasGroup", {
			[Roact.Ref] = self.cardRef,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(20, 20, 20),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 6),
			}),
			Stroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Thickness = 1,
				Transparency = 0.85,
			}),

			
			BorderLine = Roact.createElement("Frame", {
				Size = UDim2.new(0, 4, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundColor3 = props.color,
				BorderSizePixel = 0,
			}),

			
			Content = Roact.createElement("Frame", {
				Size = UDim2.new(1, -16, 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				BackgroundTransparency = 1,
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingTop = UDim.new(0, 6),
					PaddingBottom = UDim.new(0, 6),
				}),
				
				Title = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0, 18),
					BackgroundTransparency = 1,
					Text = props.title,
					TextColor3 = Theme.Colors.Text,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),

				Message = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 1, -18),
					Position = UDim2.new(0, 0, 0, 18),
					BackgroundTransparency = 1,
					Text = props.text,
					TextColor3 = Theme.Colors.TextSecondary,
					Font = Enum.Font.Gotham,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextYAlignment = Enum.TextYAlignment.Top,
					TextWrapped = true,
				}),
			})
		})
	})
end


function NotificationContainer:init()
	self:setState({
		notifications = {},
	})
	
	self.connection = nil
end

function NotificationContainer:didMount()
	
	self.connection = NotificationController.NotificationAdded:Connect(function(notif)
		self:setState(function(state)
			local newNotifs = {}
			for _, n in ipairs(state.notifications) do
				table.insert(newNotifs, n)
			end
			table.insert(newNotifs, notif)
			return { notifications = newNotifs }
		end)

		
		task.delay(notif.Duration, function()
			if not self.connection then return end 
			self:setState(function(state)
				local newNotifs = {}
				for _, n in ipairs(state.notifications) do
					if n.Id ~= notif.Id then
						table.insert(newNotifs, n)
					end
				end
				return { notifications = newNotifs }
			end)
		end)
	end)
end

function NotificationContainer:willUnmount()
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
end

function NotificationContainer:render()
	local state = self.state

	local cards: { [string]: any } = {
		UIList = Roact.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		})
	}

	for index, notif in ipairs(state.notifications) do
		cards[notif.Id] = Roact.createElement(NotificationCard, {
			title = notif.Title,
			text = notif.Text,
			color = notif.Color,
			layoutOrder = index,
		})
	end

	return Roact.createElement("Frame", {
		Size = UDim2.new(0, 260, 0, 400),
		Position = UDim2.new(1, -20, 1, -20),
		AnchorPoint = Vector2.new(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Active = false,
	}, cards)
end

return NotificationContainer
