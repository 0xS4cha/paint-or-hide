--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Roact = require(ReplicatedStorage.Packages.Roact)
local OverheadBillboard = require(ReplicatedStorage.UI.Components.OverheadBillboard)

local BillboardController = {}
local spawnedHandles = {}

function BillboardController:Init()
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			self:SetupBillboard(player, char)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:RemoveBillboard(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			task.spawn(function()
				self:SetupBillboard(player, player.Character)
			end)
		end
		player.CharacterAdded:Connect(function(char)
			self:SetupBillboard(player, char)
		end)
	end

	Logger:info("BillboardController", "BillboardController started.")
end

function BillboardController:SetupBillboard(player: Player, character: Model)
	self:RemoveBillboard(player)
	Logger:info("BillboardController", "Setting up custom overhead billboard for " .. player.Name)

	local head = character:WaitForChild("Head", 8) :: BasePart?
	if not head then
		Logger:warn("BillboardController", "Head not found for player: " .. player.Name)
		return
	end

	local humanoid = character:WaitForChild("Humanoid", 8) :: Humanoid?
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "OverheadBillboardGui_" .. player.UserId
	billboardGui.Size = UDim2.new(0, 180, 0, 75)
	billboardGui.StudsOffset = Vector3.new(0, 3.5, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.ResetOnSpawn = true
	billboardGui.Active = true
	billboardGui.LightInfluence = 0
	billboardGui.Adornee = head

	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	billboardGui.Parent = playerGui

	local handle = Roact.mount(
		Roact.createElement(OverheadBillboard, {
			player = player,
		}),
		billboardGui,
		"BillboardContent"
	)

	spawnedHandles[player] = {
		Handle = handle,
		Gui = billboardGui,
	}
end

function BillboardController:RemoveBillboard(player: Player)
	local info = spawnedHandles[player]
	if info then
		pcall(function()
			Roact.unmount(info.Handle)
		end)
		pcall(function()
			if info.Gui and info.Gui.Parent then
				info.Gui:Destroy()
			end
		end)
		spawnedHandles[player] = nil
	end
end

return BillboardController
