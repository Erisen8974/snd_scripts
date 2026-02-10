require 'utils'
require 'luasharp'


ALL_INVENTORY = {
    InventoryType.Inventory1,
    InventoryType.Inventory2,
    InventoryType.Inventory3,
    InventoryType.Inventory4,
}

ALL_ARMORY = {
    InventoryType.ArmoryHead,
    InventoryType.ArmoryBody,
    InventoryType.ArmoryHands,
    InventoryType.ArmoryLegs,
    InventoryType.ArmoryFeets,
    InventoryType.ArmoryEar,
    InventoryType.ArmoryNeck,
    InventoryType.ArmoryWrist,
    InventoryType.ArmoryRings,
    InventoryType.ArmoryMainHand,
    InventoryType.ArmoryOffHand,
}

ALL_RETAINER = {
    InventoryType.RetainerPage1,
    InventoryType.RetainerPage2,
    InventoryType.RetainerPage3,
    InventoryType.RetainerPage4,
    InventoryType.RetainerPage5,
    InventoryType.RetainerPage6,
    InventoryType.RetainerPage7,
}

ALL_EQUIPMENT = {
    InventoryType.EquippedItems,
    InventoryType.ArmoryHead,
    InventoryType.ArmoryBody,
    InventoryType.ArmoryHands,
    InventoryType.ArmoryLegs,
    InventoryType.ArmoryFeets,
    InventoryType.ArmoryEar,
    InventoryType.ArmoryNeck,
    InventoryType.ArmoryWrist,
    InventoryType.ArmoryRings,
    InventoryType.ArmoryMainHand,
    InventoryType.ArmoryOffHand,
}

NUM_GEARSETS = 100

item_info_list = {
    -- ARR Maps
    TimewornLeatherMap = { itemId = 6688, itemName = "Timeworn Leather Map" },
    TimewornGoatskinMap = { itemId = 6689, itemName = "Timeworn Goatskin Map" },
    TimewornToadskinMap = { itemId = 6690, itemName = "Timeworn Toadskin Map" },
    TimewornBoarskinMap = { itemId = 6691, itemName = "Timeworn Boarskin Map" },
    TimewornPeisteskinMap = { itemId = 6692, itemName = "Timeworn Peisteskin Map" },

    -- Heavensward Maps
    TimewornArchaeoskinMap = { itemId = 12241, itemName = "Timeworn Archaeoskin Map" },
    TimewornWyvernskinMap = { itemId = 12242, itemName = "Timeworn Wyvernskin Map" },
    TimewornDragonskinMap = { itemId = 12243, itemName = "Timeworn Dragonskin Map" },

    -- Stormblood Maps
    TimewornGaganaskinMap = { itemId = 17835, itemName = "Timeworn Gaganaskin Map" },
    TimewornGazelleskinMap = { itemId = 17836, itemName = "Timeworn Gazelleskin Map" },

    -- Shadowbringers Maps
    TimewornGliderskinMap = { itemId = 26744, itemName = "Timeworn Gliderskin Map" },
    TimewornZonureskinMap = { itemId = 26745, itemName = "Timeworn Zonureskin Map" },

    -- Endwalker Maps
    TimewornSaigaskinMap = { itemId = 36611, itemName = "Timeworn Saigaskin Map" },
    TimewornKumbhiraskinMap = { itemId = 36612, itemName = "Timeworn Kumbhiraskin Map" },
    TimewornOphiotauroskinMap = { itemId = 39591, itemName = "Timeworn Ophiotauroskin Map" },

    -- Dawntrail Maps
    TimewornLoboskinMap = { itemId = 43556, itemName = "Timeworn Loboskin Map" },
    TimewornBraaxskinMap = { itemId = 43557, itemName = "Timeworn Br'aaxskin Map" },


    -- Raid Utils
    Moqueca = { itemId = 44178, recipeId = 35926, itemName = "Moqueca" },
    Grade2GemdraughtofDexterity = { itemId = 44163, recipeId = 35919, itemName = "Grade 2 Gemdraught of Dexterity" },
    Grade2GemdraughtofIntelligence = { itemId = 44165, recipeId = 35921, itemName = "Grade 2 Gemdraught of Intelligence" },

    SquadronSpiritbondingManual = { itemId = 14951, buffId = 1083, itemName = "Squadron Spiritbonding Manual" },
    SuperiorSpiritbondPotion = { itemId = 27960, buffId = 49, itemName = "Superior Spiritbond Potion" }, --This is just medicated



    -- precrafts:
    SanctifiedWater = { itemId = 44051, recipeId = 5661, itemName = "Sanctified Water" },
    CoconutMilk = { itemId = 36082, recipeId = 5287, itemName = "Coconut Milk" },
    TuraliCornOil = { itemId = 43976, recipeId = 5590, itemName = "Turali Corn Oil" },



    -- Hunt bills
    EliteMarkBill = { itemId = 2001362, itemName = "Elite Mark Bill" },
    EliteClanMarkBill = { itemId = 2001703, itemName = "Elite Clan Mark Bill" },
    EliteVeteranClanMarkBill = { itemId = 2002116, itemName = "Elite Veteran Clan Mark Bill" },
    EliteClanNutsyMarkBill = { itemId = 2002631, itemName = "Elite Clan Nutsy Mark Bill" },
    EliteGuildshipMarkBill = { itemId = 2003093, itemName = "Elite Guildship Mark Bill" },
    EliteDawnHuntBill = { itemId = 2003512, itemName = "Elite Dawn Hunt Bill" },
}



