require 'utils'
import "System"

ipc_cache = {}

function require_ipc(ipc_signature, result_type, arg_types)
    if ipc_cache[ipc_signature] ~= nil then
        log_debug("IPC already loaded", ipc_signature)
        return
    end
    arg_types[#arg_types + 1] = result_type
    local method = get_generic_method(Svc.PluginInterface, 'GetIpcSubscriber', arg_types)
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

    return subscriber:InvokeFunc(...)
end

function get_generic_method(object, method_name, genericTypes)
    local targetType
    if object.GetType then
        targetType = object:GetType()
    else
        targetType = object
    end
    local genericArgsArr = luanet.make_array(Type, genericTypes)
    local methods = targetType:GetMethods()
    for i = 0, methods.Length - 1 do
        local m = methods[i]
        if m.Name == method_name and m.IsGenericMethodDefinition and m:GetGenericArguments().Length == genericArgsArr.Length then
            local constructed = nil
            local success, err = pcall(function()
                constructed = m:MakeGenericMethod(genericArgsArr)
            end)
            if success then
                return constructed
            else
                StopScript("Error constructing generic method", CallerName(false), err)
            end
        end
    end
    StopScript("No generic method found", CallerName(false), "No matching generic method found for", method_name, "with",
        #genericTypes, "generic args")
end
