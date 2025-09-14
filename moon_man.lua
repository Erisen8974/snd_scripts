require 'utils'
require 'luasharp'
require 'hard_ipc'
require 'path_helpers'
require 'inventory_buddy'


-- Cool NPCs
-- Researchingway - tools
-- Orbitingway - gamba
-- Summoning Bell - summoning bell...
-- Mesouaidonque - da goods!

local WALK_THERSHOLD = 100


function ice_only_mission(s)
    local ICE_SETMISSION = 'ICE.OnlyMissions'
    require_ipc(ICE_SETMISSION, nil, { 'System.Collections.Generic.HashSet`1[System.UInt32]' })
    invoke_ipc(ICE_SETMISSION, s)
end

function ice_enable()
    local ICE_ENABLE = 'ICE.Enable'
    require_ipc(ICE_ENABLE)
    invoke_ipc(ICE_ENABLE)
end

function ice_disable()
    local ICE_DISABLE = 'ICE.Disable'
    require_ipc(ICE_DISABLE)
    invoke_ipc(ICE_DISABLE)
end

function ice_current_state()
    local ICE_CURRENTSTATE = 'ICE.CurrentState'
    require_ipc(ICE_CURRENTSTATE, 'System.String')
    return invoke_ipc(ICE_CURRENTSTATE)
end

function ice_is_running()
    local ICE_ISRUNNING = 'ICE.IsRunning'
    require_ipc(ICE_ISRUNNING, 'System.Boolean')
    return invoke_ipc(ICE_ISRUNNING)
end

function ice_change_bool(name, value)
    local ICE_CHANGEBOOL = 'ICE.ChangeSetting'
    require_ipc(ICE_CHANGEBOOL, nil, { 'System.String', 'System.Boolean' })
    invoke_ipc(ICE_CHANGEBOOL, name, value)
end

function ice_change_number(name, value)
    local ICE_CHANGENUM = 'ICE.ChangeSettingAmount'
    require_ipc(ICE_CHANGENUM, nil, { 'System.String', 'System.UInt32' })
    invoke_ipc(ICE_CHANGENUM, name, value)
end

--[[
    Expected settings:
        OnlyGrabMission: bool
        StopAfterCurrent: bool
        XPRelicGrind: bool

        StopOnceHitCosmoCredits: bool
        CosmoCreditsCap: number

        StopOnceHitLunarCredits: bool
        LunarCreditsCap: number
--]]
function ice_setting(name, value)
    if type(name) ~= "string" then
        StopScript("Bad setting name type", CallerName(false), "Settings names are strings, not", type(name), name)
    end
    if type(value) == "boolean" then
        log_debug("Setting boolean", name, "to", value)
        ice_change_bool(name, value)
    elseif type(value) == "number" then
        log_debug("Setting string", name, "to", value)
        ice_change_number(name, value)
    else
        StopScript("Bad setting type", CallerName(false), "Unexpected settings type", type(value), value)
    end
end

function start_ice_once()
    if ice_is_running() then
        return false
    end
    ice_enable()
    ice_setting('StopAfterCurrent', true)
    return true
end

function set_missions(...)
    s = make_set('System.UInt32', ...)
    log_(LEVEL_DEBUG, log_iterable, s)
    ice_only_mission(s)
end

function on_moon()
    return list_contains({ 1237, 1291 }, Svc.ClientState.TerritoryType)
end

function path_to_moon_thing(thing, distance)
    distance = default(distance, 3)
    if not on_moon() then
        log_(LEVEL_INFO, "Must be on moon to path to moon thing")
        return false
    end
    local e = get_closest_entity(thing)
    local path = nil
    local path_len = WALK_THERSHOLD
    if e.Position ~= nil then
        path = pathfind_with_tolerance(e.Position, false, distance)
        path_len = path_length(path)
    end
    if path_len >= WALK_THERSHOLD then
        log_(LEVEL_INFO, log, "Too far away or not found, returning to base")
        Actions.ExecuteAction(42149)
        ZoneTransition()
        e = get_closest_entity(thing, true)
        path = pathfind_with_tolerance(e.Position, false, distance)
    end
    walk_path(path, false, distance)
end

function moon_talk(who)
    path_to_moon_thing(who)
    local e = get_closest_entity(who, true)
    e:SetAsTarget()
    e:Interact()
    close_talk("SelectString", "SelectIconString")
end

function report_research(class)
    moon_talk("Researchingway")
    SelectInList("Report research data.", "SelectString")
    SelectInList(class.Name, "SelectIconString", true)
    local yesno
    repeat
        yesno = Addons.GetAddon("SelectYesno")
        wait(0)
    until yesno.Exists and yesno.Ready
    if yesno:GetAtkValue(8).ValueString == "Report research data." then
        SafeCallback("SelectYesno", true, 0)
    end
    close_talk()
