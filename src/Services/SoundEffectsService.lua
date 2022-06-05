--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local SoundEffectsService = Knit.CreateService({
    Name = "SoundEffectsService",
    Client = {
        PlaySoundEffect = Knit.CreateSignal() -- (Name: string, Parent: Instance?)
    }
})

--[[
    Tells the client to play a sound effect.
    If no parent is specified it will play inside of the player.
]]
function SoundEffectsService:PlaySoundEffect(Player: Player, Name: string, Parent: Instance?)
    self.Client.PlaySoundEffect:Fire(Player, Name, Parent)
end

return SoundEffectsService
