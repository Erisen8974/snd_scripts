require 'utils'
require 'legacy_interface'

-------------------------------
------- Phantom Jobbies -------
-------------------------------

MKDInfo = "MKDInfo"
MKDSupportJob = "MKDSupportJob"
MKDSupportJobList = "MKDSupportJobList"


job_ranges = {
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

function och_illegal(state)
    yield("/ochillegal " .. bool_to_string(state, "on", "off"))
end

function main_crystal()
    local x = 837
    local y = 73
    local z = -707
    if GetDistanceToPoint(x, y, z) > 30 then
        yield("/gaction return")
        ZoneTransition()
    end
    WalkTo(x, y, z)
    while GetCharacterCondition(4) do
        yield('/ac dismount')
        wait(.1)
    end
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

function apply_phantom_buffs(allow_freelancer)
    allow_freelancer = default(allow_freelancer, true)
    local original_job = calculate_jobbie()
    if original_job.name == nil then
        error("No phantom job set", "Probably not in instance")
    end
    local skip_individual = false
    if allow_freelancer then
        local freelancer = set_phantom_job(4242)
        if freelancer.level >= 15 then
            local inquiring_mind = 46606
            log_(LEVEL_DEBUG, _text, "Applying all phantom buffs")
            wait_spell_cd(inquiring_mind)
            Actions.ExecuteAction(inquiring_mind)
            skip_individual = true
        end
    end
    if not skip_individual then
        local global_buffs = {
            RomeosBallad = { id = 41609, job = 4363, min_level = 2, buff_id = 4244 },
            Fleetfooted = { id = 41597, job = 4360, min_level = 3, buff_id = 4239 },
            EnduringFortitude = { id = 41589, job = 4358, min_level = 2, buff_id = 4233 },
            QuickerStep = { id = 46603, job = 4805, min_level = 2, buff_id = 4799 }
        }
        for name, data in pairs(global_buffs) do
            local tmp_job = set_phantom_job(data.job)
            if tmp_job.level >= data.min_level then
                wait_ready(1, .2, true, .1)
                log_(LEVEL_DEBUG, _text, "Applying phantom buff", name)
                apply_phantom_buff(data.id, data.buff_id)
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

function apply_phantom_buff(spell_id, buff_id)
    wait_spell_cd(spell_id)
    Actions.ExecuteAction(spell_id)
    local ti = ResetTimeout()
    while not HasStatusId(buff_id) do
        CheckTimeout(5, ti, "Waiting for phantom buff to be applied", spell_id, buff_id)
        wait(.1)
    end
end
