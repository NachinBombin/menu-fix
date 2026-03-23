if not BOMBIN_MENU_FACTORY or not NPC_SMOKE_WH then
    ErrorNoHalt("[NPC Smoke When Hit] UI dependencies missing\n")
    return
end

hook.Add("PopulateToolMenu", "NPCSmokeWhenHit_Menu", function()
    BOMBIN_MENU_FACTORY.AddOption(
        "NPCSmokeWhenHit",
        "Smoke When Hit",
        function(panel)

            panel:ClearControls()
            panel:Help("Drops smoke grenades when Combine units are hit.")
            panel:Help("Uses entity: cup_smoke_maniac")

            panel:NumSlider(
                "Drop Chance",
                NPC_SMOKE_WH.CVars.Chance,
                0, 1, 2
            )

            panel:NumSlider(
                "Extra Smoke Chance",
                NPC_SMOKE_WH.CVars.ExtraChance,
                0, 1, 2
            )

            panel:NumSlider(
                "Max Extra Smokes",
                NPC_SMOKE_WH.CVars.ExtraMax,
                0, 10, 0
            )

            panel:CheckBox(
                "Include Combine Turrets",
                NPC_SMOKE_WH.CVars.Turrets
            )
        end
    )
end)
