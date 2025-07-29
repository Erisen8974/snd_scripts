require 'legacy_interface'

import 'System.Numerics'


-----------------------
-- General Utilities --
-----------------------

function default(value, default_value)
    if value == nil then return default_value end
    return value
end

function wait(duration)
    yield('/wait ' .. string.format("%.1f", duration))
end

function pause_pyes()
    pyes_pause_count = default(pyes_pause_count, 0)
    pyes_pause_count = pyes_pause_count + 1
    IPC.YesAlready.SetPluginEnabled(false)
end

function resume_pyes()
    if pyes_pause_count == nil then
        return
    end
    pyes_pause_count = pyes_pause_count - 1
    if pyes_pause_count == 0 then
        IPC.YesAlready.SetPluginEnabled(true)
    end
end

function find_after(msg, target, after)
    e, s = msg:reverse():find(after:reverse())
    if e == nil then
        return nil -- cant find something after something if the second thing doesnt exist!
    end
    return string.find(msg, target, -e)
end

function get_chat_messages(tab)
    local chat = GetNodeText("ChatLogPanel_" .. tostring(tab), 1, 2, 3)
    if chat == 2 then
        StopScript("Error getting chat log")
    end
    return chat
end

function wait_message(after, timeout, ...)
    local ti = ResetTimeout()
    local messages = { ... }
    local found = false

    timeout = default(timeout, 10)
    repeat
        CheckTimeout(timeout, ti, CallerName(false), "Waiting for message '" .. after .. "' followed by", ...)
        wait(.1)
        for i = 1, #messages do
            if find_after(get_chat_messages(3), messages[i], after) then
                found = true
            end
        end
    until found
end

function open_addon(addon, base_addon, ...)
    wait_any_addons(base_addon)
    local ti = ResetTimeout()
    while not IsAddonReady(addon) do
        CheckTimeout(1, ti, CallerName(false), "Opening addon", addon)
        if not IsAddonReady(base_addon) then
            StopScript("open_addon failed", CallerName(false), "Failed opening", addon,
                "base addon missing or not ready",
                base_addon)
        end
        SafeCallback(base_addon, ...)
        wait(0.1)
    end
    while not IsAddonReady(addon) do
        CheckTimeout(1, ti, CallerName(false), "Waiting for addon ready", addon)
        wait(0.1)
    end
end

function confirm_addon(addon, ...)
    local ti = ResetTimeout()
    while IsAddonReady(addon) do
        CheckTimeout(1, ti, CallerName(false), "Confirming addon", addon)
        SafeCallback(addon, ...)
        wait(0.1)
    end
end

function talk(who, what_addon)
    what_addon = default(what_addon, "SelectString")
    repeat
        local entity = Entity.GetEntityByName(who)
        if entity then
            entity:Interact()
        end
        wait(.5)
    until IsAddonReady(what_addon)
end

function close_yes_no(accept, expected_text)
    accept = default(accept, false)
    if IsAddonReady("SelectYesno") then
        if expected_text ~= nil then
            local node = GetNodeText("SelectYesno", 1, 2)
            if node == nil or not node:find(expected_text) then
                log_debug("Expected yesno text '" .. expected_text .. "' didnt match actual text:", node)
                return
            end
        end
        if accept then
            SafeCallback("SelectYesno", true, 0)
        else
            SafeCallback("SelectYesno", true, 1)
        end
    end
end

function close_talk()
    pause_pyes()
    local ti = ResetTimeout()
    while IsAddonReady("Talk") do
        yield("/click Talk Click")
        CheckTimeout(1, ti, CallerName(false), "Finishing talking")
        wait(.1)
    end
    resume_pyes()
end

function close_addon(addon)
    local ti = ResetTimeout()
    while IsAddonReady(addon) do
        CheckTimeout(1, ti, CallerName(false), "Closing addon", addon)
        SafeCallback(addon, true, -1)
        wait(0.1)
    end
end

function wait_any_addons(...)
    target_addons = { ... }
    local ti = ResetTimeout()
    while true do
        for _, v in pairs(target_addons) do
            if IsAddonReady(v) then
                return v
            end
        end
        CheckTimeout(30, ti, CallerName(false), "Waiting for addons", ...)
        wait(0.1)
    end
end

function open_retainer_bell()
    OpenShop("Summoning Bell", "RetainerList")
    if IPC.AutoRetainer.AreAnyRetainersAvailableForCurrentChara() then
        repeat
            wait(1)
        until not IPC.AutoRetainer.IsBusy()
    end
    wait_any_addons("RetainerList")
end

