require 'utils'
require 'shop_helpers'


function squad_test()
    open_mission()
    pick_gc_mission(2, 14)
    local plan = plan_mission()
    set_team(plan)
    SafeCallback("GcArmyExpedition", true, 14) -- start mission
    close_yes_no(true, "Commence")
    close_mission()
end

function open_mission()
    if not IsAddonReady("GcArmyExpedition") then
        OpenShop("Storm Squadron Sergeant", "GcArmyExpedition", { SelectString = { 1 } })
    end

    open_addon("GcArmyMemberList", "GcArmyExpedition", true, 13)
end

function close_mission()
    close_addons({ "GcArmyMemberList", "GcArmyExpedition", "SelectString" })
end

function pick_gc_mission(tab, number)
    open_mission()
    SafeCallback("GcArmyExpedition", true, 11, tab)
    SafeCallback("GcArmyExpedition", true, 12, number)
end

function get_mission_req()
    open_mission()

    local phys = GetNodeText("GcArmyExpedition", 1, 38, 40, 2, 2)
    local ment = GetNodeText("GcArmyExpedition", 1, 38, 40, 4, 2)
    local tact = GetNodeText("GcArmyExpedition", 1, 38, 40, 6, 2)
    return {
        Phys = tonumber(phys),
        Ment = tonumber(ment),
        Tact = tonumber(tact),
    }
end

function get_char_stats(charnum)
    open_mission()
    local char_base = 6
    local stat_count = 15
    local stats = { Phys = 7, Ment = 8, Tact = 9 }
    for stat, offset in pairs(stats) do
        local text = atk_data_checked("GcArmyMemberList", char_base + charnum * stat_count + offset)
        stats[stat] = tonumber(text)
    end
    return stats
end

function get_base_stats()
    open_mission()
    local base_stats = atk_data_checked("GcArmyMemberList", 1)
    local phys, ment, tact = base_stats:match(" (%d+)/(%d+)/(%d+)$")
    return {
        Phys = tonumber(phys),
        Ment = tonumber(ment),
        Tact = tonumber(tact),
    }
end

function toggle_team_member(charnum)
    open_mission()
    SafeCallback("GcArmyMemberList", true, 11, charnum)
end

function select_team_member(charnum)
    if not is_team_member_selected(charnum) then
        toggle_team_member(charnum)
    end
    while not is_team_member_selected(charnum) do
        wait(.1)
    end
end

function set_team(selected_chars)
    for i = 0, 7 do
        if is_team_member_selected(i) and not list_contains(selected_chars, i) then
            toggle_team_member(i)
            while is_team_member_selected(i) do
                wait(.1)
            end
        end
    end
    for _, charnum in pairs(selected_chars) do
        select_team_member(charnum)
    end
end

function is_team_member_selected(charnum)
    open_mission()
    local char_base = 6
    local stat_count = 15
    return atk_data_checked("GcArmyMemberList", char_base + charnum * stat_count - 1) == "3"
end

function plan_mission()
    local selected_chars = {}
    local req = get_mission_req()
    local chars = {}
    for i = 0, 7 do
        table.insert(chars, get_char_stats(i))
    end
    local base = get_base_stats()

    -- brute‑force all 4‑of‑8 combinations and choose the one that satisfies
    -- the most requirements.  If more than one combo hits the same number of
    -- stats, pick the one whose unmet stats are as close to the requirement as
    -- possible (i.e. smallest total shortfall).  Note that once a stat exceeds
    -- the requirement the excess is wasted.

    local best = { meets = -1, shortfall = math.huge, combo = {} }

    -- helper to evaluate a combination of zero‑based indices
    local function evaluate(combo)
        local tot = { Phys = base.Phys, Ment = base.Ment, Tact = base.Tact }
        for _, idx in ipairs(combo) do
            -- our chars list is 1‑indexed while idx is 0‑based
            local c = chars[idx + 1]
            tot.Phys = tot.Phys + c.Phys
            tot.Ment = tot.Ment + c.Ment
            tot.Tact = tot.Tact + c.Tact
        end
        local meets = 0
        local short = 0
        for stat, reqval in pairs(req) do
            if tot[stat] >= reqval then
                meets = meets + 1
            else
                short = short + (reqval - tot[stat])
            end
        end
        return meets, short
    end

    -- iterate 8 choose 4 combinations (indices 0..7)
    for a = 0, 4 do
        for b = a + 1, 5 do
            for c = b + 1, 6 do
                for d = c + 1, 7 do
                    local combo = { a, b, c, d }
                    local meets, short = evaluate(combo)
                    if meets > best.meets or (meets == best.meets and short < best.shortfall) then
                        best.meets = meets
                        best.shortfall = short
                        best.combo = combo
                    end
                end
            end
        end
    end

    -- store/return the selected characters
    selected_chars = best.combo

    -- debug output
    log_(LEVEL_INFO, _table, selected_chars, "selected team:")
    log_(LEVEL_INFO, _text, "requirements met:", best.meets, "shortfall:", best.shortfall)

    return selected_chars
end
