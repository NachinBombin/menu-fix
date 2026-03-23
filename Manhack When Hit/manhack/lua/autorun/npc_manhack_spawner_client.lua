hook.Add("PopulateToolMenu", "NPCManhackSpawner_Menu", function()
    if not BOMBIN_MENU_FACTORY or not NPC_MANHACK_SP then return end
    BOMBIN_MENU_FACTORY.AddOption(
        "NPCManhackSpawner",
        "Manhack Spawner",
        function(panel)

            panel:ClearControls()
            panel:Help("Spawns manhacks near Combine units when they are hit.")
            panel:Help("Excludes manhacks, turrets, and scanners.")

            panel:NumSlider(
                "Spawn Chance",
                NPC_MANHACK_SP.CVars.Chance,
                0, 1, 2
            )

            panel:NumSlider(
                "Extra Manhack Chance",
                NPC_MANHACK_SP.CVars.ExtraChance,
                0, 1, 2
            )

            panel:NumSlider(
                "Max Extra Manhacks",
                NPC_MANHACK_SP.CVars.ExtraMax,
                0, 10, 0
            )

            panel:Help("Optional unit types:")

            panel:CheckBox(
                "Include Hunters",
                NPC_MANHACK_SP.CVars.Hunters
            )

            panel:CheckBox(
                "Include Combine APCs",
                NPC_MANHACK_SP.CVars.APCs
            )

        end
    )
end)
