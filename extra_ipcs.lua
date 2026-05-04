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

function ar_add_unconditional_sell(plan_name, itemid)
    local i = get_plugin_instance("AutoRetainer")
    local im_settings = _field(i, "API", "Config", "AdditionalIMSettings")

    log(im_settings)

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

function _field(o, field, ...)
    if field == nil then
        return o
    end
    local t = o:GetType()
    local f = get_field(t, field, { private = true, static = true }, false)
    if f == nil then
        f = get_property(t, field, { private = true, static = true }, false)
        if f == nil then
            error("field or property not found", CallerName(false), o, field)
        end
    end
    local res = f:GetValue(o)
    if res == o then
        error("could not get value", CallerName(false), o, field)
    end
    return _field(res, ...)
end

function get_plugin_instance(plugin_name, required)
    required = default(required, true)
    local DalamudReflector = load_type("ECommons.Reflection.DalamudReflector")
    local pluginManager = DalamudReflector.GetPluginManager()
    for plugin in luanet.each(pluginManager.InstalledPlugins) do
        if plugin.Name == plugin_name then
            return _field(plugin, "instance")
        end
    end
    if required then
        error("Plugin not found", CallerName(false), plugin_name)
    end
end