function normalize_item_name(name)
    return name:gsub("%W", "")
end

function get_item_name_from_id(id)
    return luminia_row_checked("item", id).Name
end

function get_item_info(item_name)
    local item_info = item_info_list[normalize_item_name(item_name)]
    if item_info == nil then
        StopScript("No information for item", item_name)
    end
    return item_info
end

function get_item_info_by_id(item_id)
    for _, item_info in pairs(item_info_list) do
        if item_info.itemId == item_id then
            return item_info
        end
    end
end

function equip_gearset(gearset_name, update_after)
    update_after = default(update_after, false)
    local ti = ResetTimeout()
    for gs in luanet.each(Player.Gearsets) do
        if gs.Name == gearset_name then
            repeat
                CheckTimeout(10, ti, CallerName(false), "Couldnt equip gearset:", gearset_name)
                gs:Equip()
                wait_ready(10, 1)
            until Player.Gearset.Name == gearset_name
            log_(LEVEL_INFO, log, "Gearset", gearset_name, "equipped")
            if update_after then
                Player.Gearset:Update()
            end
            return true
        end
    end
    log_(LEVEL_ERROR, log, "Gearset", gearset_name, "not found")
    return false
end

function equip_classjob(classjob_abrev, update_after)
    update_after = default(update_after, false)
    classjob_abrev = classjob_abrev:upper()
    local ti = ResetTimeout()
    for gs in luanet.each(Player.Gearsets) do
        if luminia_row_checked("ClassJob", gs.ClassJob).Abbreviation == classjob_abrev then
            gearset_name = gs.Name
            log_(LEVEL_INFO, log, "Equipping gearset", gearset_name, "for class/job", classjob_abrev)
            repeat
                CheckTimeout(10, ti, CallerName(false), "Couldnt equip gearset:", gearset_name)
                gs:Equip()
                wait(0.3)
                yesno = Addons.GetAddon("SelectYesno")
                wait(0.3)
                if yesno.Ready then
                    close_yes_no(true,
                        "registered to this gear set could not be found in your Armoury Chest. Replace it with")
                end
                wait(0.4)
            until Player.Gearset.Name == gearset_name
            wait_ready(10, 1)
            log_(LEVEL_VERBOSE, log, "Gearset", gearset_name, "equipped")
            if update_after then
                Player.Gearset:Update()
            end
            return true
        end
    end
    log_(LEVEL_ERROR, log, "No gearset found for class/job", classjob_abrev)
    return false
end

function move_to_inventory(item)
    for _, destination in pairs(ALL_INVENTORIES) do
        if Inventory.GetInventoryContainer(destination).FreeSlots > 0 then
            item:MoveItemSlot(destination)
            return true
        end
    end
    return false
