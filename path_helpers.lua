require 'utils'
require 'luasharp'
require 'hard_ipc'
import "System.Numerics"
import "System"

local WALK_THRESHOLD = 35
local FLY_THRESHOLD = 100

function TownPath(town, x, y, z, shard, dest_town, ...)
    local alt_zones = { town, dest_town, ... }
    dest_town = default(dest_town, town)
    wait_ready(10, 1)
    local current_town = luminia_row_checked("TerritoryType", Svc.ClientState.TerritoryType).PlaceName.Name
    if list_contains(alt_zones, current_town) then
        log_(LEVEL_DEBUG, _text, "Already in", current_town)
    else
        log_(LEVEL_DEBUG, _text, "Moving to", town, "from", current_town)
        repeat
            yield("/tp " .. tostring(town))
            wait(1)
        until Player.Entity.IsCasting
        ZoneTransition()
    end

    if shard ~= nil then
        local nearest_shard = closest_aethershard()
        local shard_name = luminia_row_checked("Aetheryte", nearest_shard.DataId).AethernetName.Name
        if current_town == dest_town and path_distance_to(Vector3(x, y, z)) < path_distance_to(nearest_shard.Position) then
            log_(LEVEL_DEBUG, _text, "Already nearer to", x, y, z, "than to aethernet", shard_name)
        elseif shard_name == shard then
            log_(LEVEL_DEBUG, _text, "Nearest shard is already", shard_name)
        else
            log_(LEVEL_DEBUG, _text, "Walking to shard", nearest_shard.DataId, shard_name, "to warp to", shard)
            WalkTo(nearest_shard.Position, nil, nil, 7)
            running_lifestream = true
            yield("/li " .. tostring(shard))
            ZoneTransition()
        end
    end

    WalkTo(x, y, z)
end

local aether_info = nil
local net_info = nil
function load_aether_info()
    if aether_info == nil then
        local t = os.clock()
        aether_info = {}
        net_info = {}
        local sheet = Excel.GetSheet("Aetheryte")
        for r = 0, sheet.Count - 1 do
            if os.clock() - t > 1.0 / 10.0 then
                wait(0)
                t = os.clock()
            end
            local row = sheet[r]
            if Instances.Telepo:IsAetheryteUnlocked(r) then
                if row.IsAetheryte then
                    aether_info[row.RowId] = {
                        AetherId = row.RowId,
                        Name = row.PlaceName.Name,
                        TerritoryId = row.Territory.RowId,
                        Position = Instances.Telepo:GetAetherytePosition(r)
                    }
                end
                if row.AethernetName.RowId ~= 0 then
                    net_info[row.RowId] = {
                        Group = row.AethernetGroup,
                        Name = row.AethernetName.Name,
                        TerritoryId = row.Territory.RowId,
                        Position = Instances.Telepo:GetAetherytePosition(r),
                        Invisible = row.Invisible
                    }
                end
            end
        end
    end
    return aether_info, net_info
end

function nearest_aetherite(territory_id, goal_point)
    local closest = nil
    local distance = nil
    for _, row in pairs(load_aether_info()) do
        if row.TerritoryId == territory_id then
            local d = Vector3.Distance(goal_point, row.Position)
            if closest == nil or d < distance then
                closest = row
                distance = d
            end
        end
    end

    return closest
end

function random_real(lower, upper)
    if not default(random_is_seeded, false) then
        random_is_seeded = true
        math.randomseed()
    end
    return math.random() * (upper - lower) + lower
end

function warp_near_point(spot, radius, territory_id, fly)
    fly = default(fly, false)
    if Svc.ClientState.TerritoryType ~= territory_id then
        local a = nearest_aetherite(territory_id, spot)
        if a == nil then
            StopScript("NoAetheryte", CallerName(false), "No aetherite found for", territory_id)
        end
        repeat
            Instances.Telepo:Teleport(a.AetherId, 0) -- IDK what the sub index is. if things break its probably that.
            wait(1)
        until Player.Entity.IsCasting
        ZoneTransition()
    end
    move_near_point(spot, radius, fly)
    land_and_dismount()
