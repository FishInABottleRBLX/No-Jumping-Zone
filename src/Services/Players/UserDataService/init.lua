--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local ProfileService = require(script.ProfileService)
local DefaultData = require(script.DefaultData)

local UserDataService = Knit.CreateService({
	Name = "UserDataService",

	_ProfileStore = nil,
	_ProfilesStored = {},
	_ProfilesBeingLoaded = {},
	_IsInCriticalState = false,
	CrticalStateUpdated = Signal.new(),
	ProfileLoaded = Signal.new(),

	Client = {
		CrticalStateUpdated = Knit.CreateSignal(),
		ProfileLoaded = Knit.CreateSignal(),
	}
})

-- Initialization.
function UserDataService:KnitInit()

	-- We need to create the profile store.
	UserDataService._ProfileStore = ProfileService.GetProfileStore(
		"UserData/Global", DefaultData
	)

	-- ProfileService is telling us we reached a critical state.
	ProfileService.CriticalStateSignal:Connect(function(IsCritical: boolean)
		self._IsInCriticalState = IsCritical
		self.CrticalStateUpdated:Fire(IsCritical)
		self.Client.CrticalStateUpdated:FireAllClients(IsCritical)
	end)
end

-- Attempts to load a user's data. Returning whether or not it was successful.
function UserDataService:LoadData(Player: Player) : boolean

	-- All of these need to pass before we can continue.
	if
		not Player:IsDescendantOf(Players)
		or not self._ProfileStore
		or self._ProfilesStored[Player]
	then
		return false
	end

	-- Attempt to call LoadProfileAsync with ForceLoad.
	self._ProfilesBeingLoaded[Player] = true

	local LoadedProfileData = self._ProfileStore:LoadProfileAsync(
		tostring(Player.UserId), "ForceLoad"
	)

	-- The profile was successfully loaded.
	if LoadedProfileData ~= nil then

		-- Reconcile syncs current data with the current default template
		-- ListenToRelease is a callback for when this session lock is released.
		LoadedProfileData:Reconcile()
		LoadedProfileData:ListenToRelease(function()
			self._ProfilesStored[Player] = nil
			self._ProfilesBeingLoaded[Player] = nil
		end)

		-- The player is still in the game after all of our setup, so we can continue.
		if Player:IsDescendantOf(Players) then
			self._ProfilesStored[Player] = LoadedProfileData
			self.ProfileLoaded:Fire(Player, LoadedProfileData.Data)
			self.Client.ProfileLoaded:Fire(Player, LoadedProfileData.Data)

		else
			-- The player left so we need to end this session.
			LoadedProfileData:Release()
		end

	else
		-- Something went wrong and the profile could not be loaded.
		Player:Kick()
		self._ProfilesBeingLoaded[Player] = nil

		return false
	end

	-- All went well if it reaches this point.
	self._ProfilesBeingLoaded[Player] = nil
	return true
end

-- Attempts to save a user's data. Returns whether or not it was successful.
function UserDataService:SaveData(Player: Player) : boolean

	-- All of these need to pass before we can continue.
	if
		not Player:IsDescendantOf(Players)
		or not self._ProfilesStored[Player]
	then
		return false
	end

	-- Release the current session.
	self._ProfilesStored[Player]:Release()
	return true
end

-- Attempts to get the data of this user.
-- If the data has not been loaded it tries to load it.
function UserDataService:GetData(Player: Player) : {[string]: any}?

	-- In the case the player left let's just do this so it doesn't error.
	if not Player:IsDescendantOf(Players) then return end

	-- Their profile has not been loaded yet.
	if not self._ProfilesStored[Player] then

		-- LoadData has already been called so we just need to wait.
		if self._ProfilesBeingLoaded[Player] then
			repeat
				self.ProfileLoaded:Wait()
			until not self._ProfilesBeingLoaded[Player]

		else
			-- LoadData has not been called so we need to.
			self:LoadData(Player)
		end
	end

	-- All should be good if it reaches this point.
	return self._ProfilesStored[Player].Data
end

-- The server wants to obtain _IsInCriticalState.
function UserDataService:IsInCriticalState() : boolean
	return self._IsInCriticalState
end

-- The client wants to obtain their data.
function UserDataService.Client:GetData(Player: Player) : {[string]: any}?
	return self.Server:GetData(Player)
end

-- The client wants to obtain _IsInCriticalState.
function UserDataService.Client:IsInCriticalState() : boolean
	return self.Server:IsInCriticalState()
end

return UserDataService
