local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Roact = require(ReplicatedStorage.Packages.Roact)
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

local InteractionButton = Roact.Component:extend("InteractionButton")

function InteractionButton:init()
	self:setState({
		isVisible = false,
		distance = math.huge,
	})
	
	self.billboardRef = Roact.createRef()
	self.frameRef = Roact.createRef()
	
	
	self.scaleBinding, self.updateScaleBinding = Roact.createBinding(0)
	self.opacityBinding, self.updateOpacityBinding = Roact.createBinding(0)
	
	
	self.connections = {}
	
	
	self.props = self.props or {}
	self.targetPart = self.props.targetPart
	self.interactionText = self.props.interactionText or "Appuyez sur [E]"
	self.icon = self.props.icon or "📋"
	self.maxDistance = self.props.maxDistance or 20
end

function InteractionButton:updateVisibility()
	if not self.targetPart or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		return
	end
	
	local humanoidRootPart = LocalPlayer.Character.HumanoidRootPart
	local distance = (humanoidRootPart.Position - self.targetPart.Position).Magnitude
	
	local shouldShow = distance <= self.maxDistance
	
	if shouldShow ~= self.state.isVisible then
		self:setState({
			isVisible = shouldShow,
			distance = distance,
		})
		
		
		if shouldShow then
			self:animateIn()
		else
			self:animateOut()
		end
	end
end

function InteractionButton:animateIn()
	local frame = self.frameRef:getValue()
	if frame then
		
		local scaleTween = TweenService:Create(
			frame,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Size = UDim2.new(0, 200, 0, 80)}
		)
		scaleTween:Play()
		
		
		for i = 0, 1, 0.1 do
			self.updateOpacityBinding(i)
			task.wait(0.02)
		end
	end
end

function InteractionButton:animateOut()
	local frame = self.frameRef:getValue()
	if frame then
		
		local scaleTween = TweenService:Create(
			frame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Size = UDim2.new(0, 0, 0, 0)}
		)
		scaleTween:Play()
		
		
		for i = 1, 0, -0.1 do
			self.updateOpacityBinding(i)
			task.wait(0.02)
		end
	end
end

function InteractionButton:render()
	local props = self.props
	local state = self.state
	
	if not state.isVisible then
		return nil
	end
	
	local opacity = self.opacityBinding:map(function(value)
		return 1 - value
	end)
	
	return Roact.createElement("BillboardGui", {
		[Roact.Ref] = self.billboardRef,
		Size = UDim2.new(0, 200, 0, 80),
		SizeOffset = Vector2.new(0, 2),
		Active = true,
		AlwaysOnTop = true,
		LightInfluence = 0,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		MainFrame = Roact.createElement("Frame", {
			[Roact.Ref] = self.frameRef,
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BackgroundTransparency = opacity:map(function(op)
				return 0.2 + op * 0.8
			end),
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),
			
			Stroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(52, 152, 219),
				Transparency = opacity:map(function(op)
					return 0.3 + op * 0.7
				end),
				Thickness = 2,
			}),
			
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 15),
				PaddingRight = UDim.new(0, 15),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 10),
			}),
			
			
			Icon = Roact.createElement("TextLabel", {
				Size = UDim2.new(0, 40, 0, 40),
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Text = props.icon or "📋",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 30,
				TextTransparency = opacity:map(function(op)
					return op
				end),
			}),
			
			
			TextContainer = Roact.createElement("Frame", {
				Size = UDim2.new(1, -50, 1, 0),
				Position = UDim2.new(0, 50, 0, 0),
				BackgroundTransparency = 1,
			}, {
				InteractionText = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0.6, 0),
					Position = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 1,
					Text = props.interactionText or "Appuyez sur [E]",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Font = Enum.Font.GothamBold,
					TextSize = 16,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTransparency = opacity:map(function(op)
						return op
					end),
				}),
				
				HintText = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, 0, 0.4, 0),
					Position = UDim2.new(0, 0, 0.6, 0),
					BackgroundTransparency = 1,
					Text = props.hintText or "",
					TextColor3 = Color3.fromRGB(200, 200, 200),
					Font = Enum.Font.Gotham,
					TextSize = 12,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTransparency = opacity:map(function(op)
						return 0.3 + op * 0.7
					end),
				}),
			}),
			
			
			PulseEffect = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
			}, {
				Pulse = Roact.createElement("Frame", {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundColor3 = Color3.fromRGB(52, 152, 219),
					BackgroundTransparency = 0.8,
					BorderSizePixel = 0,
				}, {
					Corner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 12),
					}),
				}),
			}),
		}),
	})
end

function InteractionButton:didMount()
	
	local connection
	connection = game:GetService("RunService").Heartbeat:Connect(function()
		self:updateVisibility()
	end)
	
	self.connections.heartbeat = connection
	
	
	if self.state.isVisible then
		self:animateIn()
	end
end

function InteractionButton:willUnmount()
	for _, connection in pairs(self.connections) do
		if connection then
			connection:Disconnect()
		end
	end
	self.connections = {}
end

return InteractionButton
