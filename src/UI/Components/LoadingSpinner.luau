



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local TweenService = game:GetService("TweenService")

local LoadingSpinner = Roact.Component:extend("LoadingSpinner")

function LoadingSpinner:init()
	self:setState({
		rotation = 0,
	})
	
	self.rotationTween = nil
	self.spinnerRef = Roact.createRef()
end

function LoadingSpinner:startRotation()
	local spinner = self.spinnerRef:getValue()
	if not spinner then
		return
	end
	
	
	self.rotationTween = TweenService:Create(
		spinner,
		TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
		{Rotation = 360}
	)
	self.rotationTween:Play()
end

function LoadingSpinner:render()
	local props = self.props
	
	
	local size = props.size or UDim2.new(0, 60, 0, 60)
	local position = props.position or UDim2.new(0.5, 0, 0.5, 0)
	local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
	local color = props.color or Color3.fromRGB(52, 152, 219)
	local thickness = props.thickness or 4
	
	return Roact.createElement("Frame", {
		[Roact.Ref] = self.spinnerRef,
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundTransparency = 1,
	}, {
		
		BackgroundCircle = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			
			UIStroke = Roact.createElement("UIStroke", {
				Color = color,
				Transparency = 0.8,
				Thickness = thickness,
			}),
		}),
		
		
		AnimatedCircle = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			UICorner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(1, 0),
			}),
			
			UIStroke = Roact.createElement("UIStroke", {
				Color = color,
				Transparency = 0,
				Thickness = thickness,
			}),
		}),
	})
end

function LoadingSpinner:didMount()
	self:startRotation()
end

function LoadingSpinner:willUnmount()
	if self.rotationTween then
		self.rotationTween:Cancel()
	end
end

return LoadingSpinner
