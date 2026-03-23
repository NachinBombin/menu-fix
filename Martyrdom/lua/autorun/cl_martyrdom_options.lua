--[[-------------------------------------------------------------------------
    Martyrdom - Client Options Panel  (cl_martyrdom_options.lua)

    Single unified options panel replacing 5 separate cl_ files.
    Found in: Options → Bombin Addons → Martyrdom
---------------------------------------------------------------------------]]

local ADDON_TITLE    = "Martyrdom"
local ADDON_CATEGORY = "Bombin Addons"

local function BuildMartyrdomOptions()
    spawnmenu.AddToolMenuOption("Options", ADDON_CATEGORY, "MartyrdomSettingsPanel", ADDON_TITLE, "", "", function(panel)
        panel:ClearControls()

        -- ----------------------------------------------------------------
        -- Header
        -- ----------------------------------------------------------------
        panel:Help("MARTYRDOM — NPC Death Drop System")
        panel:Help(
            "Combine NPCs drop live grenades, smoke canisters,\n" ..
            "Combine Mines, flashbangs, and toxin canisters on death\n" ..
            "as a last-stand attempt to harm the player."
        )
        panel:ControlHelp(
            "Required addons:  EZ T Grenade · CUP Smoke Maniac\n" ..
            "                  combine_mine · CUP Flash · CUP Smoke BO"
        )

        -- ----------------------------------------------------------------
        -- Global
        -- ----------------------------------------------------------------
        panel:Help("\n─────  Global Settings  ─────")
        panel:NumSlider("Max Entities Alive (All Types)", "mrd_entity_cap", 0, 500, 0)
        panel:ControlHelp(
            "Hard cap on total spawned entities from this addon.\n" ..
            "Prevents server flooding during mass-death events (e.g. explosions)."
        )

        -- ----------------------------------------------------------------
        -- Shared NPC toggles
        -- ----------------------------------------------------------------
        panel:Help("\n─────  Additional NPC Types (All Items)  ─────")
        panel:ControlHelp("These apply to every item type. Per-item Manhack toggles are below.")
        panel:CheckBox("Include Hunters (npc_hunter)",              "mrd_include_hunter")
        panel:CheckBox("Include Scanners (City / Claw Scanner)",    "mrd_include_scanner")

        -- ----------------------------------------------------------------
        -- Grenade
        -- ----------------------------------------------------------------
        panel:Help("\n─────  Grenade  ─────")
        panel:ControlHelp("Entity: zbase_ezt_grenade  (EZ T Grenade addon required)")
        panel:CheckBox("Enable Grenade Drops",                      "mrd_grenade_enabled")
        panel:NumSlider("Drop Chance (%)",                          "mrd_grenade_chance",        0, 100, 0)
        panel:NumSlider("Max Extra Grenades (1 to Max)",            "mrd_grenade_extra_count",   0, 40,  0)
        panel:NumSlider("Extra Grenade Spawn Chance (%)",           "mrd_grenade_extra_chance",  0, 100, 0)
        panel:CheckBox("Include Manhacks for Grenades",             "mrd_grenade_manhack")

        -- ----------------------------------------------------------------
        -- Smoke
        -- ----------------------------------------------------------------
        panel:Help("\n─────  Smoke Canister  ─────")
        panel:ControlHelp("Entity: cup_smoke_maniac")
        panel:CheckBox("Enable Smoke Drops",                        "mrd_smoke_enabled")
        panel:NumSlider("Drop Chance (%)",                          "mrd_smoke_chance",          0, 100, 0)
        panel:NumSlider("Max Extra Smokes (1 to Max)",              "mrd_smoke_extra_count",     0, 20,  0)
        panel:NumSlider("Extra Smoke Spawn Chance (%)",             "mrd_smoke_extra_chance",    0, 100, 0)
        panel:CheckBox("Include Manhacks for Smokes",               "mrd_smoke_manhack")

        -- ----------------------------------------------------------------
        -- Mine
        -- ----------------------------------------------------------------
        panel:Help("\n─────  Combine Mine  ─────")
        panel:ControlHelp(
            "Entity: combine_mine (built-in HL2 entity, no addon needed)\n" ..
            "Mines self-arm after landing. Manhack drops not supported."
        )
        panel:CheckBox("Enable Mine Drops",                         "mrd_mine_enabled")
        panel:NumSlider("Drop Chance (%)",                          "mrd_mine_chance",           0, 100, 0)
        panel:CheckBox("Striders Drop 2 Guaranteed Mines on Death", "mrd_mine_strider")

        -- ----------------------------------------------------------------
        -- Flashbang (Mindblock)
        -- ----------------------------------------------------------------
        panel:Help("\n─────  Flashbang (Mindblock)  ─────")
        panel:ControlHelp("Entity: cup_flash  (CUP Mindblock addon required)\nSingle drop only — no burst extras.")
        panel:CheckBox("Enable Flashbang Drops",                    "mrd_flash_enabled")
        panel:NumSlider("Drop Chance (%)",                          "mrd_flash_chance",          0, 100, 0)
        panel:CheckBox("Include Manhacks for Flashbangs",           "mrd_flash_manhack")

        -- ----------------------------------------------------------------
        -- Toxin
        -- ----------------------------------------------------------------
        panel:Help("\n─────  Toxin Canister  ─────")
        panel:ControlHelp("Entity: cup_smoke_bo  (CUP Toxin addon required)")
        panel:CheckBox("Enable Toxin Drops",                        "mrd_toxin_enabled")
        panel:NumSlider("Drop Chance (%)",                          "mrd_toxin_chance",          0, 100, 0)
        panel:NumSlider("Max Extra Toxins (1 to Max)",              "mrd_toxin_extra_count",     0, 20,  0)
        panel:NumSlider("Extra Toxin Spawn Chance (%)",             "mrd_toxin_extra_chance",    0, 100, 0)
        panel:CheckBox("Include Manhacks for Toxins",               "mrd_toxin_manhack")

    end)
end

hook.Add("PopulateToolMenu", "Martyrdom_AddOptionsMenu", BuildMartyrdomOptions)