end

function net_near_point(spot, radius, fly)
    fly = default(fly, false)
    move_near_point(spot, radius, fly)
    land_and_dismount()
end

function move_near_point(spot, radius, fly)
    running_vnavmesh = true
    fly = default(fly, false)
    local distance = random_real(0, radius)
    local angle = random_real(0, math.pi * 2)
    local target = Vector3(spot.X + distance * math.sin(angle), spot.Y, spot.Z + distance * math.cos(angle))
    local result, fly_result
    target.Y = target.Y + 0.5
    if fly then
        log_(LEVEL_DEBUG, _text, "Looking for mesh point in range", radius, "of", target)
        fly_result = IPC.vnavmesh.NearestPoint(target, radius, radius)
    end
    log_(LEVEL_DEBUG, _text, "Looking for floor point in range", radius, "of", target)
    result = IPC.vnavmesh.PointOnFloor(target, false, radius)

    if result == nil or (fly and fly_result == nil) then
        log_(LEVEL_ERROR, _text, "No valid point found in range", radius, "of", spot, "searched from", target)
        return false
    end
    log_(LEVEL_DEBUG, _text, "Found point in area", result, fly_result)
    local path, fly_path
    if fly_result == nil or Vector3.Distance(Player.Entity.Position, result) < FLY_THRESHOLD then
        path = pathfind_with_tolerance(result, false, radius)
    end
    if fly_result ~= nil and (path == nil or path_length(path) > FLY_THRESHOLD) then
        fly_path = pathfind_with_tolerance(fly_result, true, radius)
        walk_path(fly_path, true, radius, 0.01, spot)
    else
        walk_path(path, false, radius, 0.01, spot)
    end
    return true
end

function jump_to_point(p, runup, retry)
    running_vnavmesh = true
    p = xyz_to_vec3(table.unpack(p))
    runup = default(runup, .1)
    retry = default(retry, false)
    local start_pos = Player.Entity.Position
    local last_pos = Player.Entity.Position
    local stuck = nil
    custom_path(false, { p })
    repeat
        wait(0)
        if Vector3.Distance(last_pos, Player.Entity.Position) < 0.01 then
            if stuck == nil then
                stuck = os.clock()
            elseif os.clock() - stuck > .25 then
                log("Didnt move from start pos, jumping anyway")
                break
            end
        else
            last_pos = Player.Entity.Position
            stuck = nil
        end
    until Vector3.Distance(Player.Entity.Position, start_pos) > runup or not IPC.vnavmesh.IsRunning()
    if not IPC.vnavmesh.IsRunning() then
        StopScript("Failed to jump", CallerName(false), "to point", p)
    end
    Actions.ExecuteGeneralAction(2)
    local retries = 0
    while IPC.vnavmesh.IsRunning() or Player.IsBusy do
        wait(0.1)
        if Vector3.Distance(last_pos, Player.Entity.Position) < 0.01 then
            if stuck == nil then
                stuck = os.clock()
            elseif os.clock() - stuck > .25 then
                if retry and retries < 5 then
                    log("Stuck during jump, retrying", retries + 1)
                    retries = retries + 1
                    Actions.ExecuteGeneralAction(2)
                else
                    StopScript("Stuck during jump", CallerName(false), "to point", p, "Landed at", Player.Entity
                        .Position)
                end
            end
        else
            last_pos = Player.Entity.Position
            stuck = nil
        end
    end
    if Vector3.Distance(Player.Entity.Position, p) > 3.0 then
        StopScript("Missed jump", CallerName(false), "to point", p, "Landed at", Player.Entity.Position)
    end
    custom_path(false, { p })
    while IPC.vnavmesh.IsRunning() or Player.IsBusy do
        wait(0.1)
    end
    if Vector3.Distance(Player.Entity.Position, p) > 3.0 then
        StopScript("Fell during reposition", CallerName(false), "to point", p, "Landed at", Player.Entity.Position)
    end
end

