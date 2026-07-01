



local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local TweenService = game:GetService("TweenService")

local Modal = Roact.Component:extend("Modal")

function Modal:init()
	self:setState({
		isVisible = self.props.isOpen or false,
	})
	
	self.modalRef = Roact.createRef()
end

function Modal:render()
	local props = self.props
	local state = self.state
	
	if not state.isVisible then
		return nil
	end
	
	
	local size = props.size or UDim2.new(0, 500, 0, 400)
	local title = props.title or "Modal"
	local showCloseButton = props.showCloseButton ~= false
	local onClose = props.onClose or function() end
	local children = props[Roact.Children] or {}
	
	return Roact.createElement("ScreenGui", {
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
	}, {
		
		Overlay = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			ZIndex = 1,
			
			[Roact.Event.MouseButton1Click] = function()
				if props.closeOnOverlayClick then
					onClose()
				end
			end,
		}),
		
		
		Modal = Roact.createElement("Frame", {
			[Roact.Ref] = self.modalRef,
			Size = size,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			ZIndex = 2,
		}, {
			Corner = Roact.createElement("UICorner", {
				CornerRadius = UDim.new(0, 12),
			}),
			
			Stroke = Roact.createElement("UIStroke", {
				Color = Color3.fromRGB(255, 255, 255),
				Transparency = 0.9,
				Thickness = 1,
			}),
			
			
			Header = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 50),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundColor3 = Color3.fromRGB(52, 152, 219),
				BackgroundTransparency = 0.3,
				BorderSizePixel = 0,
			}, {
				Corner = Roact.createElement("UICorner", {
					CornerRadius = UDim.new(0, 12),
				}),
				
				Title = Roact.createElement("TextLabel", {
					Size = UDim2.new(1, showCloseButton and -50 or 0, 1, 0),
					Position = UDim2.new(0, 10, 0, 0),
					BackgroundTransparency = 1,
					Text = title,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					Font = Enum.Font.GothamBold,
					TextSize = 20,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				
				CloseButton = showCloseButton and Roact.createElement("ImageButton", {
					Size = UDim2.new(0, 24, 0, 24),
					Position = UDim2.new(1, -10, 0.5, -12),
					AnchorPoint = Vector2.new(1, 0),
					BackgroundColor3 = Color3.fromRGB(231, 76, 60),
					BackgroundTransparency = 0.5,
					Image = "rbxassetid://140355181374747",
					BorderSizePixel = 0,
					
					[Roact.Event.MouseButton1Click] = function()
						onClose()
					end,
				}, {
					Corner = Roact.createElement("UICorner", {
						CornerRadius = UDim.new(0, 12),
					}),
				}) or nil,
			}),
			
			
			Content = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 1, -50),
				Position = UDim2.new(0, 0, 0, 50),
				BackgroundTransparency = 1,
			}, {
				Padding = Roact.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 20),
					PaddingRight = UDim.new(0, 20),
					PaddingTop = UDim.new(0, 20),
					PaddingBottom = UDim.new(0, 20),
				}),
			}, children),
		}),
	})
end

function Modal:didUpdate(prevProps, prevState)
	
	if self.props.isOpen ~= prevProps.isOpen then
		self:setState({ isVisible = self.props.isOpen })
		
		local modal = self.modalRef:getValue()
		if modal then
			if self.props.isOpen then
				
				modal.Size = UDim2.new(0, 0, 0, 0)
				local tween = TweenService:Create(
					modal,
					TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{Size = self.props.size or UDim2.new(0, 500, 0, 400)}
				)
				tween:Play()
			end
		end
	end
end

return Modal
