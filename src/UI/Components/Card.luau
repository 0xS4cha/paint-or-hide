local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)

local Card = Roact.Component:extend("Card")

function Card:init()
	self:setState({
		isHovered = false,
	})
end

function Card:render()
	local props = self.props
	local state = self.state
	local Theme = require(ReplicatedStorage.UI.Styles.Theme)
	
	
	local size = props.size or UDim2.new(0, 300, 0, 200)
	local position = props.position or UDim2.new(0.5, 0, 0.5, 0)
	local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
	local backgroundColor = props.backgroundColor or Theme.Colors.Surface
	local children = props[Roact.Children] or {}
	
	
	local transparency = state.isHovered and Theme.Transparency.CardHover or Theme.Transparency.Card
	
	return Roact.createElement("Frame", {
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundColor3 = backgroundColor,
		BackgroundTransparency = transparency,
		BorderSizePixel = 0,
		
		[Roact.Event.MouseEnter] = function()
			self:setState({ isHovered = true })
		end,
		
		[Roact.Event.MouseLeave] = function()
			self:setState({ isHovered = false })
		end,
	}, {
		
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, Theme.CornerRadius.Medium or 10),
		}),
		
		
		Padding = Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingTop = UDim.new(0, 16),
			PaddingBottom = UDim.new(0, 16),
		}),
		
		
		Stroke = Roact.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Transparency = state.isHovered and 0.82 or 0.9,
			Thickness = 1,
		}),
		
		
		Content = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, children),
	})
end

return Card
