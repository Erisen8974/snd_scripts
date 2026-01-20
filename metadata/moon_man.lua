--[=====[
[[SND Metadata]]
author: Erisen
version: 1.0.0
description: >-
  Moon Manager


  Control ICE through the fancy new IPCs!
plugin_dependencies:
- ICE
- vnavmesh
- AutoHook
plugins_to_disable:
- TextAdvance
- YesAlready

configs:
  MaxResearch:
    default: false
    description: Get research to cap instead of just target
  HandleRetainers:
    default: true
    description: Interact with summoning bell when AR is ready.
  GambaLimit:
    default: 8000
    description: Lunar Credits to start start spinning the wheel. Must configure ICE to do gamba! 0 to disable.
    min: 0
    max: 10000

  RelicJobs:
    description: Jobs abbreviations to cycle through completing the relic. Dont add any to only run on current job.
    is_choice: false
    choices: ["FSH", "BTN", "MIN"]

  DebugMessages:
    default: false
    description: Show debug logs
[[End Metadata]]
--]=====]

require "moon_man"

GAMBA_TIME = Config.Get("GambaLimit")
PROCESS_RETAINERS = Config.Get("HandleRetainers")
local MAX_RESEARCH = Config.Get("MaxResearch")
local JOBS_LIST = Config.Get("RelicJobs")

if Config.Get("DebugMessages") then
    debug_level = LEVEL_DEBUG
end


log_(LEVEL_INFO, log, "Gamba limit:", GAMBA_TIME, "Max research:", MAX_RESEARCH, "Handle retainers:", PROCESS_RETAINERS)

function run_current_job()
    local current_job = Player.Job
    log_(LEVEL_INFO, log, "Starting auto relic on job", current_job.Name, "(" .. current_job.Abbreviation .. ")")

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
end

if JOBS_LIST.Count == 0 then
    run_current_job()
else
    for job in luanet.each(JOBS_LIST) do
        equip_classjob(job)
        run_current_job()
    end
end
