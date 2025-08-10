require 'utils'
require 'path_helpers'
require 'inventory_buddy'


local duty_blacklist = {}
function reset_blacklist()
    duty_blacklist = {
        577, -- P1T6 ex, no module support, falls off the platform
        --720, -- emanation ex, no module support, sometimes works, depends if the vril mech is used too fast
        748, -- Phantom train, gets caught by the ghosties and gets stuck
    }
end

function do_wt(gearset)
    reset_blacklist()
    if gearset ~= nil then
        equip_gearset(gearset)
    end
    if not Player.Bingo.HasWeeklyBingoJournal or Player.Bingo.IsWeeklyBingoExpired then
        get_wt()
    end
    while wt_count() < 9 do
        if not wt_duty() then
            log("No Possible Duties", default(CallerName(false), FunctionInfo(true)),
                "Failed to find a duty to fill out wt bingo", wt_count(), 'of 9 done')
            return false
        end
    end
    log("WT Bingo completed", wt_count(), "of 9 done")
    return true
end

function log_wt()
    log("---- WT Info ----")
    for i = 0, 15 do
        local cell = Player.Bingo:GetWeeklyBingoTaskStatus(i)
        local duty = Player.Bingo:GetWeeklyBingoOrderDataRow(i)

        log("Wt item", i + 1, duty.Type, wt_item_name(duty), "Level:", extract_level(duty), duty.RowId, cell)
        local instance = wt_pick_duty(duty)
        if instance == nil then
            log("Not supported")
        else
            local instance_id = instance.TerritoryType.RowId
            local type, unsync = wt_duty_type(instance)
            if duty_executable(instance) then
                log("Using:", type, unsync, '-', instance.Name, '-', instance_id, '-',
                    IPC.AutoDuty.ContentHasPath(instance_id))
            end
        end
    end
    log("Completed:", wt_count(), "of 9")
end

function get_wt()
    RunVislandRoute(
        "H4sIAAAAAAAACu1SyW7bMBD9leKdGYNyEjjmrVAWuIVdJ3HhLOiBqSYWAZHjiqMUgaF/Dygri5trTkF54czDzJs3ywYz6wkGP0OwnoovF9wIQeGs5mbd4atkUQGFU+YCRitMbWhs1ZkLW69IzqyUVE+EfAcu7eOaXZAIc7vBnKMTxwFmgyuYvWw8OBqNR3qocA0zzLKBVriB0YNM7x+ODg/GrcINB5ocwxyMjhQubOGaCDNOL0VP+YE8BYEZKsytlPcuFDBSN6QwCUK1/S1LJ+WPxKF3sb5j7KL/qNSpzHX/d+J0qxBL/vuc5DhEmHtbxTc1O4JM4cSz0HNtId+bX7uI3jlvKMpb+5L+bMfLdz18KbzOORS9Mq3w3VVVzk1qXSt023rtJy+t5Oy9TcNIQNK7tE5ehSbvlOtd0gQunKdp3HFPFu+H0SpM4ry0Qdi/kKYNwISmqhRmREWcbhVu97E9DhdWi8c1pSUmihkX9JKfnG98B6Nb9ZH3Mvx/K/knvpVf7RMEuPS/vwQAAA==",
        "Going to Khloe")

    if Player.Bingo.HasWeeklyBingoJournal and not Player.Bingo.IsWeeklyBingoExpired then
        StopScript("AlreadyHaveWT", CallerName(false),
            "Weekly Bingo Journal already exists and is not expired, turn in first")
    end

    repeat
        local entity = get_closest_entity("Khloe Aliapoh", true)
        entity:SetAsTarget()
        entity:Interact()
        wait(.1)
        CheckTimeout(2, ti, "AcceptQuest", "Talking to Khloe Aliapoh didnt work")
        wait(.1)
    until IsAddonReady("Talk") or IsAddonReady("SelectString")

    while wait_any_addons("SelectString", "Talk") == "Talk" do
        close_talk()
        wait(0.1)
    end

    SelectInList("Receive a new journal from Khloe.", "SelectString")

    local ti = ResetTimeout()
    repeat
        CheckTimeout(10, ti, "GetWeeklyBingoJournal", "Waiting for Weekly Bingo Journal to be received")
        close_talk()
        wait(.1)
    until not is_busy() and Player.Bingo.HasWeeklyBingoJournal
