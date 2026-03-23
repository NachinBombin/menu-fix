--[[-------------------------------------------------------------------------
    Client-side Q Menu Options for Combine Loot Drops (Crate Spawn Chance)
---------------------------------------------------------------------------]]

if not MY_COMBINE_LOOT or not MY_COMBINE_LOOT.CrateSpawnChanceConVarName then -- Also check for the new ConVar name
    ErrorNoHalt("[Combine Loot] Shared config not loaded or incomplete! Client script cannot run.\n")
    return
end

local C = MY_COMBINE_LOOT -- Alias
print("[Combine Loot] Client script loading (Crate Spawn Chance).")

hook.Add("PopulateToolMenu", "CreateCombineLootSettingsMenu_WithCrateChance", function()
    spawnmenu.AddToolMenuOption("Options", "Utilities", "CombineLootSettings", "Combine Loot", "", "", function(panel)
        panel:ClearControls()
        panel:SetName("Combine Loot Drop Chances")

        -- *** ADD Crate Spawn Chance Slider at the TOP ***
        panel:NumSlider("OVERALL CRATE SPAWN CHANCE", C.CrateSpawnChanceConVarName, 0, 100, 0)
            :SetTooltip("The chance (0-100%) that a Loot Cache will spawn IF any potential items were rolled successfully.")

        -- Add a separator/label
        local separator = panel:Add("DLabel")
        separator:SetText("\n-- Chance for Each Category to Add Items --")
        separator:SetDark(true)
        separator:SizeToContents()
        panel:AddSpacer() -- Add a little vertical space
        -- *** ***

        -- Create sliders for each item category
        for _, category in ipairs(C.Categories) do
            local convarName = "my_combine_loot_chance_" .. category
            local slider = panel:NumSlider(category:gsub("_", " "):upper(), convarName, 0, 100, 0)
            slider:SetTooltip("Adjust the chance (0-100%) for the " .. category .. " category to add an item to the crate.")
        end

        -- Add a label explaining saving
        local helpLabel = panel:Add("DLabel")
        helpLabel:SetText("\nSettings are saved automatically on change (requires server permission).")
        helpLabel:SetDark(true)
        helpLabel:SizeToContents()

    end)
end)

print("[Combine Loot] Client script (Crate Spawn Chance) loaded successfully. Options menu updated.")