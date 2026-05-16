-- compat.lua
-- Detects the active game (MTG or VoxeLibre) and returns default light source node lists.
-- Public interface: compat.default_sources() -> list of {name, weight}

local MTG_SOURCES = {
    natural = {
        {name = "default:lava_source",  weight = 14},
        {name = "default:lava_flowing", weight = 14},
        {name = "fire:basic_flame",     weight = 13},
    },
    artificial = {
        {name = "default:torch",    weight = 12},
        {name = "default:meselamp", weight = 15},
        {name = "default:mese",     weight = 15},
    },
}

local VOXELIBRE_SOURCES = {
    natural = {
        {name = "mcl_core:lava_source", weight = 14},
        {name = "mcl_fire:fire",        weight = 13},
    },
    artificial = {
        {name = "mcl_torches:torch",    weight = 12},
        {name = "mcl_nether:glowstone", weight = 15},
    },
}

local function collect(source_table, kind)
    local result = {}
    if kind == "natural" or kind == "both" then
        for _, entry in ipairs(source_table.natural) do
            table.insert(result, {name = entry.name, weight = entry.weight})
        end
    end
    if kind == "artificial" or kind == "both" then
        for _, entry in ipairs(source_table.artificial) do
            table.insert(result, {name = entry.name, weight = entry.weight})
        end
    end
    return result
end

compat = {}

function compat.default_sources()
    local kind   = config.get("source_types") or "both"
    local result = {}

    if minetest.get_modpath("default") then
        for _, entry in ipairs(collect(MTG_SOURCES, kind)) do
            table.insert(result, entry)
        end
    end

    if minetest.get_modpath("mcl_core") then
        for _, entry in ipairs(collect(VOXELIBRE_SOURCES, kind)) do
            table.insert(result, entry)
        end
    end

    return result
end