end

function wt_duty()
    for i = 0, 15 do
        local cell = Player.Bingo:GetWeeklyBingoTaskStatus(i)
        if cell ~= WeeklyBingoTaskStatus.Open then
            log_debug("Bingo cell", i, "not available", cell)
        else
            local duty = Player.Bingo:GetWeeklyBingoOrderDataRow(i)
            local content = wt_pick_duty(duty)
            if content == nil then
                log_debug("Bingo cell", i, "not supported type", wt_item_name(duty))
            else
                -- try to do the duty
                local instance_id = content.TerritoryType.RowId
                local type, unsync = wt_duty_type(content)
                if duty_executable(content) then
                    log("Using:", type, unsync, '-', content.Name, '-', instance_id, '-',
                        IPC.AutoDuty.ContentHasPath(instance_id))
                    run_content(type, unsync, instance_id)
                    return true
                end
            end
        end
    end
    return false
end

function run_content(type, unsync, instance_id)
    setup_content(type, unsync)
    local count = wt_count()
    IPC.AutoDuty.Run(instance_id, 1, false)
    repeat
        wait(1)
    until IPC.AutoDuty.IsStopped()
    if count == wt_count() then
        log_debug("Duty failed? Still in instance?", Svc.ClientState.TerritoryType, instance_id)
        table.insert(duty_blacklist, instance_id)
        if Svc.ClientState.TerritoryType == instance_id then
            yield('/pdfleave')
        end
        wait_ready()
    end
end

function setup_content(type, unsync)
    if type == "Dungeons" and unsync then
        IPC.AutoDuty.SetConfig("dutyModeEnum", "Regular")
        IPC.AutoDuty.SetConfig("Unsynced", "True")
    elseif type == "Dungeons" and not unsync then
        IPC.AutoDuty.SetConfig("dutyModeEnum", "Trust")
    elseif type == "Raids" then
        IPC.AutoDuty.SetConfig("dutyModeEnum", "Raid")
        IPC.AutoDuty.SetConfig("Unsynced", "True")
    elseif type == "Trials" then
        IPC.AutoDuty.SetConfig("dutyModeEnum", "Trial")
        IPC.AutoDuty.SetConfig("Unsynced", "True")
    else
        StopScript("NotImplemented", CallerName(false), "Duty type", type, unsync, "not configured")
    end
end

function duty_executable(content)
    local instance_id = content.TerritoryType.RowId
    local type, unsync = wt_duty_type(content)
    if not unsync and type ~= "Dungeons" then
        log_debug("Not supported", content.Name, "type", type, "must be unsynced but allow undersized is", unsync)
        return false
    elseif type == "Trials" and content.ClassJobLevelRequired > 70 then
        log_debug("Not supported", content.Name, "type", type, "dont work well above level 70 but needs",
            content.ClassJobLevelRequired)
        return false
    elseif not IPC.AutoDuty.ContentHasPath(instance_id) then
        log_debug("Not supported", content.Name, "- No autoduty path")
        return false
    elseif list_contains(duty_blacklist, instance_id) then
        log("Blacklisted duty,", content.Name, '-', instance_id, "has been blacklisted")
        return false
    end
    return true
end

function get_duty_row(duty_id)
    local duty = Excel.GetRow("InstanceContent", duty_id)
    if duty == nil then
        return StopScript("InvalidDuty", CallerName(false), "no duty with ID", duty_id)
    end
    return duty.ContentFinderCondition
end

function get_content_row(content_id)
    local duty = Excel.GetRow("TerritoryType", content_id)
    if duty == nil then
        return StopScript("InvalidDuty", CallerName(false), "no duty with territory ID", content_id)
    end
    return duty.ContentFinderCondition
end

function wt_pick_high_level_duty(level)
    if level == 50 then
        --return get_content_row(350)  --Haukke Manor Hard, not stable, runs into walls in candle hall
        return get_content_row(387) --Sastasha Hard
    elseif level == 70 then
        return get_content_row(742) --Hell's Lid
    elseif level == 90 then
        --return get_content_row(973)  --The Dead Ends, not stable, first boss has mechanic requiring 2 players
        --return get_content_row(976)  --Smileton, no bossmod support
        return get_content_row(1070) --The Fell Court of Troia, no bossmod support
    elseif level == 100 then
        return get_content_row(1266) --The Underkeep
    end
    StopScript("NotImplemented", nil, "High level duty Lv.", level, "is not implemented")
