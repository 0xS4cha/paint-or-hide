local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Roact = require(ReplicatedStorage.Packages.Roact)

local DragFrame = Roact.Component:extend("DragFrame")

function DragFrame:init()
	self:setState({
		dragging = false,
	})
	
	
	self.frameRef = Roact.createRef()
	self.headerRef = Roact.createRef()
	
	
	self.dragStart = nil
	self.startPos = nil
	self.connections = {}
end

function DragFrame:startDrag(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	
	local frame = self.frameRef:getValue()
	if not frame then
		return
	end
	
	self:setState({ dragging = true })
	self.dragStart = input.Position
	
	self.startPos = frame.Position
end

function DragFrame:updateDrag(input)
	if not self.state.dragging then
		return
	end
	
	local frame = self.frameRef:getValue()
	if not frame or not self.dragStart or not self.startPos then
		return
	end
	
	local delta = input.Position - self.dragStart
	local newPosition = UDim2.new(
		self.startPos.X.Scale,
		self.startPos.X.Offset + delta.X,
		self.startPos.Y.Scale,
		self.startPos.Y.Offset + delta.Y
	)
	
	frame.Position = newPosition
	
	
	if self.props.onPositionChanged then
		self.props.onPositionChanged(newPosition)
	end
end

function DragFrame:stopDrag()
	self:setState({ dragging = false })
	self.dragStart = nil
	self.startPos = nil
end

function DragFrame:didMount()
	local frame = self.frameRef:getValue()
	if not frame then
		return
	end

	local header = self.headerRef:getValue()
	if not header then
		header = frame:FindFirstChild("HubHeader", true) or frame:FindFirstChild("Header", true)
	end

	local dragHandle = header or frame

	local inputBeganConnection = dragHandle.InputBegan:Connect(function(input)
		self:startDrag(input)
		
		local changedConnection
		changedConnection = input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				self:stopDrag()
				if changedConnection then
					changedConnection:Disconnect()
				end
			end
		end)
	end)
	
	local inputChangedConnection = UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			self:updateDrag(input)
		end
	end)
	
	self.connections = {
		inputBegan = inputBeganConnection,
		inputChanged = inputChangedConnection,
	}
end

function DragFrame:didUpdate(prevProps, prevState)
	
	if not self.state.dragging and self.props.position ~= prevProps.position then
		local frame = self.frameRef:getValue()
		if frame then
			frame.Position = self.props.position
		end
	end
end

function DragFrame:willUnmount()
	
	for _, connection in pairs(self.connections) do
		if connection then
			connection:Disconnect()
		end
	end
	self.connections = {}
end

function DragFrame:render()
	local props = self.props
	local Theme = require(ReplicatedStorage.UI.Styles.Theme)
	
	
	local size = props.size or UDim2.new(0, 400, 0, 300)
	local position = props.position or UDim2.new(0.5, 0, 0.5, 0)
	local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
	local backgroundColor = props.backgroundColor or Theme.Colors.Background
	local backgroundTransparency = props.backgroundTransparency or Theme.Transparency.Background
	local children = props[Roact.Children] or {}
	
	
	local headerHeight = props.headerHeight or 44
	local headerColor = props.headerColor or Theme.Colors.Surface
	local headerText = props.headerText or "Déplacer"
	local showHeader = props.showHeader ~= false 
	local onClose = props.onClose
	
	return Roact.createElement("Frame", {
		[Roact.Ref] = self.frameRef,
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundColor3 = backgroundColor,
		BackgroundTransparency = backgroundTransparency,
		BorderSizePixel = 0,
		Active = true,
	}, {
		
		Header = showHeader and Roact.createElement("Frame", {
			[Roact.Ref] = self.headerRef,
			Size = UDim2.new(1, 0, 0, headerHeight),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = headerColor,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			ZIndex = 10,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, Theme.CornerRadius.Large or 14),
			}),
			
			
			CornerCache = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 10),
				Position = UDim2.new(0, 0, 1, -10),
				BackgroundColor3 = headerColor,
				BackgroundTransparency = 0.5,
				BorderSizePixel = 0,
			}),

			
			Separator = Roact.createElement("Frame", {
				Size = UDim2.new(1, -20, 0, 1),
				Position = UDim2.new(0, 10, 1, -1),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 0.85,
				BorderSizePixel = 0,
			}),
			
			
			Title = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, onClose and -70 or -40, 1, 0),
				Position = UDim2.new(0, 15, 0, 0),
				BackgroundTransparency = 1,
				Text = headerText,
				TextColor3 = Theme.Colors.Text,
				Font = Theme.Fonts.Title or Enum.Font.GothamBold,
				TextSize = 16,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),
			
			
			CloseBtn = onClose and Roact.createElement("ImageButton", {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(1, -10, 0.5, -12),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.6,
				Image = "rbxassetid://140355181374747",
				BorderSizePixel = 0,
				ZIndex = 12,
				
				[Roact.Event.MouseButton1Click] = onClose,
			}, {
				Corner = Roact.createElement("UICorner", { CornerRadius = UDim.new(0, 12) }),
				Stroke = Roact.createElement("UIStroke", {
					Color = Color3.fromRGB(255, 255, 255),
					Transparency = 0.8,
					Thickness = 1,
				}),
			}) or nil,
			
			
			DragIcon = not onClose and Roact.createElement("TextLabel", {
				Size = UDim2.new(0, 30, 1, 0),
				Position = UDim2.new(1, -30, 0, 0),
				BackgroundTransparency = 1,
				Text = "⋮⋮",
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Enum.Font.GothamBold,
				TextSize = 16,
				TextYAlignment = Enum.TextYAlignment.Center,
			}) or nil,
		}) or nil,
		
		
		Content = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, showHeader and -headerHeight or 0),
			Position = UDim2.new(0, 0, 0, showHeader and headerHeight or 0),
			BackgroundTransparency = 1,
		}, children),
		
		
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, Theme.CornerRadius.Large or 14),
		}),
		
		
		Stroke = Roact.createElement("UIStroke", {
			Color = Color3.fromRGB(255, 255, 255),
			Transparency = 0.88,
			Thickness = 1,
		}),
	})
end

return DragFrame
