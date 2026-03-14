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
        CheckTimeout(30, ti, CallerName(false), "Waiting for shop addon:", table.unpack(shop_names))

        local npc = get_closest_entity(shopkeep_name, true)
        npc:SetAsTarget()
        npc:Interact()

        local addon = wait_any_addons("Talk", table.unpack(all_names))
        if list_contains(shop_names, addon) then
            return true
        elseif addon == "Talk" then
            close_talk(table.unpack(all_names))
        else
            local callback = callbacks[addon]
            SafeCallback(addon, true, table.unpack(callback))
        end
        wait(.1)
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
