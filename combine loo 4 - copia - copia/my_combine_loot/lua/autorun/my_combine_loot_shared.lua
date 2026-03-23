--[[-------------------------------------------------------------------------
    Shared configuration for Combine Loot Drops (Crate Spawn Chance)
    OPTIMIZED: NPCTargetSet hash, cached CrateSpawnChanceConVar,
               ChanceConVarList ordered array (built by server after pools load)
---------------------------------------------------------------------------]]
MY_COMBINE_LOOT = MY_COMBINE_LOOT or {}
local C = MY_COMBINE_LOOT

-- -------------------------------------------------------------------------
-- NPCs that should drop loot
-- -------------------------------------------------------------------------
C.NPCTargets = {
    "npc_metrocop",
    "npc_combine_s",
    "npc_combine_elite",
}

-- O(1) hash-set version of NPCTargets — built immediately so it is ready
-- before any hook can fire (e.g. during a late map load with NPCs already
-- alive).  Server uses this instead of table.HasValue in OnNPCKilled.
C.NPCTargetSet = {}
for _, class in ipairs(C.NPCTargets) do
    C.NPCTargetSet[class] = true
end

-- -------------------------------------------------------------------------
-- Loot Categories
-- -------------------------------------------------------------------------
C.Categories = {
    "melee", "explosive", "utility", "pistol_light", "pistol_heavy",
    "shotgun", "smg", "rifle", "sniper", "machinegun"
}

-- -------------------------------------------------------------------------
-- ConVar name — kept for reference / UI labels; the live object is cached
-- below after CreateConVar returns it.
-- -------------------------------------------------------------------------
C.CrateSpawnChanceConVarName = "my_combine_loot_chance_crate_spawn"

-- -------------------------------------------------------------------------
-- Mapping of engine/custom ammo types
-- -------------------------------------------------------------------------
C.SortingAmmoTypes = { /* ... content remains the same ... */ }

-- -------------------------------------------------------------------------
-- Helper functions
-- -------------------------------------------------------------------------
function C.GetWeaponAmmoCategory(ammoType)
    if not ammoType or ammoType == "" then return nil end
    return C.SortingAmmoTypes[string.lower(ammoType)]
end

function C.GetPrimaryAmmoSafe(entData)
    if not entData or type(entData) ~= "table" then return nil end
    return entData.Primary and entData.Primary.Ammo or entData.Ammo
end

