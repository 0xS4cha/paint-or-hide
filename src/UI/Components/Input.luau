local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)

local Input = Roact.Component:extend("Input")

function Input:init()
	self:setState({
		value = self.props.defaultValue or "",
		isFocused = false,
		isValid = true,
		errorMessage = "",
	})
	
	self.inputRef = Roact.createRef()
end

function Input:render()
	local props = self.props
	local state = self.state
	local Theme = require(ReplicatedStorage.UI.Styles.Theme)
	
	
	local placeholder = props.placeholder or "Entrez du texte..."
	local size = props.size or UDim2.new(0, 300, 0, 50)
	local position = props.position or UDim2.new(0.5, 0, 0.5, 0)
	local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
	local backgroundColor = props.backgroundColor or Theme.Colors.Surface
	local textColor = props.textColor or Theme.Colors.Text
	local onChange = props.onChange or function() end
	local onValidate = props.onValidate or function() return true end
	local disabled = props.disabled or false
	
	return Roact.createElement("Frame", {
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundTransparency = 1,
	}, {
		Label = props.label and Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 20),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Text = props.label,
			TextColor3 = Theme.Colors.TextSecondary,
			Font = Theme.Fonts.Title,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		}) or nil,
		
		
		InputFrame = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 36),
			Position = UDim2.new(0, 0, 0, props.label and 24 or 0),
			BackgroundColor3 = backgroundColor,
			BackgroundTransparency = state.isFocused and 0.1 or 0.3,
			BorderSizePixel = 0,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, Theme.CornerRadius.Small or 6),
			}),
			
			Stroke = Roact.createElement("UIStroke", {
				Color = state.isValid and (state.isFocused and Theme.Colors.Primary or Color3.fromRGB(80, 85, 95)) or Theme.Colors.Danger,
				Transparency = state.isFocused and 0.4 or 0.75,
				Thickness = state.isFocused and 1.5 or 1,
			}),
			
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),
			
			TextBox = Roact.createElement("TextBox", {
				[Roact.Ref] = self.inputRef,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = state.value,
				PlaceholderText = placeholder,
				TextColor3 = textColor,
				PlaceholderColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Body,
				TextSize = 13,
				ClearTextOnFocus = false,
				TextXAlignment = Enum.TextXAlignment.Left,
				Active = not disabled,
				
				[Roact.Event.Focused] = function()
					if not disabled then
						self:setState({ isFocused = true })
					end
				end,
				
				[Roact.Event.FocusLost] = function(enterPressed)
					self:setState({ isFocused = false })
					local textBox = self.inputRef:getValue()
					if textBox then
						local newValue = textBox.Text
						
						
						local isValid, errorMsg = onValidate(newValue)
						self:setState({
							value = newValue,
							isValid = isValid,
							errorMessage = errorMsg or "",
						})
						
						onChange(newValue, isValid)
					end
				end,
				
				[Roact.Event.Changed] = function(rbx, property)
					if property == "Text" then
						local textBox = self.inputRef:getValue()
						if textBox and props.onChangeWhileTyping then
							task.defer(props.onChangeWhileTyping, textBox.Text)
						end
					end
				end,
			}),
		}),
		
		
		ErrorMessage = not state.isValid and state.errorMessage ~= "" and Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18),
			Position = UDim2.new(0, 0, 1, 5),
			BackgroundTransparency = 1,
			Text = state.errorMessage,
			TextColor3 = Theme.Colors.Danger,
			Font = Theme.Fonts.Body,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
		}) or nil,
	})
end

return Input
