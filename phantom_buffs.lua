require 'utils'
require 'legacy_interface'

-------------------------------
------- Phantom Jobbies -------
-------------------------------

MKDInfo = "MKDInfo"
MKDSupportJob = "MKDSupportJob"
MKDSupportJobList = "MKDSupportJobList"

phantom_jobbies = {
    Freelancer = { index = 0, status = 4242 },
    Knight = { index = 1, status = 4358 },
    Berserker = { index = 2, status = 4359 },
    Monk = { index = 3, status = 4360 },
    Ranger = { index = 4, status = 4361 },
    Samurai = { index = 5, status = 4362 },
    Bard = { index = 6, status = 4363 },
    Geomancer = { index = 7, status = 4364 },
    TimeMage = { index = 8, status = 4365 },
    Cannoneer = { index = 9, status = 4366 },
    Chemist = { index = 10, status = 4367 },
    Oracle = { index = 11, status = 4368 },
    Thief = { index = 12, status = 4369 },
}

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

function DeterminePhantomJob()
    for name, data in pairs(phantom_jobbies) do
        if HasStatusId(data.status) then
            return name, GetStatusStackCount(data.status) & 0xff
        end
    end
    return nil, nil
end

function SetPhantomJob(job_name)
    local ti = ResetTimeout()
    local job_data = phantom_jobbies[job_name]
    if job_data == nil then
        StopScript("bad name", CallerName(false), "Unknown phantom job", job_name)
    end

    if HasStatusId(job_data.status) then
        log_debug("Phantom job", job_name, "already set")
        return GetStatusStackCount(job_data.status) & 0xff
    end

    log_debug("Setting phantom job to", job_name, "index:", job_data.index)
    open_addon(MKDSupportJob, MKDInfo, false, 1, 0)
    open_addon(MKDSupportJobList, MKDSupportJob, false, 0, 0, 0)

    confirm_addon(MKDSupportJobList, false, 0, job_data.index)


    while not HasStatusId(job_data.status) do
        CheckTimeout(2, ti, CallerName(false), "Waiting for phantom job to be set", job_name)
        wait(.1)
    end
    return GetStatusStackCount(job_data.status) & 0xff
end

function ApplyPhantomBuffs()
    local base_job, _ = DeterminePhantomJob()

    if base_job == nil then
        StopScript("No phantom job set", CallerName(false), "Probably not in instance")
    end

    local global_buffs = {
        RomeosBallad = { id = 41609, job = "Bard", min_level = 2, buff_id = 4244 },
        Fleetfooted = { id = 41597, job = "Monk", min_level = 3, buff_id = 4239 },
        EnduringFortitude = { id = 41589, job = "Knight", min_level = 2, buff_id = 4233 },
    }

    for name, data in pairs(global_buffs) do
        if SetPhantomJob(data.job) >= data.min_level then
            wait(1)
            log_debug("Applying phantom buff", name)
            ApplyPhantomBuff(data.id, data.buff_id)
        else
            log("Not high enough level for global buff", name, "min level:", data.min_level)
        end
        wait(1)
    end

    SetPhantomJob(base_job)
end

function ApplyPhantomBuff(skill_id, buff_id)
    wait(GetSpellCooldown(skill_id) + .1)
    ExecuteAction(skill_id)
    local ti = ResetTimeout()
    while not HasStatusId(buff_id) do
        CheckTimeout(5, ti, CallerName(false), "Waiting for phantom buff to be applied", skill_id, buff_id)
        wait(.1)
    end
end
