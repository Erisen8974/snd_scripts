require 'utils'
require 'hard_ipc'
import "System"


local GBR = 'GatherBuddyReborn'
local GBR_ENABLED = GBR .. '.IsAutoGatherEnabled'
local GBR_WAITING = GBR .. '.IsAutoGatherWaiting'
local GBR_SET_AUTO_GATHER = GBR .. '.SetAutoGatherEnabled'

function gbr_gather(max_time)
    require_ipc(GBR_SET_AUTO_GATHER, nil, { 'System.Boolean' })
    invoke_ipc(GBR_SET_AUTO_GATHER, true)
    wait_gbr_idle(max_time)
    invoke_ipc(GBR_SET_AUTO_GATHER, false)
end

function wait_gbr_idle(max_wait)
    require_ipc(GBR_WAITING, 'System.Boolean', {})
    require_ipc(GBR_ENABLED, 'System.Boolean', {})
    local ti = nil
    if max_wait ~= nil then
        ti = ResetTimeout()
    end
    repeat
        if ti ~= nil then
            CheckTimeout(max_wait, ti, CallerName(), "wait_gbr_idle timed out")
        end
        wait(1)
        local waiting = invoke_ipc(GBR_WAITING)
        local enabled = invoke_ipc(GBR_ENABLED)
    until not enabled or waiting
end

local STYLIST = 'Stylist'
local STYLIST_IS_BUSY = STYLIST .. '.IsBusy'
local STYLIST_UPDATE_CURRENT_GEARSET = STYLIST .. '.UpdateCurrentGearset'

function stylist_update_current_gearset()
    require_ipc(STYLIST_IS_BUSY, 'System.Boolean', {})
    require_ipc(STYLIST_UPDATE_CURRENT_GEARSET, nil, { 'System.Boolean' })
    local ti = ResetTimeout()
    invoke_ipc(STYLIST_UPDATE_CURRENT_GEARSET, true)
    repeat
        CheckTimeout(30, ti, CallerName(), "Stylist is busy")
        wait(0.5)
    until not invoke_ipc(STYLIST_IS_BUSY)
end
