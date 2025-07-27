require 'utils'
require 'hard_ipc'
import "System"


local GBR = 'GatherBuddyReborn'
local GBR_ENABLED = GBR .. '.IsAutoGatherEnabled'
local GBR_WAITING = GBR .. '.IsAutoGatherWaiting'
local GBR_SET_AUTO_GATHER = GBR .. '.SetAutoGatherEnabled'

function gbr_gather(max_time)
    require_ipc(GBR_SET_AUTO_GATHER, nil, { 'System.Boolean' })
    invoke_action(GBR_SET_AUTO_GATHER, true)
    wait_gbr_idle(max_time)
    invoke_action(GBR_SET_AUTO_GATHER, false)
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