function is_busy()
    return Player.IsBusy or GetCharacterCondition(6) or GetCharacterCondition(26) or GetCharacterCondition(27) or
        GetCharacterCondition(45) or GetCharacterCondition(51) or GetCharacterCondition(32) or
        not (GetCharacterCondition(1) or GetCharacterCondition(4)) or
        (not IPC.vnavmesh.IsReady()) or IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()
end

function wait_ready(max_wait, n_ready, stationary)
    stationary = default(stationary, true)
    n_ready = default(n_ready, 5)
    local ready_count = 0
    local ti = nil
    local p = Entity.Player.Position
    if max_wait ~= nil then
        ti = ResetTimeout()
    end
    repeat
        if ti ~= nil then
            CheckTimeout(max_wait, ti, CallerName(), "wait_ready timed out with ready count", ready_count, "and target",
                n_ready)
        end
        wait(1)
        if is_busy() or (stationary and Vector3.Distance(p, Entity.Player.Position) > 1) then
            p = Entity.Player.Position
            ready_count = 0
        else
            ready_count = ready_count + 1
        end
    until ready_count >= n_ready
end

function luminia_row_checked(table, id)
    local sheet = Excel.GetSheet(table)
    if sheet == nil then
        StopScript("Unknown sheet", CallerName(false), "sheet not found for", table)
    end
    local row = sheet:GetRow(id)
    if row == nil then
        StopScript("Unknown id", CallerName(false), "Id not found in excel data", table, id)
    end
    return row
end

function atk_data_checked(addon, index)
    local w = Addons.GetAddon(addon)
    if not (w.Exists and w.Ready) then
        StopScript("No addon", CallerName(false), "addon", addon, "not ready")
    end
    local r = w:GetAtkValue(index)
    if r == nil then
        StopScript("Bad atk index", CallerName(false), "addon", addon, "does not have index", index)
    end
    return r.ValueString
end

ListSelectionType = {
    ContextMenu = { name_offset = 6, click_offset = 0 },
    RetainerList = { name_offset = 3, click_offset = 2 },
    SelectString = { name_offset = 3 },
}

-- 0 indexed
function list_index(base, index)
    if index == 0 then
        return base
    end
    return base * 10000 + 1000 + index
end

function GetListElement(menu, index)
    local a = Addons.GetAddon(menu)
    if not a.Ready then
        StopScript("Bad addon", CallerName(false), menu)
    end
    local n = nil
    if menu == "ContextMenu" then
        n = a:GetNode(1, 2, list_index(3, index), 2, 3)
    elseif menu == "RetainerList" then
        n = a:GetNode(1, 27, list_index(4, index), 2, 3)
    elseif menu == "SelectString" then
        n = a:GetNode(1, 3, list_index(5, index), 2)
    else
        StopScript("Unknown addon", CallerName(false), menu)
    end
    if tostring(n.NodeType):find("Text:") == nil then
        log_debug("Not a text node", CallerName(false), "NodeType:", n.NodeType, "NodeId:", n.Id, name, menu, index)
        return nil
    end
    return n.Text
end

function ListContents(menu)
    menu = default(menu, "ContextMenu")
    local offsets = ListSelectionType[menu]
    wait_any_addons(menu)
    local list_items = {}
    for i = 0, 21 do
        entry = GetListElement(menu, i)
        if entry == nil then break end
        if entry ~= "" then
            table.insert(list_items, entry)
        end
    end
    return list_items
end

function SelectInList(name, menu)
    local string = name
    local click
    menu = default(menu, "ContextMenu")
    local offsets = ListSelectionType[menu]
    ::Retry::
    wait_any_addons(menu)
    if string then
        for i = 0, 21 do
            local entry = GetListElement(menu, i)
            if entry == nil then break end
            log_debug("List item", entry)
            if entry == string then
                click = i
                break
            end
        end
        if click then
            if offsets.click_offset ~= nil then
                SafeCallback(menu, true, offsets.click_offset, click)
            else
                SafeCallback(menu, true, click)
            end
            if string == "Second Tier" then
                string = name
                click = nil
                menu = "AddonContextSub"
                yield("/wait 0.1")
                goto Retry
            end
        elseif string ~= "Second Tier" then
            string = "Second Tier"
            goto Retry
        end
    end
    if click then return true else return false end
end

function list_contains(table, element)
    if table == nil then
        -- A non-existant table does not contain anything
        -- This abstraction allows not initializing if there is no items in some uses
        return false
    end
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function SafeCallback(addon, update, ...)
    pause_pyes()
    local callback_table = table.pack(...)
    if type(addon) ~= "string" then
        StopScript("addonname must be a string")
    end
    if type(update) == "boolean" then
        update = tostring(update)
    else
        StopScript("update must be a bool")
    end

    local call_command = "/callback " .. addon .. " " .. update
    for i = 1, callback_table.n do
        local value = callback_table[i]
        if type(value) == "number" then
            call_command = call_command .. " " .. tostring(value)
        else
            StopScript("Callbacks have to use numbers!")
        end
    end
    if IsAddonReady(addon) then
        yield(call_command)
    end
    resume_pyes()
