local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local TweenService = game:GetService("TweenService")

local Dropdown = Roact.Component:extend("Dropdown")

function Dropdown:init()
	self:setState({
		isOpen = false,
		selectedIndex = self.props.defaultIndex or 1,
	})
	
	self.dropdownRef = Roact.createRef()
	self.optionsRef = Roact.createRef()
end

function Dropdown:render()
	local props = self.props
	local state = self.state
	
	
	local options = props.options or {"Option 1", "Option 2", "Option 3"}
	local size = props.size or UDim2.new(0, 200, 0, 40)
	local position = props.position or UDim2.new(0.5, 0, 0.5, 0)
	local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
	local backgroundColor = props.backgroundColor or Color3.fromRGB(45, 45, 45)
	local onChange = props.onChange or function() end
	local disabled = props.disabled or false
	local label = props.label
	
	local selectedText = options[state.selectedIndex] or options[1] or "Sélectionner..."
	
	
	local optionElements = {}
	if state.isOpen then
		for index, option in ipairs(options) do
			local isSelected = index == state.selectedIndex
			optionElements["Option" .. index] = Roact.createElement("TextButton", {
				Size = UDim2.new(1, 0, 0, 35),
				Position = UDim2.new(0, 0, 0, (index - 1) * 35),
				BackgroundColor3 = isSelected and Color3.fromRGB(52, 152, 219) or backgroundColor,
				BackgroundTransparency = isSelected and 0.3 or 0.5,
				Text = option,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.Gotham,
				TextSize = 14,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				
				[Roact.Event.MouseButton1Click] = function()
					self:setState({
						selectedIndex = index,
						isOpen = false,
					})
					onChange(index, option)
				end,
				
				[Roact.Event.MouseEnter] = function()
					if not isSelected then
						local button = self.optionsRef:getValue()
						if button then
							local optionButton = button:FindFirstChild("Option" .. index)
							if optionButton then
								local tween = TweenService:Create(
									optionButton,
									TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
									{BackgroundTransparency = 0.4}
								)
								tween:Play()
							end
						end
					end
				end,
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
					PaddingRight = UDim.new(0, 10),
				}),
			})
		end
	end
	
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
			Text = label,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.Gotham,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Left,
		}) or nil,
		
		
		DropdownButton = Roact.createElement("TextButton", {
			[Roact.Ref] = self.dropdownRef,
			Size = size,
			Position = UDim2.new(0, 0, 0, label and 25 or 0),
			BackgroundColor3 = backgroundColor,
			BackgroundTransparency = 0.3,
			Text = selectedText,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.Gotham,
			TextSize = 16,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			Active = not disabled,
			
			[Roact.Event.MouseButton1Click] = function()
				if not disabled then
					self:setState({ isOpen = not state.isOpen })
				end
			end,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			
			Stroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(100, 100, 100),
				Transparency = 0.5,
				Thickness = 1,
			}),
			
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 30),
			}),
			
			
			Arrow = Roact.createElement("TextLabel", {
				Size = UDim2.new(0, 20, 1, 0),
				Position = UDim2.new(1, -20, 0, 0),
				BackgroundTransparency = 1,
				Text = state.isOpen and "▲" or "▼",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.GothamBold,
				TextSize = 12,
			}),
		}),
		
		
		Options = state.isOpen and Roact.createElement("Frame", {
			[Roact.Ref] = self.optionsRef,
			Size = UDim2.new(1, 0, 0, #options * 35),
			Position = UDim2.new(0, 0, 1, 5),
			BackgroundColor3 = backgroundColor,
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			ZIndex = 10,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 8),
			}),
			
			Stroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(100, 100, 100),
				Transparency = 0.3,
				Thickness = 1,
			}),
			
			ListLayout = Roact.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 0),
			}),
		}, optionElements) or nil,
	})
end

function Dropdown:didMount()
	
	local connection
	connection = game:GetService("UserInputService").InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			local dropdown = self.dropdownRef:getValue()
			if dropdown then
				local mouse = game:GetService("Players").LocalPlayer:GetMouse()
				if not dropdown:IsDescendantOf(mouse.Target) and self.state.isOpen then
					self:setState({ isOpen = false })
				end
			end
		end
	end)
	
	self.clickConnection = connection
end

function Dropdown:willUnmount()
	if self.clickConnection then
		self.clickConnection:Disconnect()
	end
end

return Dropdown
