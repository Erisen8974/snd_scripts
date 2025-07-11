---------------------------
------- Legacy Glue -------
---------------------------
import("System.Numerics")



function IsAddonReady(name)
    local a = Addons.GetAddon(name)
    if a == nil then
        return false
    end
    return a.Exists and a.Ready
end

function GetTargetName()
    local t = Entity.Target
    if t == nil then
        return nil
    end
    return t.Name
end

function GetPlayerRawXPos()
    if Entity == nil then
        return nil
    end
    if Entity.Player == nil then
        return nil
    end
    if Entity.Player.Position == nil then
        return nil
    end
    return Entity.Player.Position.X
end

function GetPlayerRawYPos()
    if Entity == nil then
        return nil
    end
    if Entity.Player == nil then
        return nil
    end
    if Entity.Player.Position == nil then
        return nil
    end
    return Entity.Player.Position.Y
end

function GetPlayerRawZPos()
    if Entity == nil then
        return nil
    end
    if Entity.Player == nil then
        return nil
    end
    if Entity.Player.Position == nil then
        return nil
    end
    return Entity.Player.Position.Z
end

function GetCharacterCondition(cond)
    return Svc.Condition[cond]
end

function GetDistanceToPoint(x, y, z)
    if Entity == nil then
        return nil
    end
    if Entity.Player == nil then
        return nil
    end
    if Entity.Player.Position == nil then
        return nil
    end
    return Vector3.Distance(Entity.Player.Position, Vector3(x, y, z))
end

function IsPlayerAvailable()
    return not is_busy()
end

function PathMoveTo(x, y, z, fly)
    IPC.vnavmesh.PathfindAndMoveTo(Vector3(x, y, z), fly)
end

function GetZoneID()
    return Svc.ClientState.TerritoryType
end

function GetNodeText(name, ...)
    local a = Addons.GetAddon(name)
    if not a.Ready then
        StopScript("Bad addon", CallerName(false), name)
    end
    local n = a:GetNode(...)
    if tostring(n.NodeType):find("Text:") == nil then
        StopScript("Not a text node", CallerName(false), "NodeType:", n.NodeType, "NodeId:", n.Id, name, ...)
    end
    return n.Text
end

function HasStatusId(status_id)
    for s in luanet.each(Player.Status) do
        if s.StatusId == status_id then
            return true
        end
    end
    return false
end

function GetStatusStackCount(status_id)
    for s in luanet.each(Player.Status) do
        if s.StatusId == status_id then
            return s.Param
        end
    end
    return 0
end
