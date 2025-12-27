require 'utils'
require 'luasharp'
require 'wt_doer'

local TOME_DUNGEON_ID = 1314 -- mistwake
local CURRENT_WEEKLY_TOME = 49 -- mnemonics


function get_limited_tome_count()
    local inst = cs_instance("FFXIVClientStructs.FFXIV.Client.Game.InventoryManager")

    return inst:GetTomestoneCount(CURRENT_WEEKLY_TOME),inst:GetWeeklyAcquiredTomestoneCount()
end


function cap_tomes(weekly_limit, total_limit)
    if weekly_limit == nil then
        local InventoryManager = load_type("FFXIVClientStructs.FFXIV.Client.Game.InventoryManager")
        weekly_limit = InventoryManager.GetLimitedTomestoneWeeklyLimit()
        log_(LEVEL_INFO, log, "Auto detected weekly limit:", weekly_limit)
    end
    total_limit = default(total_limit, 2000)

    local cur_count, cur_week = get_limited_tome_count()
    while cur_count < total_limit and cur_week < weekly_limit do
        log_(LEVEL_INFO, log, "Running dungeon, tome count:", cur_count, "weekly count:", cur_week)
        run_content("Dungeons", false, TOME_DUNGEON_ID)
        cur_count, cur_week = get_limited_tome_count()
    end

    log_(LEVEL_INFO, log, "Finished, tome count:", cur_count, "weekly count:", cur_week)

    if cur_week ~= weekly_limit then
        StopScript("NotCapped", CallerName(false), "Normal tome cap reached before weekly cap", cur_count, cur_week)
    end
end