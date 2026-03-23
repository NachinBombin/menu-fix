NPC_MANHACK_SP = NPC_MANHACK_SP or {}

NPC_MANHACK_SP.CVars = {
    Chance      = "npc_manhack_sp_chance",
    ExtraChance = "npc_manhack_sp_extra_chance",
    ExtraMax    = "npc_manhack_sp_extra_max",
    Hunters     = "npc_manhack_sp_include_hunters",
    APCs        = "npc_manhack_sp_include_apcs",
}

CreateConVar(NPC_MANHACK_SP.CVars.Chance,      "0.15", FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar(NPC_MANHACK_SP.CVars.ExtraChance, "0.3",  FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar(NPC_MANHACK_SP.CVars.ExtraMax,    "2",    FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar(NPC_MANHACK_SP.CVars.Hunters,     "0",    FCVAR_ARCHIVE + FCVAR_REPLICATED)
CreateConVar(NPC_MANHACK_SP.CVars.APCs,        "0",    FCVAR_ARCHIVE + FCVAR_REPLICATED)
