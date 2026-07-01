local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)

local AnimatedDots = Roact.Component:extend("AnimatedDots")

function AnimatedDots:init()
	self:setState({
		dotCount = 0,
	})
	
	
	self.animationThread = nil
end

function AnimatedDots:startAnimation()
	self.animationThread = task.spawn(function()
		while true do
			for i = 0, 3 do
				if not self.animationThread then
					break
				end
				self:setState({ dotCount = i })
				task.wait(0.5)
			end
		end
	end)
end

function AnimatedDots:render()
	local props = self.props
	local state = self.state
	
	local size = props.size or UDim2.new(0, 100, 0, 40)
	local position = props.position or UDim2.new(0.5, 0, 0.5, 0)
	local anchorPoint = props.anchorPoint or Vector2.new(0.5, 0.5)
	local color = props.color or Color3.fromRGB(255, 255, 255)
	local fontSize = props.fontSize or 24
	
	
	local dots = string.rep(".", state.dotCount)
	
	return Roact.createElement("TextLabel", {
		Size = size,
		Position = position,
		AnchorPoint = anchorPoint,
		BackgroundTransparency = 1,
		Text = dots,
		TextColor3 = color,
		Font = Enum.Font.GothamBold,
		TextSize = fontSize,
		TextTransparency = props.textTransparency or 0,
	})
end

function AnimatedDots:didMount()
	self:startAnimation()
end

function AnimatedDots:willUnmount()
	if self.animationThread then
		self.animationThread = nil
	end
end

return AnimatedDots
