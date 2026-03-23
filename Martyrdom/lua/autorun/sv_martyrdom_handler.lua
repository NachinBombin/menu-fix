--[[-------------------------------------------------------------------------
    Martyrdom - Server Logic  (sv_martyrdom_handler.lua)

    Single OnNPCKilled hook replacing 5 separate addon hooks.
    Faithfully preserves all per-item behaviours from the original addons:

      Grenade   (zbase_ezt_grenade)  - initial + optional burst, Manhack toggle
      Smoke     (cup_smoke_maniac)   - initial + optional burst, Manhack toggle
      Mine      (combine_mine)       - single chance drop + drop sound,
                                       Strider guaranteed-2 special case
      Flashbang (cup_flash)          - single drop only, Manhack toggle
      Toxin     (cup_smoke_bo)       - initial + optional burst, Manhack toggle

    All five types share:
      - Hunter toggle  (mrd_include_hunter)
      - Scanner toggle (mrd_include_scanner)
      - Global entity cap (mrd_entity_cap)

    Optimisations applied:
      ● ConVar values stored as plain Lua numbers/bools on startup,
        refreshed via cvars.AddChangeCallback - zero cost on the hot path
      ● NPC lookup table rebuilt only when a toggle convar changes
      ● Offset Vectors created lazily inside the extra-spawn loop,
        only after both roll checks succeed
      ● Closure capture bug fixed: offset captured as a local per-iteration
      ● Single entity counter with CallOnRemove enforces the global cap
      ● Mine drop sound string built once at startup (not on each death)
      ● Removed bogus FindMetaTable("ConVar") chain
      ● Removed game.GetMap() guard in timer callbacks
---------------------------------------------------------------------------]]

-- =========================================================================
-- Entity classnames - edit here if your addon names differ
-- =========================================================================
local ENT = {
    grenade = "zbase_ezt_grenade",
    smoke   = "cup_smoke_maniac",
    mine    = "combine_mine",
    flash   = "cup_flash",
    toxin   = "cup_smoke_bo",
}

