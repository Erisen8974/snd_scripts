require 'utils'

INT_POT = item_info_list.Grade2GemdraughtofIntelligence
DEX_POT = item_info_list.Grade2GemdraughtofDexterity
RAID_FOOD = item_info_list.Moqueca

BOND_MAN = item_info_list.SquadronSpiritbondingManual
-- Craft settings are for bond man. BOND_POT = item_info_list.SuperiorSpiritbondPotion

function CouldCraft()
    -- is not in any crafting menu or is at the craft select menu!
    return GetCharacterCondition(41) or not GetCharacterCondition(5)
end

function DoCraft(item_info, amt)
    local ti = ResetTimeout()
    local id = default(item_info.itemId, 0)
    local before
    if id ~= 0 then
        before = GetItemCount(id)
    end
    repeat
        CheckTimeout(10, ti, "DoCraft", item_info.itemName, amt, "not ready to craft")
        wait(1)
    until CouldCraft()
    ArtisanCraftItem(item_info.recipeId, amt)
    repeat
        CheckTimeout(60 * amt, ti, "DoCraft", item_info.itemName, amt, "did not finish")
        wait(1)
    until not ArtisanGetEnduranceStatus()
    if id ~= 0 then
        if GetItemCount(id) == before then
            log_debug("Craft failed for item", item_info.itemName, "still have", before)
            return false -- item didnt craft
        end
    end
    return true -- item crafted or we dont know the id
end

-- until buff_item expires, craft 5 of each of the items.
-- The items need to be configured to require buff_item and no buff_item in inv
-- if buff_item is in inv it will get used
-- if it is not required extras will be made without buff (to the end of cycle)
function SessionCrafting(buff_item, ...)
    local crafts = table.pack(...)
    local failures = {}
    repeat
        local craft_attempted = false
        for i = 1, crafts.n do
            -- Auto Retainer has integration hidden in /ays expert for this
            --if ARRetainersWaitingToBeProcessed() then
            --    close_addon("RecipieNote")
            --    open_retainer_bell()
            --    close_addon("RetainerList")
            --end
            local item = crafts[i]
            local count = default(failures[item], 0)
            if count < 5 then
                craft_attempted = true
                if DoCraft(item, 5) then
                    failures[item] = 0 --reset sequential fail count cause it worked
                else
                    close_addon("RecipieNote")
                    log("Craft", item.itemName, "failed", count + 1, "times")
                    failures[item] = count + 1
                end
            elseif count == 5 then
                failures[item] = count + 1 -- set it to 6 to not report again
                log("Craft failed 5 times", item.itemName, "no more attempts will be made.")
            end
        end
        if not craft_attempted then
            log("All targets failed crafting too many times. Stopping early!")
            return false
        end
    until not HasStatusId(buff_item.buffId)
    return true
end
