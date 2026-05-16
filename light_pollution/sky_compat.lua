-- sky_compat.lua
-- Normalizes player sky capture/apply/restore across Luanti sky API variants
-- and implements two-layer sky tint plus star fading for light pollution visuals.

local function deep_copy(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = deep_copy(v)
    end
    return copy
end

-- Colour palette constants
local ZENITH_BASE = {r = 0x00, g = 0x00, b = 0x1e}
local ZENITH_PEAK = {r = 0x3d, g = 0x1a, b = 0x05}
local HORIZON_BASE = {r = 0x00, g = 0x0d, b = 0x1a}
local HORIZON_PEAK = {r = 0xd4, g = 0x4a, b = 0x08}
local STAR_COLOR_CLEAR = "#ffe8ff"
local STAR_COLOR_POLLUTED = "#c87840"

local function lerp_int(a, b, t)
    return math.floor(a + (b - a) * t + 0.5)
end

local function lerp_color(base, peak, t)
    local r = lerp_int(base.r, peak.r, t)
    local g = lerp_int(base.g, peak.g, t)
    local b = lerp_int(base.b, peak.b, t)
    return string.format("#%02x%02x%02x", r, g, b)
end

local function lerp_hex(hex_a, hex_b, t)
    local ra = tonumber(hex_a:sub(2,3), 16)
    local ga = tonumber(hex_a:sub(4,5), 16)
    local ba = tonumber(hex_a:sub(6,7), 16)
    local rb = tonumber(hex_b:sub(2,3), 16)
    local gb = tonumber(hex_b:sub(4,5), 16)
    local bb = tonumber(hex_b:sub(6,7), 16)
    return string.format("#%02x%02x%02x",
        lerp_int(ra, rb, t),
        lerp_int(ga, gb, t),
        lerp_int(ba, bb, t))
end

sky_compat = {}

function sky_compat.capture(player)
    local a, b, c, d = player:get_sky()

    if type(a) == "table" then
        return { mode = "modern", def = deep_copy(a) }
    end

    if type(a) == "string" then
        return {
            mode     = "legacy",
            bgcolor  = a,
            sky_type = b or "regular",
            textures = deep_copy(c),
            clouds   = d,
        }
    end

    return { mode = "modern", def = { type = "regular" } }
end

function sky_compat.apply_tint(player, saved_sky, vis)
    -- vis: visual intensity 0.0..1.0 (already power-curved by caller)
    local saved = saved_sky or { mode = "modern", def = { type = "regular" } }

    local horizon_color = lerp_color(HORIZON_BASE, HORIZON_PEAK, vis)
    local zenith_color  = lerp_color(ZENITH_BASE,  ZENITH_PEAK,  vis)

    -- Stars fade using a steeper curve so they disappear earlier than sky tint
    local star_fade  = vis ^ 0.4
    local star_color = lerp_hex(STAR_COLOR_CLEAR, STAR_COLOR_POLLUTED, star_fade)
    local star_scale = 1.0 - (star_fade * 0.95)

    if saved.mode == "legacy" then
        -- Legacy: approximate with horizon colour as bgcolor
        player:set_sky(horizon_color, saved.sky_type or "regular", deep_copy(saved.textures), saved.clouds)
        return horizon_color, zenith_color, star_scale
    end

    local def = deep_copy(saved.def) or {}
    def.type = def.type or "regular"
    def.sky_color = def.sky_color or {}
    def.sky_color.night_sky     = zenith_color
    def.sky_color.night_horizon = horizon_color

    def.stars = def.stars or {}
    def.stars.visible = true
    def.stars.count   = def.stars.count or 1000
    def.stars.color   = star_color
    def.stars.scale   = star_scale

    local ok = pcall(function() player:set_sky(def) end)
    if ok then return horizon_color, zenith_color, star_scale end

    ok = pcall(function() player:set_sky(def.type or "regular", def) end)
    if ok then return horizon_color, zenith_color, star_scale end

    player:set_sky(horizon_color, def.type or "regular", def.textures, def.clouds)
    return horizon_color, zenith_color, star_scale
end

function sky_compat.restore(player, saved_sky)
    local saved = saved_sky or { mode = "modern", def = { type = "regular" } }

    if saved.mode == "legacy" then
        player:set_sky(saved.bgcolor or "#000000", saved.sky_type or "regular", deep_copy(saved.textures), saved.clouds)
        return
    end

    local def = deep_copy(saved.def) or { type = "regular" }
    if def.stars then
        def.stars.visible = true
        def.stars.color   = STAR_COLOR_CLEAR
        def.stars.scale   = 1.0
    end

    local ok = pcall(function() player:set_sky(def) end)
    if ok then return end

    ok = pcall(function() player:set_sky(def.type or "regular", def) end)
    if ok then return end

    local bgcolor = (def.sky_color and def.sky_color.night_sky) or "#000000"
    player:set_sky(bgcolor, def.type or "regular", def.textures, def.clouds)
end