-- Pre-build mine drop sound string once (original code called math.random at
-- module load time which was fine, but let's make it explicit and safe)
local MINE_SOUNDS = {
    "physics/metal/metal_solid_impact_hard1.wav",
    "physics/metal/metal_solid_impact_hard2.wav",
    "physics/metal/metal_solid_impact_hard3.wav",
    "physics/metal/metal_solid_impact_hard4.wav",
    "physics/metal/metal_solid_impact_hard5.wav",
}

local EXTRA_DELAY = 0.05  -- seconds between each extra entity in a burst

-- =========================================================================
-- Cached ConVar values  (plain Lua types, no ConVar object overhead at runtime)
-- =========================================================================
local cv = {}

local function RefreshCache()
    -- Global
    cv.entity_cap          = GetConVar("mrd_entity_cap"):GetInt()
    -- Shared NPC toggles
    cv.include_hunter      = GetConVar("mrd_include_hunter"):GetBool()
    cv.include_scanner     = GetConVar("mrd_include_scanner"):GetBool()
    -- Grenade
    cv.grenade_enabled     = GetConVar("mrd_grenade_enabled"):GetBool()
    cv.grenade_chance      = GetConVar("mrd_grenade_chance"):GetInt()
    cv.grenade_extra_count = GetConVar("mrd_grenade_extra_count"):GetInt()
    cv.grenade_extra_chance= GetConVar("mrd_grenade_extra_chance"):GetInt()
    cv.grenade_manhack     = GetConVar("mrd_grenade_manhack"):GetBool()
    -- Smoke
    cv.smoke_enabled       = GetConVar("mrd_smoke_enabled"):GetBool()
    cv.smoke_chance        = GetConVar("mrd_smoke_chance"):GetInt()
    cv.smoke_extra_count   = GetConVar("mrd_smoke_extra_count"):GetInt()
    cv.smoke_extra_chance  = GetConVar("mrd_smoke_extra_chance"):GetInt()
    cv.smoke_manhack       = GetConVar("mrd_smoke_manhack"):GetBool()
    -- Mine
    cv.mine_enabled        = GetConVar("mrd_mine_enabled"):GetBool()
    cv.mine_chance         = GetConVar("mrd_mine_chance"):GetInt()
    cv.mine_strider        = GetConVar("mrd_mine_strider"):GetBool()
    -- Flash
    cv.flash_enabled       = GetConVar("mrd_flash_enabled"):GetBool()
    cv.flash_chance        = GetConVar("mrd_flash_chance"):GetInt()
    cv.flash_manhack       = GetConVar("mrd_flash_manhack"):GetBool()
    -- Toxin
    cv.toxin_enabled       = GetConVar("mrd_toxin_enabled"):GetBool()
    cv.toxin_chance        = GetConVar("mrd_toxin_chance"):GetInt()
    cv.toxin_extra_count   = GetConVar("mrd_toxin_extra_count"):GetInt()
    cv.toxin_extra_chance  = GetConVar("mrd_toxin_extra_chance"):GetInt()
    cv.toxin_manhack       = GetConVar("mrd_toxin_manhack"):GetBool()
end

-- =========================================================================
-- NPC target lookup tables
-- Each item type has its own because Manhack eligibility differs per item,
-- and Mine has no Manhack toggle at all.
-- =========================================================================
local TARGET = {
    grenade = {},
    smoke   = {},
    mine    = {},   -- no manhack
    flash   = {},
    toxin   = {},
}

-- Base Combine classes eligible for ALL types
local BASE_CLASSES = {
    npc_combine_s     = true,
    npc_metropolice   = true,
    npc_prisonguard   = true,
    npc_combine_elite = true,
}

local function RebuildNPCTables()
    local hunter  = cv.include_hunter
    local scanner = cv.include_scanner

    -- Types that support Manhack (per-item toggle)
    for _, key in ipairs({ "grenade", "smoke", "flash", "toxin" }) do
        local t = {}
        for cls in pairs(BASE_CLASSES) do t[cls] = true end
        if hunter  then t["npc_hunter"]      = true end
        if scanner then t["npc_cscanner"]    = true; t["npc_clawscanner"] = true end
        -- Each item has its own manhack flag
        if cv[key .. "_manhack"] then t["npc_manhack"] = true end
        TARGET[key] = t
    end

    -- Mine: no manhack, but has Strider (handled separately in the hook)
    local mine_t = {}
    for cls in pairs(BASE_CLASSES) do mine_t[cls] = true end
    if hunter  then mine_t["npc_hunter"]     = true end
    if scanner then mine_t["npc_cscanner"]   = true; mine_t["npc_clawscanner"] = true end
    TARGET.mine = mine_t
end

-- =========================================================================
-- Change callbacks - keep caches fresh with zero per-death overhead
-- =========================================================================
local function RegisterCallbacks()
    -- All numeric/bool convars that feed RefreshCache
    local allCVars = {
        "mrd_entity_cap",
        "mrd_grenade_enabled", "mrd_grenade_chance", "mrd_grenade_extra_count", "mrd_grenade_extra_chance",
        "mrd_smoke_enabled",   "mrd_smoke_chance",   "mrd_smoke_extra_count",   "mrd_smoke_extra_chance",
        "mrd_mine_enabled",    "mrd_mine_chance",
        "mrd_flash_enabled",   "mrd_flash_chance",
        "mrd_toxin_enabled",   "mrd_toxin_chance",   "mrd_toxin_extra_count",   "mrd_toxin_extra_chance",
    }
    for _, name in ipairs(allCVars) do
        cvars.AddChangeCallback(name, RefreshCache, "MRD_NumericCache")
    end

    -- Toggle convars rebuild both the cache AND the NPC tables
    local toggleCVars = {
        "mrd_include_hunter", "mrd_include_scanner", "mrd_mine_strider",
        "mrd_grenade_manhack", "mrd_smoke_manhack", "mrd_flash_manhack", "mrd_toxin_manhack",
    }
    for _, name in ipairs(toggleCVars) do
        cvars.AddChangeCallback(name, function()
            RefreshCache()
            RebuildNPCTables()
        end, "MRD_ToggleCache")
    end
end

-- =========================================================================
-- Global entity cap tracking
-- =========================================================================
local liveCount = 0

local function TrackEntity(ent)
    liveCount = liveCount + 1
    ent:CallOnRemove("MRD_Track", function()
        liveCount = math.max(0, liveCount - 1)
    end)
end

-- =========================================================================
-- Core spawn function  (shared by all item types)
-- Returns true on success, false if cap reached or entity invalid.
-- =========================================================================
local function SpawnDrop(entityClass, pos, offset, applyPhysics, isMine)
    if liveCount >= cv.entity_cap then return false end

    local ent = ents.Create(entityClass)
    if not IsValid(ent) then
        ErrorNoHalt(("[Martyrdom] Could not create '%s'. Is the required addon installed?\n"):format(entityClass))
        return false
    end

    ent:SetPos(pos + offset)
    ent:Spawn()
    ent:Activate()

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        if isMine then
            -- Mines: original had EnableMotion + stronger, wider scatter
            phys:EnableMotion(true)
            phys:Wake()
            phys:ApplyForceCenter(VectorRand():GetNormal() * math.Rand(15, 40))
            phys:AddAngleVelocity(VectorRand() * math.Rand(-60, 60))
        elseif applyPhysics then
            -- Other items: lighter nudge for natural scatter
            phys:ApplyForceCenter(VectorRand():GetNormal() * math.Rand(20, 60))
            phys:AddAngleVelocity(VectorRand() * math.Rand(-20, 20))
        end
    end

    TrackEntity(ent)
    return true
end

-- =========================================================================
-- Drop handlers - one per item type, preserving original logic exactly
-- =========================================================================

-- Shared helper: spawn initial + optional extras with staggered timers
local function HandleBurstDrop(entityClass, deathPos, chance, maxExtra, extraChance)
    if math.random(100) > chance then return end

    -- First entity spawns immediately
    SpawnDrop(entityClass, deathPos, Vector(0, 0, 6), true, false)

    if maxExtra <= 0 then return end
    if math.random(100) > extraChance then return end

    local numExtra = math.random(1, maxExtra)
    for i = 1, numExtra do
        -- Capture offset as a local so each timer closure owns its own value
        local offset = Vector(
            math.Rand(-12, 12),
            math.Rand(-12, 12),
            math.Rand(4, 14)
        )
        timer.Simple(i * EXTRA_DELAY, function()
            SpawnDrop(entityClass, deathPos, offset, true, false)
        end)
    end
end

local function HandleGrenade(deathPos)
    if not cv.grenade_enabled then return end
    HandleBurstDrop(ENT.grenade, deathPos,
        cv.grenade_chance, cv.grenade_extra_count, cv.grenade_extra_chance)
end

local function HandleSmoke(deathPos)
    if not cv.smoke_enabled then return end
    HandleBurstDrop(ENT.smoke, deathPos,
        cv.smoke_chance, cv.smoke_extra_count, cv.smoke_extra_chance)
end

local function HandleFlash(deathPos)
    if not cv.flash_enabled then return end
    if math.random(100) > cv.flash_chance then return end
    -- Single drop, minor scatter offset (original behaviour)
    local offset = Vector(math.random(-5, 5), math.random(-5, 5), math.random(3, 8))
    SpawnDrop(ENT.flash, deathPos, offset, false, false)
end

local function HandleToxin(deathPos)
    if not cv.toxin_enabled then return end
    HandleBurstDrop(ENT.toxin, deathPos,
        cv.toxin_chance, cv.toxin_extra_count, cv.toxin_extra_chance)
end

-- Mine has two distinct code paths (standard NPC vs Strider)
local function HandleMineStandard(deathPos)
    if not cv.mine_enabled then return end
    if math.random(100) > cv.mine_chance then return end

    local offset = VectorRand() * math.Rand(3, 10) + Vector(0, 0, math.Rand(2, 5))
    local spawnPos = deathPos + offset
    if SpawnDrop(ENT.mine, deathPos, offset, false, true) then
        WorldSound(MINE_SOUNDS[math.random(#MINE_SOUNDS)], spawnPos, 75, math.random(95, 105))
    end
end

local function HandleMineStrider(deathPos)
    if not cv.mine_enabled then return end
    -- Guaranteed 2 mines with separated offsets (original behaviour)
    local offset1 = VectorRand() * math.Rand(20, 50) + Vector(0, 0, 10)
    local offset2 = VectorRand() * math.Rand(20, 50) + Vector(0, 0, 10)

    -- Keep retrying offset2 until the two offsets are far enough apart
    local maxTries = 10
    local tries = 0
    while (offset1 - offset2):LengthSqr() < 100 and tries < maxTries do
        offset2 = VectorRand() * math.Rand(20, 50) + Vector(0, 0, 10)
        tries = tries + 1
    end

    local pos1 = deathPos + offset1
    local pos2 = deathPos + offset2
    if SpawnDrop(ENT.mine, deathPos, offset1, false, true) then
        WorldSound(MINE_SOUNDS[math.random(#MINE_SOUNDS)], pos1, 75, math.random(95, 105))
    end
    if SpawnDrop(ENT.mine, deathPos, offset2, false, true) then
        WorldSound(MINE_SOUNDS[math.random(#MINE_SOUNDS)], pos2, 75, math.random(95, 105))
    end
end

-- =========================================================================
-- Single unified OnNPCKilled hook
-- =========================================================================
hook.Add("OnNPCKilled", "Martyrdom_OnNPCKilled", function(npc, attacker, inflictor)
    if not IsValid(npc) then return end

    local npcClass = npc:GetClass()

    -- --- Strider: mine-only special path ---
    if npcClass == "npc_strider" then
        if cv.mine_strider then
            HandleMineStrider(npc:GetPos())
        end
        return  -- Striders do not trigger any other drops
    end

    -- --- All other NPCs: check per-item target tables ---
    local deathPos = npc:GetPos() + npc:GetViewOffset()

    if TARGET.grenade[npcClass] then HandleGrenade(deathPos) end
    if TARGET.smoke[npcClass]   then HandleSmoke(deathPos)   end
    if TARGET.mine[npcClass]    then HandleMineStandard(deathPos) end
    if TARGET.flash[npcClass]   then HandleFlash(deathPos)   end
    if TARGET.toxin[npcClass]   then HandleToxin(deathPos)   end
end)

-- =========================================================================
-- Initialise on next tick so all ConVars from sh_ are guaranteed registered
-- =========================================================================
timer.Simple(0, function()
    RefreshCache()
    RebuildNPCTables()
    RegisterCallbacks()
end)
