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

function make_list(content_type, ...)
    local t = Type.GetType(("System.Collections.Generic.List`1[%s]"):format(content_type))
    log_(LEVEL_VERBOSE, log, "Making list of type", t)
    local l = Activator.CreateInstance(t)
    log_(LEVEL_VERBOSE, log, "List made", l)
    local args = table.pack(...)
    for i = 1, args.n do
        l:Add(args[i])
    end
    log_(LEVEL_VERBOSE, log, "Initial items added")
    log_(LEVEL_VERBOSE, log_iterable, l)
    return l
end

function make_set(content_type, ...)
    local t = Type.GetType(("System.Collections.Generic.HashSet`1[%s]"):format(content_type))
    log_(LEVEL_VERBOSE, log, "Making set of type", t)
    local l = Activator.CreateInstance(t)
    log_(LEVEL_VERBOSE, log, "Set made", l)
    local args = table.pack(...)
    for i = 1, args.n do
        l:Add(args[i])
    end
    log_(LEVEL_VERBOSE, log, "Initial items added")
    log_(LEVEL_VERBOSE, log_iterable, l)
    return l
end

function make_instance_args(ctype, args_table)
    local Activator_ty = luanet.ctype(Activator)
    local CreateInstance = get_method_overload(Activator_ty, "CreateInstance",
        { Type.GetType("System.Type"), Type.GetType("System.Object[]") })

    local args = luanet.make_array(Object, args_table)
    local arg_array = luanet.make_array(Object, { ctype, args })
    local instance = CreateInstance:Invoke(nil, arg_array)
    if arg_array == instance then
        log_array(args)
        log_array(arg_array)
        StopScript("Failed to make instance", CallerName(false), "type:", ctype, "args:", args)
    end
    return instance
end

function deref_pointer(ptr, ctype)
    if Unsafe == nil then
        _, Unsafe = load_type("System.Runtime.CompilerServices.Unsafe", "System.Runtime")
    end
    local AsRef = get_generic_method(Unsafe, "AsRef", { ctype })
    if AsRef == nil or AsRef.Invoke == nil then
        StopScript("Failed to get AsRef method", CallerName(false), "ctype:", ctype)
    end
    local arg = luanet.make_array(Object, { ptr })
    local ref = AsRef:Invoke(nil, arg)
    if ref == arg then
        StopScript("Failed to deref pointer", CallerName(false), "pointer:", ptr, "ctype:", ctype)
    end
    return ref
end

function cs_instance(type, assembly)
    local T, T_ty = load_type(type, assembly)

    local instance = T.Instance()
    return deref_pointer(instance, T_ty)
end

function assembly_name(inputstr)
    for str in string.gmatch(inputstr, "[^%.]+") do
        return str
    end
end

function load_type(type_path, assembly)
    assembly = default(assembly, assembly_name(type_path))
    log_(LEVEL_VERBOSE, log, "Loading assembly", assembly)
    luanet.load_assembly(assembly)
    log_(LEVEL_VERBOSE, log, "Wrapping type", type_path)
    local type_var = luanet.import_type(type_path)
    log_(LEVEL_VERBOSE, log, "Wrapped type", type_var)
    return type_var, luanet.ctype(type_var)
end

function load_type_(type_path, assembly)
    assembly = default(assembly, assembly_name(type_path))
    local assembly_handle = nil
    for i in luanet.each(AppDomain.CurrentDomain:GetAssemblies()) do
        if i.FullName:match(assembly .. ",") then
            if assembly_handle ~= nil then
                StopScript("Multiple assemblies found matching name", CallerName(false), "assembly:", assembly)
            end
            assembly_handle = i
        end
    end
    if assembly_handle == nil then
        StopScript("Assembly not found", CallerName(false), "assembly:", assembly)
    end
    local type_found = nil
    for i in luanet.each(assembly_handle.ExportedTypes) do
        if i.FullName == type_path then
            if type_found ~= nil then
                StopScript("Multiple types found matching name", CallerName(false), "type_path:", type_path)
            end
            type_found = i
        end
    end
    if type_found == nil then
        StopScript("Type not found", CallerName(false), "type_path:", type_path)
    end
    return type_found
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
            local extra = ""
            if meth[i].IsGenericMethodDefinition then
                extra = "<" .. tostring(meth[i]:GetGenericArguments().Length) .. ">"
            end
            log(tostring(i) .. ':', meth[i].Name .. extra)
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

function make_calling_conventions(callingConventions)
    if CallingConventions == nil then
        CallingConventions = load_type('System.Reflection.CallingConventions')
    end

    callingConventions = default(callingConventions, {})

    local flags = 0
    if default(callingConventions.standard, false) then
        flags = flags | CallingConventions.Standard.value__
    end
    if default(callingConventions.varargs, false) then
        flags = flags | CallingConventions.VarArgs.value__
    end
    if default(callingConventions.any, false) then
        flags = flags | CallingConventions.Any.value__
    end
    if default(callingConventions.hasthis, false) then
        flags = flags | CallingConventions.HasThis.value__
    end
    if default(callingConventions.explicitthis, false) then
        flags = flags | CallingConventions.ExplicitThis.value__
    end
    return luanet.enum(CallingConventions, flags)
end

--- ########################
--- ####### Generics #######
--- ########################
function get_generic_method(targetType, method_name, genericTypes)
    local genericArgsArr = luanet.make_array(Type, genericTypes)
    local methods = targetType:GetMethods()
    for i = 0, methods.Length - 1 do
        local m = methods[i]
        if m.Name == method_name and m.IsGenericMethodDefinition and m:GetGenericArguments().Length == genericArgsArr.Length then
            return m:MakeGenericMethod(genericArgsArr)
        end
    end
    StopScript("No generic method found", CallerName(false), "No matching generic method found for", method_name, "with",
        #genericTypes, "generic args")
end

function get_method_overload(targetType, method_name, paramTypes)
    local methods = targetType:GetMethods()
    for i = 0, methods.Length - 1 do
        local m = methods[i]
        if m.Name == method_name then
            local params = m:GetParameters()
            if params.Length == #paramTypes then
                local match = true
                for j = 0, params.Length - 1 do
                    if params[j].ParameterType ~= paramTypes[j + 1] then
                        match = false
                        break
                    end
                end
                if match then
                    return m
                end
            end
        end
    end
    StopScript("No method overload found", CallerName(false), "No matching overload found for", method_name, "with",
        #paramTypes, "parameters")
end
