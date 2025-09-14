require 'utils'
require 'luasharp'
import "System"

ipc_cache_actions = {}
ipc_cache_functions = {}

function require_ipc(ipc_signature, result_type, arg_types)
    if ipc_cache_actions[ipc_signature] ~= nil or ipc_cache_functions[ipc_signature] ~= nil then
        log_(LEVEL_DEBUG, log, "IPC already loaded", ipc_signature)
        return
    end
    arg_types = default(arg_types, {})
    arg_types[#arg_types + 1] = default(result_type, 'System.Object')
    for i, v in ipairs(arg_types) do
        if type(v) ~= 'string' then
            StopScript("Bad argument", CallerName(false), "argument types shound be strings")
        end
        arg_types[i] = Type.GetType(v)
    end
    local method = get_generic_method(Svc.PluginInterface, 'GetIpcSubscriber', arg_types)
    if method.Invoke == nil then
        StopScript("GetIpcSubscriber not found", CallerName(false), "No IPC subscriber for", #arg_types, "arguments")
    end
    local sig = luanet.make_array(Object, { ipc_signature })
    local subscriber = method:Invoke(Svc.PluginInterface, sig)
    if subscriber == nil then
        StopScript("IPC not found", CallerName(false), "signature:", ipc_signature)
    end
    if result_type == nil then
        log_(LEVEL_DEBUG, log, "loaded action IPC", ipc_signature)
        ipc_cache_actions[ipc_signature] = subscriber
    else
        log_(LEVEL_DEBUG, log, "loaded function IPC", ipc_signature)
        ipc_cache_functions[ipc_signature] = subscriber
    end
end

function invoke_ipc(ipc_signature, ...)
    local function_subscriber = ipc_cache_functions[ipc_signature]
    local action_subscriber = ipc_cache_actions[ipc_signature]
    if function_subscriber == nil and action_subscriber == nil then
        StopScript("IPC not ready", CallerName(false), "signature:", ipc_signature, "is not loaded")
    end
    if function_subscriber ~= nil then
        local result = function_subscriber:InvokeFunc(...)
        if result == function_subscriber then
            StopScript("Function IPC failed", CallerName(false), "signature:", ipc_signature)
        end
        return result
    end
    -- otherwise its action IPC

    local result = action_subscriber:InvokeAction(...)
    if result == action_subscriber then
        StopScript("IPC failed", CallerName(false), "signature:", ipc_signature)
    end
end
