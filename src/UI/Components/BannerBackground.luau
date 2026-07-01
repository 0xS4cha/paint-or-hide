--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local RankConfig = require(ReplicatedStorage.Shared.Config.RankConfig)

local BannerBackground = Roact.Component:extend("BannerBackground")

local function isAssetId(bannerStr: string): boolean
	if string.find(bannerStr, "rbxassetid://") or string.find(bannerStr, "http://") or string.find(bannerStr, "https://") then
		return true
	end
	if tonumber(bannerStr) ~= nil then
		return true
	end
	return false
end

function BannerBackground:init()
	self.state = {
		currentFrame = 0
	}
	self.animating = false
end

function BannerBackground:startAnimation(bannerName)
	local style = RankConfig.BANNER_STYLES[bannerName]
	if style and style.Type == "Animated" then
		self.animating = true
		task.spawn(function()
			local fps = style.FPS or 10
			local interval = 1 / fps
			while self.animating do
				task.wait(interval)
				if not self.animating then break end
				self:setState(function(prevState)
					local frameCount = style.FrameCount or 5
					local nextFrame = (prevState.currentFrame + 1) % frameCount
					return { currentFrame = nextFrame }
				end)
			end
		end)
	end
end

function BannerBackground:didMount()
	self:startAnimation(self.props.bannerName)
end

function BannerBackground:didUpdate(prevProps)
	if prevProps.bannerName ~= self.props.bannerName then
		self.animating = false
		self:setState({ currentFrame = 0 })
		self:startAnimation(self.props.bannerName)
	end
end

function BannerBackground:willUnmount()
	self.animating = false
end

function BannerBackground:render()
	local bannerName = self.props.bannerName
	local size = self.props.size or UDim2.new(1, 0, 1, 0)
	local zIndex = self.props.zIndex or 1
	local cornerRadius = self.props.cornerRadius
	
	local style = RankConfig.BANNER_STYLES[bannerName]
	local isCustomImage = not style and isAssetId(bannerName)

	if style and style.Type == "Animated" then
		local sheetWidth = style.SheetWidth or 1024
		local sheetHeight = style.SheetHeight or 1024
		local cols = style.Cols or 5
		local rows = style.Rows or 5
		
		local frameWidth = sheetWidth / cols
		local frameHeight = sheetHeight / rows
		
		local currentFrame = self.state.currentFrame
		local colIndex, rowIndex
		
		if style.RowIndex ~= nil then
			colIndex = currentFrame
			rowIndex = style.RowIndex
		else
			colIndex = currentFrame % cols
			rowIndex = math.floor(currentFrame / cols)
		end
		
		return Roact.createElement("ImageLabel", {
			Size = size,
			BackgroundTransparency = 1,
			Image = style.Image,
			ImageRectSize = Vector2.new(frameWidth, frameHeight),
			ImageRectOffset = Vector2.new(colIndex * frameWidth, rowIndex * frameHeight),
			ZIndex = zIndex,
		}, {
			Corner = cornerRadius and Roact.createElement("UICorner", { CornerRadius = cornerRadius }) or nil,
		})
	elseif isCustomImage then
		local imageStr = bannerName
		if not string.find(imageStr, "rbxassetid://") and tonumber(imageStr) then
			imageStr = "rbxassetid://" .. imageStr
		end
		return Roact.createElement("ImageLabel", {
			Size = size,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Image = imageStr,
			ZIndex = zIndex,
		}, {
			Corner = cornerRadius and Roact.createElement("UICorner", { CornerRadius = cornerRadius }) or nil,
		})
	else
		local gradStyle = style or RankConfig.BANNER_STYLES.Default
		return Roact.createElement("Frame", {
			Size = size,
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ZIndex = zIndex,
		}, {
			Corner = cornerRadius and Roact.createElement("UICorner", { CornerRadius = cornerRadius }) or nil,
			Gradient = Roact.createElement("UIGradient", {
				Color = ColorSequence.new(gradStyle.Color1, gradStyle.Color2),
				Rotation = 45,
			})
		})
	end
end

return BannerBackground