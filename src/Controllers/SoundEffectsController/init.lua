--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Knit = require(ReplicatedStorage.Packages.Knit)
local SoundEffectsService

local SOUND_EFFECTS_CONTAINER: Instance = ReplicatedStorage.Assets.Sounds

local SoundEffectsController = Knit.CreateController({
    Name = "SoundEffectsController",
})

-- Initialization.
function SoundEffectsController:KnitStart()
    SoundEffectsService = Knit.GetService("SoundEffectsService")

    -- The server is telling us to play a sound effect.
    SoundEffectsService.PlaySoundEffect:Connect(function(Name: string, Parent: Instance?)
        self:PlaySoundEffect(Name, Parent)
    end)
end

--[[
    Plays a sound effect.
    If no parent is specified it will play inside of the player.
]]
function SoundEffectsController:PlaySoundEffect(Name: string, Parent: Instance?)

	local OriginalSoundEffect: Instance? = SOUND_EFFECTS_CONTAINER:FindFirstChild(Name)

	-- We check if the sound effect exists on the client to save the server from doing it.
	if not OriginalSoundEffect or not OriginalSoundEffect:IsA("Sound") then
		return
	end

	-- Now we 100% know its safe and can go forward.
	local SoundEffectClone: Sound = (OriginalSoundEffect :: Instance):Clone() :: Sound
	SoundEffectClone.SoundGroup = script.SoundGroup
	SoundEffectClone.Parent = Parent or Knit.Player
	SoundEffectClone:Play()

	Debris:AddItem(SoundEffectClone, SoundEffectClone.TimeLength)
end

return SoundEffectsController
