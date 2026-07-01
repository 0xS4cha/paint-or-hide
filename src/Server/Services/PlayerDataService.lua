--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Config = require(ReplicatedStorage.Shared.Config)

local Logger = require(ReplicatedStorage.Shared.Modules.Core.Logger)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Networker = require(ReplicatedStorage.Packages.networker)
local ProfileService = require(ServerScriptService.ServerPackages.profileservice)

local PlayerDataService = {}
PlayerDataService.ProfileLoaded = Signal.new()
PlayerDataService.ProfileRemoving = Signal.new()
PlayerDataService.DataChanged = Signal.new()

local profilesByPlayer: { [Player]: any } = {}

local DEFAULT_DATA = {
	Rank = Config.Ranks.DEFAULT_RANK,
	PlayTime = 0,
	Coins = Config.Game.DEFAULT_COINS,
	Inventory = {},
	Cards = {},
	History = {},
}

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerDataStore_v3",
	DEFAULT_DATA
)

local networkerServer

function PlayerDataService:Init()
	networkerServer = Networker.server.new("PlayerDataService", self, {
		self.FetchData,
		self.FetchOtherPlayerData,
		self.SetCustomTitle
	})

	Players.PlayerAdded:Connect(function(player)
		self:OnPlayerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:OnPlayerRemoving(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:OnPlayerAdded(player)
		end)
	end

	task.spawn(function()
		while true do
			task.wait(Config.Game.PLAY_TIME_INTERVAL_SEC)

			for _, player in ipairs(Players:GetPlayers()) do
				local profile = profilesByPlayer[player]
				if profile then
					self:Update(player, function(data)
						data.PlayTime = (data.PlayTime or 0) + 1
						data.Coins = (data.Coins or 0) + Config.Game.COINS_REWARD_AMOUNT
						return data
					end)
				end
			end
		end
	end)

	Logger:info("PlayerDataService", "PlayerDataService started.")
end

function PlayerDataService:OnPlayerAdded(player: Player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		profile:ListenToRelease(function()
			profilesByPlayer[player] = nil
			player:Kick("Your data session was force-released. Please reconnect.")
		end)

		if player:IsDescendantOf(Players) then
			profilesByPlayer[player] = profile
			
			for k, v in pairs(DEFAULT_DATA) do
				if profile.Data[k] == nil then
					profile.Data[k] = v
				end
			end

			Logger:info("PlayerDataService", "Data loaded for " .. player.Name)
			self.ProfileLoaded:Fire(player, profile.Data)

			networkerServer:set(player, "Data", profile.Data)

			player:SetAttribute("PlayTime", profile.Data.PlayTime or 0)
			player:SetAttribute("Coins", profile.Data.Coins or 0)
		else
			profile:Release()
		end
	else
		player:Kick("Failed to load your game profile data. Please try again.")
	end
end

function PlayerDataService:OnPlayerRemoving(player: Player)
	local profile = profilesByPlayer[player]
	if profile then
		self.ProfileRemoving:Fire(player)
		profile:Release()
		profilesByPlayer[player] = nil
	end
end


function PlayerDataService:Get(player: Player)
	local profile = profilesByPlayer[player]
	return profile and profile.Data or nil
end

function PlayerDataService:Update(player: Player, callback: (data: any) -> any)
	local profile = profilesByPlayer[player]
	if not profile then
		return nil
	end

	local oldData = {}
	for k, v in pairs(profile.Data) do
		oldData[k] = v
	end

	local newData = callback(profile.Data)
	profile.Data = newData

	for k, v in pairs(newData) do
		if oldData[k] ~= v then
			self.DataChanged:Fire(player, k, v)
			if k == "PlayTime" or k == "Coins" then
				player:SetAttribute(k, v)
			end
		end
	end

	networkerServer:set(player, "Data", newData)
	return newData
end
function PlayerDataService:SetRank(player: Player, rank: string)
	self:Update(player, function(data)
		data.Rank = rank
		return data
	end)
end

function PlayerDataService:FetchData(player: Player)
	local data = self:Get(player)
	local retries = 0
	while not data and retries < 10 do
		task.wait(0.5)
		data = self:Get(player)
		retries = retries + 1
	end
	return data
end

function PlayerDataService:FetchOtherPlayerData(_: Player, targetPlayer: Player)
	local targetData = self:Get(targetPlayer)
	if targetData then
		return {
			Rank = targetData.Rank,
			PlayTime = targetData.PlayTime,
		}
	end
	return nil
end

return PlayerDataService
