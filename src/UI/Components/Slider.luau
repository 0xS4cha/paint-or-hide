



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Roact = require(ReplicatedStorage.Packages.Roact)
local TweenService = game:GetService("TweenService")

local Slider = Roact.Component:extend("Slider")

function Slider:init()
	self:setState({
		value = self.props.defaultValue or 0.5,
		isDragging = false,
	})
	
	self.trackRef = Roact.createRef()
	self.handleRef = Roact.createRef()
	self.connections = {}
end

function Slider:updateValue(inputPosition)
	local track = self.trackRef:getValue()
	if not track then
		return
	end
	
	local trackPosition = track.AbsolutePosition.X
	local trackSize = track.AbsoluteSize.X
	local mouseX = inputPosition.X
	
	local relativeX = math.clamp(mouseX - trackPosition, 0, trackSize)
	local newValue = relativeX / trackSize
	
	
	local min = self.props.min or 0
	local max = self.props.max or 1
	newValue = min + (newValue * (max - min))
	
	
	if self.props.step then
		newValue = math.floor((newValue - min) / self.props.step) * self.props.step + min
	end
	
	self:setState({ value = newValue })
	
	if self.props.onChange then
		self.props.onChange(newValue)
	end
end

function Slider:render()
	local props = self.props
	local state = self.state
	
	
	local size = props.size or UDim2.new(0, 300, 0, 40)
	local position = props.position or UDim2.new(0.5, 0, 0.5, 0)
	local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
	local min = props.min or 0
	local max = props.max or 1
	local trackColor = props.trackColor or Color3.fromRGB(100, 100, 100)
	local fillColor = props.fillColor or Color3.fromRGB(52, 152, 219)
	local handleColor = props.handleColor or Color3.fromRGB(255, 255, 255)
	local disabled = props.disabled or false
	local showValue = props.showValue ~= false
	local label = props.label
	
	
	local normalizedValue = (state.value - min) / (max - min)
	
	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, label and 60 or size.Y.Offset),
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundTransparency = 1,
	}, {
		
		Label = label and Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = label .. (showValue and (" (" .. math.floor(state.value) .. ")") or ""),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}) or nil,
		
		
		Track = Roact.createElement("Frame", {
			[Roact.Ref] = self.trackRef,
			Size = UDim2.new(1, 0, 0, 6),
			Position = UDim2.new(0, 0, 0, label and 30 or 17),
			BackgroundColor3 = trackColor,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 3),
			}),
			
			
			Fill = Roact.createElement("Frame", {
				Size = UDim2.new(normalizedValue, 0, 1, 0),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundColor3 = fillColor,
				BorderSizePixel = 0,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 3),
				}),
			}),
			
			
			Handle = Roact.createElement("Frame", {
				[Roact.Ref] = self.handleRef,
				Size = UDim2.new(0, 20, 0, 20),
				Position = UDim2.new(normalizedValue, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = handleColor,
				BorderSizePixel = 0,
				ZIndex = 2,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(1, 0),
				}),
				
				Stroke = Roact.createElement("UIStroke", {
					Color = fillColor,
					Thickness = 2,
				}),
			}),
		}),
	})
end

function Slider:didMount()
	local track = self.trackRef:getValue()
	if not track then
		return
	end
	
	
	local inputBegan = track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if not self.props.disabled then
				self:setState({ isDragging = true })
				self:updateValue(input.Position)
			end
		end
	end)
	
	local inputChanged = UserInputService.InputChanged:Connect(function(input)
		if self.state.isDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			self:updateValue(input.Position)
		end
	end)
	
	local inputEnded = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if self.state.isDragging then
				self:setState({ isDragging = false })
			end
		end
	end)
	
	self.connections = {
		inputBegan = inputBegan,
		inputChanged = inputChanged,
		inputEnded = inputEnded,
	}
end

function Slider:willUnmount()
	for _, connection in pairs(self.connections) do
		if connection then
			connection:Disconnect()
		end
	end
	self.connections = {}
end

return Slider
