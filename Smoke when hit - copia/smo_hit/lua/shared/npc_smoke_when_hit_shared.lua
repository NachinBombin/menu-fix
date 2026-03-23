NPC_SMOKE_WH = NPC_SMOKE_WH or {}

NPC_SMOKE_WH.CVars = {
    Chance      = "npc_smoke_wh_chance",
    ExtraChance = "npc_smoke_wh_extra_chance",
    ExtraMax    = "npc_smoke_wh_extra_max",
    Turrets     = "npc_smoke_wh_include_turrets"
}

CreateConVar(NPC_SMOKE_WH.CVars.Chance, "0.25", FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar(NPC_SMOKE_WH.CVars.ExtraChance, "0.5", FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar(NPC_SMOKE_WH.CVars.ExtraMax, "3", FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar(NPC_SMOKE_WH.CVars.Turrets, "0", FCVAR_ARCHIVE + FCVAR_REPLICATED)
