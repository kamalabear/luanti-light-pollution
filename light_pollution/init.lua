-- init.lua
-- Entry point for the light_pollution mod (Iteration 1).
-- Loads modules in dependency order and wires the globalstep engine loop.

local modpath = minetest.get_modpath("light_pollution")

dofile(modpath .. "/config.lua")
dofile(modpath .. "/compat.lua")
dofile(modpath .. "/api.lua")
dofile(modpath .. "/scanner.lua")
dofile(modpath .. "/zone_manager.lua")
dofile(modpath .. "/sky_compat.lua")
dofile(modpath .. "/debug_hud.lua")
dofile(modpath .. "/effect_engine.lua")

-- Seed source_registry from game-detected defaults.
for _, source in ipairs(compat.default_sources()) do
    light_pollution.source_registry[source.name] = {weight = source.weight}
end

-- Build content ID cache now that source_registry is fully populated.
scanner.rebuild_content_id_cache()

-- Globalstep: throttled per-player effect update.
local elapsed       = 0
local scan_interval = config.get("scan_interval")

minetest.register_globalstep(function(dtime)
    elapsed = elapsed + dtime
    if elapsed < scan_interval then return end
    elapsed = 0
    for _, player in ipairs(minetest.get_connected_players()) do
        effect_engine.update(player)
    end
end)

minetest.log("action", "[light_pollution] Iteration 1 loaded.")
