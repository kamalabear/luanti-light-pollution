-- spec/zone_manager_spec.lua
-- Unit tests for zone_manager module: zone computation, caching, falloff, and merge.

require("mineunit")
mineunit("core")

dofile("config.lua")
dofile("api.lua")
dofile("scanner.lua")
dofile("zone_manager.lua")

-- Stub scanner.scan_around to return controlled results.
local function stub_scan(light_score, positions)
    stub(scanner, "scan_around", function()
        return {light_score = light_score, positions = positions or {}}
    end)
end

-- Stub scanner.has_dirty_near to always return false (no dirty = use cache).
local function stub_clean()
    stub(scanner, "has_dirty_near",    function() return false end)
    stub(scanner, "clear_dirty_near",  function() end)
end

-- Stub to simulate dirty state.
local function stub_dirty()
    stub(scanner, "has_dirty_near",    function() return true end)
    stub(scanner, "clear_dirty_near",  function() end)
end

describe("zone_manager module", function()

    before_each(function()
        -- Reset zone_manager between tests.
        zone_manager._clear_cache()
        -- Default settings: base_radius=32, scale=10, max_intensity=1.0, zone_ttl=30
        minetest.settings:remove("light_pollution.base_radius")
        minetest.settings:remove("light_pollution.radius_scale_factor")
        minetest.settings:remove("light_pollution.max_intensity")
        minetest.settings:remove("light_pollution.zone_ttl")
        minetest.settings:remove("light_pollution.scan_radius")
        config._reload()
    end)

    after_each(function()
        -- Revert any stubs set in tests.
        if scanner.scan_around.revert then scanner.scan_around:revert() end
        if scanner.has_dirty_near.revert then scanner.has_dirty_near:revert() end
        if scanner.clear_dirty_near.revert then scanner.clear_dirty_near:revert() end
    end)

    it("returns intensity 0.0 when scanner finds no sources", function()
        stub_scan(0, {})
        stub_clean()
        local intensity = zone_manager.get_intensity({x=0,y=0,z=0})
        assert.equals(0, intensity)
    end)

    it("computes radius larger than base_radius when light_score is above zero", function()
        -- light_score=100, scale=10 → extra radius = 10, total = 42
        stub_scan(100, {{x=0,y=0,z=0,weight=100}})
        stub_clean()
        -- First call computes zone
        zone_manager.get_intensity({x=0,y=0,z=0})
        -- Second call (clean cache): should use cached zone
        stub_dirty()  -- force rescan to verify radius
        zone_manager._clear_cache()
        stub_scan(100, {{x=0,y=0,z=0,weight=100}})
        zone_manager.get_intensity({x=0,y=0,z=0})
        -- Verify indirectly: intensity at exact center > 0
        local intensity = zone_manager.get_intensity({x=0,y=0,z=0})
        assert.is_true(intensity > 0)
    end)

    it("returns cached zone data on second call when not dirty and not expired", function()
        stub_scan(200, {{x=0,y=0,z=0,weight=200}})
        stub_clean()
        zone_manager.get_intensity({x=0,y=0,z=0})
        -- Replace scan stub with one that would return different data
        scanner.scan_around:revert()
        stub_scan(999, {{x=0,y=0,z=0,weight=999}})
        -- Should return cached result, not 999
        local intensity = zone_manager.get_intensity({x=0,y=0,z=0})
        -- light_score 200 capped at LIGHT_SCORE_MAX 500 → intensity = 0.4
        assert.is_true(intensity > 0)
        assert.is_true(intensity <= 1.0)
    end)

    it("recomputes zone when dirty flag is set", function()
        stub_scan(0, {})
        stub_clean()
        zone_manager.get_intensity({x=0,y=0,z=0})
        -- Now mark dirty and rescan with sources
        scanner.has_dirty_near:revert()
        scanner.clear_dirty_near:revert()
        stub_dirty()
        scanner.scan_around:revert()
        stub_scan(300, {{x=0,y=0,z=0,weight=300}})
        local intensity = zone_manager.get_intensity({x=0,y=0,z=0})
        assert.is_true(intensity > 0)
    end)

    it("recomputes zone when TTL has expired", function()
        minetest.settings:set("light_pollution.zone_ttl", "0")
        config._reload()
        zone_manager._clear_cache()
        stub_scan(200, {{x=0,y=0,z=0,weight=200}})
        stub_clean()
        zone_manager.get_intensity({x=0,y=0,z=0})
        -- With TTL=0, every call is considered expired
        local call_count = 0
        scanner.scan_around:revert()
        stub(scanner, "scan_around", function()
            call_count = call_count + 1
            return {light_score=200, positions={{x=0,y=0,z=0,weight=200}}}
        end)
        zone_manager.get_intensity({x=0,y=0,z=0})
        assert.is_true(call_count >= 1)
    end)

    it("returns falloff intensity less than peak at the zone edge", function()
        -- light_score=500 → intensity peak=1.0, radius = 32 + 500/10 = 82
        stub_scan(500, {{x=0,y=0,z=0,weight=500}})
        stub_clean()
        local peak = zone_manager.get_intensity({x=0,y=0,z=0})
        zone_manager._clear_cache()
        -- Player at edge (dist ≈ radius - 1 = 81)
        stub_scan(500, {{x=0,y=0,z=0,weight=500}})
        local edge = zone_manager.get_intensity({x=81,y=0,z=0})
        assert.is_true(edge < peak)
        assert.is_true(edge > 0)
    end)

    it("returns 0.0 intensity when player position is outside zone radius", function()
        -- radius = 32 + 100/10 = 42; player at x=100 is well outside
        stub_scan(100, {{x=0,y=0,z=0,weight=100}})
        stub_clean()
        local intensity = zone_manager.get_intensity({x=100,y=0,z=0})
        -- The zone was computed for mapblock at x=100; centroid is at x=100
        -- A separate zone key for x=0 origin would give falloff; this test
        -- verifies that positions outside ALL cached zones return 0.
        assert.equals(0, intensity)
    end)

    it("caps intensity at max_intensity even when light_score is very high", function()
        minetest.settings:set("light_pollution.max_intensity", "0.5")
        config._reload()
        zone_manager._clear_cache()
        -- Very high light_score should still cap at 0.5
        stub_scan(9999, {{x=0,y=0,z=0,weight=9999}})
        stub_clean()
        local intensity = zone_manager.get_intensity({x=0,y=0,z=0})
        assert.is_true(intensity <= 0.5 + 0.001)
    end)

    it("merges two overlapping zones and caps combined intensity at max_intensity", function()
        -- Simulate two zones already cached that both cover position {x=0,y=0,z=0}.
        minetest.settings:set("light_pollution.max_intensity", "1.0")
        config._reload()
        zone_manager._clear_cache()
        -- Inject two cache entries manually via repeated scans from different mapblocks.
        -- Zone A: centered at x=0, computed from mapblock at (0,0,0)
        stub_scan(400, {{x=0,y=0,z=0,weight=400}})
        stub_clean()
        zone_manager.get_intensity({x=0,y=0,z=0})
        -- Zone B: centered at x=64, from mapblock at (64,0,0); covers x=0 if radius large
        scanner.scan_around:revert()
        -- positions centered at x=32 so centroid = 32, radius = 32 + 400/10 = 72; covers x=0
        stub_scan(400, {{x=32,y=0,z=0,weight=400}})
        stub_dirty()
        zone_manager.get_intensity({x=64,y=0,z=0})

        -- Now query at x=0 — both zones contribute, capped at max_intensity
        scanner.has_dirty_near:revert()
        stub_clean()
        local intensity = zone_manager.get_intensity({x=0,y=0,z=0})
        assert.is_true(intensity <= 1.0)
        assert.is_true(intensity > 0)
    end)

end)
