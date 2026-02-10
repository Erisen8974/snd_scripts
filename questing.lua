require 'utils'
require 'luasharp'
require 'path_helpers'
require 'inventory_buddy'

DEFAULT_COMBAT = "Viper"
DEFAULT_GATHER = "Botanist"
DEFAULT_CRAFT = "Culinarian"

local required_plugins = {
    "Questionable",
    "TextAdvance",
    "vnavmesh",
}


local CATEGORY_CRAFTING = "Crafting"
local CATEGORY_COMBAT = "Combat"
local CATEGORY_GATHERING = "Gathering"


quest_npcs = {
    YokHuy = { Position = Vector3(493.2173, 142.24991, 783.0471), TerritoryId = 1187, Name = "Vuyargur", Category = CATEGORY_CRAFTING },
    PeluPelu = { Position = Vector3(770.8533, 12.846572, -259.50546), TerritoryId = 1188, Name = "Yubli", Category = CATEGORY_COMBAT, PathRange = 2, InteractRange = 7 },
    MamoolJa = { Position = Vector3(589.3186, -142.89168, 729.4575), TerritoryId = 1189, Name = "Kageel Ja", Category = CATEGORY_GATHERING },
    Ananta = { Position = Vector3(-25.406637, 56.02146, 232.20523), TerritoryId = 612, Name = "Eshana", Category = CATEGORY_COMBAT, PathRange = 2, InteractRange = 7 },
    Namazu = { Position = Vector3(-776.52997, 127.395256, 99.42353), TerritoryId = 622, Name = "Seigetsu the Enlightened", Category = CATEGORY_CRAFTING, PathRange = 2, InteractRange = 7 },
}

function move_to_quest_giver(path)
    local interact_range = default(path.InteractRange, 4)
    local path_range = default(path.PathRange, interact_range)
    if IsNearThing(path.Name, interact_range) then
        return
    end
    if Svc.ClientState.TerritoryType ~= path.TerritoryId then
        local a = nearest_aetherite(path.TerritoryId, path.Position)
        if a == nil then
            StopScript("NoAetheryte", CallerName(false), "No aetherite found for", path.TerritoryId)
        end
        repeat
            Instances.Telepo:Teleport(a.AetherId, 0) -- IDK what the sub index is. if things break its probably that.
            wait(1)
        until Player.Entity.IsCasting
        ZoneTransition()
    end
    move_near_point(path.Position, path_range, true)
    land_and_dismount()
end

function GetBeastTribeQuest(path, n, class, one_per)
    require_plugins(required_plugins)
    n = default(n, 3)
    one_per = default(one_per, false)
    if class == nil then
        if path.Category == CATEGORY_COMBAT then
            class = DEFAULT_COMBAT
        elseif path.Category == CATEGORY_GATHERING then
            class = DEFAULT_GATHER
        elseif path.Category == CATEGORY_CRAFTING then
            class = DEFAULT_CRAFT
        else
            StopScript("NoClass", CallerName(false), "No class specified in call or path")
        end
    end
    yield("/at y")

    for i = 1, n do
        move_to_quest_giver(path)
        equip_gearset(class)
        AcceptQuest(path.Name)
        if one_per or i == n then
            RunQuesty()
        end
    end
end

function get_allowances()
    local QuestManager, QuestManager_ty = load_type("FFXIVClientStructs.FFXIV.Client.Game.QuestManager")

    local instance = QuestManager.Instance()
    return deref_pointer(instance, QuestManager_ty):GetBeastTribeAllowance()
end

function RunQuesty(max_time)
    max_time = default(max_time, 15 * 60)
    local ti = ResetTimeout()
    repeat
        local loop_ti = ResetTimeout()
        repeat
            CheckTimeout(10, loop_ti, CallerName(false), "Starting questy")
            running_questy = true
            yield("/qst start")
            wait(2)
        until IPC.Questionable.IsRunning()
        repeat
            CheckTimeout(max_time, ti, CallerName(false), "Running questy")
            wait(.1)
            close_yes_no(true, "Allagan Tomestones")
        until not IPC.Questionable.IsRunning()
        local step = IPC.Questionable.GetCurrentStepData()
        log_(LEVEL_DEBUG, log, "Questy step data:", step)
        if step ~= nil then
            log_(LEVEL_ERROR, log, "Questy ended but step data is not nil, restarting questy",
                step.TerritoryId, step.QuestId, step.Position, step.InteractionType)
        end
    until step == nil
end

function AcceptQuest(who, which, qlist)
    qlist = default(qlist, "SelectIconString")
    which = default(which, 0)

    local ti = ResetTimeout()
    repeat
        local entity = get_closest_entity(who)
        entity:SetAsTarget()
        entity:Interact()
        wait(.1)
        CheckTimeout(2, ti, "AcceptQuest", "Talking to", who, "didnt open", qlist)
        wait(.1)
    until IsAddonReady(qlist)
    SafeCallback(qlist, true, which)
    repeat
        CheckTimeout(10, ti, "AcceptQuest", "Waiting for quest accept dialog (Is text advance on?)")
        wait(.1)
    until not Player.IsBusy
    wait(.1)
end
