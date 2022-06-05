--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local PlayerUtilities = require(ReplicatedStorage.Libraries.PlayerUtilities)
--local StageBadges = require(script.StageBadges)
local UserDataService
local SoundEffectsService

--local BONUS_STAGES_CONTAINER: Instance = workspace.Map.Stages.BonusStages
local STAGE_CHECKPOINTS_CONTAINER: Instance = workspace.Map.Stages.Checkpoints

local StageService = Knit.CreateService({
    Name = "CheckpointService",
	BonusStageStarted = Signal.new(),	-- (Player: Player, Name: string)
	StageStarted = Signal.new(),	-- (Player: Player, StageNumber: number)
    Client = {}
})

-- Initialization.
function StageService:KnitStart()
    UserDataService = Knit.GetService("UserDataService")
	SoundEffectsService = Knit.GetService("SoundEffectsService")

	-- Every BasePart child under STAGE_CHECKPOINTS_CONTAINER is considered a checkpoint.
	for _, Checkpoint: Instance in pairs(STAGE_CHECKPOINTS_CONTAINER:GetChildren()) do
		if Checkpoint:IsA("BasePart") and tonumber(Checkpoint.Name) then
			Checkpoint.Touched:Connect(function(Hit: BasePart)

				-- As long as the player is alive we should be able to update their checkpoints.
				local Player: Player? = Players:GetPlayerFromCharacter(Hit.Parent)
				local StageNumber: number = tonumber(Checkpoint.Name) :: number

				if PlayerUtilities.IsPlayerAlive(Player) then
					self:UpdateFarthestCheckpoint(Player, StageNumber)
					self:UpdateCurrentCheckpoint(Player, StageNumber)
				end
			end)
		end
	end
end

-- Attempts to teleport the player to the given bonus stage.
function StageService:TeleportToBonusStage(Player: Player, Name: string, AskForPermission: boolean?) : boolean
	print(Player, Name, AskForPermission)
	return true
end

-- Attempts to teleport the player to the given stage.
function StageService:TeleportToStage(Player: Player, StageNumber: number, AskForPermission: boolean?, SafetyCheckException: boolean?) : boolean

	-- We want nothing to do with them if this is the case.
	if not PlayerUtilities.IsPlayerAlive(Player) or not UserDataService:GetData(Player) then
		return false
	end

	-- We need to make sure that StageNumber is a positive integer or else everything can go wacky.
	if StageNumber % 1 > 0 or StageNumber <= 0 then
		return false
	end

	-- We need to make sure that they have reached this checkpoint before unless there is an exception.
	-- We add the safety check exception in case the level designer wants to add a skip (think the cannons from Mario).
	if UserDataService:GetData(Player).StageInformation.CurrentCheckpoint < StageNumber and not SafetyCheckException then
		return false
	end

	-- If the stage corresponding with StageNumber does not exist it could be a level designer issue.
	if not STAGE_CHECKPOINTS_CONTAINER:FindFirstChild(tostring(StageNumber)) then
		warn(string.format(
			"[%s]: %s",
			script.Name,
			"Cannot find stage " .. tostring(StageNumber)
		))

		return false
	end

	-- If we need to ask for permission we need to do it before we update anything.
	if AskForPermission then
		print("Ask for permission first")
	end

	-- We want to update both their farthest and current checkpoint.
	-- We do both so we can have backwards compatability and account for the safety check being disabled.
	self:UpdateFarthestCheckpoint(Player, StageNumber)
	self:UpdateCurrentCheckpoint(Player, StageNumber)
	-- Teleport them.

	return true
end

--[[
	Updates StageInformation.CurrentCheckpoint if possible.
	All reward giving should be done in this function to maintain backwards compatability.
]]
function StageService:UpdateCurrentCheckpoint(Player: Player, StageNumber: number) : boolean

	local UserData = UserDataService:GetData(Player)

	-- These are the only two cases in which this function should fail to complete.
	if not UserData or UserData.StageInformation.FarthestCheckpoint < StageNumber then
		return false
	end

	-- We need to make sure that StageNumber is a positive integer or else everything can go wacky.
	if StageNumber % 1 > 0 or StageNumber <= 0 then
		return false
	end

	--[[
		Since the actual checkpoint instances do not have any sort of debounces
		we need to check to see if they have even progressed further in order
		to avoid spamming updates when we don't need to.
	]]
	local PreviousCheckpoint: number = UserData.StageInformation.CurrentCheckpoint

	-- Now we want to update their data before making any changes.
	-- I overwrite the bonus stage information in case the player somehow escapes and returns to the main stages.
	UserData.StageInformation.CurrentCheckpoint = StageNumber
	UserData.StageInformation.BonusStageName = ""
	UserData.StageInformation.BonusStageCheckpoint = 1

	-- If we ensure that a change has happened we can do things like updating the client.
	if PreviousCheckpoint ~= StageNumber then
		SoundEffectsService:PlaySoundEffect(Player, "CheckpointTouched")
		SoundEffectsService:PlaySoundEffect(Player, "Stage" .. tostring(StageNumber))
	end

	-- We do most of the reward giving here for backwards compatability reasons.
	-- ...

	return true
