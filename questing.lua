require 'utils'
require 'path_helpers'
require 'inventory_buddy'


function PeluPelu(n)
    GetBeastTribeQuest("Yubli", "Viper",
        "H4sIAAAAAAAACu1SwW7aQBD9FTTnLbJpCfbeIkoiWkFJoCEQ5bDUE7ySd4d6Zxsh5H+v1hgIRcqpl0o97bzn9Zu3M28HY2UQJDxop7m18KtCt8bUGpG3DAJuS/IbkPDdrkOFGQi4IcpARgJGynpV1OVMlWvkW8U5lkNGU5Nztd2QtuxAPu1gQk6zJgtyB48ge724HXWTWMACZNxpJ5+uur2OgCXID51u2u59TOJKwJIsDj+DjOMkEXCvMu0dyDRN03ZwQL/QoOW63URx/qJtBvJFFQ4FDC1jqX7wXHP+LYhE51zzdDhn//AZhT6L5lzWZyXA5fR6+EmTdRc9a4FYwMAQ46E3o2nK6/pGA+48On5bT/HnfsC0augp06ZPNmucRQK+6qLo11sK6J484+k9/Vxxn4xRYRqBCH7nSvPJaEA3VJ6LBnKmDY7cGRzMLodRCRi6Sa4skzmKhhWAtL4oBIwRM7fP0eHzPh/armfbDYYtBo0xZXi8EcAXWoGMKvF3I9N5Jy9c+v9xoX87Ls/VbwBV+anMBAAA",
        false, n)
end

function MamoolJa(n)
    GetBeastTribeQuest("Kageel Ja", "Botanist",
        "H4sIAAAAAAAACu2V32/TMBDH/5Xqnk0U50cX+w2VbeqmlrIVyop48MitsZT4SuyApir/O3KabgsbvIKgT777xrk7331k72CuKgQJH7TVbnSpNojl6EKNZtQYBwzOa2q2IOG92XgLc2BwRpSDDBnMlGlU2ZlLVW/QnStXYD11WHXiSt1vSRtnQX7awYKsdpoMyB18BJlmWRBlIk0Z3IB8xZMoyAQfZwzWIE9iHvCTcdwyWJPB6RuQnGeCwZXKdWNBCiFE4Eugb1ihcV2+hXLFnTY5yDtVWmQwNQ5r9cWttCve+iDhUOsPD0P1p0JDn+emX9fd2jKwBX0//KTJ2Gc5uwCcwWlFDg+5HVa9+brb0TvvGrTuqX2NX/cdpttevna0nZDJ+8pCBpe6LCfdmLx3RY3Dx/NMCuUmVFXKd8MLvt6V0u6xUO+dUT0M6sWlrnBmB+7p8nkzWgZTuyiUcVQ9BPUjAGmasmQwR8ztHqTD5z0g2myW91v0U/Qx5pTjww7vXNAtyLBlLzCTBHwci+TATBIIHidRz0wcJFkm0l9Cw8MhMvwpMq5ujsT8RcTs5/FngYl+c8Ucefk3bxgRJFHy8qMUiSAep+KIi/w/cfnc/gA+PsqiMAkAAA==",
        true, n)
end

function Ananta(n)
    GetBeastTribeQuest("Eshana", "Viper",
        "H4sIAAAAAAAACu2VbWvbMBDHv8q415qR5We9K1lbspEsSwJZMvZCra+1wJY8S94IId99yHHSel2h7AE2yCvp/pbvTnc/dDuYigqBw4USyopXc6yBwHWj29qJZSkxX+hbiXYLBK60zoFTAhOhWlF226Vo7tFeC1tgM7ZYdeJKbGstlTXAP+1gpo20UivgO/gI/DWLPZYENPEJrIFHsUeZH0YpgQ1wFjCPRVEQ7glstMLxG+CxzwjMRS5bAzzLssxzKeivWKGyXbyZsMWdVDnwO1EaJDBWFhtxa1fSFu+dDzrU+lvDUP0hUerirPt10617AqbQ344/Sa3Mk5idA5/AZaUtHmNbrPrtRXeiNz60aOzj/QK/HCqsb3p5YXU90irvM6ME3smyHOm2v/tctxYf7jMqhB3pqhKuGk5w+a6EtA+JOutKN0OnTlzKCidmYF4unxZjT2BsZoVQVlcnp64FwFVblgSmiLmZHDLsPx8Akep+ua3RddH5mOocTyec8VbfAKd78hNmfM8P4o6ENfAk9sIgYOyADPO9MKTps8iwIS/+Y15s074cFzSFUOIMzV+H5tCV32Ym8fw4oDQ8vjO+H2Vx0r8zgReljKbPQRP8KWjOuPwvuMReFLKIpaexlCZZGp/GUhYwmrwQl8FMOuMi/ilcfmUkfd5/BxKUKEMrCQAA",
        false, n)
end

function Namazu(n)
    GetBeastTribeQuest("Seigetsu the Enlightened", "Culinarian",
        "H4sIAAAAAAAACu1SwW7bMAz9lYFn1ZDjxI51K7K2SIdkWRIga4od1JqtBdiiZ9EbssD/Pshx02Xdei/QE8ln+fGRfHuY6xJB+aB/NR+WWIGAq5qaChScF4XBbEX3BnkHAi6JMlBSwEzbRhddutb1I/KV5hzrKWPZgRu9q8hYdqBu97AgZ9iQBbWHr6DOkiQOwngUxgJuQIWDJIjGSTQUsAUVyjAYpnIQtwK2ZHH6EVQ8GAhY6sw0DlSapmngJdAPLNFy12+hOX8wNgP1oAuHAqaWsdb3vDGcf/Yc8hTrp4ZT9C+h0ve56eO2i60Al9PPp58MWfeiZ0cQCrgoifGpN2PZp+fdi7740qDjP/MVfj9smO56eMVUTchmvTIp4JMpigk1/exLahif55nkmidUltpvwwNe70Ybfhbqq0uqT0k9uDYlztxJebF+uYxWwNQtcm2ZyiOpPwEo2xSFgDli5mYHhf3ng0GMfVzvKvRX9BxzyvD4whfXdAdKtuJfnkmC0XA0io6eGcuxTLq7pOMgjaL/OiZ6xS5cN+9uobftlm/tbzU59I3GBAAA",
        false, n)
end

function GetBeastTribeQuest(npc, class, path, one_per, n)
    n = default(n, 3)
    one_per = default(one_per, false)
    yield("/gbr auto off")
    yield("/at y")
    equip_gearset(class)

    for i = 1, n do
        if not IsNearThing(npc, 4) then
            RunVislandRoute(path, "Going to " .. npc)
        end
        AcceptQuest(npc)
        if one_per or i == n then
            RunQuesty()
        end
    end
end

function RunQuesty(max_time)
    max_time = default(max_time, 10 * 60)
    local ti = ResetTimeout()
    repeat
        CheckTimeout(10, ti, CallerName(false), "Starting questy")
        yield("/qst start")
        wait(2)
    until IPC.Questionable.IsRunning()
    repeat
        CheckTimeout(max_time, ti, CallerName(false), "Running questy")
        wait(.1)
    until not IPC.Questionable.IsRunning()
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