end

function start_gamba()
    moon_talk("Orbitingway")
    SelectInList('Draw a cosmic fortune', "SelectString", true)
    SelectInList('Yes.', "SelectString")
    repeat
        wait(1)
    until ice_current_state() == "Gambling"
    repeat
        wait(1)
    until ice_current_state() == "Idle"
    close_talk()
end

--stage1_range = 45591-45689
--stage2_range = 49009-49063

function item_is_lunar(item_id)
    return
        (45591 <= item_id and item_id <= 45689) or
        (49009 <= item_id and item_id <= 49063)
end

function move_lunar_weapons()
    move_items(ALL_INVENTORIES, InventoryType.ArmoryMainHand, 45591, 45689)
    move_items(ALL_INVENTORIES, InventoryType.ArmoryMainHand, 49009, 49063)
end

--[[
    Broken cause gearset.items isnt valid...
    local wep_id = nil
    log_(LEVEL_VERBOSE, log, "Items for gearset:", gs.Name, gs.BannerIndex, gs.IsValid)
    for item in luanet.each(gs.Items) do
        log_(LEVEL_VERBOSE, log, "--", item.ItemId, item.Container)
        if item.Container == InventoryType.ArmoryMainHand then
            wep_id = item.ItemId
        end
    end
    if wep_id == nil then
        log_(LEVEL_ERROR, log, "Main hand weapon not in gearset. Assuming not stellar.")
        return false
    end
    log_(LEVEL_DEBUG, log, "Mainhand item id is", wep_id)
--]]

function turnin_mission()
    open_addon("WKSMissionInfomation", "WKSHud", true, 11)
    confirm_addon("WKSMissionInfomation", true, 11)
end

function is_moon_tool_equiped()
    for item in luanet.each(Inventory.GetInventoryContainer(InventoryType.EquippedItems).Items) do
        if item_is_lunar(item.ItemId) then
            return true
        end
    end
    return false
end

function equip_some_other_job(initial_gs)
    for gs in luanet.each(Player.Gearsets) do
        if gs.ClassJob ~= initial_gs.ClassJob then
            repeat
                gs:Equip()
                wait_ready(10, 1)
            until Player.Gearset.ClassJob ~= initial_gs.ClassJob
            return true
        end
    end
    return false
end

function reapply_gearset(gs)
    local yesno = nil
    repeat
        gs:Equip()
        wait(0.3)
        yesno = Addons.GetAddon("SelectYesno")
        wait(0.3)
        if yesno.Ready then
            close_yes_no(true,
                "registered to this gear set could not be found in your Armoury Chest. Replace it with")
        end
        wait(0.4)
    until Player.Gearset.BannerIndex == gs.BannerIndex
    wait_ready(10, 1)
end

function report_research_safe()
    local initial_gs = Player.Gearset
    local initial_job = Player.Job

    local need_swap = is_moon_tool_equiped()
    if need_swap then
        if not equip_some_other_job(initial_gs) then
            StopScript("No Other Job", CallerName(false),
                "Need to change gearset to hand in tool but no gearsets for other jobs were found")
        end
    end
    report_research(initial_job)
    wait_ready(10, 1)
    if need_swap then
        move_lunar_weapons()
        wait(1)
        reapply_gearset(initial_gs)
        --Player.Gearset:Update()
    end
end

known_fissions = {
    [988] = { Setup = Vector3(404.64, 29.07, -78.85), Fish = Vector3(394.01, 27.56, -74.69), ReturnDist = 500 },
    [986] = { Setup = Vector3(207.61, 133.72, -753.43), Fish = Vector3(213.55, 133.50, -746.50), ReturnDist = 550 },
}


function moon_path_to_fish(fish)
    if Vector3.Distance(Player.Entity.Position, fish.Fish) < 2 then
        return -- already here
    end
    local path = await(IPC.vnavmesh.Pathfind(Player.Entity.Position, fish.Setup, false))
    if path_length(path) > fish.ReturnDist then
        log_(LEVEL_INFO, log, "Too far away, returning to base")
        Actions.ExecuteAction(42149)
        ZoneTransition()
        path = await(IPC.vnavmesh.Pathfind(Player.Entity.Position, fish.Setup, false))
    end
    walk_path(path, false)
    Actions.ExecuteGeneralAction(23)
    custom_path(false, { fish.Fish })
end

