--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddControllersDeep(ReplicatedStorage.Controllers)
Knit.Start():catch(warn)
