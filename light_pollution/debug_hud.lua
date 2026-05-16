-- debug_hud.lua
-- Optional per-player HUD overlay for live light_pollution diagnostics.

debug_hud = {}

local hud_ids = {}    -- player_name -> hud id
local active   = {}   -- player_name -> bool
local instant  = {}   -- player_name -> bool

local function build_text(state, debug_state)
    local tod = string.format("%.3f", minetest.get_timeofday())
    local is_active = (tonumber(tod) > 0.23 and tonumber(tod) < 0.77) and "NO (day)" or "YES"
    local raw = state and state.current_intensity or 0
    local vis = string.format("%.3f", math.sqrt(math.max(0, raw)))
    local raw_s = string.format("%.3f", raw)
    local sky_on = state and state.sky_applied and "true" or "false"
    local score = debug_state and debug_state.zone_score or 0
    local radius = debug_state and debug_state.zone_radius or 0
    local horizon = debug_state and debug_state.horizon_color or "---"
    local zenith = debug_state and debug_state.zenith_color or "---"
    local stars = debug_state and (debug_state.star_scale and string.format("%.2f", debug_state.star_scale) or "---") or "---"
    local instant_mode = state and state.debug_instant and "ON" or "OFF"

    local lines = {
        "[light_pollution debug]",
        string.format("tod:     %s   active: %s", tod, is_active),
        string.format("raw:     %s   vis: %s", raw_s, vis),
        string.format("sky_on:  %s", sky_on),
        string.format("instant: %s", instant_mode),
        string.format("score:   %d     radius: %d", score, radius),
        string.format("horizon: %s", horizon),
        string.format("zenith:  %s", zenith),
        string.format("stars:   %s", stars),
    }
    return minetest.colorize("#ffffff", table.concat(lines, "\n"))
end

function debug_hud.toggle(player)
    if not player then return end
    local name = player:get_player_name()
    if active[name] then
        if hud_ids[name] then player:hud_remove(hud_ids[name]) end
        hud_ids[name] = nil
        active[name] = nil
        return
    end

    local id = player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.01, y = 0.10},
        offset = {x = 0, y = 0},
        text = "[light_pollution debug]",
        alignment = {x = 1, y = 1},
        scale = {x = 100, y = 100},
        number = 0,
    })
    hud_ids[name] = id
    active[name] = true
end

function debug_hud.update(player, state, debug_state)
    if not player then return end
    local name = player:get_player_name()
    if not active[name] or not hud_ids[name] then return end
    local text = build_text(state, debug_state)
    player:hud_change(hud_ids[name], "text", text)
end

function debug_hud.toggle_instant(player)
    if not player then return false end
    local name = player:get_player_name()
    instant[name] = not instant[name]
    return instant[name]
end

function debug_hud.instant_enabled(player_name)
    return instant[player_name] == true
end

minetest.register_chatcommand("lp_debug", {
    params = "",
    description = "Toggle light_pollution debug HUD",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        debug_hud.toggle(player)
        return true, "Toggled light_pollution debug HUD"
    end,
})

minetest.register_chatcommand("lp_debug_instant", {
    params = "",
    description = "Toggle instant light_pollution debug apply mode",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        local enabled = debug_hud.toggle_instant(player)
        return true, "Instant debug apply " .. (enabled and "enabled" or "disabled")
    end,
})

minetest.register_chatcommand("lp_scan", {
    params = "",
    description = "Force a light_pollution scan at your position and report the raw score",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return false, "Player not found" end
        local pos = player:get_pos()
        local radius = config.get("scan_radius")
        local result = scanner.scan_around(pos, radius)
        local msg = string.format(
            "scan radius=%d  score=%d  sources=%d",
            radius, result.light_score, #result.positions)
        minetest.log("action", "[light_pollution] /lp_scan by " .. name .. ": " .. msg)
        return true, msg
    end,
})

minetest.register_on_leaveplayer(function(player)
    local name = player:get_player_name()
    if hud_ids[name] then
        pcall(function() player:hud_remove(hud_ids[name]) end)
        hud_ids[name] = nil
    end
    active[name] = nil
    instant[name] = nil
end)
