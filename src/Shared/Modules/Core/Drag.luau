local UserInputService = game:GetService("UserInputService")
local Draggable = {}

local DragInstance = {}
DragInstance.__index = DragInstance

function DragInstance:resetPosition()
	if self.target then
		self.target.Position = self.initialPos
	end
end

function DragInstance:destroy()
	for _, conn in ipairs(self._connections) do
		pcall(function()
			conn:Disconnect()
		end)
	end
	self._connections = {}
end

function Draggable:register(target, header)
	local self = setmetatable({
		target = target,
		header = header,
		dragging = false,
		dragInput = nil,
		dragStart = nil,
		startPos = nil,
		initialPos = target.Position,
		_connections = {},
	}, DragInstance)

	local function update(input)
		local delta = input.Position - self.dragStart
		self.target.Position = UDim2.new(
			self.startPos.X.Scale,
			self.startPos.X.Offset + delta.X,
			self.startPos.Y.Scale,
			self.startPos.Y.Offset + delta.Y
		)
	end

	self._connections[#self._connections + 1] = header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			self.dragging = true
			self.dragStart = input.Position
			self.startPos = self.target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					self.dragging = false
				end
			end)
		end
	end)

	self._connections[#self._connections + 1] = header.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			self.dragInput = input
		end
	end)

	self._connections[#self._connections + 1] = UserInputService.InputChanged:Connect(function(input)
		if input == self.dragInput and self.dragging then
			if self.header.Visible then
				update(input)
			end
		end
	end)

	return self
end

return Draggable