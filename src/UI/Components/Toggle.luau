



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local TweenService = game:GetService("TweenService")

local Toggle = Roact.Component:extend("Toggle")

function Toggle:init()
	self:setState({
		isOn = self.props.defaultValue or false,
		isHovered = false,
	})
	
	self.toggleRef = Roact.createRef()
	self.sliderRef = Roact.createRef()
end

function Toggle:render()
	local props = self.props
	local state = self.state
	
	
	local size = props.size or UDim2.new(0, 50, 0, 30)
	local position = props.position or UDim2.new(0.5, 0, 0.5, 0)
	local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
	local onColor = props.onColor or Color3.fromRGB(46, 204, 113)
	local offColor = props.offColor or Color3.fromRGB(100, 100, 100)
	local onChange = props.onChange or function() end
	local disabled = props.disabled or false
	local label = props.label
	
	
	local currentColor = state.isOn and onColor or offColor
	
	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, label and 50 or size.Y.Offset),
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundTransparency = 1,
	}, {
		
		Label = label and Roact.createElement("TextLabel", {
			Size = UDim2.new(1, -60, 0, 30),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = label,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.Gotham,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Left,
		}) or nil,
		
		
		ToggleContainer = Roact.createElement("Frame", {
			[Roact.Ref] = self.toggleRef,
			Size = size,
			Position = UDim2.new(1, 0, label and 0.5 or 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = currentColor,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			
			[Roact.Event.MouseEnter] = function()
				if not disabled then
					self:setState({ isHovered = true })
				end
			end,
			
			[Roact.Event.MouseLeave] = function()
				self:setState({ isHovered = false })
			end,
			
			[Roact.Event.MouseButton1Click] = function()
				if not disabled then
					local newValue = not state.isOn
					self:setState({ isOn = newValue })
					onChange(newValue)
				end
			end,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 15),
			}),
			
			
			Slider = Roact.createElement("Frame", {
				[Roact.Ref] = self.sliderRef,
				Size = UDim2.new(0, 24, 0, 24),
				Position = state.isOn and UDim2.new(1, -27, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderSizePixel = 0,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
			}),
		}),
	})
end

function Toggle:didUpdate(prevProps, prevState)
	
	if self.state.isOn ~= prevState.isOn then
		local slider = self.sliderRef:getValue()
		local toggle = self.toggleRef:getValue()
		if slider and toggle then
			local targetPosition = self.state.isOn and UDim2.new(1, -27, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
			local tween = TweenService:Create(
				slider,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Position = targetPosition}
			)
			tween:Play()
			
			
			local targetColor = self.state.isOn and (self.props.onColor or Color3.fromRGB(46, 204, 113)) or (self.props.offColor or Color3.fromRGB(100, 100, 100))
			local colorTween = TweenService:Create(
				toggle,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{BackgroundColor3 = targetColor}
			)
			colorTween:Play()
		end
	end
	
	
	if self.props.defaultValue ~= prevProps.defaultValue and self.props.defaultValue ~= self.state.isOn then
		self:setState({ isOn = self.props.defaultValue })
	end
end

return Toggle
