BOMBIN_MENU_FACTORY = BOMBIN_MENU_FACTORY or {}

hook.Add("PopulateToolMenu", "BombinAddons_CreateCategory", function()
    spawnmenu.AddToolCategory("Options", "Bombin_Addons", "Bombin Addons")
end)

function BOMBIN_MENU_FACTORY.AddOption(id, title, buildFunc)
    spawnmenu.AddToolMenuOption(
        "Options",
        "Bombin Addons",
        id,
        title,
        "",
        "",
        buildFunc
    )
end
