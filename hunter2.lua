require 'utils'
require 'path_helpers'
require 'shop_helpers'


function GetHunts()
    if Inventory.GetInventoryItem(get_item_info("Elite Mark Bill").itemId) == nil then
        -- ARR
        if Player.GrandCompany == 1 then
            TownPath("Limsa Lominsa Lower Decks", 95, 40, 61, "The Aftcastle", "Limsa Lominsa Upper Decks")
        elseif Player.GrandCompany == 2 then
            TownPath("New Gridania", -75, 0, 0)
        elseif Player.GrandCompany == 3 then
            TownPath("Ul'dah - Steps of Nald", -150, 5, -95)
        end
        GrabHunt("Hunt", 1)
    else
        log("Skipping ARR hunt")
    end

    if Inventory.GetInventoryItem(get_item_info("Elite Clan Mark Bill").itemId) == nil then
        -- HW
        TownPath("Foundation", 75, 25, 20, "The Forgotten Knight")
        GrabHunt("Clan Hunt", 3, 2)
    else
        log("Skipping HW hunt")
    end

    if Inventory.GetInventoryItem(get_item_info("Elite Veteran Clan Mark Bill").itemId) == nil then
        -- SB
        TownPath("Kugane", -30, 0, -45)
        GrabHunt("Clan Hunt", 3, 3)
    else
        log("Skipping SB hunt")
    end

    if Inventory.GetInventoryItem(get_item_info("Elite Clan Nutsy Mark Bill").itemId) == nil then
        -- ShB
        TownPath("The Crystarium", -85, 0, -90, "Temenos Rookery")
        GrabHunt("Nuts", 3, 4)
    else
        log("Skipping ShB hunt")
    end

    if Inventory.GetInventoryItem(get_item_info("Elite Guildship Mark Bill").itemId) == nil then
        -- EW
        TownPath("Radz-at-Han", -35, 1, -195, "Mehryde's Meyhane")
        GrabHunt("Guildship Hunt", 3, 5)
    else
        log("Skipping EW hunt")
    end

    if Inventory.GetInventoryItem(get_item_info("Elite Dawn Hunt Bill").itemId) == nil then
        -- DT
        TownPath("Tuliyollal", 25, -15, 135, "Bayside Bevy Marketplace")
        GrabHunt("Hunt", 3, 6)
    else
        log("Skipping DT hunt")
    end
end

function GrabHunt(boardName, stringIndex, huntIndex)
    OpenShop(boardName .. " Board", "SelectString")
    confirm_addon("SelectString", true, stringIndex)
    if huntIndex == nil then
        confirm_addon("Mobhunt", true, 0)
    else
        confirm_addon(string.format("Mobhunt%d", huntIndex), true, 0)
    end
    wait_ready(10, 2)
end

function HasAnyLog()
    for _, log in pairs({
        "Elite Mark Bill",
        "Elite Clan Mark Bill",
        "Elite Veteran Clan Mark Bill",
        "Elite Clan Nutsy Mark Bill",
        "Elite Guildship Mark Bill",
        "Elite Dawn Hunt Bill"
    }) do
        local item = Inventory.GetInventoryItem(get_item_info(log).itemId)
        if item ~= nil and item.Count >= 1 then
            return true
        end
    end
    return false
end
