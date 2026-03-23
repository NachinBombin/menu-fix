-- Shared
AddCSLuaFile("shared/npc_smoke_when_hit_shared.lua")
include("shared/npc_smoke_when_hit_shared.lua")

-- Client
-- Note: AddCSLuaFile must be called in the global scope (not inside if CLIENT),
-- so the server can send these files to connecting clients
AddCSLuaFile("includes/bombin_menu_factory.lua")
AddCSLuaFile("client/npc_smoke_when_hit_client.lua")

if CLIENT then
    include("includes/bombin_menu_factory.lua")
    include("client/npc_smoke_when_hit_client.lua")
end

-- Server
if SERVER then
    include("server/npc_smoke_when_hit_server.lua")
end