end

function item_id_range(lowest_item_id, highest_item_id, in_range)
    highest_item_id = default(highest_item_id, lowest_item_id)
    lowest_item_id = default(lowest_item_id, 0)
    highest_item_id = default(highest_item_id, 999999999)
    in_range = default(in_range, true)
    return function(target_item)
        if lowest_item_id <= target_item.ItemId and target_item.ItemId <= highest_item_id then
            return in_range
        end
        return not in_range
    end
end

RaptureGearsetModule_GearsetItemIndex = load_type(
    "FFXIVClientStructs.FFXIV.Client.UI.Misc.RaptureGearsetModule+GearsetItemIndex")

function resolve_gearset_ids(number)
    RaptureGearsetModule = cs_instance("FFXIVClientStructs.FFXIV.Client.UI.Misc.RaptureGearsetModule")
    if not RaptureGearsetModule:IsValidGearset(number) then
        return nil
    end
    if RaptureGearsetModule_GearsetEntry == nil then
        _, RaptureGearsetModule_GearsetEntry = load_type(
            "FFXIVClientStructs.FFXIV.Client.UI.Misc.RaptureGearsetModule+GearsetEntry")
    end
    local gearset_ptr = RaptureGearsetModule:GetGearset(number)
    if gearset_ptr == nil then
        return nil
    end
    local gs = deref_pointer(gearset_ptr, RaptureGearsetModule_GearsetEntry)
    return {
        MainHand = gs:GetItem(RaptureGearsetModule_GearsetItemIndex.MainHand).ItemId,
        OffHand = gs:GetItem(RaptureGearsetModule_GearsetItemIndex.OffHand).ItemId,
        Head = gs:GetItem(RaptureGearsetModule_GearsetItemIndex.Head).ItemId,
        Body = gs:GetItem(RaptureGearsetModule_GearsetItemIndex.Body).ItemId,
        Hands = gs:GetItem(RaptureGearsetModule_GearsetItemIndex.Hands).ItemId,
        Legs = gs:GetItem(RaptureGearsetModule_GearsetItemIndex.Legs).ItemId,
        Feet = gs:GetItem(RaptureGearsetModule_GearsetItemIndex.Feet).ItemId,
        Ears = gs:GetItem(RaptureGearsetModule_GearsetItemIndex.Ears).ItemId,
        Neck = gs:GetItem(RaptureGearsetModule_GearsetItemIndex.Neck).ItemId,
        Wrists = gs:GetItem(RaptureGearsetModule_GearsetItemIndex.Wrists).ItemId,
        LeftRing = gs:GetItem(RaptureGearsetModule_GearsetItemIndex.RingLeft).ItemId,
        RightRing = gs:GetItem(RaptureGearsetModule_GearsetItemIndex.RingRight).ItemId,
    }
end

function resolve_gearset_items(number)
    local gearset_ids = resolve_gearset_ids(number)
    if gearset_ids == nil then
        return nil
    end
    local items = {}
    for slot, _ in pairs(gearset_ids) do
        items[slot] = nil
    end
    for _, container in pairs(ALL_EQUIPMENT) do
        local inv = Inventory.GetInventoryContainer(container)
        for item in luanet.each(inv.Items) do
            local itemId = item.ItemId
            if item.IsHighQuality then
                itemId = itemId + 1000000
            end
            for slot, gid in pairs(gearset_ids) do
                if itemId == gid then
                    gearset_ids[slot] = nil
                    items[slot] = item
                    break
                end
            end
        end
    end
    for slot, gid in pairs(gearset_ids) do
        if gid ~= nil then
            log_(LEVEL_ERROR, log, "Did not find item for slot", slot, "with id", gid, "in gearset", number)
        end
    end
    return items
end

