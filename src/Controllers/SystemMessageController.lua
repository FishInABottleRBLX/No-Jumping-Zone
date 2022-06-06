--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local PlayerUtilities = require(ReplicatedStorage.Libraries.PlayerUtilities)
local ServerMessagingService

local SystemMessageController = Knit.CreateController({
    Name = "SystemMessageController"
})

-- Initialization.
function SystemMessageController:KnitStart()
    ServerMessagingService = Knit.GetService("ServerMessagingService")

    ServerMessagingService.SendSystemMessage:Connect(function(Message: string, Color: Color3)
        PlayerUtilities.SetCore(
            "ChatMakeSystemMessage",
            {Text = Message, Color = Color}
        )
    end)
end

return SystemMessageController
