-- zone_manager.lua
-- Computes, caches, and queries light pollution zones from scanner data.
-- Public interface: zone_manager.get_intensity(pos) -> number (0.0–1.0)

local LIGHT_SCORE_MAX = 1000

local zone_cache = {}

local function mapblock_key(pos)
    return math.floor(pos.x / 16) .. "," ..
           math.floor(pos.y / 16) .. "," ..
           math.floor(pos.z / 16)
end

local function vec_distance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- Weighted centroid of source positions.
local function compute_centroid(positions)
    if #positions == 0 then
        return {x = 0, y = 0, z = 0}
    end
    local sx, sy, sz     = 0, 0, 0
    local total_weight   = 0
    for _, p in ipairs(positions) do
        local w    = p.weight or 1
        sx         = sx + p.x * w
        sy         = sy + p.y * w
        sz         = sz + p.z * w
        total_weight = total_weight + w
    end
    if total_weight == 0 then
        return {x = 0, y = 0, z = 0}
    end
    return {
        x = sx / total_weight,
        y = sy / total_weight,
        z = sz / total_weight,
    }
end

zone_manager = {}

function zone_manager.get_intensity(pos)
    local key         = mapblock_key(pos)
    local scan_radius = config.get("scan_radius")
    local zone_ttl    = config.get("zone_ttl")
    local max_i       = config.get("max_intensity")
    local base_r      = config.get("base_radius")
    local scale       = config.get("radius_scale_factor")
    local now         = os.time()

    -- Determine whether we need to rescan.
    local cached      = zone_cache[key]
    local needs_scan  = true
    if cached then
        local age      = now - cached.updated_at
        local is_dirty = scanner.has_dirty_near(pos, scan_radius)
        if not is_dirty and age < zone_ttl then
            needs_scan = false
        end
    end

    if needs_scan then
        scanner.clear_dirty_near(pos, scan_radius)
        local result = scanner.scan_around(pos, scan_radius)

        if result.light_score == 0 then
            zone_cache[key] = {
                center      = {x = pos.x, y = pos.y, z = pos.z},
                radius      = 0,
                intensity   = 0,
                light_score = 0,
                updated_at  = now,
            }
        else
            local center    = compute_centroid(result.positions)
            local raw_score = result.light_score
            -- Use sqrt growth for radius so very large raw scores don't
            -- blow up the computed zone radius. Also cap by configured
            -- max_zone_radius to keep radii bounded for performance.
            local radius    = base_r + math.sqrt(raw_score) / scale
            local max_radius = config.get("max_zone_radius")
            if max_radius and max_radius > 0 then
                radius = math.min(radius, max_radius)
            end
            local intensity = math.min(raw_score / LIGHT_SCORE_MAX, max_i)
            zone_cache[key] = {
                center      = center,
                radius      = radius,
                intensity   = intensity,
                light_score = raw_score,
                updated_at  = now,
            }
        end
    end

    -- Sum falloff contributions from all cached zones whose radius covers pos,
    -- then cap at max_intensity to handle overlapping zone merges.
    local total = 0
    for _, zone in pairs(zone_cache) do
        if zone.intensity > 0 and zone.radius > 0 then
            local dist = vec_distance(pos, zone.center)
            if dist < zone.radius then
                total = total + zone.intensity * (1.0 - dist / zone.radius)
            end
        end
    end

    local last_debug = { score = 0, radius = 0 }
    local entry = zone_cache[key]
    if entry then
        last_debug.score = entry.light_score or 0
        last_debug.radius = entry.radius or 0
    end

    return math.min(total, max_i), last_debug
end

-- Exposed for testing: wipe the zone cache.
function zone_manager._clear_cache()
    zone_cache = {}
end