end

function bool_to_string(state, true_string, false_string)
    true_string = default(true_string, "true")
    false_string = default(false_string, "false")
    if type(state) == "boolean" then
        if state then
            return true_string
        else
            return false_string
        end
    else
        StopScript("state must be a bool")
    end
end

--------------------
-- Error Handling --
--------------------

function require_plugins(plugins)
    if #plugins == 0 then
        return
    end
    for p in luanet.each(Svc.PluginInterface.InstalledPlugins) do
        for i, v in ipairs(plugins) do
            if p.IsLoaded and p.InternalName == v then
                table.remove(plugins, i)
                if #plugins == 0 then
                    return
                end
                break
            end
        end
    end
    if #plugins > 0 then
        StopScript("Missing required plugins", CallerName(false), "Missing plugins:", table.concat(plugins, ", "))
    end
end

function StopScript(message, caller, ...)
    caller = default(caller, CallerName())
    log("Fatal error " .. message .. " in " .. caller .. ": ", ...)
    yield("/qst stop")
    IPC.Lifestream.Abort()
    IPC.visland.StopRoute()
    IPC.vnavmesh.Stop()
    yield("/snd stop all")
    local die = nil
    die() -- crash cause idk how to stop
end

function CallerName(string)
    string = default(string, true)
    return debug_info_tostring(debug.getinfo(3), string)
end

function FunctionInfo(string)
    string = default(string, true)
    return debug_info_tostring(debug.getinfo(2), string)
end

function debug_info_tostring(debuginfo, always_string)
    string = default(string, true)
    local caller = debuginfo.name
    if caller == nil and not always_string then
        return nil
    end
    local file = debuginfo.short_src:gsub('.*\\', '') .. ":" .. debuginfo.currentline
    return tostring(caller) .. "(" .. file .. ")"
end

function caller_test()
    test2()
end

function test2()
    log(CallerName())
end

--------------------
--- Chat Logging ---
--------------------

function log_debug(...)
    if is_debug then
        log(...)
    end
end

function log_debug_table(...)
    if is_debug then
        log_table(...)
    end
end

function log_debug_list(...)
    if is_debug then
        log_list(...)
    end
end

function logify(first, ...)
    local rest = table.pack(...)
    local message = tostring(first)
    for i = 1, rest.n do
        message = message .. ' ' .. tostring(rest[i])
    end
    return message
end

function log(...)
    Svc.Chat:Print(logify(...))
end

function log_count(list, c)
    for i = 0, c - 1 do
        log(tostring(i) .. ': ' .. tostring(list[i]))
    end
end

function log_list(list)
    local c = list.Count
    if c == nil then
        log("Not a list (No Count property)", list)
    else
        log_count(list, c)
    end
end

function log_array(array)
    local c = array.Length
    if c == nil then
        log("Not a array (No Length property)", array)
    else
        log_count(array, c)
    end
end

function log_table(list)
    for i, v in pairs(list) do
        log(tostring(i) .. ': ' .. tostring(v))
    end
end

-----------------------
-- Timeout Functions --
-----------------------


global_wait_info = {
    current_timed_function = nil,
    current_timed_start = 0
}

function ResetTimeout()
    global_wait_info = {
        current_timed_function = CallerName(),
        current_timed_start = os.clock()
    }
    return global_wait_info
end

function CheckTimeout(max_duration, wait_info, caller_name, ...)
    wait_info = default(wait_info, global_wait_info)
    if wait_info == global_wait_info and CallerName() ~= wait_info.current_timed_function then
        wait_info = ResetTimeout()
    end
    max_duration = default(max_duration, 30)
    if os.clock() > wait_info.current_timed_start + max_duration then
        StopScript("Max duration reached", default(caller_name, CallerName(false)), ...)
    end
end

function AlertTimeout(max_duration, wait_info, caller_name, ...)
    wait_info = default(wait_info, global_wait_info)
    if wait_info == global_wait_info and CallerName() ~= wait_info.current_timed_function then
        wait_info = ResetTimeout()
    end
    max_duration = default(max_duration, 30)
    if os.clock() > wait_info.current_timed_start + max_duration then
        log("Max duration reached", default(caller_name, CallerName(false)), ...)
        return true
    end
    return false
end
