require "wt_doer"

local GEARSET = Config.Get("GearsetName")

if Config.Get("DebugMessages") then
    debug_level = LEVEL_DEBUG
end

if GEARSET == "" then
    GEARSET = nil
end

do_wt(GEARSET)
