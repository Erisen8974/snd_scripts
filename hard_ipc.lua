require 'utils'
require 'luasharp'
import "System"

ipc_cache = {}

function require_ipc(ipc_signature, result_type, arg_types)
    if ipc_cache[ipc_signature] ~= nil then
        log_debug("IPC already loaded", ipc_signature)
        return
    end
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
    subscriber = method:Invoke(Svc.PluginInterface, sig)
    if subscriber == nil then
        StopScript("IPC not found", CallerName(false), "signature:", ipc_signature)
    end
    ipc_cache[ipc_signature] = subscriber
end

function invoke_ipc(ipc_signature, ...)
    local subscriber = ipc_cache[ipc_signature]
    if subscriber == nil then
        StopScript("IPC not ready", CallerName(false), "signature:", ipc_signature, "is not loaded")
    end
    local result = subscriber:InvokeFunc(...)
    if result == subscriber then
        StopScript("IPC failed", CallerName(false), "signature:", ipc_signature)
    end
    return result
end

function invoke_action(ipc_signature, ...)
    local subscriber = ipc_cache[ipc_signature]
    if subscriber == nil then
        StopScript("IPC not ready", CallerName(false), "signature:", ipc_signature, "is not loaded")
    end
    local result = subscriber:InvokeAction(...)
    if result == subscriber then
        StopScript("IPC failed", CallerName(false), "signature:", ipc_signature)
    end
end
