--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Signal = require(ReplicatedStorage.Packages.Signal)

local ZoneManager = {}
ZoneManager.__index = ZoneManager

export type Zone = typeof(setmetatable(
	{} :: {
		Part: BasePart,
		PlayerEntered: Signal.Signal<Player>,
		PlayerLeft: Signal.Signal<Player>,
		_playersInZone: { [Player]: boolean },
		_active: boolean,
		_thread: thread?,
		_interval: number,
		_overlapParams: OverlapParams,
	},
	ZoneManager
))

function ZoneManager.new(part: BasePart, checkInterval: number?): Zone
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	
	
	local self = setmetatable({
		Part = part,
		PlayerEntered = Signal.new(),
		PlayerLeft = Signal.new(),
		_playersInZone = {},
		_active = false,
		_interval = checkInterval or 0.2,
		_overlapParams = overlapParams,
	}, ZoneManager)

	return self
end

function ZoneManager.Start(self: Zone)
	if self._active then return end
	self._active = true

	self._thread = task.spawn(function()
		while self._active do
			self:_update()
			task.wait(self._interval)
		end
	end)
end

function ZoneManager.Stop(self: Zone)
	self._active = false
	if self._thread then
		task.cancel(self._thread)
		self._thread = nil
	end
	
	
	for player, _ in pairs(self._playersInZone) do
		self._playersInZone[player] = nil
		self.PlayerLeft:Fire(player)
	end
end

function ZoneManager._update(self: Zone)
	
	local characterParts = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			for _, part in ipairs(char:GetChildren()) do
				if part:IsA("BasePart") then
					table.insert(characterParts, part)
				end
			end
		end
	end

	self._overlapParams.FilterDescendantsInstances = characterParts

	
	if #characterParts == 0 then
		
		for player, _ in pairs(self._playersInZone) do
			self._playersInZone[player] = nil
			self.PlayerLeft:Fire(player)
		end
		return
	end

	
	local foundParts = workspace:GetPartsInPart(self.Part, self._overlapParams)
	local currentPlayersInZone: { [Player]: boolean } = {}

	for _, part in ipairs(foundParts) do
		local character = part.Parent
		if character and character:IsA("Model") then
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				currentPlayersInZone[player] = true
			end
		end
	end

	
	for player, _ in pairs(currentPlayersInZone) do
		if not self._playersInZone[player] then
			self._playersInZone[player] = true
			self.PlayerEntered:Fire(player)
		end
	end

	
	for player, _ in pairs(self._playersInZone) do
		if not currentPlayersInZone[player] then
			self._playersInZone[player] = nil
			self.PlayerLeft:Fire(player)
		end
	end
end

function ZoneManager.GetPlayers(self: Zone): { Player }
	local list = {}
	for player, _ in pairs(self._playersInZone) do
		table.insert(list, player)
	end
	return list
end

function ZoneManager.IsPlayerInZone(self: Zone, player: Player): boolean
	return self._playersInZone[player] == true
end

function ZoneManager.Destroy(self: Zone)
	self:Stop()
	self.PlayerEntered:Destroy()
	self.PlayerLeft:Destroy()
end

return ZoneManager
