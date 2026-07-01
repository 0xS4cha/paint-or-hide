



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local TweenService = game:GetService("TweenService")

local Navigation = Roact.Component:extend("Navigation")

function Navigation:init()
	self:setState({
		activeTab = self.props.defaultTab or 1,
	})
	
	self.tabRefs = {}
end

function Navigation:render()
	local props = self.props
	local state = self.state
	
	
	local tabs = props.tabs or {"Accueil", "Profil", "Paramètres"}
	local onTabChanged = props.onTabChanged or function() end
	local size = props.size or UDim2.new(1, 0, 0, 60)
	local position = props.position or UDim2.new(0, 0, 0, 0)
	local backgroundColor = props.backgroundColor or Color3.fromRGB(30, 30, 30)
	
	
	local tabElements = {}
	for index, tabName in ipairs(tabs) do
		local isActive = state.activeTab == index
		
		tabElements["Tab" .. index] = Roact.createElement("TextButton", {
			[Roact.Ref] = function(ref)
				self.tabRefs[index] = ref
			end,
			Size = UDim2.new(1 / #tabs, 0, 1, 0),
			Position = UDim2.new((index - 1) / #tabs, 0, 0, 0),
			AnchorPoint = Vector2.new(0, 0),
			BackgroundColor3 = isActive and Color3.fromRGB(52, 152, 219) or backgroundColor,
			BackgroundTransparency = isActive and 0.3 or 0.5,
			Text = tabName,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBold,
			TextSize = 16,
			BorderSizePixel = 0,
			AutoButtonColor = false,
			
			[Roact.Event.MouseButton1Click] = function()
				if not isActive then
					self:setState({ activeTab = index })
					onTabChanged(index, tabName)
				end
			end,
			
			[Roact.Event.MouseEnter] = function()
				if not isActive then
					local ref = self.tabRefs[index]
					if ref then
						local tween = TweenService:Create(
							ref,
							TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{BackgroundTransparency = 0.4}
						)
						tween:Play()
					end
				end
			end,
			
			[Roact.Event.MouseLeave] = function()
				if not isActive then
					local ref = self.tabRefs[index]
					if ref then
						local tween = TweenService:Create(
							ref,
							TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{BackgroundTransparency = 0.5}
						)
						tween:Play()
					end
				end
			end,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 0),
			}),
		})
	end
	
	return Roact.createElement("Frame", {
		Size = size,
		Position = position,
		BackgroundColor3 = backgroundColor,
		BackgroundTransparency = 0.3,
		BorderSizePixel = 0,
	}, {
		
		Corner = Roact.createElement("UICorner", {
			CornerRadius = UDim.new(0, 0),
		}),
		
		
		TabsContainer = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, tabElements),
		
		
		BottomLine = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 0, 2),
			Position = UDim2.new(0, 0, 1, 0),
			AnchorPoint = Vector2.new(0, 1),
			BackgroundColor3 = Color3.fromRGB(52, 152, 219),
			BorderSizePixel = 0,
		}),
	})
end

function Navigation:didUpdate(prevProps, prevState)
	
	if self.state.activeTab ~= prevState.activeTab then
		
		local prevRef = self.tabRefs[prevState.activeTab]
		if prevRef then
			local tween = TweenService:Create(
				prevRef,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					BackgroundColor3 = self.props.backgroundColor or Color3.fromRGB(30, 30, 30),
					BackgroundTransparency = 0.5,
				}
			)
			tween:Play()
		end
		
		
		local newRef = self.tabRefs[self.state.activeTab]
		if newRef then
			local tween = TweenService:Create(
				newRef,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{
					BackgroundColor3 = Color3.fromRGB(52, 152, 219),
					BackgroundTransparency = 0.3,
				}
			)
			tween:Play()
		end
	end
end

return Navigation
