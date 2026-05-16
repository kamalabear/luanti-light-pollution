-- scanner.lua
-- VoxelManip-based light source scanner with dirty mapblock tracking.
-- Public interface:
--   scanner.scan_around(pos, radius)       -> {light_score, positions[]}
--   scanner.mark_dirty(pos)
--   scanner.rebuild_content_id_cache()
--   scanner.has_dirty_near(pos, radius)    -> bool
--   scanner.clear_dirty_near(pos, radius)

local dirty_mapblocks  = {}
local content_id_cache = {}

-- Returns a string key for the mapblock containing pos.
local function mapblock_key(pos)
    return math.floor(pos.x / 16) .. "," ..
           math.floor(pos.y / 16) .. "," ..
           math.floor(pos.z / 16)
end

-- Returns the center position of the mapblock identified by key.
local function key_to_center(key)
    local bx, by, bz = key:match("(-?%d+),(-?%d+),(-?%d+)")
    return {
        x = tonumber(bx) * 16 + 8,
        y = tonumber(by) * 16 + 8,
        z = tonumber(bz) * 16 + 8,
    }
end

local function vec_distance(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

scanner = {}

function scanner.mark_dirty(pos)
    dirty_mapblocks[mapblock_key(pos)] = true
end

function scanner.has_dirty_near(pos, radius)
    for key, _ in pairs(dirty_mapblocks) do
        local center = key_to_center(key)
        if vec_distance(pos, center) <= radius + 16 then
            return true
        end
    end
    return false
end

function scanner.clear_dirty_near(pos, radius)
    for key, _ in pairs(dirty_mapblocks) do
        local center = key_to_center(key)
        if vec_distance(pos, center) <= radius + 16 then
            dirty_mapblocks[key] = nil
        end
    end
end

function scanner.rebuild_content_id_cache()
    content_id_cache = {}
    local unknown_cid = minetest.get_content_id("unknown")
    local air_cid     = minetest.get_content_id("air")
    for name, data in pairs(light_pollution.source_registry) do
        local cid = minetest.get_content_id(name)
        if cid and cid ~= unknown_cid and cid ~= air_cid then
            content_id_cache[cid] = data.weight
            minetest.log("action", "[light_pollution] registered source: " ..
                name .. " (cid=" .. tostring(cid) .. ", weight=" .. tostring(data.weight) .. ")")
        else
            minetest.log("warning", "[light_pollution] source node not found in this game: " .. name)
        end
    end
    minetest.log("action", "[light_pollution] content_id_cache built: " ..
        tostring(#(function() local t={} for _ in pairs(content_id_cache) do t[#t+1]=1 end return t end)()) .. " entries")
end

function scanner.scan_around(pos, radius)
    local max_mb_score = config.get("max_mapblock_score")

    local p1 = {x = pos.x - radius, y = pos.y - radius, z = pos.z - radius}
    local p2 = {x = pos.x + radius, y = pos.y + radius, z = pos.z + radius}

    local vm = minetest.get_voxel_manip(p1, p2)
    if not vm then
        return {light_score = 0, positions = {}}
    end

    local emin, emax = vm:get_emerged_area()
    local data        = vm:get_data()
    local area        = VoxelArea:new({MinEdge = emin, MaxEdge = emax})

    -- Accumulate source node weights per 16³ mapblock.
    -- This prevents a dense lava field (56k nodes) from producing an
    -- astronomically large score; each mapblock contributes at most
    -- max_mapblock_score regardless of how many source nodes it contains.
    local mb_scores = {}
    for z = emin.z, emax.z do
        for y = emin.y, emax.y do
            for x = emin.x, emax.x do
                local i      = area:index(x, y, z)
                local cid    = data[i]
                local weight = content_id_cache[cid]
                if weight then
                    local key = mapblock_key({x = x, y = y, z = z})
                    mb_scores[key] = (mb_scores[key] or 0) + weight
                end
            end
        end
    end

    -- Cap each mapblock contribution and sum totals.
    -- Positions are mapblock centroids weighted by their capped score.
    local light_score = 0
    local positions   = {}
    for key, raw in pairs(mb_scores) do
        local capped = (max_mb_score > 0) and math.min(raw, max_mb_score) or raw
        light_score  = light_score + capped
        local center = key_to_center(key)
        center.weight = capped
        table.insert(positions, center)
    end

    return {light_score = light_score, positions = positions}
end

-- Event-driven dirty tracking: mark mapblocks when source nodes change.
minetest.register_on_placenode(function(pos, newnode)
    if light_pollution.source_registry[newnode.name] then
        scanner.mark_dirty(pos)
    end
end)

minetest.register_on_dignode(function(pos, oldnode)
    if light_pollution.source_registry[oldnode.name] then
        scanner.mark_dirty(pos)
    end
end)