end

function wt_pick_leveling_duty(level)
    if level == 1 then
        return get_content_row(1040) -- Haukke Manor
    elseif level == 51 then
        return get_content_row(434)  -- Dusk Vigil
    elseif level == 81 then
        return get_content_row(952)  -- Tower of Zot
    end
    StopScript("NotImplemented", nil, "Leveling duty Lv.", level, "is not implemented")
end

function extract_level(duty)
    local name = wt_item_name(duty)
    local s, e = name:find("Lv%. %d+")
    if s == nil then
        return nil
    end
    -- skip the "Lv. "
    s = s + 4
    return tonumber(name:sub(s, e))
end

local UNSUPPORTED_RAID_IDS = {
    26, 27, 28, 29, 30, -- Alliance raids by expansion
    23, 24,             -- Eden
    31, 32, 33, 37,     -- Pandora
    34, 35,             -- AAC Light-heavyweight
}

function raid_id_to_duty(raid_id)
    if list_contains(UNSUPPORTED_RAID_IDS, raid_id) then
        return nil
    elseif raid_id == 2 then
        -- Binding Coil of Bahamut
        return get_content_row(242) -- Turn 2
    elseif raid_id == 4 then
        -- Final Coil of Bahamut
        return get_content_row(195) -- Turn 3
    elseif raid_id == 6 then
        -- Alexander: The Son
        return get_content_row(520) -- Fist of the Son
    elseif raid_id == 7 then
        -- Alexander: The Creator
        return get_content_row(580) -- Eyes of the Creator
    elseif raid_id == 9 then
        -- Sigmascape
        --return get_content_row(748) -- Phantom Train
        return get_content_row(750) -- TV guy
    elseif raid_id == 10 then
        -- Alphascape
        return get_content_row(798) -- Chaos!
    elseif raid_id == 25 then
        -- Edens Promise
        return get_content_row(943) -- Litany
    end
    StopScript("NotImplemented", nil, "Raid", raid_id, "is not implemented")
end

-- I dont think they use most of these anymore, so just crash and implement it when they come up.
function wt_pick_duty(duty)
    if duty.Type == 0 then
        -- Specicfic duty, Data == duty_id
        return get_duty_row(duty.Data)
    elseif duty.Type == 1 then
        -- X0 dungeons, Data == X0
        return wt_pick_high_level_duty(extract_level(duty))
    elseif duty.Type == 2 then
        -- X1-X9 dungeons, Data == X9
        StopScript("NotImplemented")
    elseif duty.Type == 3 then
        -- Special (PvP, treasure, etc.)
        return nil
    elseif duty.Type == 4 then
        -- Normal/Alliance raids, Data == Specific raid index
        return raid_id_to_duty(duty.Data)
    elseif duty.Type == 5 then
        -- X1-Y9 Leveling dungeons, Data == Y9
        return wt_pick_leveling_duty(extract_level(duty))
    elseif duty.Type == 6 then
        -- X0,Y0 High level dungeons, Data == Y0
        return wt_pick_high_level_duty(extract_level(duty))
    elseif duty.Type == 7 then
        -- X0-Y0 Trials, Data == Y0
        StopScript("NotImplemented")
    elseif duty.Type == 8 then
        -- X0-Y0 Alliance Raids, Data == Y0
        StopScript("NotImplemented")
    elseif duty.Type == 9 then
        -- X0-Y0 Normal Raids, Data == Y0
        StopScript("NotImplemented")
    end
end

function wt_item_name(duty)
    if duty.Type == 0 then
        return get_duty_row(duty.Data).Name
    else
        return duty.Text.Description
    end
end

function wt_duty_type(content_instance)
    return content_instance.ContentType.Name, content_instance.AllowUndersized
end

function wt_count()
    local count = 0
    for i = 0, 15 do
        local cell = Player.Bingo:GetWeeklyBingoTaskStatus(i)
        if cell == WeeklyBingoTaskStatus.Claimable or cell == WeeklyBingoTaskStatus.Claimed then
            count = count + 1
        end
    end
    return count
end
