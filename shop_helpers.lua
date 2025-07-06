require 'utils'
require 'path_helpers'

--------------
-- Shopping --
--------------

function OpenShop(shopkeep_name, shop_name)
    local ti = ResetTimeout()
    while not IsAddonReady(shop_name) do
        CheckTimeout(30, ti, CallerName(false), "Waiting for shop addon:", shop_name)

        if not IsAddonReady("SelectIconString") then
            local entity = get_closest_entity(shopkeep_name)
            if entity then
                entity:SetAsTarget()
                entity:Interact()
            end
        else
            yield("/callback SelectIconString true 0")
        end
        yield("/wait 0.1")
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
