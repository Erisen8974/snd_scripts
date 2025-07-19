require 'utils'
import "System.Linq"
import "System"


function await(o, max_wait)
    max_wait = default(max_wait, 30)
    local ti = ResetTimeout()
    while not o.IsCompleted do
        CheckTimeout(max_wait, ti, CallerName(false), "Waiting for task to complete")
        wait(0.1)
    end
    return o.Result
end

function make_list(type, ...)
    local a = luanet.make_array(type, { ... })
    return Enumerable.ToList(a)
end

function assembly_name(inputstr)
    for str in string.gmatch(inputstr, "[^%.]+") do
        return str
    end
end

function load_type(type_path)
    local assembly = assembly_name(type_path)
    log_debug("Loading assembly", assembly)
    luanet.load_assembly(assembly)
    log_debug("Wrapping type", type_path)
    local type_var = luanet.import_type(type_path)
    log_debug("Wrapped type", type_var)
    return type_var
end

function get_method(type, method_name, binding)
    local method = type:GetMethod(method_name, make_binding_flags(binding))
    if method == nil then
        StopScript("Method not found", CallerName(false), "type:", type, "method_name:", method_name)
    end
    return method
end

function get_field(type, field_name, binding)
    local field = type:GetField(field_name, make_binding_flags(binding))
    if field == nil then
        StopScript("Field not found", CallerName(false), "type:", type, "field_name:", field_name)
    end
    return field
end

function get_property(type, property_name, binding)
    local property = type:GetProperty(property_name, make_binding_flags(binding))
    if property == nil then
        StopScript("Property not found", CallerName(false), "type:", type, "property_name:", property_name)
    end
    return property
end

function dump_object_info(object, show_what)
    log("--- info for object ---")
    log("Object:", object)
    local type = object:GetType()
    dump_type_info(type, show_what, object)
end

function dump_type_info(type, show_what, object)
    show_what = default(show_what, { properties = true, public = true, instance = true })
    if object == nil then log("--- info for type ---") end
    log("Type:", type)

    local binding_flags = make_binding_flags(show_what)
    log("BindingFlags:", binding_flags)

    if default(show_what.properties, false) then
        local props = type:GetProperties(binding_flags)
        log(props.Length, "Properties")
        for i = 0, props.Length - 1, 1 do
            log(tostring(i) .. ':', props[i].Name, '---', props[i]:GetValue(object))
        end
    end

    if default(show_what.fields, false) then
        local fields = type:GetFields(binding_flags)
        log(fields.Length, "Fields")
        for i = 0, fields.Length - 1, 1 do
            log(tostring(i) .. ':', fields[i].Name, '---', fields[i].FieldType, '---', fields[i]:GetValue(object))
        end
    end

    if default(show_what.methods, false) then
        local meth = type:GetMethods(binding_flags)
        log(meth.Length, "Methods")
        for i = 0, meth.Length - 1, 1 do
            log(tostring(i) .. ':', meth[i].Name)
        end
    end

    if default(show_what.constructors, false) then
        local ctors = type:GetConstructors(binding_flags)
        log(ctors.Length, "Constructors")
        for i = 0, ctors.Length - 1, 1 do
            log(tostring(i) .. ':', ctors[i].Name)
        end
    end

    if default(show_what.members, false) then
        local members = type:GetMembers(binding_flags)
        log(members.Length, "Members")
        for i = 0, members.Length - 1, 1 do
            log(tostring(i) .. ':', members[i].Name)
        end
    end

    if default(show_what.nestedtypes, false) then
        local nested = type:GetNestedTypes(binding_flags)
        log(nested.Length, "NestedTypes")
        for i = 0, nested.Length - 1, 1 do
            log(tostring(i) .. ':', nested[i].Name)
        end
    end

    log("--- end info ---")
end

function make_binding_flags(bindings)
    if BindingFlags == nil then
        BindingFlags = load_type('System.Reflection.BindingFlags')
    end

    bindings = default(bindings, {})

    local flags = 0
    if default(bindings.public, true) then
        flags = flags | BindingFlags.Public.value__
    end
    if default(bindings.private, false) then
        flags = flags | BindingFlags.NonPublic.value__
    end
    if default(bindings.instance, true) then
        flags = flags | BindingFlags.Instance.value__
    end
    if default(bindings.static, false) then
        flags = flags | BindingFlags.Static.value__
    end
    return luanet.enum(BindingFlags, flags)
end

function invoke_ipc(ipc_signature, result_type, arg_type_hints, ...)
    local args = table.pack(...)
    local arg_types = {}
    for i = 1, args.n do
        if arg_type_hints[i] == nil then
            arg_types[i] = args[i]:GetType()
        else
            arg_types[i] = arg_type_hints[i]
        end
    end
    arg_types[#arg_types + 1] = result_type
    local method = get_generic_method(Svc.PluginInterface, 'GetIpcSubscriber', arg_types)
    local sig = luanet.make_array(Object, { ipc_signature })
    subscriber = method:Invoke(Svc.PluginInterface, sig)
    return subscriber:InvokeFunc(...)
end

-- Finds a method by name and number of generic arguments, binds the generics, and returns the constructed MethodInfo
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
