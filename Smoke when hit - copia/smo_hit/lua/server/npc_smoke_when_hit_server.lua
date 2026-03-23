local SMOKE_ENTITY = "cup_smoke_maniac"

local CombineNPCs = {
    npc_combine_s       = true,
    npc_metropolice     = true,
    npc_hunter          = true,
    npc_manhack         = true,
    npc_turret_floor    = true,
    npc_turret_ceiling  = true,
    npc_turret_ground   = true,
    npc_apcdriver       = true,
}

local TurretClasses = {
    npc_turret_floor    = true,
    npc_turret_ceiling  = true,
    npc_turret_ground   = true,
}

-- Cache ConVar lookups once rather than calling GetConVar() on every damage event
local cvChance      = GetConVar(NPC_SMOKE_WH.CVars.Chance)
local cvExtraChance = GetConVar(NPC_SMOKE_WH.CVars.ExtraChance)
local cvExtraMax    = GetConVar(NPC_SMOKE_WH.CVars.ExtraMax)
local cvTurrets     = GetConVar(NPC_SMOKE_WH.CVars.Turrets)

local cooldown = {}

-- Clean up dead entities from the cooldown table to prevent memory leaks
hook.Add("EntityRemoved", "NPCSmokeWhenHit_Cleanup", function(ent)
    cooldown[ent] = nil
end)

local function IsValidCombine(ent)
    -- IsValid guards against NULL entities passed by certain damage sources
    if not IsValid(ent) then return false end
    if not CombineNPCs[ent:GetClass()] then return false end
    if TurretClasses[ent:GetClass()] then return cvTurrets:GetBool() end
    return true
end

hook.Add("EntityTakeDamage", "NPCSmokeWhenHit", function(ent)
    if not IsValidCombine(ent) then return end

    -- Bail early if the entity is already dead or dying
    if ent:Health() <= 0 then return end

    local ct = CurTime()
    if cooldown[ent] and cooldown[ent] > ct then return end
    cooldown[ent] = ct + 0.25

    -- Roll for the primary drop chance first (cheapest bail-out)
    if math.Rand(0, 1) > cvChance:GetFloat() then return end

    local count = 1
    if math.Rand(0, 1) <= cvExtraChance:GetFloat() then
        count = count + math.random(0, cvExtraMax:GetInt())
    end

    local pos = ent:GetPos()

    for i = 1, count do
        local smoke = ents.Create(SMOKE_ENTITY)
        -- Use break instead of return so one failed spawn doesn't abort the rest
        if not IsValid(smoke) then break end
        smoke:SetPos(pos + VectorRand(-1, 1) * 30)
        smoke:Spawn()
    end
end)