end

--[[
	Updates StageInformation.FarthestCheckpoint if possible.
	This function should not do any reward giving.
]]
function StageService:UpdateFarthestCheckpoint(Player: Player, StageNumber: number) : boolean

	local UserData = UserDataService:GetData(Player)

	-- These are the only two cases in which this function should fail to complete.
	if not UserData or UserData.StageInformation.FarthestCheckpoint >= StageNumber then
		return false
	end

	-- We need to make sure that StageNumber is a positive integer or else everything can go wacky.
	if StageNumber % 1 > 0 or StageNumber <= 0 then
		return false
	end

	UserData.StageInformation.FarthestCheckpoint = StageNumber

	return true
end

-- The client wants to teleport to this specific bonus stage.
function StageService.Client:TeleportToBonusStage(Player: Player, BonusStageName: string) : boolean
	return self.Server:TeleportToBonusStage(Player, BonusStageName, false)
end

-- The client wants to teleport to this specific stage.
function StageService.Client:TeleportToStage(Player: Player, StageNumber: number) : boolean
	return self.Server:TeleportToStage(Player, StageNumber, false)
end

return StageService

--[[
    local players: Players = game:GetService("Players")

local coreModule = require(script:FindFirstAncestor("Core"))
local userDataManager = require(coreModule.GetObject("Modules.Gameplay.PlayerManager.UserDataManager"))
local teleportationManager = require(coreModule.GetObject("Modules.Gameplay.MechanicsManager.TeleportationManager"))
local badgeService = require(coreModule.Shared.GetObject("Libraries.Services.BadgeService"))
local playerUtilities = require(coreModule.Shared.GetObject("Libraries.Utilities.PlayerUtilities"))
local badgeList = require(coreModule.Shared.GetObject("Libraries.BadgeList"))
local zoneNames = require(coreModule.Shared.GetObject("Libraries.ZoneNames"))
local sharedConstants = require(coreModule.Shared.GetObject("Libraries.SharedConstants"))
local signal = require(coreModule.Shared.GetObject("Libraries.Signal"))

local userInformationUpdatedRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.UserInformationUpdated")
local playSoundEffectRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.PlaySoundEffect")
local makeSystemMessageRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.MakeSystemMessage")
local teleportToStageRemote: RemoteEvent = coreModule.Shared.GetObject("//Remotes.Gameplay.Stages.TeleportToStage")
local thisPlatformContainer: Instance? = workspace.Map.Gameplay.LevelStorage:FindFirstChild("Checkpoints")

local CheckpointsManager = {}
CheckpointsManager.CurrentCheckpointUpdated = signal.new()

-- Initialize
function CheckpointsManager.Initialize()
	if not thisPlatformContainer then return end

	-- Every descendant that is a BasePart of this collection will respawn them.
	for _, thisPlatform: Instance in next, (thisPlatformContainer :: Instance):GetDescendants() do

		if thisPlatform:IsA("BasePart") and tonumber(thisPlatform.Name) then
			thisPlatform.Touched:Connect(function(hit: BasePart)

				local player: Player? = players:GetPlayerFromCharacter(hit.Parent)
				if not playerUtilities.IsPlayerAlive(player) then return end

				-- Update their Farthest and Current checkpoints.
				CheckpointsManager.UpdateFarthestCheckpoint(player, tonumber(thisPlatform.Name))
				CheckpointsManager.UpdateCurrentCheckpoint(player, tonumber(thisPlatform.Name))
			end)
		end
	end

	-- The client wants to teleport to a specific stage.
	-- We need make sure they've even reached this point.
	teleportToStageRemote.OnServerEvent:Connect(function(player: Player, checkpointNumber: number?)

		-- If these are invalid something has gone horrible wrong.
		if not playerUtilities.IsPlayerAlive(player) then return end
		if not userDataManager.GetData(player) then return end

		-- We need to make sure the number is correct.
		if typeof(checkpointNumber) ~= "number" then return end
		if math.floor(checkpointNumber) ~= checkpointNumber then return end

		-- Does this checkpoint even exist and have they reached this point?
		if not thisPlatformContainer:FindFirstChild(checkpointNumber) then return end
		if userDataManager.GetData(player).UserInformation.FarthestCheckpoint < checkpointNumber then return end

		-- Update their Farthest and Current checkpoints.
		CheckpointsManager.UpdateFarthestCheckpoint(player, checkpointNumber)
		CheckpointsManager.UpdateCurrentCheckpoint(player, checkpointNumber)
		teleportationManager.TeleportPlayer(player)
	end)
end

-- Updates the current checkpoint the user is at as long as everything is valid.
-- This is the checkpoint they will teleport to when they respawn.
function CheckpointsManager.UpdateCurrentCheckpoint(player: Player, checkpointNumber: number)

	if not playerUtilities.IsPlayerValid(player) then return end
	if not userDataManager.GetData(player) then return end

	-- This should be impossible but I still have it here just in case.
	if userDataManager.GetData(player).UserInformation.FarthestCheckpoint < checkpointNumber then return end

	-- We keep track of this so we aren't spamming remotes and such.
	local userData: {} = userDataManager.GetData(player)
	local originalCurrentCheckpoint: number = userData.UserInformation.CurrentCheckpoint

	-- Update their data to match their new current checkpoint.
	userData.UserInformation.CurrentCheckpoint = checkpointNumber
	userData.UserInformation.CurrentBonusStage = ""

	-- Backwards compatibility for things like badges and CompletedStages.
	if originalCurrentCheckpoint ~= userData.UserInformation.CurrentCheckpoint then

		-- We can fire the bindable and try to play any sound effects related.
		CheckpointsManager.CurrentCheckpointUpdated:Fire(player, originalCurrentCheckpoint, userData.UserInformation.CurrentCheckpoint)
		playSoundEffectRemote:FireClient(player, "CheckpointTouched")
		playSoundEffectRemote:FireClient(player, "Stage" .. tostring(checkpointNumber))

		-- Backwards compatibility for award trial badges.
		if checkpointNumber > 1 and checkpointNumber % 10 == 1 then

			local trialNumber: number = math.floor(checkpointNumber / 10)

			-- Can we award a badge for this?
			if badgeList.Trials[trialNumber] then
				badgeService.AwardBadge(player, badgeList.Trials[trialNumber])
			end

			-- We add this to the list so we only show the message once.
			if not table.find(userData.UserInformation.CompletedStages, checkpointNumber) then

				table.insert(userData.UserInformation.CompletedStages, checkpointNumber)

				-- We want the clapping to play for just them and then the message for everyone.
				playSoundEffectRemote:FireClient(player, "Clapping")
				makeSystemMessageRemote:FireAllClients(string.format(
					sharedConstants.FORMATS.TRIAL_COMPLETION_MESSAGE_FORMAT,
					player.Name,
					zoneNames[trialNumber] or "???"
				))
			end
		end

		-- Informing the client we have updated their data.
		userInformationUpdatedRemote:FireClient(player, userData)
	end

	-- Backwards compatability for CompletedStages.
	-- Apparently we need to make sure it isn't a trial or else it'll be overwritten and our effects won't show.
	if checkpointNumber == 1 or checkpointNumber % 10 ~= 1 then
		if not table.find(userData.UserInformation.CompletedStages, checkpointNumber) then
			table.insert(userData.UserInformation.CompletedStages, checkpointNumber)
		end
	end

	-- Backwards compatability for No-Jumping-Zone-Completionist.
	if checkpointNumber == 101 then
		badgeService.AwardBadge(player, 2125036729)
	end
end

-- Updates the farthest checkpoint a user has ever reached is possible.
-- This is mainly used for visual purposes.
function CheckpointsManager.UpdateFarthestCheckpoint(player: Player, checkpointNumber: number)

	if not playerUtilities.IsPlayerValid(player) then return end
	if not userDataManager.GetData(player) then return end

	-- FarthestCheckpoint cannot regress.
	if userDataManager.GetData(player).UserInformation.FarthestCheckpoint >= checkpointNumber then return end

	-- Update their data to match their new farthest checkpoint.
	local userData: {} = userDataManager.GetData(player)
	userData.UserInformation.FarthestCheckpoint = checkpointNumber
	userInformationUpdatedRemote:FireClient(player, userData)

	-- Did they just finish the game???
	if checkpointNumber == 101 then

		-- We want a little delay so it shows up after the trial completion message,
		task.delay(0.5, function()
			makeSystemMessageRemote:FireAllClients(string.format(
				sharedConstants.FORMATS.EXPERIENCE_COMPLETION_MESSAGE_FORMAT,
				player.Name
			))
		end)
	end
end

return CheckpointsManager

]]