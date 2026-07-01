




local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local TweenService = game:GetService("TweenService")

local LoadingBar = Roact.Component:extend("LoadingBar")

function LoadingBar:init()
	
	self.progressBinding, self.updateProgressBinding = Roact.createBinding(0)
	
	
	self.barRef = Roact.createRef()
	
	self.currentTween = nil
end

function LoadingBar:setProgress(progress)
	
	progress = math.clamp(progress, 0, 1)
	
	
	if self.currentTween then
		self.currentTween:Cancel()
	end
	
	
	local bar = self.barRef:getValue()
	if bar then
		local currentWidth = self.progressBinding:getValue()
		self.currentTween = TweenService:Create(
			bar,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Size = UDim2.new(progress, 0, 1, 0)}
		)
		self.currentTween:Play()
	end
	
	self.updateProgressBinding(progress)
end

function LoadingBar:render()
	local props = self.props
	
	
	local size = props.size or UDim2.new(0, 400, 0, 30)
	local position = props.position or UDim2.new(0.5, 0, 0.5, 0)
	local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
	local backgroundColor = props.backgroundColor or Color3.fromRGB(30, 30, 30)
	local fillColor = props.fillColor or Color3.fromRGB(52, 152, 219)
	local showPercentage = props.showPercentage ~= false
	local progress = props.progress or 0
	
	
	local animatedWidth = self.progressBinding:map(function(value)
		return value
	end)
	
	return Roact.createElement("Frame", {
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundColor3 = backgroundColor,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
	}, {
		
		ProgressBar = Roact.createElement("Frame", {
			[Roact.Ref] = self.barRef,
			Size = animatedWidth:map(function(width)
				return UDim2.new(width, 0, 1, 0)
			end),
			Position = UDim2.new(0, 0, 0, 0),
			AnchorPoint = Vector2.new(0, 0),
			BackgroundColor3 = fillColor,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
		}, {
			
			Shine = Roact.createElement("Frame", {
				Size = UDim2.new(0, 50, 1, 0),
				Position = UDim2.new(1, -50, 0, 0),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.7,
				BorderSizePixel = 0,
			}, {
				UIGradient = Roact.createElement("UIGradient", {
					Transparency = NumberSequence.new({
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(0.5, 0.5),
						NumberSequenceKeypoint.new(1, 1),
					}),
				}),
			}),
			
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
		}),
		
		
		PercentageText = showPercentage and Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = animatedWidth:map(function(width)
				return math.floor(width * 100) .. "%"
			end),
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			ZIndex = 2,
		}) or nil,
		
		
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 8),
		}),
		
		
		Stroke = Roact.createElement("UIStroke", {
			Color = fillColor,
			Transparency = 0.5,
			Thickness = 2,
		}),
	})
end

function LoadingBar:didUpdate(prevProps, prevState)
	
	if self.props.progress ~= prevProps.progress then
		self:setProgress(self.props.progress)
	end
end

function LoadingBar:didMount()
	
	if self.props.progress then
		self:setProgress(self.props.progress)
	end
end

function LoadingBar:willUnmount()
	
	if self.currentTween then
		self.currentTween:Cancel()
	end
end

return LoadingBar
