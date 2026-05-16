-- spec/compat_spec.lua
-- Unit tests for compat module: game detection and source node list filtering.

require("mineunit")
mineunit("core")

dofile("config.lua")

describe("compat module", function()

    local real_get_modpath

    before_each(function()
        real_get_modpath = minetest.get_modpath
        -- Reset source_types to "both" for each test
        minetest.settings:remove("light_pollution.source_types")
        config._reload()
        compat = nil  -- luacheck: ignore
        dofile("compat.lua")
    end)

    after_each(function()
        minetest.get_modpath = real_get_modpath
    end)

    local function stub_modpath(present)
        minetest.get_modpath = function(name)
            for _, n in ipairs(present) do
                if n == name then return "/fake/path/" .. name end
            end
            return nil
        end
    end

    it("returns MTG node names when only 'default' modpath is present", function()
        stub_modpath({"default", "fire"})
        local sources = compat.default_sources()
        local names = {}
        for _, s in ipairs(sources) do names[s.name] = true end
        assert.is_true(names["default:lava_source"])
        assert.is_true(names["default:torch"])
        assert.is_nil(names["mcl_core:lava_source"])
    end)

    it("returns VoxeLibre node names when only 'mcl_core' modpath is present", function()
        stub_modpath({"mcl_core", "mcl_fire", "mcl_torches", "mcl_nether"})
        local sources = compat.default_sources()
        local names = {}
        for _, s in ipairs(sources) do names[s.name] = true end
        assert.is_true(names["mcl_core:lava_source"])
        assert.is_true(names["mcl_torches:torch"])
        assert.is_nil(names["default:lava_source"])
    end)

    it("filters to natural sources only when source_types is 'natural'", function()
        stub_modpath({"default", "fire"})
        minetest.settings:set("light_pollution.source_types", "natural")
        config._reload()
        dofile("compat.lua")
        local sources = compat.default_sources()
        local names = {}
        for _, s in ipairs(sources) do names[s.name] = true end
        assert.is_true(names["default:lava_source"])
        assert.is_nil(names["default:torch"])
        assert.is_nil(names["default:meselamp"])
    end)

    it("filters to artificial sources only when source_types is 'artificial'", function()
        stub_modpath({"default", "fire"})
        minetest.settings:set("light_pollution.source_types", "artificial")
        config._reload()
        dofile("compat.lua")
        local sources = compat.default_sources()
        local names = {}
        for _, s in ipairs(sources) do names[s.name] = true end
        assert.is_nil(names["default:lava_source"])
        assert.is_true(names["default:torch"])
    end)

    it("returns both natural and artificial sources when source_types is 'both'", function()
        stub_modpath({"default", "fire"})
        local sources = compat.default_sources()
        local names = {}
        for _, s in ipairs(sources) do names[s.name] = true end
        assert.is_true(names["default:lava_source"])
        assert.is_true(names["default:torch"])
    end)

    it("returns an empty list without error when neither modpath is present", function()
        stub_modpath({})
        local sources = compat.default_sources()
        assert.equals(0, #sources)
    end)

    it("each returned entry has a name (string) and weight (number)", function()
        stub_modpath({"default", "fire"})
        local sources = compat.default_sources()
        assert.is_true(#sources > 0)
        for _, s in ipairs(sources) do
            assert.equals("string", type(s.name))
            assert.equals("number", type(s.weight))
            assert.is_true(s.weight > 0)
        end
    end)

end)
