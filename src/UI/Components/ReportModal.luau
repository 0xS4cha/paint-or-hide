--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Packages.Roact)
local Theme = require(ReplicatedStorage.UI.Styles.Theme)
local DragFrame = require(ReplicatedStorage.UI.Components.DragFrame)
local Button = require(ReplicatedStorage.UI.Components.Button)
local Input = require(ReplicatedStorage.UI.Components.Input)
local Dropdown = require(ReplicatedStorage.UI.Components.Dropdown)

local ReportModal = Roact.Component:extend("ReportModal")

local REPORT_REASONS = {
	"Spam micro / Musique",
	"Harcèlement / Insultes",
	"Comportement Toxique / Troll",
	"Pseudo inapproprié",
	"Autre raison",
}

function ReportModal:init()
	self.state = {
		selectedReasonIndex = 1,
		details = "",
	}
end

function ReportModal:render()
	local props = self.props
	local state = self.state
	local targetPlayer = props.player

	return Roact.createElement(DragFrame, {
		size = UDim2.new(0, 340, 0, 310),
		position = UDim2.new(0.5, 0, 0.5, 0), 
		headerText = "Signaler " .. (targetPlayer.DisplayName or targetPlayer.Name),
		headerColor = Theme.Colors.Danger, 
	}, {
		MainContainer = Roact.createElement("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		}, {
			Padding = Roact.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 15),
				PaddingRight = UDim.new(0, 15),
				PaddingTop = UDim.new(0, 15),
				PaddingBottom = UDim.new(0, 15),
			}),

			
			InfoLabel = Roact.createElement("TextLabel", {
				Size = UDim2.new(1, 0, 0, 36),
				BackgroundTransparency = 1,
				Text = "Veuillez sélectionner une raison et apporter des précisions ci-dessous :",
				TextColor3 = Theme.Colors.TextSecondary,
				Font = Theme.Fonts.Body,
				TextSize = Theme.TextSizes.Small,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}),

			
			ReasonDropdown = Roact.createElement(Dropdown, {
				options = REPORT_REASONS,
				size = UDim2.new(1, 0, 0, 36),
				position = UDim2.new(0, 0, 0, 45),
				anchorPoint = Vector2.new(0, 0),
				label = "Motif du signalement :",
				defaultIndex = 1,
				onChange = function(index, value)
					self:setState({ selectedReasonIndex = index })
				end,
			}),

			
			DetailsInput = Roact.createElement(Input, {
				size = UDim2.new(1, 0, 0, 40),
				position = UDim2.new(0, 0, 0, 115),
				anchorPoint = Vector2.new(0, 0),
				placeholder = "Spécifiez des détails (heure, propos)...",
				defaultValue = state.details,
				label = "Détails supplémentaires :",
				onChangeWhileTyping = function(text)
					self:setState({ details = text })
				end,
			}),

			
			ActionsFrame = Roact.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 40),
				Position = UDim2.new(0, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundTransparency = 1,
			}, {
				UIList = Roact.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
					SortOrder = Enum.SortOrder.LayoutOrder,
					Padding = UDim.new(0, 10),
				}),

				CancelBtn = Roact.createElement(Button, {
					text = "Annuler",
					size = UDim2.new(0, 90, 1, 0),
					backgroundColor = Theme.Colors.Surface,
					onClick = props.onClose,
					layoutOrder = 1,
				}),

				SubmitBtn = Roact.createElement(Button, {
					text = "Signaler",
					size = UDim2.new(0, 110, 1, 0),
					backgroundColor = Theme.Colors.Danger,
					onClick = function()
						local reasonText = REPORT_REASONS[state.selectedReasonIndex] or "Autre"
						local detailsText = state.details
						
						
						local success, err = pcall(function()
							local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
							local net = require(playerScripts:WaitForChild("Client"):WaitForChild("Services"):WaitForChild("PlayerDataServiceClient")).networkerClient
							if net then
								net:fire("SubmitReport", targetPlayer, reasonText, detailsText)
							end
						end)

						if not success then
							warn("Failed to send report: ", err)
						end

						props.onClose() 
					end,
					layoutOrder = 2,
				}),
			})
		})
	})
end

return ReportModal
