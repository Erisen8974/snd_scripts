require 'utils'

-------------------------------
------- Phantom Jobbies -------
-------------------------------

local MKDInfo = "MKDInfo"
local MKDSupportJob = "MKDSupportJob"
local MKDSupportJobList = "MKDSupportJobList"

local global_buffs = {
    RomeosBallad = { id = 41609, job = 4363, min_level = 2, buff_id = 4244 },
    Fleetfooted = { id = 41597, job = 4360, min_level = 3, buff_id = 4239 },
    EnduringFortitude = { id = 41589, job = 4358, min_level = 2, buff_id = 4233 },
    QuickerStep = { id = 46603, job = 4805, min_level = 2, buff_id = 4799 }
}

local freelancer_id = 4242
local inquiring_mind = 46606

local job_ranges = {
    { 4242, 4242 },
    { 4358, 4369 },
    { 4803, 4805 },
    { 5328, 5335 },
}

function is_jobbie_status(status_info)
    local hit_effect = status_info.HitEffect.RowId
    return hit_effect == 35
end

function calculate_phantom_index(id)
    local status_index = 0
    for _, range in ipairs(job_ranges) do
        if id >= range[1] and id <= range[2] then
            return status_index + id - range[1]
        end
        status_index = status_index + range[2] - range[1] + 1
    end
    error("Unknown phantom job status", id)
end

function calculate_jobbie()
    for s in luanet.each(Player.Status) do
        if s.StatusId ~= 0 then
            local status_info = luminia_row_checked("Status", s.StatusId)
            if status_info ~= nil then
                log_(LEVEL_DEBUG, _text, "Checking status", s.StatusId,
                    "Name:", status_info.Name, status_info)
                if is_jobbie_status(status_info) then
                    local id = s.StatusId
                    return {
                            status = id,
                            index = calculate_phantom_index(id),
                            name = status_info.Name,
                            level = s.Param & 0xff
                        },
                        status_info
                end
            end
        end
    end
    return {
        status = nil,
        index = nil,
        name = nil,
        level = nil
    }
end

function set_phantom_job(job_id)
    local current_job = calculate_jobbie()
    if not current_job then
        error("No phantom job", "Couldnt detect any phantom job status not in a OC area?")
    end

    if current_job.status == job_id then
        log_(LEVEL_DEBUG, _text, "Phantom job already set to", current_job.name)
        return current_job
    end

    local job_idx = calculate_phantom_index(job_id)

    log_(LEVEL_DEBUG, _text, "Setting phantom job to", job_id, "index:", job_idx)
    open_addon(MKDSupportJob, MKDInfo, false, 1, 0)
    open_addon(MKDSupportJobList, MKDSupportJob, false, 0, 0, 0)

    confirm_addon(MKDSupportJobList, false, 0, job_idx)

    local ti = ResetTimeout()
    local new_job = calculate_jobbie()
    while new_job.status ~= job_id do
        if AlertTimeout(1, ti, "Waiting for phantom job to be set", job_id, new_job.status) then
            return {
                status = nil,
                index = nil,
                name = nil,
                level = 0
            }
        end
        wait(.1)
        new_job = calculate_jobbie()
    end
    return new_job
end

function apply_phantom_buffs(allow_freelancer, wait_for_buff, freelancer_check_buff)
    allow_freelancer = default(allow_freelancer, true)
    wait_for_buff = default(wait_for_buff, true)
    freelancer_check_buff = default(freelancer_check_buff, "RomeosBallad")
    local original_job = calculate_jobbie()
    if original_job.name == nil then
        error("No phantom job set", "Probably not in instance")
    end
    local skip_individual = false
    if allow_freelancer then
        local freelancer = set_phantom_job(freelancer_id)
        if freelancer.level >= 15 then
            log_(LEVEL_DEBUG, _text, "Applying all phantom buffs, watching for", freelancer_check_buff)
            apply_phantom_buff(inquiring_mind, global_buffs[freelancer_check_buff].buff_id, wait_for_buff)
            skip_individual = true
        end
    end
    if not skip_individual then
        for name, data in pairs(global_buffs) do
            local tmp_job = set_phantom_job(data.job)
            if tmp_job.level >= data.min_level then
                wait_ready(1, .2, true, .1)
                log_(LEVEL_DEBUG, _text, "Applying phantom buff", name)
                apply_phantom_buff(data.id, data.buff_id, wait_for_buff)
            else
                log_(LEVEL_ERROR, _text, "Not high enough level for global buff", name, "min level:", data.min_level,
                    "current level:", tmp_job.level)
            end
            wait(.1)
        end
    end
    set_phantom_job(original_job.status)
end

function wait_spell_cd(spell_id)
    repeat
        local action = Actions.GetActionInfo(spell_id)
        wait(action.SpellCooldown + .1)
    until action.SpellCooldown == 0
end

function get_phantom_status(status_id)
    for s in luanet.each(Player.Status) do
        if s.StatusId == status_id then
            return s
        end
    end
    return nil
end

function wait_phantom_status_duration(status_id, target_duration)
    local ti = ResetTimeout()
    repeat
        CheckTimeout(10, ti, "Waiting for phantom buff", status_id)
        wait(.1)
        local buff = get_phantom_status(status_id)
        if buff ~= nil then
            log_(LEVEL_DEBUG, _text, "Found target status", status_id, "found", buff.StatusID, "duration needed",
                target_duration, "has", buff.RemainingTime)
        end
    until buff ~= nil and buff.RemainingTime >= target_duration
end

function apply_phantom_buff(spell_id, buff_id, wait_for_buff)
    wait_spell_cd(spell_id)
    Actions.ExecuteAction(spell_id)
    local ti = ResetTimeout()
    if wait_for_buff then
        wait_phantom_status_duration(buff_id, 29 * MINUTES + 55)
    end
end
