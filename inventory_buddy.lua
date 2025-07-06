require 'utils'



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
    for _, item_info in ipairs(item_info_list) do
        if item_info.itemId == item_id then
            return item_info
        end
    end
end

function equip_gearset(gearset_name)
    local ti = ResetTimeout()
    for gs in luanet.each(Player.Gearsets) do
        if gs.Name == gearset_name then
            repeat
                CheckTimeout(10, ti, CallerName(false), "Couldnt equip gearset:", gearset_name)
                gs:Equip()
                wait_ready(10, 1)
            until Player.Gearset.Name == gearset_name
            log_debug("Gearset", gearset_name, "equipped")
            return true
        end
    end
    log_debug("Gearset", gearset_name, "not found")
    return false
end