function move_to_point(p)
    running_vnavmesh = true
    p = xyz_to_vec3(table.unpack(p))
    custom_path(false, { p })
    local last_pos = Player.Entity.Position
    local stuck = nil
    while IPC.vnavmesh.IsRunning() or Player.IsBusy do
        wait(0.1)
        if Vector3.Distance(last_pos, Player.Entity.Position) < 0.01 then
            if stuck == nil then
                stuck = os.clock()
            elseif os.clock() - stuck > .25 then
                StopScript("Stuck during walk", CallerName(false), "to point", p, "Landed at", Player.Entity.Position)
            end
        else
            last_pos = Player.Entity.Position
            stuck = nil
        end
    end
end

function walk_path(path, fly, range, stop_if_stuck, ref_point)
    running_vnavmesh = true
    stop_if_stuck = default(stop_if_stuck, false)
    ref_point = default(ref_point, path[path.Count - 1])
    local ti = ResetTimeout()
    IPC.vnavmesh.MoveTo(path, fly)
    if not GetCharacterCondition(4) and (fly or path_length(path) > WALK_THRESHOLD) then
        Actions.ExecuteGeneralAction(9)
    end
    local last_pos
    while (IPC.vnavmesh.IsRunning() or IPC.vnavmesh.PathfindInProgress()) do
        CheckTimeout(60, ti, CallerName(false), "Waiting for pathfind")
        local cur_pos = Player.Entity.Position
        if range ~= nil and Vector3.Distance(Entity.Player.Position, ref_point) <= range then
            IPC.vnavmesh.Stop()
        end
        if not fly or GetCharacterCondition(4) then
            if stop_if_stuck and Vector3.Distance(last_pos, cur_pos) < stop_if_stuck then
                log_(LEVEL_ERROR, _text, "Antistuck triggered!")
                IPC.vnavmesh.Stop()
            end
            last_pos = cur_pos
        end
        wait(0.1)
    end
end

function land_and_dismount()
    running_vnavmesh = true
    if not GetCharacterCondition(4) then
        return
    end
    if GetCharacterCondition(77) then
        local floor = IPC.vnavmesh.NearestPoint(Player.Entity.Position, 20, 20)
        IPC.vnavmesh.PathfindAndMoveTo(floor, true)
        local t = os.clock()
        while (IPC.vnavmesh.IsRunning() or IPC.vnavmesh.PathfindInProgress()) and os.clock() - t < 2 do
            wait(.1)
        end
        IPC.vnavmesh.Stop()
    end
    while GetCharacterCondition(4) do
        Actions.ExecuteGeneralAction(23)
        wait(.1)
    end
end

function custom_path(fly, waypoints)
    running_vnavmesh = true
    local vec_waypoints = {}
    log_(LEVEL_DEBUG, _text, "Setting up")
    log_(LEVEL_DEBUG, _table, vec_waypoints)
    log_(LEVEL_DEBUG, _table, "Waypoints:", waypoints)
    for i, waypoint in pairs(waypoints) do
        if type(waypoint) == "table" then
            local x, y, z = table.unpack(waypoint)
            vec_waypoints[i] = Vector3(x, y, z)
        elseif type(waypoint) == "userdata" then -- it better be a vector3
            vec_waypoints[i] = waypoint
        else
            StopScript("Invalid waypoint type", CallerName(false), "Type:", type(waypoint))
        end
    end
    log_(LEVEL_DEBUG, _text, "Calling moveto")
    log_(LEVEL_DEBUG, _table, vec_waypoints)
    local list_waypoints = make_list("System.Numerics.Vector3", table.unpack(vec_waypoints))
    log_(LEVEL_DEBUG, _text, "List waypoints:", list_waypoints)
    log_(LEVEL_DEBUG, _list, list_waypoints)
    IPC.vnavmesh.MoveTo(list_waypoints, fly)
end

function xyz_to_vec3(x, y, z)
    if y ~= nil and z ~= nil then
        log_(LEVEL_VERBOSE, _text, "Converting coordinates to vector3", x, y, z)
        return Vector3(x, y, z)
    elseif y ~= nil or z ~= nil then
        StopScript("Invalid coordinates for WalkTo", CallerName(false), "Must provide either vec3 or x,y,z", "x:", x,
            "y:", y, "z:", z)
    else
        log_(LEVEL_VERBOSE, _text, "Assuming provided value is already a vector3:", x)
        return x
    end
