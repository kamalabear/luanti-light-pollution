-- config.lua
-- Loads and validates all light_pollution settings from minetest.conf at startup.
-- Public interface: config.get(key), config.get_number(key), config.get_bool(key)

local DEFAULTS = {
    scan_radius         = 160,
    scan_interval       = 5.0,
    move_threshold      = 8,
    base_radius         = 80,
    radius_scale_factor = 8.0,
    max_intensity       = 1.0,
    lerp_rate           = 0.02,
    zone_ttl            = 30,
    max_zone_radius     = 2000,
    max_mapblock_score  = 500,
    light_score_max     = 10000,
    source_types        = "both",
}

local VALIDATORS = {
    scan_radius         = function(v) return v > 0 end,
    scan_interval       = function(v) return v > 0 end,
    move_threshold      = function(v) return v >= 0 end,
    base_radius         = function(v) return v >= 0 end,
    radius_scale_factor = function(v) return v > 0 end,
    max_intensity       = function(v) return v > 0.0 and v <= 1.0 end,
    lerp_rate           = function(v) return v >= 0.001 and v <= 1.0 end,
    zone_ttl            = function(v) return v >= 0 end,
    max_zone_radius     = function(v) return v >= 0 end,
    max_mapblock_score  = function(v) return v >= 0 end,
    light_score_max     = function(v) return v > 0 end,
    source_types        = function(v)
        return v == "natural" or v == "artificial" or v == "both"
    end,
}

local INT_KEYS   = {"scan_radius", "move_threshold", "base_radius", "zone_ttl", "max_zone_radius", "max_mapblock_score", "light_score_max"}
local FLOAT_KEYS = {"scan_interval", "radius_scale_factor", "max_intensity", "lerp_rate"}
local STR_KEYS   = {"source_types"}

local _cache = {}

local function load()
    local s = minetest.settings

    for _, key in ipairs(INT_KEYS) do
        local raw = s:get("light_pollution." .. key)
        local val = raw and math.floor(tonumber(raw) or 0)
        if val == nil or (raw ~= nil and not tonumber(raw)) then
            val = DEFAULTS[key]
        elseif not VALIDATORS[key](val) then
            minetest.log("warning", string.format(
                "[light_pollution] 'light_pollution.%s' value %q is out of range. Using default: %s",
                key, tostring(raw), tostring(DEFAULTS[key])))
            val = DEFAULTS[key]
        end
        _cache[key] = val
    end

    for _, key in ipairs(FLOAT_KEYS) do
        local raw = s:get("light_pollution." .. key)
        local val = raw and tonumber(raw)
        if val == nil then
            val = DEFAULTS[key]
        elseif not VALIDATORS[key](val) then
            minetest.log("warning", string.format(
                "[light_pollution] 'light_pollution.%s' value %q is out of range. Using default: %s",
                key, tostring(raw), tostring(DEFAULTS[key])))
            val = DEFAULTS[key]
        end
        _cache[key] = val
    end

    for _, key in ipairs(STR_KEYS) do
        local raw = s:get("light_pollution." .. key)
        local val = (raw and raw ~= "") and raw or DEFAULTS[key]
        if not VALIDATORS[key](val) then
            minetest.log("warning", string.format(
                "[light_pollution] 'light_pollution.%s' value %q is invalid. Using default: %s",
                key, tostring(raw), tostring(DEFAULTS[key])))
            val = DEFAULTS[key]
        end
        _cache[key] = val
    end
end

load()

config = {}

function config.get(key)
    return _cache[key]
end

function config.get_number(key)
    return tonumber(_cache[key])
end

function config.get_bool(key)
    local v = _cache[key]
    if type(v) == "boolean" then return v end
    return v == "true"
end

-- Exposed for testing: reload settings from minetest.settings
function config._reload()
    load()
end
