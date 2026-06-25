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
    Player.Gearset:Update()
    require_ipc(STYLIST_IS_BUSY, 'System.Boolean', {})
    require_ipc(STYLIST_UPDATE_CURRENT_GEARSET, nil, { 'System.Boolean' })
    local ti = ResetTimeout()
    invoke_ipc(STYLIST_UPDATE_CURRENT_GEARSET, true)
    repeat
        CheckTimeout(30, ti, CallerName(), "Stylist is busy")
        wait(0.5)
    until not invoke_ipc(STYLIST_IS_BUSY)
end

function stylist_update_all()
    local start = os.clock()
    Engines.Native.Run("/stylist all")
    repeat
        wait(0)
    until stylist_is_busy() or start + 1 < os.clock()

    while stylist_is_busy() do
        wait(.5)
    end
end

function stylist_is_busy()
    require_ipc(STYLIST_IS_BUSY, 'System.Boolean', {})
    return invoke_ipc(STYLIST_IS_BUSY)
end

local AUTORETAINER = 'AutoRetainer'
local AUTORETAINER_GETCONFIG = AUTORETAINER .. '.GetConfig'
local AUTORETAINER_GETCONFIG_SHUTDOWN = AUTORETAINER_GETCONFIG .. '.ShutdownOnSubExhaustion'

function autoretainer_shutdown()
    require_ipc(AUTORETAINER_GETCONFIG_SHUTDOWN, 'System.Boolean', {})
    return invoke_ipc(AUTORETAINER_GETCONFIG_SHUTDOWN)
end

function ar_is_active(buffer_time)
    buffer_time = default(buffer_time, 3 * MINUTES)
    return IPC.AutoRetainer.GetMultiModeEnabled() and (
        IPC.AutoRetainer.IsBusy() or
        ar_multi_mode_would_start(buffer_time)
    )
end

function ar_add_unconditional_sell(plan_name, itemid)
    local i = get_plugin_instance(AUTORETAINER)
    local im_settings = _field(i, "API", "Config", "AdditionalIMSettings")

    for settings in luanet.each(im_settings) do
        if settings.Name == plan_name then
            if settings.IMProtectList:Contains(itemid) then
                log_(LEVEL_ERROR, _text, "Item is in protected list", plan_name, itemid)
                return false
            end
            if settings.IMAutoVendorHard:Contains(itemid) then
                log_(LEVEL_INFO, _text, "Item is already in unconditional sell list", plan_name, itemid)
                return true
            end
            settings.IMAutoVendorHard:Add(itemid)
            log_(LEVEL_INFO, _text, "Added item to AutoRetainer unconditional sell list", plan_name, itemid)
            return true
        end
    end
    log_(LEVEL_ERROR, _text, "Failed to add item to AutoRetainer unconditional sell list, plan not found", plan_name,
        itemid)
    return false
end

function ar_multi_mode_would_start(venture_buffer)
    venture_buffer = default(venture_buffer, 60)
    local chars = IPC.AutoRetainer.GetRegisteredCharacters()
    local now = os.time()
    for cid in luanet.each(chars) do
        local char = IPC.AutoRetainer.GetOfflineCharacterData(cid)
        local next_ready = IPC.AutoRetainer.GetClosestRetainerVentureSecondsRemaining(cid)
        log_(LEVEL_VERBOSE, _text, char.Name, char.Enabled, char.AnyAwaitingProcessing, next_ready)
        if char.Enabled then
            if char.AnyAwaitingProcessing or next_ready < venture_buffer then
                return true
            end
            for sub in luanet.each(char.OfflineSubmarineData) do
                local return_time = sub.ReturnTime
                log_(LEVEL_VERBOSE, _text, "Submarine", return_time - now)
                if return_time - now < venture_buffer then
                    return true
                end
            end
        end
    end
    return false
end

local QUESTY = 'Questionable'

function _zone_has_unlocked_aetheryte()
    local zone = Svc.ClientState.TerritoryType
    local row = luminia_row_checked("TerritoryType", zone).Aetheryte.RowId
    if row == 0 then
        return false
    end
    return Instances.Telepo:IsAetheryteUnlocked(row)
end

function _questy_get_quest_controller()
    local i = get_plugin_instance(QUESTY)
    local t = i:GetType().Assembly
    local _serviceProvider = _field(i, "_serviceProvider")
    local di_t = t:GetType("Questionable.DalamudInitializer")
    local di = _serviceProvider:GetService(di_t)
    return _field(di, "_questController")
end

function _questy_get_duties()
    local i = get_plugin_instance(QUESTY)
    local t = i:GetType().Assembly
    local _serviceProvider = _field(i, "_serviceProvider")
    local duty_config_t = t:GetType("Questionable.Windows.ConfigComponents.DutyConfigComponent")
    local duty_config = _serviceProvider:GetService(duty_config_t)
    return _field(duty_config, "Configuration", "Duties")
end

function questy_stop_soon()
    local quest_controller = _questy_get_quest_controller()
    local duties = _questy_get_duties()
    duties.RunInstancedContentWithAutoDuty = false
    --quest_controller.StopAfterCurrentQuest = true
    quest_controller.StopBeforeTeleport = true
end

function questy_reenable()
    local duties = _questy_get_duties()
    duties.RunInstancedContentWithAutoDuty = true
end

function questy_stop_blocking(interval)
    local interval = default(interval, 10)
    questy_stop_soon()
    repeat wait(interval) until not IPC.Questionable.IsRunning()
    log_(LEVEL_DEBUG, _text, "Questy stopped, running multi mode")
    questy_reenable()
end

local LIFESTREAM = 'Lifestream'

function lifestream_command_blocking(command, player_ready, max_wait)
    log_(LEVEL_DEBUG, _text, "Executing Lifestream command", command)
    IPC.Lifestream.ExecuteCommand(command)

    lifestream_block(player_ready, max_wait)
end

function lifestream_block(player_ready, max_wait)
    running_lifestream = true
    player_ready = default(player_ready, true)
    repeat wait(.1) until IPC.Lifestream.IsBusy()
    log_(LEVEL_DEBUG, _text, "Lifestream command is running")
    repeat wait(1) until not IPC.Lifestream.IsBusy()
    log_(LEVEL_DEBUG, _text, "Lifestream command finished")

    if player_ready then
        wait_ready(max_wait, 1, true, .5)
        log_(LEVEL_DEBUG, _text, "Lifestream command player ready")
    end
end

local AUTODUTY = 'AutoDuty'

function ad_helper_running()
    local ad = get_plugin_instance(AUTODUTY)
    local ass = ad:GetType().Assembly
    local helper = ass:GetType("AutoDuty.Helpers.ActiveHelper")
    local m = get_method(helper, "AnyHelperRunning", { static = true })
    local arg_array = luanet.make_array(Object, {})
    local res = m:Invoke(helper, arg_array)
    return res
end

function wait_ad(command)
    local s = os.clock()
    if command then
        log_(LEVEL_DEBUG, _text, 'Executing AutoDuty command', command)
        yield("/ad " .. command)
    end
    repeat wait(.1) until ad_helper_running() or os.clock() - s > 1
    log_(LEVEL_DEBUG, _text, 'AD Started (or time)')
    repeat wait(1) until not ad_helper_running()
    log_(LEVEL_DEBUG, _text, 'AD Done')
end
