--!strict
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local PlayerUtilities = {}

--[[
    This method is meant to counter a common issue that plagues developers.
    Where the PlayerAdded connector won't be set in time before the first player joins.
    Possibly creating game-breaking bugs.
]]
function PlayerUtilities.CreatePlayerAddedWrapper(CallbackFunction: (Player: Player) -> ())  : RBXScriptConnection

	for _, Player: Player in pairs(Players:GetPlayers()) do
		CallbackFunction(Player)
	end

	return Players.PlayerAdded:Connect(CallbackFunction)
end

--[[
    This method is meant to counter a common issue that plagues developers.
    Where the CharacterAdded connector won't be set in time before the character is first added.
    Possibly creating game-breaking bugs.
]]
function PlayerUtilities.CreateCharacterAddedWrapper(Player: Player, CallbackFunction: (Character: Model) -> ()) : RBXScriptConnection

    -- We create an internal wrapper so that we can make sure the character is fully loaded.
	local function InternalCharacterAddedWrapper(Character: Model)
		if not PlayerUtilities.IsPlayerAlive(Player) then
			repeat
				task.wait()
			until PlayerUtilities.IsPlayerAlive(Player)
		end

		CallbackFunction(Character)
	end

	if Player.Character then
		InternalCharacterAddedWrapper(Player.Character)
	end

	return Player.CharacterAdded:Connect(InternalCharacterAddedWrapper)
end

--[[
    Calculates the offset from the ground the humanoid should be at.
    https://developer.roblox.com/en-us/api-reference/property/Humanoid/HipHeight
]]
function PlayerUtilities.GetGroundOffset(Player: Player) : number

    if not PlayerUtilities.IsPlayerAlive(Player) then
        return 0
    end

    -- Calculating the offset according to the docs.
    local Character: Model = Player.Character :: Model
    local Humanoid: Humanoid = Character:FindFirstChildOfClass("Humanoid") :: Humanoid
    local RootPart: BasePart = Character:FindFirstChild("HumanoidRootPart") :: BasePart
    local RigType: Enum.HumanoidRigType = Humanoid.RigType
    local HipHeight: number = Humanoid.HipHeight

    if RigType == Enum.HumanoidRigType.R6 then
        return (Character:FindFirstChild("LeftLeg") :: BasePart).Size.Y + RootPart.Size.Y / 2 + HipHeight
    else
        return RootPart.Size.Y / 2 * HipHeight
    end
end

-- Asserts that what is passed to this function is a player and is also alive.
function PlayerUtilities.IsPlayerAlive(Player: Player?) : boolean

    -- If nothing is passed to this function it is assumed you are the client.
	Player = Player or Players.LocalPlayer

	-- First we're doing some type-checking and asserting that they're still in the server.
	if typeof(Player) ~= "Instance" or not Player:IsA("Player") or not Player:IsDescendantOf(Players) then
        return false
    end

    -- Now we want to check if their character is loaded properly.
    local Character: Model? = (Player :: Player).Character

	if not Character or not Character.PrimaryPart or not Character:IsDescendantOf(workspace) then
        return false
    end

    -- Now we want to check if the humanoid is alive and well.
    local Humanoid: Humanoid? = (Character :: Model):FindFirstChildOfClass("Humanoid")

	if not Humanoid or Humanoid:GetState() == Enum.HumanoidStateType.Dead then
        return false
    end

	return true
end

--[[
    This function allows you to ensure that SetCore will be called successfully.
    Depending on when SetCore is called it's possible that it hasn't been
    registered by the CoreScripts yet throwing an error.
]]
function PlayerUtilities.SetCore(CoreGuiName: string, ...)

    local WasSuccessful: boolean = pcall(StarterGui.SetCore, StarterGui, CoreGuiName, ...)

    -- We only want to try again if we have to.
    if not WasSuccessful then
        repeat
            task.wait()
            WasSuccessful = pcall(StarterGui.SetCore, StarterGui, CoreGuiName, ...)
        until WasSuccessful
    end
end

--[[
    This function is useful when working with loading screens originating in
    ReplicatedFirst, where it may not work if called regularly.
]]
function PlayerUtilities.SetCoreGuiEnabled(CoreGuiType: Enum.CoreGuiType, Enabled: boolean)

    StarterGui:SetCoreGuiEnabled(CoreGuiType, Enabled)

    -- We only want to try again if we have to.
    if StarterGui:GetCoreGuiEnabled(CoreGuiType) ~= Enabled then
        repeat
            task.wait()
            StarterGui:SetCoreGuiEnabled(CoreGuiType, Enabled)
        until StarterGui:GetCoreGuiEnabled(CoreGuiType) == Enabled
    end
end

return PlayerUtilities
