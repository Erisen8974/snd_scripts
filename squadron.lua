require 'utils'
require 'shop_helpers'


function squad_test()
    local tab = 2
    local mission = 14
    pick_gc_tab(tab)
    if is_gc_mission_available(mission) then
        pick_gc_mission(mission)
        log_(LEVEL_INFO, _text, "Running mission", mission)
        local plan = plan_mission()
        set_team(plan)
        SafeCallback("GcArmyExpedition", true, mission) -- start mission
        close_yes_no(true, "Commence")
    else
        log_(LEVEL_INFO, _text, "Mission", tab, mission, "not available")
    end
    close_mission()
end

function enter_barracks()
    local company = Player.GrandCompany
    if company == 1 then
        TownPath("Limsa Lominsa Lower Decks", 97.2, 40.2, 62.8, "The Aftcastle", "Limsa Lominsa Upper Decks")
        talk("Entrance to the Barracks", "SelectYesno")
        close_yes_no(true, "Enter the Barracks")
        ZoneTransition()
    else
        error("Unsupported Grand Company: ", CallerName(false), company, "is not supported")
    end
end

function open_mission_list()
    if not IsAddonReady("GcArmyExpedition") then
        OpenShop("Storm Squadron Sergeant", "GcArmyExpedition", {
            SelectString = { 1 },
            GcArmyExpeditionResult = { -1 }
        })
    end
end

function open_member_list()
    open_mission_list()
    open_addon("GcArmyMemberList", "GcArmyExpedition", true, 13)
end

function close_mission()
    close_addons({ "GcArmyMemberList", "GcArmyExpedition", "SelectString" })
end

function pick_gc_tab(tab)
    open_mission_list()
    if tab >= 3 then
        error("BadTabNumber", CallerName(false), "tab", tab)
    end
    local ti = ResetTimeout()
    local _click = 0
    while tonumber(atk_data_checked("GcArmyExpedition", 0)) ~= tab do
        if _click + 1 < os.clock() then
            _click = os.clock()
            SafeCallback("GcArmyExpedition", true, 11, tab)
        end
        CheckTimeout(10, ti, CallerName(false), "Picking GC mission tab", tab)
        wait(.1)
    end
end

function pick_gc_mission(number)
    open_mission_list()
    local mission_count = tonumber(atk_data_checked("GcArmyExpedition", 6))
    if number >= mission_count then
        error("BadMission", CallerName(false), "number", number, "available", mission_count)
    end
    local ti = ResetTimeout()
    local _click = 0
    local inst = cs_instance("FFXIVClientStructs.FFXIV.Client.UI.Agent.AgentGcArmyExpedition")
    while inst.SelectedRow ~= number do
        if _click + 1 < os.clock() then
            _click = os.clock()
            SafeCallback("GcArmyExpedition", true, 12, number)
        end
        CheckTimeout(10, ti, CallerName(false), "Picking GC mission", number)
        wait(.1)
        inst = cs_instance("FFXIVClientStructs.FFXIV.Client.UI.Agent.AgentGcArmyExpedition")
    end
end

function get_mission_req()
    open_mission_list()

    local phys = GetNodeText("GcArmyExpedition", 1, 38, 40, 2, 2)
    local ment = GetNodeText("GcArmyExpedition", 1, 38, 40, 4, 2)
    local tact = GetNodeText("GcArmyExpedition", 1, 38, 40, 6, 2)
    return {
        Phys = tonumber(phys),
        Ment = tonumber(ment),
        Tact = tonumber(tact),
    }
end

function is_gc_mission_available(number)
    open_mission_list()
    if not IsAddonReady("GcArmyExpedition") then
        error("AddonNotReady", CallerName(false), "GcArmyExpedition")
    end
    local mission_base = 8
    local info_count = 4
    local available = tonumber(atk_data_checked("GcArmyExpedition", 6))
    if number >= available then
        error("BadMission", CallerName(false), "number", number, "available", available)
    end
    local status = atk_data_checked("GcArmyExpedition", mission_base + number * info_count)
    return string_to_bool(status)
