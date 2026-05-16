-- spec/integration_spec.lua
-- Integration tests for the full light_pollution Iteration 1 pipeline.
-- Requires mineunit world simulation.

require("mineunit")
mineunit("core")
mineunit("voxelmanip")
mineunit("world")
mineunit("server")

-- Load all modules in dependency order(same as init.lua, without globalstep).
dofile("config.lua")
dofile("compat.lua")
dofile("api.lua")
dofile("scanner.lua")
dofile("zone_manager.lua")
dofile("effect_engine.lua")

-- Register test nodes so get_content_id resolves them without throwing.
-- mineunit("core") loads 5.9.1/game/register.lua which nils core.register_item_raw
-- (moving it to a local); register_node is the correct public API.
minetest.register_node(":default:lava_source", {description="Lava Source"})

-- Seed a test source so the scanner knows about lava.
light_pollution.source_registry["default:lava_source"] = {weight = 14}
scanner.rebuild_content_id_cache()

-- Minimal mock player factory.
local function make_player(name, pos)
    local _pos = pos or {x=0,y=50,z=0}
    local _sky = {type="regular", sky_color={night_sky="#00007a", night_horizon="#00007a"}}
    local set_sky_log = {}
    return {
        get_player_name = function() return name end,
        get_pos         = function() return _pos end,
        set_pos         = function(_, p) _pos = p end,
        get_sky         = function() return _sky end,
        set_sky         = function(_, def)
            _sky = def
            table.insert(set_sky_log, def)
        end,
        _sky_log        = set_sky_log,
    }
end

describe("light pollution integration (Iteration 1)", function()

    before_each(function()
        -- Night time
        mineunit:set_timeofday(0.0)
        -- Fast lerp so tests converge quickly
        minetest.settings:set("light_pollution.lerp_rate",   "1.0")
        minetest.settings:set("light_pollution.scan_radius", "32")
        minetest.settings:set("light_pollution.base_radius", "16")
        config._reload()
        zone_manager._clear_cache()
        effect_engine = nil  -- luacheck: ignore
        dofile("effect_engine.lua")
        -- Clear world
        world.clear()
    end)

    it("player near a simulated lava cluster sees orange sky tint after update", function()
        -- Place a 3x3 patch of lava just below the player.
        for xi = -1, 1 do
            for zi = -1, 1 do
                world.set_node({x=xi, y=49, z=zi}, {name="default:lava_source"})
            end
        end
        scanner.mark_dirty({x=0, y=49, z=0})

        local player = make_player("tester1", {x=0, y=50, z=0})

        -- Run several update cycles to let lerp converge.
        for _ = 1, 10 do
            effect_engine.update(player)
        end

        -- Sky should be tinted — at least one set_sky call made.
        assert.is_true(#player._sky_log >= 1)
        local sky = player._sky_log[#player._sky_log]
        assert.is_not_nil(sky.sky_color)
        assert.is_not.equals("#00007a", sky.sky_color.night_sky)
    end)

    it("player moving away from zone sees sky tint fade toward zero", function()
        -- Place lava, get tinted, then move away.
        for xi = -1, 1 do
            for zi = -1, 1 do
                world.set_node({x=xi, y=49, z=zi}, {name="default:lava_source"})
            end
        end
        scanner.mark_dirty({x=0, y=49, z=0})
        local player = make_player("tester2", {x=0, y=50, z=0})

        for _ = 1, 5 do effect_engine.update(player) end

        -- Move player far away (outside zone radius).
        player.set_pos(nil, {x=500, y=50, z=0})
        scanner.mark_dirty({x=0, y=49, z=0})  -- simulate re-check on move

        for _ = 1, 10 do effect_engine.update(player) end

        -- Final sky call (if any) should be a restore, or no tint calls at far position.
        -- At minimum: intensity at x=500 is 0, so sky_applied should become false.
        local last = player._sky_log[#player._sky_log]
        if last and last.sky_color then
            -- If restore was called, night_sky should be back to base blue.
            assert.equals("#00007a", last.sky_color.night_sky)
        end
    end)

    it("two players in different zones see independently tinted skies", function()
        -- Cluster A near x=0
        for xi = -1, 1 do
            world.set_node({x=xi, y=49, z=0}, {name="default:lava_source"})
        end
        scanner.mark_dirty({x=0, y=49, z=0})

        local playerA = make_player("alice", {x=0, y=50, z=0})
        local playerB = make_player("bob",   {x=1000, y=50, z=0})

        for _ = 1, 10 do
            effect_engine.update(playerA)
            effect_engine.update(playerB)
        end

        -- Alice should be tinted; Bob (1000 nodes away) should not.
        local a_tinted = #playerA._sky_log >= 1
        local b_tinted = #playerB._sky_log >= 1
        assert.is_true(a_tinted)
        assert.is_false(b_tinted)
    end)

    it("removing all lava nodes dissolves the zone and sky returns to normal", function()
        -- Place lava, get tinted.
        for xi = -1, 1 do
            world.set_node({x=xi, y=49, z=0}, {name="default:lava_source"})
        end
        scanner.mark_dirty({x=0, y=49, z=0})
        local player = make_player("charlie", {x=0, y=50, z=0})

        for _ = 1, 5 do effect_engine.update(player) end

        -- Remove all lava nodes.
        for xi = -1, 1 do
            world.set_node({x=xi, y=49, z=0}, {name="air"})
        end
        -- Mark dirty so next scan picks up the empty region.
        scanner.mark_dirty({x=0, y=49, z=0})
        zone_manager._clear_cache()

        for _ = 1, 10 do effect_engine.update(player) end

        -- Intensity should now be 0; last sky call should restore to original.
        local last = player._sky_log[#player._sky_log]
        if last and last.sky_color then
            assert.equals("#00007a", last.sky_color.night_sky)
        end
    end)

end)

