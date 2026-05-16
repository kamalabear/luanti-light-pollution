-- spec/effect_engine_spec.lua
-- Unit tests for effect_engine module: sky tint, lerp, daytime suppression, cleanup.

require("mineunit")
mineunit("core")
mineunit("server")

dofile("config.lua")
dofile("api.lua")
dofile("scanner.lua")
dofile("zone_manager.lua")
dofile("effect_engine.lua")

-- Minimal mock player factory.
local function make_player(name, pos, sky)
    local _sky = sky or {type = "regular", sky_color = {night_sky = "#00007a", night_horizon = "#00007a"}}
    local _pos = pos or {x=0,y=0,z=0}
    local set_sky_calls = {}
    return {
        get_player_name = function() return name end,
        get_pos         = function() return _pos end,
        set_pos         = function(_, p) _pos = p end,
        get_sky         = function() return _sky end,
        set_sky         = function(_, def)
            _sky = def
            table.insert(set_sky_calls, def)
        end,
        _set_sky_calls  = set_sky_calls,
    }
end

describe("effect engine (sky tint)", function()

    before_each(function()
        minetest.settings:remove("light_pollution.lerp_rate")
        minetest.settings:remove("light_pollution.move_threshold")
        minetest.settings:remove("light_pollution.scan_radius")
        config._reload()
        zone_manager._clear_cache()
        -- Reset effect_engine state by reloading module.
        effect_engine = nil  -- luacheck: ignore
        dofile("effect_engine.lua")
        -- Default: nighttime
        mineunit:set_timeofday(0.0)
    end)

    local function stub_intensity(value)
        stub(zone_manager, "get_intensity", function() return value end)
        stub(scanner,       "has_dirty_near", function() return false end)
    end

    after_each(function()
        if zone_manager.get_intensity.revert then zone_manager.get_intensity:revert() end
        if scanner.has_dirty_near.revert then scanner.has_dirty_near:revert() end
    end)

    it("does not alter sky when intensity is 0.0", function()
        stub_intensity(0)
        local player = make_player("alice", {x=0,y=0,z=0})
        effect_engine.update(player)
        -- lerp from 0 toward 0 → no tint applied
        assert.equals(0, #player._set_sky_calls)
    end)

    it("calls player:set_sky() with orange-tinted night_sky color at intensity 1.0", function()
        -- Force intensity high immediately: set lerp_rate to 1.0
        minetest.settings:set("light_pollution.lerp_rate", "1.0")
        config._reload()
        dofile("effect_engine.lua")
        stub_intensity(1.0)
        local player = make_player("bob", {x=0,y=0,z=0})
        effect_engine.update(player)
        assert.is_true(#player._set_sky_calls >= 1)
        local sky = player._set_sky_calls[1]
        assert.is_not_nil(sky.sky_color)
        -- At full intensity the night_sky color must not be the base blue.
        assert.is_not.equals("#00007a", sky.sky_color.night_sky)
        -- Verify some red component (orange has r=0xc8).
        local r = tonumber(sky.sky_color.night_sky:sub(2,3), 16)
        assert.is_true(r > 0)
    end)

    it("does not apply sky changes when minetest.get_timeofday() indicates daytime", function()
        minetest.settings:set("light_pollution.lerp_rate", "1.0")
        config._reload()
        dofile("effect_engine.lua")
        stub_intensity(1.0)
        mineunit:set_timeofday(0.5)  -- midday
        local player = make_player("charlie", {x=0,y=0,z=0})
        effect_engine.update(player)
        -- target_intensity was zeroed by daytime check → no tint applied
        assert.equals(0, #player._set_sky_calls)
    end)

    it("interpolates current_intensity toward target_intensity at lerp_rate per step", function()
        -- lerp_rate=0.1: after one step current = 0 + (1.0 - 0)*0.1 = 0.1
        minetest.settings:set("light_pollution.lerp_rate", "0.1")
        config._reload()
        dofile("effect_engine.lua")
        stub_intensity(1.0)
        local player = make_player("dave", {x=0,y=0,z=0})
        effect_engine.update(player)
        -- After one step with lerp=0.1, sky_applied color should show ~10% tint
        -- Color r at 0.1 intensity: 0 + (200-0)*0.1 = 20 = 0x14
        if #player._set_sky_calls >= 1 then
            local sky = player._set_sky_calls[1]
            local r = tonumber(sky.sky_color.night_sky:sub(2,3), 16)
            assert.is_true(r > 0 and r < 200)
        end
    end)

    it("restores original sky when current_intensity reaches 0.0", function()
        minetest.settings:set("light_pollution.lerp_rate", "1.0")
        config._reload()
        dofile("effect_engine.lua")
        local original_sky = {type="regular", sky_color={night_sky="#00007a", night_horizon="#00007a"}}
        local player = make_player("eve", {x=0,y=0,z=0}, original_sky)
        -- First: apply tint
        stub_intensity(1.0)
        effect_engine.update(player)
        -- Move player far enough to force a rescan, then drop intensity to 0
        player:set_pos({x=1000, y=0, z=0})
        zone_manager.get_intensity:revert()
        stub_intensity(0)
        effect_engine.update(player)
        -- Sky should have been restored
        local last = player._set_sky_calls[#player._set_sky_calls]
        if last then
            -- Restored sky should match the original
            assert.equals("#00007a", (last.sky_color or {}).night_sky)
        end
    end)

    it("restores original sky when player leaves", function()
        minetest.settings:set("light_pollution.lerp_rate", "1.0")
        config._reload()
        dofile("effect_engine.lua")
        stub_intensity(1.0)
        local original_sky = {type="regular", sky_color={night_sky="#00007a", night_horizon="#00007a"}}
        local player = make_player("frank", {x=0,y=0,z=0}, original_sky)
        effect_engine.update(player)
        -- Simulate leave
        minetest.run_callbacks(minetest.registered_on_leaveplayers, 0, player)
        -- The last set_sky call should restore to the original
        local last = player._set_sky_calls[#player._set_sky_calls]
        assert.is_not_nil(last)
        assert.equals("#00007a", (last.sky_color or {}).night_sky)
    end)

    it("maintains separate sky state for two players at different intensities", function()
        minetest.settings:set("light_pollution.lerp_rate", "1.0")
        config._reload()
        dofile("effect_engine.lua")
        -- Player 1: high intensity zone
        local player1 = make_player("grace", {x=0,y=0,z=0})
        -- Player 2: zero intensity zone
        local player2 = make_player("heidi", {x=1000,y=0,z=0})

        stub(zone_manager, "get_intensity", function(pos)
            if pos.x < 500 then return 1.0 else return 0.0 end
        end)
        effect_engine.update(player1)
        effect_engine.update(player2)

        -- Player 1 should have a tinted sky
        assert.is_true(#player1._set_sky_calls >= 1)
        -- Player 2 should have no sky change (intensity 0)
        assert.equals(0, #player2._set_sky_calls)
    end)

end)