end

function get_char_stats(charnum)
    open_member_list()
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
    open_member_list()
    local base_stats = atk_data_checked("GcArmyMemberList", 1)
    local phys, ment, tact = base_stats:match(" (%d+)/(%d+)/(%d+)$")
    return {
        Phys = tonumber(phys),
        Ment = tonumber(ment),
        Tact = tonumber(tact),
    }
end

function toggle_team_member(charnum)
    open_member_list()
    log_(LEVEL_INFO, _text, "Toggling charnum", charnum)
    SafeCallback("GcArmyMemberList", true, 11, charnum)
end

function select_team_member(charnum)
    log_(LEVEL_INFO, _text, "Selecting charnum", charnum)
    if not is_team_member_selected(charnum) then
        toggle_team_member(charnum)
    end
    local ti = ResetTimeout()
    while not is_team_member_selected(charnum) do
        CheckTimeout(10, ti, CallerName(false), "Waiting for team member selection", charnum)
        wait(.1)
    end
end

function set_team(selected_chars)
    for i = 0, 7 do
        if is_team_member_selected(i) and not list_contains(selected_chars, i) then
            log_(LEVEL_INFO, _text, "Deselecting charnum", i)
            toggle_team_member(i)
            local ti = ResetTimeout()
            while is_team_member_selected(i) do
                CheckTimeout(10, ti, CallerName(false), "Waiting for team member deselection", i)
                wait(.1)
            end
        end
    end
    for _, charnum in pairs(selected_chars) do
        select_team_member(charnum)
    end
end

function is_team_member_selected(charnum)
    open_member_list()
    local char_base = 6
    local stat_count = 15
    local member_info = atk_data_checked("GcArmyMemberList", char_base + charnum * stat_count - 1)
    log_(LEVEL_DEBUG, _text, "Member info for charnum", charnum, member_info)
    return is_bit_set(member_info, 1)
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

--#region Misc Retainers stuff
-- Are retainers like a squadron?
-- not really...

function set_retainer_jobs(job)
    local info = get_char_info(Player.Entity.Name)
    if info ~= nil then
        local retainers = info.Retainers
        if retainers == nil then
            error("Retainers Error", CallerName(false), "no retainer info defined for",
                Player.Entity.Name)
        end
        for i, r in ipairs(retainers) do
            set_retainer_job(r, job)
        end
        return
    end
    error("Char Error", CallerName(false), "no char info defined for", Player.Entity.Name)
end

function set_retainer_job(retainer, job)
    pause_pyes()

    --smart_path("Old Gridania", 169, 15.5, -100)
    smart_path("Limsa Lominsa Lower Decks", -147, 18.2, 18)
    --smart_path("Ul'dah - Steps of Thal", 109, 4.1, -74)

    OpenShop("Parnell", "SelectString")
    SelectInList("Inquire about retainer jobs.", "SelectString")
    SelectInList("Purchase a copy of Modern Vocation.", "SelectString")
    close_yes_no(true, "Exchange 40 ventures", true)
    close_talk()
    open_retainer_bell()
    open_retainer(retainer)
    if SelectInList("venture report", "SelectString", true) then
        open_addon("SelectYesno", "RetainerTaskResult", true, 13)
        close_yes_no(true, "Cancel venture", true)
    end
    SelectInList("Assign retainer a job.", "SelectString")
    SelectInList(job .. '.', "SelectString")
    resume_pyes()
    close_yes_no(true, "Modern Vocation", true)
    wait_any_addons("SelectString")
    pause_pyes()
    SelectInList("Assign venture.", "SelectString")
    SelectInList("Quick Exploration.", "SelectString")
    open_addon("SelectString", "RetainerTaskAsk", true, 12)
    close_retainer()
    close_addon("RetainerList")
    resume_pyes()
    IPC.AutoRetainer.SetSuppressed(false)
end

--#endregion
