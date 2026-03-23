-- lua/entities/my_combine_loot_crate/init.lua

AddCSLuaFile("shared.lua") -- Tell server clients need this file
include("shared.lua")     -- Include shared properties on server

-- How long the crate stays before disappearing if not used (in seconds)
local CrateLifetime = 180 -- 3 minutes, adjust as needed

function ENT:Initialize()
    if not self.Model then return end -- Safety check

    self:SetModel(self.Model)

    -- Physics setup
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE) -- Allow players to press 'E' on it

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        -- Optional: Give it slight physics variation
        phys:SetMass(20) -- Give it some reasonable weight
        phys:ApplyForceCenter(VectorRand() * 50) -- Tiny initial push
        phys:AddAngleVelocity(VectorRand() * 20)
    end

    -- Table to hold the class names of potential weapons
    self.PotentialLoot = {}

    -- Set timer to automatically remove itself after a while
    self:Fire("Kill", "", CrateLifetime)
end

-- Custom function called by the NPC kill hook to store potential loot
function ENT:SetPotentialLoot(lootTable)
    if not lootTable or type(lootTable) ~= "table" then return end
    self.PotentialLoot = lootTable
    -- Optional: Print stored loot for debugging
    -- print("[Loot Crate] Stored potential loot:", table.concat(self.PotentialLoot, ", "))
end

-- Called when a player presses USE (+use) on the entity
function ENT:Use(activator, caller)
    -- Check if the activator is a valid player and the crate has loot
    if not IsValid(activator) or not activator:IsPlayer() then return end
    if not self.PotentialLoot or #self.PotentialLoot == 0 then
        activator:ChatPrint("[Combine Loot] This cache appears to be empty.")
        -- Consider removing empty crates immediately? Or let them time out?
        -- self:Remove()
        return
    end

    -- Pick ONE random item from the stored potential loot
    local itemToGive = table.Random(self.PotentialLoot)
    if not itemToGive then
         activator:ChatPrint("[Combine Loot] Failed to determine loot item.")
         self:Remove() -- Remove crate even on failure here
         return
    end

    -- Attempt to give the item to the player
    local given = activator:Give(itemToGive)

    if given then
        activator:ChatPrint(string.format("[Combine Loot] Retrieved: %s", itemToGive))
        -- Play a success sound (optional)
        activator:EmitSound("items/itempickup.wav")
        self:Remove() -- Successfully looted, remove the crate
    else
        -- Handle cases where Give might fail (e.g., invalid weapon class somehow, player inventory full?)
        activator:ChatPrint(string.format("[Combine Loot] Could not retrieve item: %s (Perhaps you already have it or it's invalid?)", itemToGive))
        -- Decide if the crate should be removed even if Give fails
        self:Remove()
    end

    -- Prevent default use action if needed (unlikely for SIMPLE_USE)
    -- return true
end

-- Optional: Make it glow slightly when looked at?
function ENT:StartTouch(entity)
    if IsValid(entity) and entity:IsPlayer() and self.PotentialLoot and #self.PotentialLoot > 0 then
        self:SetColor(Color(200, 255, 200, 255)) -- Slight green glow
    end
end

function ENT:EndTouch(entity)
     self:SetColor(Color(255, 255, 255, 255)) -- Reset color
end