end

function WalkTo(x, y, z, range)
    running_vnavmesh = true
    local pos = xyz_to_vec3(x, y, z)
    local ti = ResetTimeout()
    local p
    if range ~= nil then
        log_(LEVEL_VERBOSE, _text, "Finding path to", pos, "with range", range)
        p = pathfind_with_tolerance(pos, false, range)
    else
        log_(LEVEL_VERBOSE, _text, "Finding path to", pos)
        p = await(IPC.vnavmesh.Pathfind(Entity.Player.Position, pos, false))
    end
    if p.Count == 0 then
        StopScript("No path found", CallerName(false), "x:", x, "y:", y, "z:", z, "range:", range)
    end
    log_(LEVEL_VERBOSE, _text, "Walking to", pos, "with range", range)
    IPC.vnavmesh.MoveTo(p, false)
    while (IPC.vnavmesh.IsRunning() or IPC.vnavmesh.PathfindInProgress()) do
        CheckTimeout(30, ti, CallerName(false), "Waiting for pathfind")
        if range ~= nil and Vector3.Distance(Entity.Player.Position, pos) <= range then
            log_(LEVEL_VERBOSE, _text, "Stopping path because within range", range, "of target")
            IPC.vnavmesh.Stop()
        end
        wait(0.1)
    end
    log_(LEVEL_VERBOSE, _text, "Arrived at", pos)
end

function pathfind_with_tolerance(vec3, fly, tolerance)
    running_vnavmesh = true
    require_ipc('vnavmesh.Nav.PathfindWithTolerance',
        'System.Threading.Tasks.Task`1[System.Collections.Generic.List`1[System.Numerics.Vector3]]',
        {
            'System.Numerics.Vector3',
            'System.Numerics.Vector3',
            'System.Boolean',
            'System.Single'
        }
    )
    return await(invoke_ipc('vnavmesh.Nav.PathfindWithTolerance', Entity.Player.Position, vec3, fly, tolerance))
end

function ZoneTransition()
    local ti = ResetTimeout()
    repeat
        CheckTimeout(30, ti, "ZoneTransition", "Waiting for zone transition to start")
        wait(0.1)
    until not Player.Entity.IsCasting
    log_(LEVEL_DEBUG, _text, "Not casting")
    repeat
        CheckTimeout(30, ti, "ZoneTransition", "Waiting for zone transition to start")
        wait(0.1)
    until not IsPlayerAvailable()
    log_(LEVEL_DEBUG, _text, "Teleport started")
    repeat
        CheckTimeout(30, ti, "ZoneTransition", "Waiting for lifestream to finish")
        wait(0.1)
    until not IPC.Lifestream.IsBusy()
    log_(LEVEL_DEBUG, _text, "Lifestream done")
    repeat
        CheckTimeout(30, ti, "ZoneTransition", "Waiting for zone transition to end")
        while IPC.vnavmesh.BuildProgress() > 0 do
            CheckTimeout(10 * 60, ti, "ZoneTransition", "Waiting for navmesh to finish building")
            wait(0.1)
        end
        wait(0.1)
    until IsPlayerAvailable()
    log_(LEVEL_DEBUG, _text, "Teleport done")
    wait_ready(30, 2)
    log_(LEVEL_DEBUG, _text, "Ready!")
end

function IsNearThing(thing, distance)
    distance = default(distance, 4)
    thing = tostring(thing)
    local entity = get_closest_entity(thing)
    return entity ~= nil and entity.Name == thing and entity.DistanceTo <= distance
end

function RunVislandRoute(route_b64, wait_message)
    running_visland = true
    local ti = ResetTimeout()
    wait_message = default(wait_message, "Running route")
    log(wait_message)
    IPC.visland.StopRoute()

    IPC.visland.StartRoute(route_b64, true)
    if not IPC.visland.IsRouteRunning() then
        StopScript("Failed to start route", CallerName(), "Is visland enabled?")
    end
    repeat
        CheckTimeout(5 * 60, ti)
        log(wait_message)
        yield("/wait 1")
    until not IPC.visland.IsRouteRunning()
