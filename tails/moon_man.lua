local GAMBA_TIME = Config.Get("GambaLimit")
local PROCESS_RETAINERS = Config.Get("HandleRetainers")
local MAX_RESEARCH = Config.Get("MaxResearch")

if Config.Get("DebugMessages") then
    debug_level = LEVEL_DEBUG
end

local current_job = Player.Job

log_(LEVEL_INFO, log, "Starting auto relic on job", current_job.Name, "(" .. current_job.Abbreviation .. ")")
log_(LEVEL_INFO, log, "Gamba limit:", GAMBA_TIME, "Max research:", MAX_RESEARCH, "Handle retainers:", PROCESS_RETAINERS)

if current_job.Abbreviation == "FSH" then
    fish_relic(MAX_RESEARCH)
elseif current_job.IsGatherer then
    gather_relic(MAX_RESEARCH)
elseif current_job.IsCrafter then
    log_(LEVEL_ERROR, log, "Crafters arent supported yet")                                  --craft_relic(MAX_RESEARCH)
else
    log_(LEVEL_ERROR, log, "Invalid job", current_job.Name, "only gatherers are supported") -- update message when crafters are supported
end

log_(LEVEL_INFO, log, "Finished auto relic on job", current_job.Name, "(" .. current_job.Abbreviation .. ")")
