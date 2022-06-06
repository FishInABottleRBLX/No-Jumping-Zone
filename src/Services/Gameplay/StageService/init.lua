--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local PlayerUtilities = require(ReplicatedStorage.Libraries.PlayerUtilities)
local StageBadges = require(script.StageBadges)
local ZoneNames = require(script.ZoneNames)
local UserDataService
local SoundEffectsService
local BadgeService	-- Not to be confused with the actual badge service.
local ServerMessagingService
local TeleportationService

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
	BadgeService = Knit.GetService("BadgeService")
	ServerMessagingService = Knit.GetService("ServerMessagingService")
	TeleportationService = Knit.GetService("TeleportationService")

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
	TeleportationService:TeleportPlayer(Player)

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

	-- We do badge giving here for backwards compatability reasons.
	if StageBadges[StageNumber] then
		BadgeService:AwardBadge(Player, StageBadges[StageNumber])
	end

	-- We only do the following when they have no reached this stage.
	-- This is so the chat is not spammed and their data is not corrupted.
	if not table.find(UserData.StageInformation.CompletedStages, StageNumber) then
		table.insert(UserData.StageInformation.CompletedStages, StageNumber)

		-- If this is a trial stage we want to clap and tell the world of their achievement!
		if self:IsTrialStage(StageNumber) then
			SoundEffectsService:PlaySoundEffect(Player, "Clapping")
			ServerMessagingService:SendSystemMessage(string.format(
				"%s has just finished %s!",
				Player.Name,
				ZoneNames[math.floor((StageNumber - 1) / 10)] or "????"
			))
		end
	end

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

-- Returns whether or not the stage represented by this number is a trial stage.
function StageService:IsTrialStage(StageNumber: number) : boolean
	return StageNumber % 10 == 1 and StageNumber > 1
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