end

function StartRouteToTarget()
    running_vnavmesh = true
    if not HasTarget() then
        log("No target to route to")
        return false
    end
    local ti = ResetTimeout()

    yield("/vnav movetarget")
    repeat
        wait(.1)
        CheckTimeout(30, ti)
    until PathIsRunning()
end

function RouteToTarget()
    StartRouteToTarget()
    local ti = ResetTimeout()

    while PathIsRunning() do
        CheckTimeout(5 * 60, ti)
        wait(.5)
    end
end

function RouteToObject(object_name, distance)
    local ti = ResetTimeout()
    while not IsNearThing(object_name, distance) do
        if not PathIsRunning() and GetTargetName() == object_name then
            StartRouteToTarget()
        end
        wait(.1)
        CheckTimeout(30, ti)
    end

    PathStop()
end

---@return EntityWrapper
function get_closest_entity(name, critical)
    critical = default(critical, false)
    if EntityWrapper == nil then
        EntityWrapper = load_type('SomethingNeedDoing.LuaMacro.Wrappers.EntityWrapper')
    end
    local closest = raw_closest_thing(by_name(name), direct_distance)
    if critical and closest == nil then
        StopScript("No entity found", CallerName(false), "Name:", name)
    end
    return EntityWrapper(closest)
end

function closest_aethershard(critical)
    critical = default(critical, true)
    local closest = raw_closest_thing(is_aethershard, path_dist_to_obj(Player.CanFly))
    if critical and closest == nil then
        StopScript("No aethershard found", CallerName(false))
    end
    return closest
end

---------------
--- Support ---
---------------

function raw_closest_thing(filter, distance_function)
    distance_function = default(distance_function, direct_distance)
    local closest = nil
    local distance = nil
    for i = 0, Svc.Objects.Length - 1 do
        local obj = Svc.Objects[i]
        if filter(obj) then
            local t_distance = distance_function(obj)
            if closest == nil then
                closest = obj
                distance = t_distance
            elseif t_distance < distance then
                closest = obj
                distance = t_distance
            end
        end
    end
    return closest
end

function path_distance_to(vec3, fly)
    fly = default(fly, false)
    path = await(IPC.vnavmesh.Pathfind(Entity.Player.Position, vec3, fly))
    if path.Count == 0 then -- if theres no path use the cartesian distance
        return Vector3.Distance(Entity.Player.Position, vec3)
    end
    return path_length(path)
end

function path_length(path)
    local dist = 0
    local prev_point = Entity.Player.Position
    for point in luanet.each(path) do
        dist = dist + Vector3.Distance(prev_point, point)
        prev_point = point
    end
    return dist
end

function path_dist_to_obj(fly)
    return function(obj)
        return path_distance_to(obj.Position, fly)
    end
end

function direct_distance(obj)
    return Vector3.Distance(Entity.Player.Position, obj.Position)
end

function is_alive(obj)
    return obj ~= nil and not obj.IsDead
end

function by_name(name)
    return function(obj)
        return obj ~= nil and obj.Name.TextValue == name
    end
end

function is_aethershard(obj)
    if obj == nil then
        return false
    end
    if SvcObjectsKind == nil then
        SvcObjectsKind = load_type("Dalamud.Game.ClientState.Objects.Enums.ObjectKind")
    end
    return obj.ObjectKind == SvcObjectsKind.Aetheryte
end

function xz_to_floor(X, Z)
    local position = Vector3(X, 1000, Z)
    local floor_point = IPC.vnavmesh.NearestPoint(position, 0, 2000)
    return floor_point
end

function xz_to_landable(X, Z, range)
    range = default(range, 20)
    local position = Vector3(X, 1000, Z)
    local floor_point = IPC.vnavmesh.PointOnFloor(position, false, range)
    return floor_point
end
