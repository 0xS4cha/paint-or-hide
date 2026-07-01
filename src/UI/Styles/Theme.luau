



local Theme = {}


Theme.Colors = {
	Primary = Color3.fromRGB(37, 99, 235),      
	Secondary = Color3.fromRGB(16, 185, 129),    
	Accent = Color3.fromRGB(226, 180, 73),        
	Danger = Color3.fromRGB(225, 29, 72),        
	
	Background = Color3.fromRGB(12, 14, 20),      
	Surface = Color3.fromRGB(22, 26, 36),         
	Text = Color3.fromRGB(255, 255, 255),         
	TextSecondary = Color3.fromRGB(160, 166, 178), 
}


Theme.Transparency = {
	Background = 0.2,
	Surface = 0.15,
	Button = 0.4,
	ButtonHover = 0.2,
	Card = 0.25,
	CardHover = 0.15,
}


Theme.Sizes = {
	Button = {
		Small = UDim2.new(0, 120, 0, 40),
		Medium = UDim2.new(0, 200, 0, 50),
		Large = UDim2.new(0, 300, 0, 60),
	},
	Card = {
		Small = UDim2.new(0, 250, 0, 150),
		Medium = UDim2.new(0, 350, 0, 200),
		Large = UDim2.new(0, 500, 0, 300),
	},
}


Theme.Fonts = {
	Title = Enum.Font.GothamBold,
	Body = Enum.Font.Gotham,
	Button = Enum.Font.GothamBold,
}


Theme.TextSizes = {
	Title = 32,
	Subtitle = 24,
	Body = 18,
	Button = 18,
	Small = 14,
}


Theme.CornerRadius = {
	Small = 6,
	Medium = 10,
	Large = 14,
}

return Theme
