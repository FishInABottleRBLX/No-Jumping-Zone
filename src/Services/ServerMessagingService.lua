--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ServerMessagingService = Knit.CreateService({
    Name = "ServerMessagingService",
    Client = {
        SendSystemMessage = Knit.CreateSignal()   -- (Message: string, MessageColor: Color3)
    }
})

-- Creates a message in every users chat from the server.
function ServerMessagingService:SendSystemMessage(Message: string, MessageColor: Color3?)

    -- You can override the defaults here.
    -- This is too insignificant to add a config for.
    self.Client.SendSystemMessage:FireAll(
        "[System]: " .. Message,
        MessageColor or Color3.fromHex("#09979f")
    )
end

return ServerMessagingService
