-- spec/config_spec.lua
-- Unit tests for config module: settings loading and validation.

require("mineunit")
mineunit("core")

describe("config module", function()

    local function reload()
        -- Wipe any previously loaded global then reload from source.
        config = nil  -- luacheck: ignore
        dofile("config.lua")
    end

    before_each(function()
        -- Clear all light_pollution settings before each test.
        for _, k in ipairs({
            "scan_radius","scan_interval","move_threshold","base_radius",
            "radius_scale_factor","max_intensity","lerp_rate","zone_ttl","source_types"
        }) do
            minetest.settings:remove("light_pollution." .. k)
        end
        reload()
    end)

    it("returns default scan_radius when setting is absent", function()
        assert.equals(64, config.get("scan_radius"))
    end)

    it("returns default scan_interval when setting is absent", function()
        assert.equals(5.0, config.get("scan_interval"))
    end)

    it("returns default move_threshold when setting is absent", function()
        assert.equals(8, config.get("move_threshold"))
    end)

    it("returns default base_radius when setting is absent", function()
        assert.equals(32, config.get("base_radius"))
    end)

    it("returns default radius_scale_factor when setting is absent", function()
        assert.equals(10.0, config.get("radius_scale_factor"))
    end)

    it("returns default max_intensity when setting is absent", function()
        assert.equals(1.0, config.get("max_intensity"))
    end)

    it("returns default lerp_rate when setting is absent", function()
        assert.equals(0.02, config.get("lerp_rate"))
    end)

    it("returns default zone_ttl when setting is absent", function()
        assert.equals(30, config.get("zone_ttl"))
    end)

    it("returns default source_types when setting is absent", function()
        assert.equals("both", config.get("source_types"))
    end)

    it("returns correct typed value for scan_radius when set", function()
        minetest.settings:set("light_pollution.scan_radius", "128")
        reload()
        assert.equals(128, config.get("scan_radius"))
    end)

    it("returns correct typed value for scan_interval when set", function()
        minetest.settings:set("light_pollution.scan_interval", "2.5")
        reload()
        assert.equals(2.5, config.get("scan_interval"))
    end)

    it("returns correct typed value for source_types when set", function()
        minetest.settings:set("light_pollution.source_types", "natural")
        reload()
        assert.equals("natural", config.get("source_types"))
    end)

    it("logs a warning when scan_radius is set to 0 or negative", function()
        local warned = false
        local orig_log = minetest.log
        minetest.log = function(level, msg)
            if level == "warning" and msg:find("scan_radius") then
                warned = true
            end
        end
        minetest.settings:set("light_pollution.scan_radius", "0")
        reload()
        minetest.log = orig_log
        assert.is_true(warned)
        -- Falls back to default
        assert.equals(64, config.get("scan_radius"))
    end)

    it("logs a warning when max_intensity is above 1.0", function()
        local warned = false
        local orig_log = minetest.log
        minetest.log = function(level, msg)
            if level == "warning" and msg:find("max_intensity") then
                warned = true
            end
        end
        minetest.settings:set("light_pollution.max_intensity", "1.5")
        reload()
        minetest.log = orig_log
        assert.is_true(warned)
        assert.equals(1.0, config.get("max_intensity"))
    end)

    it("logs a warning when source_types has an invalid value", function()
        local warned = false
        local orig_log = minetest.log
        minetest.log = function(level, msg)
            if level == "warning" and msg:find("source_types") then
                warned = true
            end
        end
        minetest.settings:set("light_pollution.source_types", "invalid_value")
        reload()
        minetest.log = orig_log
        assert.is_true(warned)
        assert.equals("both", config.get("source_types"))
    end)

    it("get_number returns a number type for numeric keys", function()
        assert.equals("number", type(config.get_number("scan_radius")))
        assert.equals("number", type(config.get_number("lerp_rate")))
    end)

end)
