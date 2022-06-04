--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local PlayerUtilities = require(ReplicatedStorage.Libraries.PlayerUtilities)
local TeleportationService

local PlayerService = Knit.CreateService({
    Name = "PlayerService"
})

-- Initialization.
function PlayerService:KnitStart()
    TeleportationService = Knit.GetService("TeleportationService")

    -- Anything we want to happen when the player spawns we put here.
    PlayerUtilities.CreatePlayerAddedWrapper(function(Player: Player)

        -- Anything we want to happen when the character spawn we put here.
        PlayerUtilities.CreateCharacterAddedWrapper(Player, function()
            TeleportationService:TeleportPlayer(Player)
        end)
    end)
end

return PlayerService
