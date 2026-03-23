--[[-------------------------------------------------------------------------
    Server-side logic for Combine Loot Drops (Crate Spawn Chance)
    OPTIMIZED:
      - C.NPCTargetSet      : O(1) hash lookup replaces table.HasValue scan
      - C.PoolsReady        : single boolean replaces table.Count() every kill
      - C.CrateSpawnChanceConVar : cached object replaces GetConVar() every kill
      - C.ChanceConVarList  : ordered array with pool refs replaces per-iteration
                              hash lookups into C.ChanceConVars / C.GeneratedPools
      - math.random(1,#pool): direct index replaces table.Random() (avoids
                              internal table.Count inside that function)
      - lazy successfulItems: table only allocated when at least one item rolls
---------------------------------------------------------------------------]]
AddCSLuaFile("autorun/my_combine_loot_shared.lua")
AddCSLuaFile("autorun/client/my_combine_loot_client.lua")
AddCSLuaFile("entities/my_combine_loot_crate/shared.lua")

local C = MY_COMBINE_LOOT
if not C or not C.LootConfig or not C.CrateSpawnChanceConVarName then
    ErrorNoHalt("[Combine Loot] Shared config not loaded or incomplete! Server script cannot run.\n")
    return
end

print("[Combine Loot] Server script loading (Crate Spawn Chance).")

-- ---------------------------------------------------------------------------
-- Localized globals
-- ---------------------------------------------------------------------------
local ents_Create     = ents.Create
local ents_GetStored  = ents.GetStored
local hook_Add        = hook.Add
local ipairs          = ipairs
local IsValid         = IsValid
local list_Get        = list.Get
local math_random     = math.random
local pairs           = pairs
local pcall           = pcall
local print           = print
local string_format   = string.format
local table_insert    = table.insert
local timer_Simple    = timer.Simple
local tostring        = tostring
local type            = type
local Vector          = Vector
local Angle           = Angle
local weapons_Exists  = weapons.Exists
local weapons_GetList = weapons.GetList
local table_HasValue  = table.HasValue  -- still needed inside BuildLootPools
-- NOTE: GetConVar is intentionally NOT localized here.
--       C.CrateSpawnChanceConVar is cached at shared load time so the hook
--       never needs to call GetConVar() at all.
-- ***************************************************************************