-- -------------------------------------------------------------------------
-- Loot Configuration
-- -------------------------------------------------------------------------
C.LootConfig = {}
C.LootConfig.melee        = { whitelist = {}, default = {}, blacklist = {"weapon_physgun", "gmod_tool"}, filter = function(class, ent) if class == "weapon_crowbar" or class == "weapon_stunstick" then return false end if not ent or type(ent) ~= "table" then return false end if ent.Slot == 0 then return true end if ent.IsTFAWeapon and ent.IsMelee then return true end if ent.ArcCW and ent.PrimaryBash then return true end if ent.ARC9 and ent.PrimaryBash then return true end if ent.IsSWCSWeapon and ent.IsKnife then return true end if ent.ArcticTacRP and ent.PrimaryMelee then return true end return false end, filter_ent = nil }
C.LootConfig.explosive    = { whitelist = {}, default = {"weapon_frag", "weapon_slam", "weapon_rpg"}, blacklist = {}, filter = function(class, ent) if not ent or type(ent) ~= "table" then return false end local ammo = C.GetPrimaryAmmoSafe(ent) if C.GetWeaponAmmoCategory(ammo) == "explosive" then return true end if ent.IsTFAWeapon and ent.IsGrenade then return true end if ent.ArcCW and ent.Throwing then return true end if ent.ARC9 and ent.Throwable then return true end if weapons.IsBasedOn(class, "cw_grenade_base") then return true end if weapons.IsBasedOn(class, "bobs_nade_base") then return true end return false end, filter_ent = nil }
C.LootConfig.utility      = { whitelist = {}, default = {"item_ammo_flare_round"}, blacklist = {"gmod_tool"}, filter = function(class, ent) if not ent or type(ent) ~= "table" then return false end local ammo = C.GetPrimaryAmmoSafe(ent) if C.GetWeaponAmmoCategory(ammo) == "utility" then return true end return false end, filter_ent = function(class, ent) if not ent or type(ent) ~= "table" then return false end if string.find(class, "flare") or string.find(class, "binocular") then return true end return false end }
C.LootConfig.pistol_light = { whitelist = {}, default = {}, blacklist = {"weapon_physgun", "gmod_tool"}, filter = function(class, ent) if class == "weapon_pistol" then return false end if not ent or type(ent) ~= "table" then return false end local ammo = C.GetPrimaryAmmoSafe(ent) if C.GetWeaponAmmoCategory(ammo) == "pistol_light" then return true end if ent.Slot == 1 then if C.GetWeaponAmmoCategory(ammo) == "pistol_heavy" then return false end return true end if ent.IsTFAWeapon and ent.Type == "Pistol" and C.GetWeaponAmmoCategory(ammo) ~= "pistol_heavy" then return true end if ent.ArcCW and C.GetWeaponAmmoCategory(ammo) == "pistol_light" then return true end if ent.ARC9 and ent.Class == "Pistol" and C.GetWeaponAmmoCategory(ammo) ~= "pistol_heavy" then return true end if ent.ArcticTacRP and ent.SubCatType == "1Pistol" and C.GetWeaponAmmoCategory(ammo) ~= "pistol_heavy" then return true end if weapons.IsBasedOn(class, "bobs_gun_base") and ent.Category == "Pistol" and C.GetWeaponAmmoCategory(ammo) ~= "pistol_heavy" then return true end if weapons.IsBasedOn(class, "mg_base") and ent.SubCategory == "Pistols" and C.GetWeaponAmmoCategory(ammo) ~= "pistol_heavy" then return true end return false end, filter_ent = nil }
C.LootConfig.pistol_heavy = { whitelist = {}, default = {}, blacklist = {"weapon_physgun", "gmod_tool"}, filter = function(class, ent) if class == "weapon_357" then return false end if not ent or type(ent) ~= "table" then return false end local ammo = C.GetPrimaryAmmoSafe(ent) if C.GetWeaponAmmoCategory(ammo) == "pistol_heavy" then return true end if ent.IsTFAWeapon and ent.Type == "Revolver" then return true end if ent.IsTFAWeapon and ent.Type == "Pistol" and C.GetWeaponAmmoCategory(ammo) == "pistol_heavy" then return true end if ent.ArcCW and C.GetWeaponAmmoCategory(ammo) == "pistol_heavy" then return true end if ent.ARC9 and ent.Class == "Revolver" then return true end if ent.ARC9 and ent.Class == "Pistol" and C.GetWeaponAmmoCategory(ammo) == "pistol_heavy" then return true end if ent.ArcticTacRP and ent.SubCatType == "1Pistol" and C.GetWeaponAmmoCategory(ammo) == "pistol_heavy" then return true end if weapons.IsBasedOn(class, "bobs_gun_base") and ent.Category == "Pistol" and C.GetWeaponAmmoCategory(ammo) == "pistol_heavy" then return true end if weapons.IsBasedOn(class, "mg_base") and ent.SubCategory == "Pistols" and C.GetWeaponAmmoCategory(ammo) == "pistol_heavy" then return true end return false end, filter_ent = nil }
C.LootConfig.shotgun      = { whitelist = {}, default = {}, blacklist = {"weapon_physgun", "gmod_tool"}, filter = function(class, ent) if class == "weapon_shotgun" then return false end if not ent or type(ent) ~= "table" then return false end local ammo = C.GetPrimaryAmmoSafe(ent) if C.GetWeaponAmmoCategory(ammo) == "shotgun" then return true end if ent.Slot == 3 and C.GetWeaponAmmoCategory(ammo) == "shotgun" then return true end if ent.IsTFAWeapon and ent.Type == "Shotgun" then return true end if ent.ArcCW and (C.GetWeaponAmmoCategory(ammo) == "shotgun" or ent.apex_shotgun) then return true end if ent.ARC9 and ent.Class == "Shotgun" then return true end if ent.ArcticTacRP and ent.SubCatType == "5Shotgun" then return true end if weapons.IsBasedOn(class, "bobs_gun_base") and ent.Category == "Shotgun" then return true end if weapons.IsBasedOn(class, "mg_base") and ent.SubCategory == "Shotguns" then return true end return false end, filter_ent = nil }
C.LootConfig.smg          = { whitelist = {}, default = {}, blacklist = {"weapon_physgun", "gmod_tool"}, filter = function(class, ent) if class == "weapon_smg1" then return false end if not ent or type(ent) ~= "table" then return false end local ammo = C.GetPrimaryAmmoSafe(ent) if C.GetWeaponAmmoCategory(ammo) == "smg" then return true end if ent.Slot == 2 and C.GetWeaponAmmoCategory(ammo) == "smg" then return true end if ent.IsTFAWeapon and ent.Type == "SMG" then return true end if ent.ArcCW and C.GetWeaponAmmoCategory(ammo) == "smg" then return true end if ent.ARC9 and ent.Class == "Submachine Gun" then return true end if ent.ArcticTacRP and ent.SubCatType == "3Submachine Gun" then return true end if weapons.IsBasedOn(class, "bobs_gun_base") and ent.Category == "Submachine" then return true end if weapons.IsBasedOn(class, "mg_base") and ent.SubCategory == "Submachine Guns" then return true end return false end, filter_ent = nil }
C.LootConfig.rifle        = { whitelist = {}, default = {}, blacklist = {"weapon_physgun", "gmod_tool"}, filter = function(class, ent) if class == "weapon_ar2" then return false end if not ent or type(ent) ~= "table" then return false end local ammo = C.GetPrimaryAmmoSafe(ent) if C.GetWeaponAmmoCategory(ammo) == "rifle" then return true end if ent.Slot == 2 and C.GetWeaponAmmoCategory(ammo) == "rifle" then return true end if ent.IsTFAWeapon and ent.Type == "Rifle" then return true end if ent.ArcCW and (C.GetWeaponAmmoCategory(ammo) == "rifle" or ent.apex_heavy) then return true end if ent.ARC9 and ent.Class == "Assault Rifle" then return true end if ent.ARC9 and ent.Class == "Battle Rifle" then return true end if ent.ArcticTacRP and ent.SubCatType == "2Assault Rifle" then return true end if weapons.IsBasedOn(class, "bobs_gun_base") and ent.Category == "Assault" then return true end if weapons.IsBasedOn(class, "mg_base") and ent.SubCategory == "Assault Rifles" then return true end return false end, filter_ent = nil }
C.LootConfig.sniper       = { whitelist = {}, default = {}, blacklist = {"weapon_physgun", "gmod_tool", "weapon_crossbow"}, filter = function(class, ent) if class == "weapon_crossbow" then return false end if not ent or type(ent) ~= "table" then return false end local ammo = C.GetPrimaryAmmoSafe(ent) if C.GetWeaponAmmoCategory(ammo) == "sniper" then return true end if ent.Slot == 3 and C.GetWeaponAmmoCategory(ammo) == "sniper" then return true end if ent.IsTFAWeapon and ent.Type == "Sniper Rifle" then return true end if ent.ArcCW and (C.GetWeaponAmmoCategory(ammo) == "sniper" or ent.apex_sniper) then return true end if ent.ARC9 and ent.Class == "Sniper Rifle" then return true end if ent.ArcticTacRP and ent.SubCatType == "6Sniper Rifle" then return true end if weapons.IsBasedOn(class, "bobs_gun_base") and ent.Category == "Sniper" then return true end if weapons.IsBasedOn(class, "mg_base") and ent.SubCategory == "Sniper Rifles" then return true end return false end, filter_ent = nil }
C.LootConfig.machinegun   = { whitelist = {}, default = {}, blacklist = {"weapon_physgun", "gmod_tool"}, filter = function(class, ent) if not ent or type(ent) ~= "table" then return false end local ammo = C.GetPrimaryAmmoSafe(ent) if C.GetWeaponAmmoCategory(ammo) == "machinegun" then return true end if ent.Slot == 3 and (string.find(class, "mg") or string.find(class,"machinegun")) then return true end if ent.IsTFAWeapon and ent.Type == "LMG" then return true end if ent.ArcCW and ent.Class == "Machine Gun" then return true end if ent.ARC9 and ent.Class == "Machine Gun" then return true end if ent.ArcticTacRP and ent.SubCatType == "4Machine Gun" then return true end if weapons.IsBasedOn(class, "bobs_gun_base") and ent.Category == "Machinegun" then return true end if weapons.IsBasedOn(class, "mg_base") and ent.SubCategory == "Machineguns" then return true end if ent.Slot == 3 and C.GetWeaponAmmoCategory(ammo) ~= "shotgun" and C.GetWeaponAmmoCategory(ammo) ~= "sniper" and C.GetWeaponAmmoCategory(ammo) ~= "rifle" then return true end return false end, filter_ent = nil }

