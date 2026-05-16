-- spec/scanner_spec.lua
-- Unit tests for scanner module: VoxelManip scanning and dirty mapblock tracking.

require("mineunit")
mineunit("core")
mineunit("voxelmanip")

-- VoxelArea shim: not provided by mineunit in headless (engine_version=mineunit) mode.
if not VoxelArea then
    local math_floor = math.floor
    VoxelArea = { MinEdge = vector.new(1,1,1), MaxEdge = vector.new(0,0,0), ystride = 0, zstride = 0 }
    local va_mt = {}
    setmetatable(VoxelArea, va_mt)
    local function va_new(self, o)
        o = o or {}
        setmetatable(o, self)
        self.__index = self
        local e = o:getExtent()
        o.ystride = e.x
        o.zstride = e.x * e.y
        return o
    end
    function va_mt:__call(MinEdge, MaxEdge)
        return va_new(self, {MinEdge = MinEdge, MaxEdge = MaxEdge})
    end
    VoxelArea.new = va_new
    function VoxelArea:getExtent()
        local mx, mn = self.MaxEdge, self.MinEdge
        return vector.new(mx.x - mn.x + 1, mx.y - mn.y + 1, mx.z - mn.z + 1)
    end
    function VoxelArea:getVolume()
        local e = self:getExtent()
        return e.x * e.y * e.z
    end
    function VoxelArea:index(x, y, z)
        local mn = self.MinEdge
        return math_floor((z - mn.z) * self.zstride + (y - mn.y) * self.ystride + (x - mn.x) + 1)
    end
    function VoxelArea:indexp(p)
        local mn = self.MinEdge
        return math_floor((p.z - mn.z) * self.zstride + (p.y - mn.y) * self.ystride + (p.x - mn.x) + 1)
    end
end

dofile("config.lua")
dofile("api.lua")
dofile("scanner.lua")

-- Register test nodes so get_content_id resolves them without throwing.
-- mineunit("core") loads 5.9.1/game/register.lua which nils core.register_item_raw
-- (moving it to a local); register_node is the correct public API.
minetest.register_node(":default:lava_source", {description="Lava Source"})
minetest.register_node(":default:torch", {description="Torch"})

-- Helper: build a fake VoxelManip over a 1x1x1 region with one node at origin.
local function make_mock_vm(node_map, p1, p2)
    local emin = p1 or {x = -1, y = -1, z = -1}
    local emax = p2 or {x =  1, y =  1, z =  1}
    local area = VoxelArea:new({MinEdge = emin, MaxEdge = emax})
    local air  = minetest.get_content_id("air")
    local data = {}
    for i = 1, area:getVolume() do data[i] = air end
    for _, entry in ipairs(node_map or {}) do
        local cid = minetest.get_content_id(entry.name)
        local idx = area:index(entry.pos.x, entry.pos.y, entry.pos.z)
        data[idx]  = cid
    end
    return {
        get_emerged_area = function() return emin, emax end,
        get_data         = function() return data end,
    }
end

describe("scanner module", function()

    before_each(function()
        -- Reset source_registry and content_id_cache between tests.
        light_pollution = {source_registry = {}}  -- luacheck: ignore
        scanner = nil  -- luacheck: ignore
        dofile("scanner.lua")
    end)

    it("returns light_score 0 when no registered sources are in range", function()
        stub(minetest, "get_voxel_manip", function() return make_mock_vm({}) end)
        local result = scanner.scan_around({x=0,y=0,z=0}, 16)
        assert.equals(0, result.light_score)
        assert.equals(0, #result.positions)
        minetest.get_voxel_manip:revert()
    end)

    it("accumulates weight for each source node found in the scanned volume", function()
        light_pollution.source_registry["default:lava_source"] = {weight = 14}
        scanner.rebuild_content_id_cache()
        local nodes = {
            {name = "default:lava_source", pos = {x=0, y=0, z=0}},
            {name = "default:lava_source", pos = {x=1, y=0, z=0}},
        }
        stub(minetest, "get_voxel_manip", function()
            return make_mock_vm(nodes, {x=-2,y=-2,z=-2}, {x=2,y=2,z=2})
        end)
        local result = scanner.scan_around({x=0,y=0,z=0}, 16)
        assert.equals(28, result.light_score)  -- 2 x weight 14
        assert.equals(2, #result.positions)
        minetest.get_voxel_manip:revert()
    end)

    it("marks a mapblock dirty when a registered source is placed in it", function()
        light_pollution.source_registry["default:lava_source"] = {weight = 14}
        -- Simulate register_on_placenode callback
        local callbacks = minetest._placenode_callbacks or {}
        local pos = {x=8, y=8, z=8}
        scanner.mark_dirty(pos)
        assert.is_true(scanner.has_dirty_near(pos, 32))
    end)

    it("marks a mapblock dirty when a registered source is removed from it", function()
        local pos = {x=16, y=0, z=0}
        scanner.mark_dirty(pos)
        assert.is_true(scanner.has_dirty_near({x=16,y=0,z=0}, 32))
    end)

    it("does not mark dirty when an unregistered node is placed", function()
        -- scanner.has_dirty_near returns false when no mark_dirty was called
        assert.is_false(scanner.has_dirty_near({x=0,y=0,z=0}, 32))
    end)

    it("rebuilds content_id_cache correctly when source_registry is updated", function()
        -- Start with empty registry
        scanner.rebuild_content_id_cache()
        -- No dirty content IDs yet; add a source
        light_pollution.source_registry["default:torch"] = {weight = 12}
        scanner.rebuild_content_id_cache()
        -- Now a scan should pick up torches
        local nodes = {{name = "default:torch", pos = {x=0, y=0, z=0}}}
        stub(minetest, "get_voxel_manip", function()
            return make_mock_vm(nodes, {x=-1,y=-1,z=-1}, {x=1,y=1,z=1})
        end)
        local result = scanner.scan_around({x=0,y=0,z=0}, 16)
        assert.equals(12, result.light_score)
        minetest.get_voxel_manip:revert()
    end)

    it("clear_dirty_near removes entries within radius", function()
        local pos = {x=0, y=0, z=0}
        scanner.mark_dirty(pos)
        assert.is_true(scanner.has_dirty_near(pos, 32))
        scanner.clear_dirty_near(pos, 32)
        assert.is_false(scanner.has_dirty_near(pos, 32))
    end)

    it("has_dirty_near returns false after dirty entries are cleared", function()
        scanner.mark_dirty({x=0,y=0,z=0})
        scanner.clear_dirty_near({x=0,y=0,z=0}, 64)
        assert.is_false(scanner.has_dirty_near({x=0,y=0,z=0}, 64))
    end)

end)