-- ---------------------------------------------------------------------------
-- BuildLootPools
-- Runs once, 5 s after map load.  Populates C.GeneratedPools, sets
-- C.PoolsReady, and builds C.ChanceConVarList for the optimized hook loop.
-- ---------------------------------------------------------------------------
function C.BuildLootPools()
    print("[Combine Loot] Starting loot pool generation...")
    local startTime = SysTime()
    local totalItemsFound = 0

    -- Reset state
    C.GeneratedPools  = {}
    C.PoolsReady      = false
    C.ChanceConVarList = {}

    for _, category in ipairs(C.Categories) do
        C.GeneratedPools[category] = {}
    end

    -- -----------------------------------------------------------------------
    -- Pass 1: weapons registered in the weapon registry
    -- -----------------------------------------------------------------------
    local weaponList = weapons_GetList()
    for _, wepData in ipairs(weaponList) do
        local wepClass = wepData.ClassName
        if not wepClass or wepClass == "" then continue end
        for _, category in ipairs(C.Categories) do
            local config = C.LootConfig[category]
            if not config then continue end
            if config.blacklist and table_HasValue(config.blacklist, wepClass) then goto next_category_wep end
            if config.whitelist and table_HasValue(config.whitelist, wepClass) then
                table_insert(C.GeneratedPools[category], wepClass)
                goto next_category_wep
            end
            if config.filter and config.filter(wepClass, wepData) then
                table_insert(C.GeneratedPools[category], wepClass)
                goto next_category_wep
            end
            if config.default and table_HasValue(config.default, wepClass) and weapons_Exists(wepClass) then
                table_insert(C.GeneratedPools[category], wepClass)
                goto next_category_wep
            end
            ::next_category_wep::
        end
    end

    -- -----------------------------------------------------------------------
    -- Pass 2: spawnable entities
    -- -----------------------------------------------------------------------
    local entityList = list_Get("SpawnableEntities")
    for entClass, _ in pairs(entityList) do
        if not entClass or entClass == "" then continue end
        local entData = nil
        local success, result = pcall(ents_GetStored, entClass)
        if success then entData = result end
        if type(entData) ~= "table" then entData = {} end
        for _, category in ipairs(C.Categories) do
            local config = C.LootConfig[category]
            if not config then continue end
            if config.blacklist and table_HasValue(config.blacklist, entClass) then goto next_category_ent end
            if config.whitelist and table_HasValue(config.whitelist, entClass) then
                table_insert(C.GeneratedPools[category], entClass)
                goto next_category_ent
            end
            if config.filter_ent and config.filter_ent(entClass, entData) then
                table_insert(C.GeneratedPools[category], entClass)
                goto next_category_ent
            end
            if config.default and table_HasValue(config.default, entClass) and entityList[entClass] then
                table_insert(C.GeneratedPools[category], entClass)
                goto next_category_ent
            end
            ::next_category_ent::
        end
    end

    -- -----------------------------------------------------------------------
    -- Consolidate: deduplicate each pool, log counts, build ChanceConVarList
    -- -----------------------------------------------------------------------
    print("[Combine Loot] Consolidating loot pools...")
    for _, category in ipairs(C.Categories) do        -- ipairs preserves order
        local pool   = C.GeneratedPools[category]
        local unique = {}
        local seen   = {}
        for _, itemClass in ipairs(pool) do
            if not seen[itemClass] then
                table_insert(unique, itemClass)
                seen[itemClass] = true
            end
        end
        C.GeneratedPools[category] = unique

        local count = #unique
        if count > 0 then
            print(string_format("  - Category '%s': Found %d unique items.", category, count))
            totalItemsFound = totalItemsFound + count

            -- OPT: Build the flat array the hook loop uses.
            -- Storing a direct reference to the final pool table means the
            -- hook never has to index C.GeneratedPools by string at kill-time.
            table_insert(C.ChanceConVarList, {
                convar = C.ChanceConVars[category],   -- cached ConVar object
                pool   = unique,                       -- direct pool reference
                size   = count,                        -- cached #pool
            })
        end
    end

    -- OPT: Set the single boolean the hook checks.  Only true if at least one
    -- category has items — avoids table.Count(GeneratedPools) every kill.
    C.PoolsReady = (#C.ChanceConVarList > 0)

    local endTime = SysTime()
    print(string_format(
        "[Combine Loot] Pool generation complete. %d total items across %d active categories in %.4f s.",
        totalItemsFound, #C.ChanceConVarList, endTime - startTime
    ))
end

-- ---------------------------------------------------------------------------
-- InitPostEntity — kick off pool build 5 s after map load
-- ---------------------------------------------------------------------------
hook_Add("InitPostEntity", "CombineLootBuildPools", function()
    timer_Simple(5, function()
        if C and type(C.BuildLootPools) == "function" then
            C.BuildLootPools()
        else
            ErrorNoHalt("[Combine Loot] BuildLootPools not found during InitPostEntity timer!\n")
        end
    end)
end)

-- ---------------------------------------------------------------------------
-- OnNPCKilled — OPTIMIZED hot path
-- ---------------------------------------------------------------------------
hook_Add("OnNPCKilled", "CombineLootCacheSpawn_WithChance", function(npc, attacker, inflictor)

    -- OPT 1: Single boolean instead of table.Count() on every kill.
    if not C.PoolsReady then return end

    -- OPT 2: IsValid guard (cheap engine call, always keep first after PoolsReady).
    if not IsValid(npc) then return end

    -- OPT 3: O(1) hash lookup instead of table.HasValue linear scan.
    --        This is the most important early-exit: fires for EVERY NPC death
    --        server-wide, including citizens, rebels, and addon NPCs.
    if not C.NPCTargetSet[npc:GetClass()] then return end

    local npcDeathPos = npc:GetPos()

    -- OPT 4: successfulItems is nil until the first successful roll.
    --        No table allocation happens on the (statistically common) case
    --        where nothing rolls successfully.
    local successfulItems = nil

    -- OPT 5: Iterate C.ChanceConVarList — a pre-built ordered array of
    --        {convar, pool, size} structs.  Eliminates:
    --          • C.ChanceConVars[category]    (hash lookup per iteration)
    --          • C.GeneratedPools[category]   (hash lookup per iteration)
    --          • nil-guard on chanceConvar    (all entries are guaranteed valid)
    --        Direct pool indexing with math_random(1, entry.size) eliminates
    --        table.Random's internal table.Count call.
    local list     = C.ChanceConVarList
    local listSize = #list
    for i = 1, listSize do
        local entry = list[i]
        if math_random(1, 100) <= entry.convar:GetInt() then
            -- Direct index: pool is a pure sequence, size is pre-cached.
            local item = entry.pool[math_random(1, entry.size)]
            if item then
                -- OPT 4 (cont.): Lazy allocate on first successful roll only.
                if not successfulItems then
                    successfulItems = {}
                end
                successfulItems[#successfulItems + 1] = item
            end
        end
    end

    -- Nothing rolled — exit without any further work.
    if not successfulItems then return end

    -- OPT 6: C.CrateSpawnChanceConVar is the cached ConVar object stored at
    --        shared load time.  No GetConVar() string lookup at kill-time.
    if math_random(1, 100) <= C.CrateSpawnChanceConVar:GetInt() then
        local spawnPos = npcDeathPos + Vector(0, 0, 5)
        local spawnAng = Angle(0, math_random(0, 360), 0)

        local crate = ents_Create("my_combine_loot_crate")
        if IsValid(crate) then
            crate:SetPos(spawnPos)
            crate:SetAngles(spawnAng)
            crate:Spawn()
            crate:Activate()
            crate:SetPotentialLoot(successfulItems)

            local phys = crate:GetPhysicsObject()
            if IsValid(phys) then
                phys:ApplyForceCenter(Vector(0, 0, math_random(50, 150)))
            end
        else
            print("[Combine Loot] Error: Failed to create 'my_combine_loot_crate' entity!")
        end
    end
end)

print("[Combine Loot] Server script (Crate Spawn Chance) loaded successfully.")