function item_in_gearset(in_gearset)
    in_gearset = default(in_gearset, true)
    return function(item)
        for idx = 0, NUM_GEARSETS - 1 do
            gs = resolve_gearset_items(idx)
            if gs ~= nil then
                for _, gsi in pairs(gs) do
                    if gsi.ItemId == item.ItemId
                        and gsi.Slot == item.Slot
                        and gsi.Container == item.Container
                        and gsi.IsHighQuality == item.IsHighQuality
                    then
                        return in_gearset
                    end
                end
            end
        end
        return not in_gearset
    end
end

function move_items(source_inv, dest_inv, pred)
    if type(source_inv) ~= "table" then
        source_inv = { source_inv }
    end
    if type(dest_inv) ~= "table" then
        dest_inv = { dest_inv }
    end
    local source_idx = 1
    local dest_idx = 1
    local destinv = nil
    while source_idx <= #source_inv do
        local sourceinv = Inventory.GetInventoryContainer(source_inv[source_idx])
        if sourceinv == nil then
            StopScript("No inventory", CallerName(false), source_inv[source_idx])
        else
            destinv = Inventory.GetInventoryContainer(dest_inv[dest_idx])
            if destinv == nil then
                StopScript("No inventory", CallerName(false), dest_inv[dest_idx])
            end
            for item in luanet.each(sourceinv.Items) do
                if pred(item) then
                    local need_move = true
                    while dest_idx <= #dest_inv and need_move do
                        if destinv.FreeSlots > 0 then
                            log("Moving", item.ItemId, "from", source_inv[source_idx], "to", dest_inv[dest_idx])
                            item:MoveItemSlot(dest_inv[dest_idx])
                            need_move = false
                            wait(0)
                        else
                            log_(LEVEL_INFO, log, "No space to move item to", dest_inv[dest_idx])
                            dest_idx = dest_idx + 1
                            if dest_idx <= #dest_inv then
                                destinv = Inventory.GetInventoryContainer(dest_inv[dest_idx])
                                if destinv == nil then
                                    StopScript("No inventory", CallerName(false), dest_inv[dest_idx])
                                end
                            end
                        end
                    end
                    if need_move then
                        return false -- found an item to move with no space available
                    end
                end
            end
        end
        source_idx = source_idx + 1
    end
    return true -- all items if any were able to be moved
end

function open_map(map_name, partial_ok)
    partial_ok = default(partial_ok, false)
    local ready = false
    repeat
        local addon = Addons.GetAddon("SelectIconString")
        if addon.Ready then
            title = addon:GetAtkValue(0)
            if title ~= nil then
                title = title.ValueString
            end
            if title == "Decipher" then
                ready = true
            else
                log_(LEVEL_ERROR, log, "SelectIconString found with unexpected title:", title)
                close_addon("SelectIconString")
            end
        end
        if not ready then
            Actions.ExecuteGeneralAction(19)
            wait(0.5)
        end
    until ready
    if not SelectInList(map_name, "SelectIconString", partial_ok) then
        log_(LEVEL_ERROR, log, "Map", map_name, "not found in map list")
        return false
    end
    wait_any_addons("SelectYesno")
    close_yes_no(true, map_name)
    wait_ready(10, 1)
end

function collect_reward_mail()
    if not Addons.GetAddon("LetterList").Ready then
        StopScript("LetterList addon not ready")
    end
    local count = tonumber(Addons.GetAddon("LetterList"):GetNode(1, 22, 23).Text:match("(.-)/"))
    repeat
        open_addon("LetterViewer", "LetterList", true, 0, 0)
        SafeCallback("LetterViewer", true, 1)
        repeat wait(0) until Addons.GetAddon("LetterViewer"):GetNode(1, 32, 2, 3).IsVisible
        repeat wait(0) until not Addons.GetAddon("LetterViewer"):GetNode(1, 32, 2, 3).IsVisible
        wait(.1)
        SafeCallback("LetterViewer", true, 2)
        wait_any_addons("SelectYesno")
        SafeCallback("SelectYesno", true, 0)
        local l = count
        repeat
            wait(0)
            count = tonumber(Addons.GetAddon("LetterList"):GetNode(1, 22, 23).Text:match("(.-)/"))
        until l ~= count
        wait(.1)
    until count == 0
    close_addon("LetterList")
end
