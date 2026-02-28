require 'utils'
require 'path_helpers'

--------------
-- Shopping --
--------------

function OpenShop(shopkeep_name, shop_name, callbacks)
    callbacks = default(callbacks, { SelectIconString = { 0 } })
    local keys = table_keys(callbacks)
    local ti = ResetTimeout()
    while not IsAddonReady(shop_name) do
        CheckTimeout(30, ti, CallerName(false), "Waiting for shop addon:", shop_name)

        local npc = get_closest_entity(shopkeep_name, true)
        npc:SetAsTarget()
        npc:Interact()

        local addon = wait_any_addons(shop_name, "Talk", table.unpack(keys))
        if addon == shop_name then
            return true
        elseif addon == "Talk" then
            close_talk(shop_name, table.unpack(keys))
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
