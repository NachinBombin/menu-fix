--[[-------------------------------------------------------------------------
    Martyrdom - Shared ConVars
    Unified configuration for all NPC death-drop item types:
      Grenade, Smoke, Mine, Flashbang (Mindblock), Toxin
---------------------------------------------------------------------------]]

local F = { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }

-- =========================================================================
-- Global
-- =========================================================================
CreateConVar("mrd_entity_cap",  "40", F,
    "Max total Martyrdom-spawned entities alive at once (all types combined). " ..
    "Prevents burst NPC deaths flooding the server.", 0, 500)

-- =========================================================================
-- Shared NPC toggle flags
-- NOTE: Manhack and Strider toggles are item-specific (see below).
-- =========================================================================
CreateConVar("mrd_include_hunter",  "0", F, "Include Hunters (npc_hunter) for ALL item types? 1=Yes 0=No",        0, 1)
CreateConVar("mrd_include_scanner", "0", F, "Include City/Claw Scanners for ALL item types? 1=Yes 0=No",          0, 1)

-- =========================================================================
-- Grenade  (entity: zbase_ezt_grenade)
-- NPC toggles: Manhack ✓  Hunter ✓  Scanner ✓  Strider ✗
-- Behavior: initial drop + optional extra burst
-- =========================================================================
CreateConVar("mrd_grenade_enabled",       "1",  F, "Master enable for grenade drops. 1=On 0=Off.",                  0, 1)
CreateConVar("mrd_grenade_chance",        "25", F, "% chance a target NPC drops any grenade on death.",             0, 100)
CreateConVar("mrd_grenade_extra_count",   "5",  F, "Max extra grenades (randomised 1 to this value).",              0, 40)
CreateConVar("mrd_grenade_extra_chance",  "50", F, "If a grenade drops, % chance the extras also spawn.",           0, 100)
CreateConVar("mrd_grenade_manhack",       "0",  F, "Include Manhacks for grenade drops? 1=Yes 0=No.",               0, 1)

-- =========================================================================
-- Smoke Canister  (entity: cup_smoke_maniac)
-- NPC toggles: Manhack ✓  Hunter ✓  Scanner ✓  Strider ✗
-- Behavior: initial drop + optional extra burst
-- =========================================================================
CreateConVar("mrd_smoke_enabled",         "1",  F, "Master enable for smoke drops. 1=On 0=Off.",                    0, 1)
CreateConVar("mrd_smoke_chance",          "25", F, "% chance a target NPC drops any smoke canister on death.",      0, 100)
CreateConVar("mrd_smoke_extra_count",     "3",  F, "Max extra smokes (randomised 1 to this value).",                0, 20)
CreateConVar("mrd_smoke_extra_chance",    "40", F, "If a smoke drops, % chance the extras also spawn.",             0, 100)
CreateConVar("mrd_smoke_manhack",         "0",  F, "Include Manhacks for smoke drops? 1=Yes 0=No.",                 0, 1)

-- =========================================================================
-- Combine Mine  (entity: combine_mine)
-- NPC toggles: Manhack ✗  Hunter ✓  Scanner ✓  Strider ✓ (special: 2 guaranteed)
-- Behavior: single chance-based drop; Strider always drops 2
-- =========================================================================
CreateConVar("mrd_mine_enabled",          "1",  F, "Master enable for mine drops. 1=On 0=Off.",                     0, 1)
CreateConVar("mrd_mine_chance",           "15", F, "% chance a target NPC drops a mine on death.",                  0, 100)
CreateConVar("mrd_mine_strider",          "0",  F, "Striders drop 2 guaranteed mines on death? 1=Yes 0=No.",        0, 1)

-- =========================================================================
-- Flashbang / Mindblock  (entity: cup_flash)
-- NPC toggles: Manhack ✓  Hunter ✓  Scanner ✓  Strider ✗
-- Behavior: single drop only (no extras)
-- =========================================================================
CreateConVar("mrd_flash_enabled",         "1",  F, "Master enable for flashbang drops. 1=On 0=Off.",                0, 1)
CreateConVar("mrd_flash_chance",          "20", F, "% chance a target NPC drops a flashbang on death.",             0, 100)
CreateConVar("mrd_flash_manhack",         "0",  F, "Include Manhacks for flashbang drops? 1=Yes 0=No.",             0, 1)

-- =========================================================================
-- Toxin Canister  (entity: cup_smoke_bo)
-- NPC toggles: Manhack ✓  Hunter ✓  Scanner ✓  Strider ✗
-- Behavior: initial drop + optional extra burst
-- =========================================================================
CreateConVar("mrd_toxin_enabled",         "1",  F, "Master enable for toxin drops. 1=On 0=Off.",                    0, 1)
CreateConVar("mrd_toxin_chance",          "25", F, "% chance a target NPC drops any toxin canister on death.",      0, 100)
CreateConVar("mrd_toxin_extra_count",     "3",  F, "Max extra toxins (randomised 1 to this value).",                0, 20)
CreateConVar("mrd_toxin_extra_chance",    "40", F, "If a toxin drops, % chance the extras also spawn.",             0, 100)
CreateConVar("mrd_toxin_manhack",         "0",  F, "Include Manhacks for toxin drops? 1=Yes 0=No.",                 0, 1)
