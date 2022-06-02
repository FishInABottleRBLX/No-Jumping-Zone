--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddServicesDeep(ServerStorage.Services)
Knit.Start():catch(warn)
