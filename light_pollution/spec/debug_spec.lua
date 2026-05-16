require("mineunit")
mineunit("core")
mineunit("voxelmanip")
if not VoxelArea then
    print("VoxelArea is nil!")
else
    print("VoxelArea OK")
end
dofile("config.lua")
dofile("api.lua")
dofile("scanner.lua")
minetest.register_node(":default:lava_source", {description="Lava Source"})

local lava_cid = minetest.get_content_id("default:lava_source")
local air_cid  = minetest.get_content_id("air")
print("lava_source CID:", lava_cid, "air CID:", air_cid)

light_pollution.source_registry["default:lava_source"] = {weight = 14}
scanner.rebuild_content_id_cache()
print("content_id_cache[lava_cid]:", (function()
    -- Can't directly access; use a scan
    local nodes = {{name = "default:lava_source", pos = {x=0, y=0, z=0}}}
    local emin = {x=-1,y=-1,z=-1}
    local emax = {x=1,y=1,z=1}
    local area = VoxelArea:new({MinEdge=emin, MaxEdge=emax})
    local air = minetest.get_content_id("air")
    local data = {}
    for i = 1, area:getVolume() do data[i] = air end
    local cid = minetest.get_content_id("default:lava_source")
    local idx = area:index(0,0,0)
    data[idx] = cid
    print("lava cid in vm:", cid, "at idx:", idx, "data[idx]:", data[idx])
    local vm = {
        get_emerged_area = function() return emin, emax end,
        get_data = function() return data end,
    }
    rawset(minetest, "get_voxel_manip", function() return vm end)
    local result = scanner.scan_around({x=0,y=0,z=0}, 16)
    print("light_score:", result.light_score)
    return result.light_score
end)())
