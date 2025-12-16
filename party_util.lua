require 'luasharp'
require 'utils'

function party_invite_friend(name)
    local f = Instances.FriendsList:GetFriendByName(name)
    if f == nil then
        StopScript("NoSuchFriend", CallerName(), "No friend with name", name)
    end

    local InfoProxyPartyInvite, InfoProxyPartyInvite_ty = load_type(
        "FFXIVClientStructs.FFXIV.Client.UI.Info.InfoProxyPartyInvite")

    log_(LEVEL_DEBUG, log, "Inviting friend", f.Name, "with content ID", f.ContentId, "and home world", f.HomeWorld)

    local instance = InfoProxyPartyInvite.Instance()
    return deref_pointer(instance, InfoProxyPartyInvite_ty):InviteToPartyContentId(f.ContentId, f.HomeWorld)
end

function party_has_member(name)
    local p = Addons.GetAddon("_PartyList")
    if not p.Ready then
        return false
    end
    for i = 1, 8 do
        local wrapper = p:GetNode(1, 2, 9, 9 + i)
        local text_node = p:GetNode(1, 2, 9, 9 + i, 14, 17)
        if not wrapper.IsVisible then
            return false
        end
        local member_name = text_node.Text
        if member_name:find(name, 1, true) then
            return true
        end
    end
    return false
end

function wait_for_member(name, match_name, max_wait)
    match_name = default(match_name, name:sub(1, 13))
    max_wait = default(max_wait, 15)
    local ti = ResetTimeout()
    while not party_has_member(match_name) do
        party_invite_friend(name)
        CheckTimeout(max_wait, ti, CallerName(), "Waiting for party member", name)
        wait(3)
    end
end
