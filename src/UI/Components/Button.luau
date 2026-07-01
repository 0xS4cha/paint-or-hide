




local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local TweenService = game:GetService("TweenService")

local Button = Roact.Component:extend("Button")

function Button:init()
	
	self:setState({
		isHovered = false,
		isPressed = false,
	})
	
	
	self.sizeBinding, self.updateSizeBinding = Roact.createBinding(1)
	self.transparencyBinding, self.updateTransparencyBinding = Roact.createBinding(0.5)
	
	
	self.frameRef = Roact.createRef()
end

function Button:render()
	local props = self.props
	local state = self.state
	local Theme = require(ReplicatedStorage.UI.Styles.Theme)
	
	
	local text = props.text or "Button"
	local size = props.size or UDim2.new(0, 200, 0, 50)
	local position = props.position or UDim2.new(0.5, 0, 0.5, 0)
	local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
	local backgroundColor = props.backgroundColor or Theme.Colors.Primary
	local textColor = props.textColor or Color3.fromRGB(255, 255, 255)
	local onClick = props.onClick or function() end
	local disabled = props.disabled or false
	local layoutOrder = props.layoutOrder
	
	
	local function darken(color: Color3)
		local h, s, v = color:ToHSV()
		return Color3.fromHSV(h, s, math.clamp(v * 0.75, 0, 1))
	end
	local secondaryColor = darken(backgroundColor)
	
	
	local animatedSize = self.sizeBinding:map(function(scale)
		return UDim2.new(size.X.Scale, size.X.Offset * scale, size.Y.Scale, size.Y.Offset * scale)
	end)
	
	
	local animatedTransparency = self.transparencyBinding:map(function(transparency)
		return transparency
	end)
	
	return Roact.createElement("TextButton", {
		[Roact.Ref] = self.frameRef,
		Size = animatedSize,
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundColor3 = backgroundColor,
		TextColor3 = textColor,
		Text = text,
		Font = Theme.Fonts.Button or Enum.Font.GothamBold,
		TextSize = props.textSize or Theme.TextSizes.Button or 18,
		BackgroundTransparency = animatedTransparency,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Active = not disabled,
		LayoutOrder = layoutOrder,
		
		
		[Roact.Event.MouseEnter] = function()
			if not disabled then
				self:setState({ isHovered = true })
			end
		end,
		
		[Roact.Event.MouseLeave] = function()
			self:setState({ isHovered = false, isPressed = false })
		end,
		
		[Roact.Event.MouseButton1Down] = function()
			if not disabled then
				self:setState({ isPressed = true })
			end
		end,
		
		[Roact.Event.MouseButton1Up] = function()
			if not disabled and self.state.isPressed then
				self:setState({ isPressed = false })
				onClick()
			end
		end,
	}, {
		
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, Theme.CornerRadius.Small or 6),
		}),
		
		
		Gradient = Roact.createElement("UIGradient", {
			Color = ColorSequence.new(backgroundColor, secondaryColor),
			Rotation = 90,
		}),
		
		
		Padding = Roact.createElement("UIPadding", {
			PaddingLeft = UDim.new(0, 16),
			PaddingRight = UDim.new(0, 16),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
		
		
		Stroke = Roact.createElement("UIStroke", {
			Color = state.isHovered and Color3.fromRGB(255, 255, 255) or textColor,
			Transparency = state.isHovered and 0.65 or 0.85,
			Thickness = 1,
		}),
	})
end

function Button:didUpdate(prevProps, prevState)
	local state = self.state
	local frame = self.frameRef:getValue()
	
	if not frame then
		return
	end
	
	
	if state.isHovered ~= prevState.isHovered then
		local targetTransparency = state.isHovered and 0.3 or 0.5
		self.updateTransparencyBinding(targetTransparency)
	end
	
	
	if state.isHovered ~= prevState.isHovered or state.isPressed ~= prevState.isPressed then
		local targetScale
		if state.isPressed then
			targetScale = 0.95
		elseif state.isHovered then
			targetScale = 1.05
		else
			targetScale = 1
		end
		
		local currentSize = self.props.size or UDim2.new(0, 200, 0, 50)
		local tween = TweenService:Create(
			frame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(
				currentSize.X.Scale,
				currentSize.X.Offset * targetScale,
				currentSize.Y.Scale,
				currentSize.Y.Offset * targetScale
			)}
		)
		tween:Play()
	end
end

return Button
