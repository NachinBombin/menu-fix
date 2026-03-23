-- Shared (runs on both server and client)
AddCSLuaFile("npc_manhack_spawner_shared.lua")
include("npc_manhack_spawner_shared.lua")

-- Client files
-- bombin_menu_factory.lua is owned by the smoke addon and already loaded globally
AddCSLuaFile("npc_manhack_spawner_client.lua")

if CLIENT then
    include("npc_manhack_spawner_client.lua")
end

-- Server
if SERVER then
    include("npc_manhack_spawner_server.lua")
end