-- -------------------------------------------------------------------------
-- ConVar creation
-- -------------------------------------------------------------------------
local defaultChance      = 15
local defaultCrateChance = 75

-- OPT: Store the ConVar *object* directly on C so the server hook never has
--      to call GetConVar() (a string registry lookup) at kill-time.
C.CrateSpawnChanceConVar = CreateConVar(
    C.CrateSpawnChanceConVarName,
    tostring(defaultCrateChance),
    {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY},
    "Chance (0-100) for a loot crate to spawn if potential items exist.",
    0, 100
)
print("[Combine Loot] Created Crate Spawn Chance ConVar: "
    .. C.CrateSpawnChanceConVarName
    .. " (Default: " .. defaultCrateChance .. "%)")

-- Category ConVars — still keyed by name for the UI, but also collected into
-- ChanceConVarList (an ordered array with pool refs) by BuildLootPools()
-- on the server after pools are ready.  ChanceConVarList is the structure
-- the hot-path loop actually uses.
C.ChanceConVars    = {}   -- [category] = ConVar object  (used by client UI)
C.ChanceConVarList = {}   -- built by server; [{convar, pool}]  (used by hook)

print("[Combine Loot] Creating Drop Chance ConVars...")
for _, category in ipairs(C.Categories) do
    local convarName = "my_combine_loot_chance_" .. category
    local description = "Drop chance (0-100) for the " .. category .. " category to contribute items."
    C.ChanceConVars[category] = CreateConVar(
        convarName,
        tostring(defaultChance),
        {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY},
        description,
        0, 100
    )
end
print("[Combine Loot] ConVar creation complete.")

-- PoolsReady flag — flipped to true by BuildLootPools() on the server once
-- at least one pool has items.  The hook checks this single boolean instead
-- of calling table.Count() on GeneratedPools every kill.
C.PoolsReady      = false
C.GeneratedPools  = {}

print("[Combine Loot] Shared configuration (Crate Spawn Chance) loaded.")