function start_fisher_mission(number)
    if ice_current_state() ~= "Idle" then
        StopScript("Invalid State", CallerName(false), "ICE should be idle to initialize proplerly")
    end
    set_missions(number)

    local locs = known_fissions[number]
    if locs ~= nil then
        moon_path_to_fish(locs)
    end

    ice_setting("OnlyGrabMission", true)
    ice_setting("StopAfterCurrent", true)
    ice_setting("XPRelicGrind", false)
    ice_setting("StopOnceHitCosmoCredits", false)
    ice_setting("StopOnceHitLunarCredits", false)

    log_(LEVEL_INFO, log, "ICE Configured, starting mission")

    ice_enable()

    while ice_current_state() ~= "ManualMode" do
        wait(1)
    end

    ice_disable()

    log_(LEVEL_INFO, log, "ICE started mission, running AH")

    repeat
        IPC.AutoHook.DeleteAllAnonymousPresets()
        IPC.AutoHook.SetPluginState(true)
        IPC.AutoHook.CreateAndSelectAnonymousPreset(
            "AH4_H4sIAAAAAAAACq2U227bMAyGX2XgtQ3Yjk/xXRo0RYG0K5ruqtgFI9OxEFfKJLlrV+TdB/nQxDkswNC7hBS//ydF+QMmtZFT1EZPixVkH3AtcFnRpKogM6omBx6JoTYTwV/QcCmmKBh9Jqdl/XIuhdrMuaAdNO9TtzlkQTp24EFxqbh5h8x34FZfv7Gqzinfhe35bcu6k5KVFtb8CM5h49SBm81TqUiXssoh8z1vIPRvpXPIPYB30aqdyhl/oe+FFwz2EFlVxIzldIX+/rHgsgupco5VD4j9cAAIu2Mzrsvrd9J7QtGBwygaOIz7G8E1LUpemCvkjU8b0H1gYZCtNWTR5xSPufvUcUd9QMNJMNrzEx/WxcOJBX2p4n9oiqbdk171sDo4mPeoq34qseK41jN8lcoCBoG+nZEzjD8Sk6+kIPPtkE6vz8UrH1qcLOUrQVZgpfu7vOKrG3xpZjIRq4qU7v3YPcghGyVeeNToQCPd2vV+Mwq7l24v6UkufuPmVpia2xd8g1z0o3N9B+a1ojvSGlcEGYAD940JuJeCwGkJ7xuCzM7wBG8utflv3oMiTacdggtn8q1ik9/5WWyIGYXVtFaKhPmiLg+oX9brSbdHHZ9Ub061C7IwcmOfNherhaFN84Xdee+WaKK+xvI+rvHwQ/BfNVkueGkU+cxnbk7F0g1Z4LkpGy3dPGSYsDgpkmUKWwfmXJvvhdXQkD3/7APdZ38XsE21/1sHncc7KcW3GWozVE/GoyLBNHKTlI3dMMxTF0cUu0WY5vk4xsCjArZ/AT3TAGUHBwAA"
        )
        --IDK which is better cast or ahstart. ahstart
        Engines.Native.Run('/ahstart')
        --Actions.ExecuteAction(289)
        wait(0.1)
    until GetCharacterCondition(43)

    wait_ready(nil, 2)

    turnin_mission()
end

function get_relic_exp(max)
    if Addons.GetAddon("WKSToolCustomize").Ready then
        close_addon("WKSToolCustomize")
        wait(5)
    end
    max = default(max, false)
    open_addon("WKSToolCustomize", "WKSHud", true, 15)
    local addon = Addons.GetAddon("WKSToolCustomize")
    if not addon.Exists or not addon.Ready then
        StopScript("No WKS Tool", CallerName(false), "Failed to get the research screen")
    end
    local completed = true
    local EXP_COUNT = 5
    local exp_needed = {}
    for i = 1, EXP_COUNT do
        local current = tonumber(addon:GetAtkValue(80 + i).ValueString)
        local base_target = tonumber(addon:GetAtkValue(90 + i).ValueString)
        local max_target = tonumber(addon:GetAtkValue(100 + i).ValueString)
        if base_target ~= 0 then
            completed = false
        end
        if max then
            exp_needed[i] = max_target - current
        else
            exp_needed[i] = base_target - current
        end
    end
    close_addon("WKSToolCustomize")
    return exp_needed, completed
end

function fish_relic(max)
    repeat
        local exp, finished = get_relic_exp(max)
        local ready = true
        for t, need in ipairs(exp) do
            if need > 0 then
                ready = false
                log_(LEVEL_INFO, log, "Need", need, "type", t, "research")
                if t == 1 or t == 2 then
                    start_fisher_mission(986)
                elseif t == 3 or t == 4 or t == 5 then
                    start_fisher_mission(988)
                else
                    StopScript("Bad State", CallerName(false), "Unexpected research type", t)
                end
                break
            end
        end
        if ready and not finished then
            report_research_safe()
        end
    until finished and ready
end
