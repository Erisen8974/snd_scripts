require 'utils'
require 'path_helpers'

--------------
-- Shopping --
--------------

function OpenShop(shopkeep_name, shop_names, callbacks)
    if type(shop_names) == "string" then
        shop_names = { shop_names }
    end
    callbacks = default(callbacks, { SelectIconString = { 0 } })
    local keys = table_keys(callbacks)
    local all_names = list_concat(shop_names, keys)
    local ti = ResetTimeout()
    while true do
        CheckTimeout(30, ti, "Waiting for shop addon:", table.unpack(shop_names))
        local addon = nil
        repeat
            CheckTimeout(5, ti, "Opening shop with", shopkeep_name)
            local npc = get_closest_entity(shopkeep_name, true)
            npc:SetAsTarget()
            npc:Interact()
            wait(.1)
            addon = any_addons_ready("Talk", table.unpack(all_names))
        until addon ~= nil

        if list_contains(shop_names, addon) then
            return true
        elseif addon == "Talk" then
            close_talk(table.unpack(all_names))
        else
            local callback = callbacks[addon]
            SafeCallback(addon, true, table.unpack(callback))
        end
    end
end

function OpenCollectableShop()
    OpenShop("Collectable Appraiser", "CollectablesShop")
end

function OpenScripShop()
    OpenShop("Scrip Exchange", "InclusionShop")
end

function CloseExchanges()
    if IsAddonReady("CollectablesShop") then
        yield("/callback CollectablesShop true -1")
    end
    if IsAddonReady("InclusionShop") then
        yield("/callback InclusionShop true -1")
    end
end

function is_auto_repairing()
    local rep = Addons.GetAddon("RepairAuto")
    if rep == nil or not rep.Ready then
        return false
    end
    return rep:GetAtkValue(0).ValueString ~= "1"
end
