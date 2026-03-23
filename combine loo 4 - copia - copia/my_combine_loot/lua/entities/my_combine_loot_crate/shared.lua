-- lua/entities/my_combine_loot_crate/shared.lua

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Combine Loot Cache"
ENT.Author = "Your Name Here" -- Update if you like
ENT.Contact = ""
ENT.Purpose = "Contains potential loot from a fallen Combine."
ENT.Instructions = "Press USE to retrieve loot."

ENT.Spawnable = false
ENT.AdminSpawnable = false

-- *** UPDATE THIS LINE ***
ENT.Model = "models/props_c17/SuitCase_Passenger_Physics.mdl"
-- *** ***

-- Make sure the client knows about the model
if CLIENT then
    ENT.RenderGroup = RENDERGROUP_OPAQUE
end