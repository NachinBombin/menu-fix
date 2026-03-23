local MANHACK_ENTITY = "npc_manhack"

-- Base Combine NPCs that always qualify.
-- Excludes: manhacks, turrets, and scanners by design.
local BaseNPCs = {
    npc_combine_s   = true,
    npc_metropolice = true,
    npc_apcdriver   = true,
}

-- Optional NPCs gated behind their own menu toggles
local HunterClasses = {
    npc_hunter = true,
}

local APCClasses = {
    npc_apc = true,
}

-- Cache ConVar objects once at load time to avoid GetConVar() on every damage event
local cvChance      = GetConVar(NPC_MANHACK_SP.CVars.Chance)
local cvExtraChance = GetConVar(NPC_MANHACK_SP.CVars.ExtraChance)
local cvExtraMax    = GetConVar(NPC_MANHACK_SP.CVars.ExtraMax)
local cvHunters     = GetConVar(NPC_MANHACK_SP.CVars.Hunters)
local cvAPCs        = GetConVar(NPC_MANHACK_SP.CVars.APCs)

local cooldown = {}

-- Clean up cooldown entries when entities are removed to prevent memory leaks
hook.Add("EntityRemoved", "NPCManhackSpawner_Cleanup", function(ent)
    cooldown[ent] = nil
end)

local function IsValidTarget(ent)
    if not IsValid(ent) then return false end

    local class = ent:GetClass()

    if BaseNPCs[class]   then return true end
    if HunterClasses[class] then return cvHunters:GetBool() end
    if APCClasses[class]    then return cvAPCs:GetBool() end

    return false
end

-- Minimum units above the ground the manhack will spawn at
local SPAWN_HEIGHT = 48

local function SpawnManhack(pos)
    local manhack = ents.Create(MANHACK_ENTITY)
    if not IsValid(manhack) then return false end

    -- Scatter only on the horizontal plane
    local randVec  = VectorRand(-1, 1)
    local scatterPos = Vector(pos.x + randVec.x * 40, pos.y + randVec.y * 40, 0)

    -- Trace from well above the NPC down to ensure we always find the ground
    local traceStart = Vector(scatterPos.x, scatterPos.y, pos.z + 256)
    local traceEnd = Vector(scatterPos.x, scatterPos.y, pos.z - 1024)

    local trace = util.TraceLine({
        start  = traceStart,
        endpos = traceEnd,
        mask   = MASK_SOLID_BRUSHONLY,
    })

    -- Place the manhack above the floor; if no ground found, use NPC's height
    local spawnPos
    if trace.Hit then
        spawnPos = Vector(scatterPos.x, scatterPos.y, trace.HitPos.z + SPAWN_HEIGHT)
    else
        spawnPos = Vector(scatterPos.x, scatterPos.y, pos.z + SPAWN_HEIGHT)
    end

    manhack:SetPos(spawnPos)
    manhack:Spawn()
    manhack:Activate()

    return true
end

hook.Add("EntityTakeDamage", "NPCManhackSpawner", function(ent)
    if not IsValidTarget(ent) then return end
    if ent:Health() <= 0 then return end

    local ct = CurTime()
    if cooldown[ent] and cooldown[ent] > ct then return end
    cooldown[ent] = ct + 0.5

    if math.Rand(0, 1) > cvChance:GetFloat() then return end

    local count = 1
    if math.Rand(0, 1) <= cvExtraChance:GetFloat() then
        count = count + math.random(0, cvExtraMax:GetInt())
    end

    local pos = ent:GetPos()

    for i = 1, count do
        if not SpawnManhack(pos) then break end
    end
end)
