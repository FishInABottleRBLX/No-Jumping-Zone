--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BadgeService = game:GetService("BadgeService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)

export type BadgeInformation = {
    Name: string,
    Description: string,
    IconImageId: number,
    IsEnabled: boolean
}

local BadgeServiceWrapper = Knit.CreateService({
    Name = "BadgeService",
    BadgeAwarded = Signal.new(),    -- (Player: Player, BadgeId: number)
    _BadgesAlreadyAwarded = {},

    Client = {
        BadgeAwarded = Knit.CreateSignal()  -- (BadgeId: number)
    }
})

-- Initialization.
function BadgeServiceWrapper:KnitInit()

    -- Removing their entry to clear up memory avoiding a leak.
    Players.PlayerRemoving:Connect(function(Player: Player)
        self._BadgesAlreadyAwarded[Player] = nil
    end)
end

-- Attempts to award a badge to this user.
function BadgeServiceWrapper:AwardBadge(Player: Player, BadgeId: number) : boolean

    -- If they have already been awarded this badge on the server then we shall not do it again.
    if self._BadgesAlreadyAwarded[Player] and self._BadgesAlreadyAwarded[Player][BadgeId] then
        return false
    end

    local WasSuccessful: boolean, Value: boolean | string = pcall(
        BadgeService.AwardBadge,
        BadgeService,
        Player.UserId,
        BadgeId
    )

    -- If that was successful we want to update everything.
    if WasSuccessful then
        self._BadgesAlreadyAwarded[Player] = self._BadgesAlreadyAwarded[Player] or {}
        self._BadgesAlreadyAwarded[Player][BadgeId] = true

        self.BadgeAwarded:Fire(Player, BadgeId)
        self.Client.BadgeAwarded:Fire(Player, BadgeId)
    else
        warn(Value :: string)
        return false
    end

    return true
end

-- Checks whether a player has the badge given.
function BadgeServiceWrapper:UserHasBadgeAsync(Player: Player, BadgeId: number) : boolean

    -- Has this badge already been awarded?
    if self._BadgesAlreadyAwarded[Player] and self._BadgesAlreadyAwarded[Player][BadgeId] then
        return true
    end

    local WasSuccessful: boolean, Value: boolean | string = pcall(
        BadgeService.UserHasBadgeAsync,
        BadgeService,
        Player.UserId,
        BadgeId
    )

    if WasSuccessful then
        return true
    else
        warn(Value :: string)
        return false
    end
end

-- Fetch information about a badge given its ID.
function BadgeServiceWrapper:GetBadgeInfoAsync(BadgeId: number) : BadgeInformation?

    local WasSuccessful: boolean, Value: BadgeInformation | string = pcall(
        BadgeService.GetBadgeInfoAsync,
        BadgeService,
        BadgeId
    )

    if not WasSuccessful then
        warn(Value :: string)
    end

    return if WasSuccessful then Value :: BadgeInformation else nil
end

-- The client wants to call UserHasBadgeAsync.
function BadgeServiceWrapper.Client:UserHasBadgeAsync(Player: Player, BadgeId: number) : boolean
    return self.Server:UserHasBadgeAsync(Player, BadgeId)
end

--[[
    The client wants to call GetBadgeInfoAsync.
    This can be called on the client and thus we don't need to contact the server.
]]
function BadgeServiceWrapper.Client:GetBadgeInfoAsync(BadgeId: number) : BadgeInformation?

    local WasSuccessful: boolean, Value: BadgeInformation | string = pcall(
        BadgeService.GetBadgeInfoAsync,
        BadgeService,
        BadgeId
    )

    if not WasSuccessful then
        warn(Value :: string)
    end

    return if WasSuccessful then Value :: BadgeInformation else nil
end

return BadgeServiceWrapper
